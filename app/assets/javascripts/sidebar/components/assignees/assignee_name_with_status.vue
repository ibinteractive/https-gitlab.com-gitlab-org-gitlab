<script>
import { isUserBusy } from '~/set_status_modal/utils';

export default {
  name: 'AssigneeNameWithStatus',
  props: {
    assigneeName: {
      type: String,
      required: true,
    },
    containerClasses: {
      type: String,
      required: false,
      default: '',
    },
    availability: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isBusy() {
      return isUserBusy(this.availability);
    },
  },
};
</script>
<template>
  <span :class="containerClasses">
    <gl-sprintf v-if="isBusy" :message="s__('UserAvailability|%{name} (Busy)')">
      <template #name>{{ assigneeName }}</template>
    </gl-sprintf>
    <template v-else>{{ assigneeName }}</template>
  </span>
</template>
