<script>
import { s__, n__ } from '~/locale';
import { GlButton, GlFormSelect } from '@gitlab/ui';
import toast from '~/vue_shared/plugins/global_toast';
import createFlash from '~/flash';
import dismissVulnerability from '../graphql/dismissVulnerability.graphql';

const REASON_NONE = s__('SecurityReports|[No reason]');
const REASON_WONT_FIX = s__("SecurityReports|Won't fix / Accept risk");
const REASON_FALSE_POSITIVE = s__('SecurityReports|False positive');

export default {
  name: 'SelectionSummary',
  components: {
    GlButton,
    GlFormSelect,
  },
  props: {
    selectedVulnerabilities: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      dismissalReason: null,
    };
  },
  computed: {
    selectedVulnerabilitiesCount() {
      return this.selectedVulnerabilities.length;
    },
    canDismissVulnerability() {
      return Boolean(this.dismissalReason && this.selectedVulnerabilitiesCount > 0);
    },
    message() {
      return n__(
        'Dismiss %d selected vulnerability as',
        'Dismiss %d selected vulnerabilities as',
        this.selectedVulnerabilitiesCount,
      );
    },
  },
  methods: {
    dismissalSuccessMessage() {
      return n__(
        '%d vulnerability dismissed',
        '%d vulnerabilities dismissed',
        this.selectedVulnerabilities.length,
      );
    },
    handleDismiss() {
      if (!this.canDismissVulnerability) return;

      this.dismissSelectedVulnerabilities();
    },
    dismissSelectedVulnerabilities() {
      const promises = this.selectedVulnerabilities.map(vulnerability =>
        this.$apollo.mutate({
          mutation: dismissVulnerability,
          variables: { id: vulnerability.id, comment: this.dismissalReason },
        }),
      );

      Promise.all(promises)
        .then(() => {
          toast(this.dismissalSuccessMessage());
          this.$emit('deselect-all-vulnerabilities');
        })
        .catch(() => {
          createFlash(
            s__('SecurityReports|There was an error dismissing the vulnerabilities.'),
            'alert',
          );
        })
        .finally(() => {
          this.$emit('refetch-vulnerabilities');
        });
    },
  },
  dismissalReasons: [
    { value: null, text: s__('SecurityReports|Select a reason') },
    REASON_FALSE_POSITIVE,
    REASON_WONT_FIX,
    REASON_NONE,
  ],
};
</script>

<template>
  <div class="card">
    <form class="card-body d-flex align-items-center" @submit.prevent="handleDismiss">
      <span ref="dismiss-message">{{ message }}</span>
      <gl-form-select
        v-model="dismissalReason"
        class="mx-3 w-auto"
        :options="$options.dismissalReasons"
      />
      <gl-button
        type="submit"
        class="js-no-auto-disable"
        category="secondary"
        variant="warning"
        :disabled="!canDismissVulnerability"
      >
        {{ s__('SecurityReports|Dismiss Selected') }}
      </gl-button>
    </form>
  </div>
</template>
