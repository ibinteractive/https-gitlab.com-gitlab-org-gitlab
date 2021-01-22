import * as types from './mutation_types';

export default {
  [types.REQUEST_SETTINGS](state) {
    Object.assign(state, {
      isLoading: true,
    });
  },
  [types.RECEIVE_SETTINGS_SUCCESS](state, data) {
    Object.assign(state, {
      preventAuthorApproval: !data.allow_author_approval,
      isLoading: false,
    });
  },
  [types.RECEIVE_SETTINGS_ERROR](state) {
    Object.assign(state, {
      isLoading: false,
    });
  },
  [types.UPDATE_PREVENT_AUTHOR_APPROVAL](state, value) {
    Object.assign(state, {
      preventAuthorApproval: value,
    });
  },
};
