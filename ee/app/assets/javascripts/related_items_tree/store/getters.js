import { issuableTypesMap, PathIdSeparator } from 'ee/related_issues/constants';

export const autoCompleteSources = () => gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources;

export const directChildren = state => state.children[state.parentItem.reference] || [];

export const anyParentHasChildren = (state, getters) =>
  getters.directChildren.some(item => item.hasChildren || item.hasIssues);

export const itemAutoCompleteSources = (state, getters) => {
  if (getters.isEpic) {
    return state.autoCompleteEpics ? getters.autoCompleteSources : {};
  }
  return state.autoCompleteIssues ? getters.autoCompleteSources : {};
};

export const itemPathIdSeparator = (state, getters) =>
  getters.isEpic ? PathIdSeparator.Epic : PathIdSeparator.Issue;

export const isEpic = state => state.issuableType === issuableTypesMap.EPIC;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
