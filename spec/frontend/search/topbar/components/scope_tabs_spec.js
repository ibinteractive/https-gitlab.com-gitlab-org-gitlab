import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { MOCK_QUERY, MOCK_COUNT } from 'jest/search/mock_data';
import MockAdapter from 'axios-mock-adapter';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { ALL_SCOPE_TABS } from '~/search/topbar/constants';
import axios from '~/lib/utils/axios_utils';
import ScopeTabs from '~/search/topbar/components/scope_tabs.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.fn(),
}));

const SEARCH_COUNT_PATH = '/search/count';

describe('ScopeTabs', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(SEARCH_COUNT_PATH).reply(200, MOCK_COUNT);
  });

  const defaultProps = {
    countPath: SEARCH_COUNT_PATH,
    scopeTabs: ['issues', 'merge_requests', 'milestones'],
    count: '20',
  };

  const createComponent = (search = 'test', props = {}, initialState = {}) => {
    const store = new Vuex.Store({
      state: {
        query: {
          ...MOCK_QUERY,
          search,
        },
        ...initialState,
      },
    });

    wrapper = extendedWrapper(
      mount(ScopeTabs, {
        localVue,
        store,
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  const findScopeTabs = () => wrapper.find(GlTabs);
  const findTabs = () => wrapper.findAll(GlTab);
  const findBadges = () => wrapper.findAll(GlBadge);
  const findBadgeByScope = (scope) => wrapper.findByTestId(scope);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render Scope Tabs if search query is empty', () => {
      createComponent(null, {}, { query: {} });

      expect(findScopeTabs().exists()).toBe(false);
    });

    it('renders Scope Tabs if search query is present', () => {
      expect(findScopeTabs().exists()).toBe(true);
    });

    describe('findTabs', () => {
      it('renders a tab for each scope', () => {
        expect(findTabs()).toHaveLength(wrapper.props().scopeTabs.length);
      });
    });

    describe('findBadges', () => {
      it('renders a badge for each scope', async () => {
        await axios.waitForAll().then(() => {
          const scopeTabsCount = wrapper.props().scopeTabs.length;
          expect(mock.history.get).toHaveLength(scopeTabsCount - 1); // not called for active tab
          expect(findBadges()).toHaveLength(scopeTabsCount);
        });
      });

      it('sets the variant to neutral for active tab only', async () => {
        await axios.waitForAll().then(() => {
          expect(findBadgeByScope('issues').attributes('class')).toContain('badge-neutral');
          expect(findBadgeByScope('milestones').attributes('class')).toContain('badge-muted');
          expect(findBadgeByScope('merge_requests').attributes('class')).toContain('badge-muted');
        });
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('handleTabChange', () => {
      beforeEach(() => {
        wrapper.vm.handleTabChange('snippet_titles');
      });

      it('calls setUrlParams with scope, search from ALL_SCOPE_TABS, and sends nulls for page, state, confidential, and nav_source', () => {
        expect(setUrlParams).toHaveBeenCalledWith({
          scope: 'snippet_titles',
          page: null,
          state: null,
          confidential: null,
          nav_source: null,
          ...ALL_SCOPE_TABS.snippet_titles.search,
        });
      });

      it('calls visitUrl', () => {
        expect(visitUrl).toHaveBeenCalled();
      });
    });

    describe('getCount', () => {
      it('uses count prop for active tab', () => {
        expect(wrapper.vm.getCount('issues')).toStrictEqual({ scope: 'issues', count: '20' });
      });

      it('uses count prop for non-active tab', async () => {
        await wrapper.vm.getCount('milestones').then((resp) => {
          expect(resp).toStrictEqual({ scope: 'milestones', ...MOCK_COUNT });
        });
      });
    });
  });
});
