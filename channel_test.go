package main

import (
	"bytes"
	"encoding/pem"
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"path"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
)

var (
	envTerminalPath     = fmt.Sprintf("%s/-/environments/1/terminal.ws", testProject)
	jobTerminalPath     = fmt.Sprintf("%s/-/jobs/1/terminal.ws", testProject)
	servicesProxyWSPath = fmt.Sprintf("%s/-/jobs/1/proxy.ws", testProject)
)

type connWithReq struct {
	conn *websocket.Conn
	req  *http.Request
}

func TestChannelHappyPath(t *testing.T) {
	tests := []struct {
		name        string
		channelPath string
	}{
		{"environments", envTerminalPath},
		{"jobs", jobTerminalPath},
		{"services", servicesProxyWSPath},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			serverConns, clientURL, close := wireupChannel(test.channelPath, nil, "channel.k8s.io")
			defer close()

			client, _, err := dialWebsocket(clientURL, nil, "terminal.gitlab.com")
			if err != nil {
				t.Fatal(err)
			}

			server := (<-serverConns).conn
			defer server.Close()

			message := "test message"

			// channel.k8s.io: server writes to channel 1, STDOUT
			if err := say(server, "\x01"+message); err != nil {
				t.Fatal(err)
			}
			assertReadMessage(t, client, websocket.BinaryMessage, message)

			if err := say(client, message); err != nil {
				t.Fatal(err)
			}

			// channel.k8s.io: client writes get put on channel 0, STDIN
			assertReadMessage(t, server, websocket.BinaryMessage, "\x00"+message)

			// Closing the client should send an EOT signal to the server's STDIN
			client.Close()
			assertReadMessage(t, server, websocket.BinaryMessage, "\x00\x04")
		})
	}
}

func TestChannelBadTLS(t *testing.T) {
	_, clientURL, close := wireupChannel(envTerminalPath, badCA, "channel.k8s.io")
	defer close()

	client, _, err := dialWebsocket(clientURL, nil, "terminal.gitlab.com")
	if err != websocket.ErrBadHandshake {
		t.Fatalf("Expected connection to fail ErrBadHandshake, got: %v", err)
	}
	if err == nil {
		log.Info("TLS negotiation should have failed!")
		defer client.Close()
	}
}

func TestChannelSessionTimeout(t *testing.T) {
	serverConns, clientURL, close := wireupChannel(envTerminalPath, timeout, "channel.k8s.io")
	defer close()

	client, _, err := dialWebsocket(clientURL, nil, "terminal.gitlab.com")
	if err != nil {
		t.Fatal(err)
	}

	sc := <-serverConns
	defer sc.conn.Close()

	client.SetReadDeadline(time.Now().Add(time.Duration(2) * time.Second))
	_, _, err = client.ReadMessage()

	if !websocket.IsCloseError(err, websocket.CloseAbnormalClosure) {
		t.Fatalf("Client connection was not closed, got %v", err)
	}
}

func TestChannelProxyForwardsHeadersFromUpstream(t *testing.T) {
	hdr := make(http.Header)
	hdr.Set("Random-Header", "Value")
	serverConns, clientURL, close := wireupChannel(envTerminalPath, setHeader(hdr), "channel.k8s.io")
	defer close()

	client, _, err := dialWebsocket(clientURL, nil, "terminal.gitlab.com")
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()

	sc := <-serverConns
	defer sc.conn.Close()
	if sc.req.Header.Get("Random-Header") != "Value" {
		t.Fatal("Header specified by upstream not sent to remote")
	}
}

func TestChannelProxyForwardsXForwardedForFromClient(t *testing.T) {
	serverConns, clientURL, close := wireupChannel(envTerminalPath, nil, "channel.k8s.io")
	defer close()

	hdr := make(http.Header)
	hdr.Set("X-Forwarded-For", "127.0.0.2")
	client, _, err := dialWebsocket(clientURL, hdr, "terminal.gitlab.com")
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	clientIP, _, err := net.SplitHostPort(client.LocalAddr().String())
	if err != nil {
		t.Fatal(err)
	}

	sc := <-serverConns
	defer sc.conn.Close()

	if xff := sc.req.Header.Get("X-Forwarded-For"); xff != "127.0.0.2, "+clientIP {
		t.Fatalf("X-Forwarded-For from client not sent to remote: %+v", xff)
	}
}

func wireupChannel(channelPath string, modifier func(*api.Response), subprotocols ...string) (chan connWithReq, string, func()) {
	serverConns, remote := startWebsocketServer(subprotocols...)
	authResponse := channelOkBody(remote, nil, subprotocols...)
	if modifier != nil {
		modifier(authResponse)
	}
	upstream := testAuthServer(nil, nil, 200, authResponse)
	workhorse := startWorkhorseServer(upstream.URL)

	return serverConns, websocketURL(workhorse.URL, channelPath), func() {
		workhorse.Close()
		upstream.Close()
		remote.Close()
	}
}

func startWebsocketServer(subprotocols ...string) (chan connWithReq, *httptest.Server) {
	upgrader := &websocket.Upgrader{Subprotocols: subprotocols}

	connCh := make(chan connWithReq, 1)
	server := httptest.NewTLSServer(webSocketHandler(upgrader, connCh))

	return connCh, server
}

func webSocketHandler(upgrader *websocket.Upgrader, connCh chan connWithReq) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		logEntry := log.WithFields(log.Fields{
			"method":  r.Method,
			"url":     r.URL,
			"headers": r.Header,
		})

		logEntry.Info("WEBSOCKET")
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			logEntry.WithError(err).Error("WEBSOCKET Upgrade failed")
			return
		}
		connCh <- connWithReq{conn, r}
		// The connection has been hijacked so it's OK to end here
	})
}

func channelOkBody(remote *httptest.Server, header http.Header, subprotocols ...string) *api.Response {
	out := &api.Response{
		Channel: &api.ChannelSettings{
			Url:            websocketURL(remote.URL),
			Header:         header,
			Subprotocols:   subprotocols,
			MaxSessionTime: 0,
		},
	}

	if len(remote.TLS.Certificates) > 0 {
		data := bytes.NewBuffer(nil)
		pem.Encode(data, &pem.Block{Type: "CERTIFICATE", Bytes: remote.TLS.Certificates[0].Certificate[0]})
		out.Channel.CAPem = data.String()
	}

	return out
}

func badCA(authResponse *api.Response) {
	authResponse.Channel.CAPem = "Bad CA"
}

func timeout(authResponse *api.Response) {
	authResponse.Channel.MaxSessionTime = 1
}

func setHeader(hdr http.Header) func(*api.Response) {
	return func(authResponse *api.Response) {
		authResponse.Channel.Header = hdr
	}
}

func dialWebsocket(url string, header http.Header, subprotocols ...string) (*websocket.Conn, *http.Response, error) {
	dialer := &websocket.Dialer{
		Subprotocols: subprotocols,
	}

	return dialer.Dial(url, header)
}

func websocketURL(httpURL string, suffix ...string) string {
	url, err := url.Parse(httpURL)
	if err != nil {
		panic(err)
	}

	switch url.Scheme {
	case "http":
		url.Scheme = "ws"
	case "https":
		url.Scheme = "wss"
	default:
		panic("Unknown scheme: " + url.Scheme)
	}

	url.Path = path.Join(url.Path, strings.Join(suffix, "/"))

	return url.String()
}

func say(conn *websocket.Conn, message string) error {
	return conn.WriteMessage(websocket.TextMessage, []byte(message))
}

func assertReadMessage(t *testing.T, conn *websocket.Conn, expectedMessageType int, expectedData string) {
	messageType, data, err := conn.ReadMessage()
	if err != nil {
		t.Fatal(err)
	}

	if messageType != expectedMessageType {
		t.Fatalf("Expected message, %d, got %d", expectedMessageType, messageType)
	}

	if string(data) != expectedData {
		t.Fatalf("Message was mangled in transit. Expected %q, got %q", expectedData, string(data))
	}
}
