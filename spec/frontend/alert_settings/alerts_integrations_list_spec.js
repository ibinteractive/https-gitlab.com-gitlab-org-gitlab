import { GlTable, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AlertIntegrationsList, {
  i18n,
} from '~/alerts_settings/components/alerts_integrations_list.vue';

const mockIntegrations = [
  {
    activated: true,
    name: 'Integration 1',
    type: 'HTTP endpoint',
  },
  {
    activated: false,
    name: 'Integration 2',
    type: 'HTTP endpoint',
  },
];

describe('AlertIntegrationsList', () => {
  let wrapper;

  function mountComponent(propsData = {}) {
    wrapper = mount(AlertIntegrationsList, {
      propsData: {
        integrations: mockIntegrations,
        ...propsData,
      },
      stubs: {
        GlIcon: true,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  beforeEach(() => {
    mountComponent();
  });

  const findTableComponent = () => wrapper.find(GlTable);
  const finsStatusCell = () => wrapper.findAll('[data-testid="integration-activated-status"]');

  it('renders a table', () => {
    expect(findTableComponent().exists()).toBe(true);
  });

  it('renders an empty state when no integrations provided', () => {
    mountComponent({ integrations: [] });
    expect(findTableComponent().text()).toContain(i18n.emptyState);
  });

  describe('integration status', () => {
    it('enabled', () => {
      const cell = finsStatusCell().at(0);
      const activatedIcon = cell.find(GlIcon);
      expect(cell.text()).toBe(i18n.status.enabled.name);
      expect(activatedIcon.attributes('name')).toBe('check-circle-filled');
      expect(activatedIcon.attributes('title')).toBe(i18n.status.enabled.tooltip);
    });

    it('disabled', () => {
      const cell = finsStatusCell().at(1);
      const notActivatedIcon = cell.find(GlIcon);
      expect(cell.text()).toBe(i18n.status.disabled.name);
      expect(notActivatedIcon.attributes('name')).toBe('warning-solid');
      expect(notActivatedIcon.attributes('title')).toBe(i18n.status.disabled.tooltip);
    });
  });
});
