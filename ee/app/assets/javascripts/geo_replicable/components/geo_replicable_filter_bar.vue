<script>
import { mapActions, mapState } from 'vuex';
import { debounce } from 'lodash';
import { GlSearchBoxByType, GlDropdown, GlDropdownItem, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { DEFAULT_SEARCH_DELAY, ACTION_TYPES } from '../store/constants';

export default {
  name: 'GeoReplicableFilterBar',
  components: {
    GlSearchBoxByType,
    GlDropdown,
    GlDropdownItem,
    GlButton,
  },
  computed: {
    ...mapState(['currentFilterIndex', 'filterOptions', 'searchFilter', 'replicableType']),
    search: {
      get() {
        return this.searchFilter;
      },
      set: debounce(function debounceSearch(newVal) {
        this.setSearch(newVal);
        this.fetchReplicableItems();
      }, DEFAULT_SEARCH_DELAY),
    },
    resyncText() {
      return sprintf(__('Resync all %{replicableType}'), { replicableType: this.replicableType });
    },
  },
  methods: {
    ...mapActions(['setFilter', 'setSearch', 'fetchReplicableItems', 'initiateAllReplicableSyncs']),
    filterChange(filterIndex) {
      this.setFilter(filterIndex);
      this.fetchReplicableItems();
    },
  },
  actionTypes: ACTION_TYPES,
};
</script>

<template>
  <nav class="bg-secondary border-bottom border-secondary-100 p-3">
    <div class="row d-flex flex-column flex-sm-row">
      <div class="col">
        <div class="d-sm-flex mx-n1">
          <gl-dropdown :text="__('Filter by status')" class="px-1 my-1 my-sm-0 w-100">
            <gl-dropdown-item
              v-for="(filter, index) in filterOptions"
              :key="index"
              :class="{ 'bg-secondary-100': index === currentFilterIndex }"
              @click="filterChange(index)"
            >
              <span
                >{{ filter.label }}
                <span v-if="filter.label === 'All'">{{ replicableType }}</span></span
              >
            </gl-dropdown-item>
          </gl-dropdown>
          <gl-search-box-by-type
            v-model="search"
            class="px-1 my-1 my-sm-0 bg-white w-100"
            type="text"
            :placeholder="__('Filter by name')"
          />
        </div>
      </div>
      <div class="col col-sm-5 d-flex justify-content-end my-1 my-sm-0 w-100">
        <gl-button @click="initiateAllReplicableSyncs($options.actionTypes.RESYNC)">{{
          __('Resync all')
        }}</gl-button>
      </div>
    </div>
  </nav>
</template>
