import { shallowMount } from '@vue/test-utils';

import SidebarItemEpicsSelect from 'ee/sidebar/components/sidebar_item_epics_select.vue';

import {
  mockSidebarStore,
  mockEpic1,
  mockIssue,
} from 'ee_jest/vue_shared/components/sidebar/mock_data';

describe('SidebarItemEpicsSelect', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(SidebarItemEpicsSelect, {
      stubs: {
        'epics-select': true,
      },
      propsData: {
        canEdit: true,
        sidebarStore: mockSidebarStore,
        epicIssueId: mockSidebarStore.epic_issue_id,
        groupId: mockEpic1.group_id,
        issueId: mockIssue.id,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('getInitialEpicLoading', () => {
      it('should return `false` when `initialEpic` prop is provided', () => {
        wrapper.setProps({
          initialEpic: mockEpic1,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.getInitialEpicLoading()).toBe(false);
        });
      });

      it('should return value of `sidebarStore.isFetching.epic` when `initialEpic` prop is null and `isFetching` is available', () => {
        wrapper.setProps({
          sidebarStore: { isFetching: { epic: true } },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.getInitialEpicLoading()).toBe(true);
        });
      });

      it('should return `false` when both `initialEpic` and `sidebarStore.isFetching` are unavailable', () => {
        wrapper.setProps({
          initialEpic: null,
          sidebarStore: { isFetching: null },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.getInitialEpicLoading()).toBe(false);
        });
      });
    });

    describe('getEpic', () => {
      it('should return value of `initialEpic` as it is when it is available', () => {
        wrapper.setProps({
          initialEpic: mockEpic1,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.getEpic()).toBe(mockEpic1);
        });
      });

      it('should return value of `sidebarStore.epic` as it is when it is available', () => {
        expect(wrapper.vm.getEpic()).toBe(mockEpic1);
      });

      it('should return No Epic object as it is when both `initialEpic` & `sidebarStore.epic` are unavailable', () => {
        wrapper.setProps({
          initialEpic: null,
          sidebarStore: { epic: null },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.getEpic()).toEqual(
            expect.objectContaining({
              id: 0,
              title: 'none',
            }),
          );
        });
      });
    });
  });

  describe('template', () => {
    it('should render epics-select component', () => {
      expect(wrapper.is('epics-select-stub')).toBe(true);
      expect(wrapper.attributes('blocktitle')).toBe('Epic');
      expect(wrapper.text()).toBe('None');
    });
  });
});
