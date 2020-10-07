import { shallowMount } from '@vue/test-utils';
import InviteActionButtons from '~/vue_shared/components/members/action_buttons/invite_action_buttons.vue';
import RemoveMemberButton from '~/vue_shared/components/members/action_buttons/remove_member_button.vue';
import { invite as member } from '../mock_data';

describe('InviteActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(InviteActionButtons, {
      propsData: {
        member,
        ...propsData,
      },
    });
  };

  const findRemoveMemberButton = () => wrapper.find(RemoveMemberButton);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when user has `canRemove` permissions', () => {
    beforeEach(() => {
      createComponent({
        permissions: {
          canRemove: true,
        },
      });
    });

    it('renders remove member button', () => {
      expect(findRemoveMemberButton().exists()).toBe(true);
    });

    it('sets props correctly', () => {
      expect(findRemoveMemberButton().props()).toEqual({
        memberId: member.id,
        message: `Are you sure you want to revoke the invitation for ${member.invite.email} to join "${member.source.name}"`,
        title: 'Revoke invite',
        isAccessRequest: false,
        icon: 'remove',
      });
    });
  });

  describe('when user does not have `canRemove` permissions', () => {
    it('does not render remove member button', () => {
      createComponent({
        permissions: {
          canRemove: false,
        },
      });

      expect(findRemoveMemberButton().exists()).toBe(false);
    });
  });
});