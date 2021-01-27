import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlTabs, GlBadge } from '@gitlab/ui';
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

  const createComponent = (initialState = {}, props = {}) => {
    const store = new Vuex.Store({
      state: {
        query: {
          search: 'test',
          scope: 'issues',
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
  const findBadges = () => findScopeTabs().findAll(GlBadge);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render Scope Tabs if search query is empty', () => {
      createComponent({ query: {}});

      expect(findScopeTabs().exists()).toBe(false);
    });

    it('renders Scope Tabs if search query is present', () => {
      expect(findScopeTabs().exists()).toBe(true);
    });

    describe('findBadges', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders a badge for each scope', () => {
        expect(findBadges().wrappers.length).toBe(wrapper.props().scopeTabs.count());
      });
    });
  });
});
