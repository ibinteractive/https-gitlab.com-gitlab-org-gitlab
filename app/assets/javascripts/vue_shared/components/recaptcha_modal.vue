<script>
/* eslint-disable vue/no-v-html */
import { GlModal } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { eventHub } from './recaptcha_eventhub';

export default {
  name: 'RecaptchaModal',
  components: {
    GlModal,
  },
  props: {
    html: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    return {
      script: {},
      scriptSrc: 'https://www.recaptcha.net/recaptcha/api.js',
    };
  },

  watch: {
    html() {
      this.appendRecaptchaScript();
    },
  },

  mounted() {
    eventHub.$on('submit', this.submit);

    if (this.html) {
      this.appendRecaptchaScript();
    }
  },

  beforeDestroy() {
    eventHub.$off('submit', this.submit);
  },
  computed: {
    show() {
      return !isEmpty(this.html);
    },
  },
  methods: {
    appendRecaptchaScript() {
      this.removeRecaptchaScript();

      const script = document.createElement('script');
      script.src = this.scriptSrc;
      script.classList.add('js-recaptcha-script');
      script.async = true;
      script.defer = true;

      this.script = script;

      document.body.appendChild(script);
    },

    removeRecaptchaScript() {
      if (this.script instanceof Element) this.script.remove();
    },

    close() {
      this.removeRecaptchaScript();
      this.$emit('close');
    },

    submit() {
      this.$refs.recaptcha.querySelector('form').submit();
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="show"
    :hide-footer="true"
    :title="__('Please solve the reCAPTCHA')"
    modal-id="recaptcha-modal"
    kind="warning"
    class="recaptcha-modal js-recaptcha-modal"
    @cancel="close"
  >
    <p>{{ __('We want to be sure it is you. Please confirm you are not a robot.') }}</p>
    <div ref="recaptcha" v-html="html"></div>
  </gl-modal>
</template>
