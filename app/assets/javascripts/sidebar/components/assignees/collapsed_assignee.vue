<script>
import AssigneeAvatar from './assignee_avatar.vue';
import AssigneeNameWithStatus from './assignee_name_with_status.vue';

export default {
  components: {
    AssigneeAvatar,
    AssigneeNameWithStatus,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
  },
};
</script>

<template>
  <button type="button" class="btn-link">
    <assignee-avatar :user="user" :img-size="24" :issuable-type="issuableType" />
    <assignee-name-with-status
      :assignee-name="user.name"
      :status="user.availability"
      container-classes="author"
    />
  </button>
</template>
