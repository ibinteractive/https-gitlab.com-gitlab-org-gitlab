<script>
import ApprovalCheckPopover from './approval_check_popover.vue';
import { VULNERABILITY_CHECK_NAME, LICENSE_CHECK_NAME, APPROVAL_RULE_CONFIGS } from '../constants';

export default {
  name: 'ApprovalCheckRulePopover',
  components: {
    ApprovalCheckPopover,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    securityApprovalsHelpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    showVulnerabilityCheckPopover() {
      return this.rule.name === VULNERABILITY_CHECK_NAME;
    },
    showLicenseCheckPopover() {
      return this.rule.name === LICENSE_CHECK_NAME;
    },
    showApprovalCheckPopover() {
      return this.showVulnerabilityCheckPopover || this.showLicenseCheckPopover;
    },
    approvalRuleConfig() {
      return APPROVAL_RULE_CONFIGS[this.rule.name];
    },
    documentationLink() {
      /*
       * The docs for these two rules have the same url & anchor
       * We get the path from a rails view helper
       */
      if (this.showLicenseCheckPopover || this.showApprovalCheckPopover) {
        return this.securityApprovalsHelpPagePath;
      }
      return '';
    },
  },
};
</script>

<template>
  <approval-check-popover
    v-if="showApprovalCheckPopover"
    :title="approvalRuleConfig.title"
    :text="approvalRuleConfig.popoverText"
    :documentation-link="documentationLink"
    :documentation-text="approvalRuleConfig.documentationText"
  />
</template>
