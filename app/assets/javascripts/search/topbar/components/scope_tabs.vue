<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { ALL_SCOPE_TABS } from '../constants';

export default {
  name: 'ScopeTabs',
  components: {
    GlTabs,
    GlTab,
    GlBadge,
  },
  props: {
    scopeTabs: {
      type: Array,
      required: true,
    },
    count: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapState(['query', 'inflatedScopeTabs']),
  },
  created() {
    this.fetchSearchCounts({ scopeTabs: this.scopeTabs, activeCount: this.count });
  },
  methods: {
    ...mapActions(['fetchSearchCounts']),
    handleTabChange(scope) {
      const params = {
        scope,
        page: null,
        state: null,
        confidential: null,
        nav_source: null,
        ...ALL_SCOPE_TABS[scope].search,
      };
      visitUrl(setUrlParams(params));
    },
    isTabActive(scope) {
      return scope === this.query.scope;
    },
  },
};
</script>

<template>
  <div>
    <gl-tabs content-class="gl-p-0" nav-class="search-filter search-nav-tabs gl-display-flex gl-overflow-x-auto">
      <gl-tab
        v-for="tab in inflatedScopeTabs"
        :key="tab.scope"
        class="gl-display-flex"
        :active="isTabActive(tab.scope)"
        :title-link-attributes="{ 'data-qa-selector': tab.qaSelector }"
        title-link-class="gl-white-space-nowrap"
        @click="handleTabChange(tab.scope)"
      >
        <template #title>
          <span> {{ tab.title }} </span>
          <gl-badge
            v-show="tab.count"
            :data-scope="tab.scope"
            :data-testid="tab.scope"
            :variant="isTabActive(tab.scope) ? 'neutral' : 'muted'"
            size="sm"
          >
            {{ tab.count }}
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
