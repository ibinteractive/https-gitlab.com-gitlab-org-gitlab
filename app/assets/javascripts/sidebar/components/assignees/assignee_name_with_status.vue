<script>
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
    status: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <span :class="containerClasses">
    <gl-sprintf v-if="authorIsBusy" :message="s__('UserAvailability|%{author} (Busy)')">
      <template #author>{{ authorName }}</template>
    </gl-sprintf>
    <template v-else>{{ authorName }}</template>
  </span>
</template>
