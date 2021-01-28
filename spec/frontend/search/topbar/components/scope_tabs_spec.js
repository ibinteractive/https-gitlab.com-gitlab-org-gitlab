import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlTabs, GlTab, GlBadge, GlDropdownItem } from '@gitlab/ui';
import { MOCK_QUERY } from 'jest/search/mock_data';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import ScopeTabs from '~/search/topbar/components/scope_tabs.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const SEARCH_COUNT_PATH = '/search/count';
const SEARCH_COUNT_RESPONSE = { count: '15' };

describe('ScopeTabs', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(SEARCH_COUNT_PATH).reply(200, SEARCH_COUNT_RESPONSE);
  });

  const defaultProps = {
    countPath: SEARCH_COUNT_PATH,
    scopeTabs: ['issues', 'merge_requests', 'milestones'],
    count: '10',
  };

  const createComponent = (search = 'test', props = {}, initialState= {}) => {
    const store = new Vuex.Store({
      state: {
        query: {
          ...MOCK_QUERY,
          search,
        },
        ...initialState,
      },
    });

    wrapper = shallowMount(ScopeTabs, {
      localVue,
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  const findScopeTabs = () => wrapper.find(GlTabs);
  const findTabs = () => wrapper.findAll(GlTab);
  const findBadges = () => wrapper.findAll(GlBadge);

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
      it('renders a badge for each scope', () => {
        expect(findBadges()).toHaveLength(wrapper.props().scopeTabs.length);
      })
    });
  });
});
