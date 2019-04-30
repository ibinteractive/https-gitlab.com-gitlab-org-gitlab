# frozen_string_literal: true

module Gitlab
  module Geo
    module Oauth
      class Session
        include Gitlab::Routing
        include Gitlab::Utils::StrongMemoize
        include GrapePathHelpers::NamedRouteMatcher

        # We don't use oauth_token_path helper because its output depends
        # on secondary configuration (ex., relative URL) while we really need
        # it for a primary. This is why we're building it ourselves using
        # primary node configuration and this static URL
        TOKEN_PATH = '/oauth/token'

        def authorize_url(params = {})
          oauth_client.auth_code.authorize_url(params)
        end

        def authenticate(access_token)
          api = OAuth2::AccessToken.from_hash(oauth_client, access_token: access_token)
          api.get(primary_api_user_path).parsed
        end

        def get_token(code, params = {}, opts = {})
          oauth_client.auth_code.get_token(code, params, opts).token
        end

        private

        def oauth_application
          strong_memoize(:oauth_application) do
            Gitlab::Geo.oauth_authentication
          end
        end

        def oauth_client
          strong_memoize(:oauth_client) do
            ::OAuth2::Client.new(
              oauth_application&.uid,
              oauth_application&.secret,
              site: Gitlab::Geo.primary_node.url,
              authorize_url: oauth_authorization_path,
              token_url: token_url
            )
          end
        end

        def primary_api_user_path
          Gitlab::Utils.append_path(Gitlab::Geo.primary_node.internal_url, api_v4_user_path)
        end

        def token_url
          Gitlab::Utils.append_path(Gitlab::Geo.primary_node.internal_url, TOKEN_PATH)
        end
      end
    end
  end
end
