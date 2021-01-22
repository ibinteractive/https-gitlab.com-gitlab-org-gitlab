import mutations from 'ee/approvals/stores/modules/group_settings/mutations';
import getInitialState from 'ee/approvals/stores/modules/group_settings/state';

describe('Group settings store mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe('REQUEST_SETTINGS', () => {
    it('sets loading state', () => {
      mutations.REQUEST_SETTINGS(state);

      expect(state.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_SETTINGS_SUCCESS', () => {
    it('updates settings', () => {
      mutations.RECEIVE_SETTINGS_SUCCESS(state, { allow_author_approval: true });

      expect(state.preventAuthorApproval).toEqual(false);
      expect(state.isLoading).toEqual(false);
    });
  });

  describe('RECEIVE_SETTINGS_ERROR', () => {
    it('sets loading state', () => {
      mutations.RECEIVE_SETTINGS_ERROR(state);

      expect(state.isLoading).toEqual(false);
    });
  });

  describe('UPDATE_PREVENT_AUTHOR_APPROVAL', () => {
    it('updates setting', () => {
      mutations.UPDATE_PREVENT_AUTHOR_APPROVAL(state, false);

      expect(state.preventAuthorApproval).toEqual(false);
    });
  });
});
