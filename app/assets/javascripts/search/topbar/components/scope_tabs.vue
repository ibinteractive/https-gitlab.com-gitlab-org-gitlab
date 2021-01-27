<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { mapState } from 'vuex';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
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
    countPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      inflatedTabs: [],
    };
  },
  computed: {
    ...mapState(['query']),
  },
  async created() {
    if (!this.query.search) return;

    this.inflatedTabs = this.scopeTabs.map((tab) => {
      return { ...ALL_SCOPE_TABS[tab], count: this.isTabActive(tab) ? this.count : '' };
    });

    const promises = this.scopeTabs.map((scope) => this.getCount(scope));

    const inflatedTabs = await Promise.all(promises).then((tabCounts) => {
      return tabCounts.map((tab) => {
        return { ...ALL_SCOPE_TABS[tab.scope], count: tab.count };
      });
    });
    this.$set(this, 'inflatedTabs', inflatedTabs);
  },
  methods: {
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
    showCount(el, count) {
      el.textContent = count;
      el.classList.remove('hidden');
    },
    getCount(scope) {
      const params = { ...this.query, scope };

      return axios
        .get(this.countPath, { params })
        .then(({ data }) => {
          return { scope, count: data.count };
        })
        .catch((e) => {
          // eslint-disable-next-line no-console
          console.error(`Failed to fetch search count from '${this.countPath}'.`, e);
        });
    },
    shouldShowTabs() {
      return this.query.search;
    },
  },
};
</script>

<template>
  <div v-if="shouldShowTabs" class="scrolling-tabs-container inner-page-scroll-tabs">
    <gl-tabs nav-class="search-filter scrolling-tabs search-nav-tabs">
      <gl-tab
        v-for="tab in inflatedTabs"
        :key="tab.scope"
        :active="isTabActive(tab.scope)"
        :title-link-attributes="{ 'data-qa-selector': tab.qaSelector }"
        @click="handleTabChange(tab.scope)"
      >
        <template #title>
          <span> {{ tab.title }} </span>
          <gl-badge
            v-show="tab.count"
            :data-scope="tab.scope"
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
