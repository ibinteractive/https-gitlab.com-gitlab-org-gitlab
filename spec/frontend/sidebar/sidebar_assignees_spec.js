import SidebarAssigneesWidget from 'ee_else_ce/sidebar/components/assignees/sidebar_assignees_widget.vue';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import SidebarAssignees from '~/sidebar/components/assignees/sidebar_assignees.vue';
import AssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

describe('sidebar assignees', () => {
  let wrapper;
  let mediator;
  let axiosMock;
  const createComponent = (realTimeIssueSidebar = false, props) => {
    wrapper = shallowMount(SidebarAssignees, {
      propsData: {
        issuableIid: '1',
        mediator,
        field: '',
        projectPath: 'projectPath',
        changing: false,
        ...props,
      },
      provide: {
        glFeatures: {
          realTimeIssueSidebar,
        },
      },
      // Attaching to document is required because this component emits something from the parent element :/
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    mediator = new SidebarMediator(Mock.mediator);

    jest.spyOn(mediator, 'saveAssignees');
    jest.spyOn(mediator, 'assignYourself');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
    axiosMock.restore();
  });

  it('calls the mediator when saves the assignees', () => {
    createComponent();
    jest.spyOn(wrapper.vm.store, 'setAssigneeData');

    expect(wrapper.vm.store.setAssigneeData).not.toHaveBeenCalled();

    wrapper
      .find(SidebarAssigneesWidget)
      .vm.$emit('assigneesUpdated', { issueSetAssignees: { issue: { assignees: [] } } });

    expect(wrapper.vm.store.setAssigneeData).toHaveBeenCalled();
  });

  describe('when realTimeIssueSidebar is turned on', () => {
    describe('when issuableType is issue', () => {
      it('finds AssigneesRealtime componeont', () => {
        createComponent(true);

        expect(wrapper.find(AssigneesRealtime).exists()).toBe(true);
      });
    });

    describe('when issuableType is MR', () => {
      it('does not find AssigneesRealtime componeont', () => {
        createComponent(true, { issuableType: 'MR' });

        expect(wrapper.find(AssigneesRealtime).exists()).toBe(false);
      });
    });
  });

  describe('when realTimeIssueSidebar is turned off', () => {
    it('does not find AssigneesRealtime', () => {
      createComponent(false, { issuableType: 'issue' });

      expect(wrapper.find(AssigneesRealtime).exists()).toBe(false);
    });
  });
});
