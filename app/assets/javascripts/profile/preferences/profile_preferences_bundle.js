import Vue from 'vue';
import ProfilePreferences from './components/profile_preferences.vue';

export default () => {
  const el = document.querySelector('#js-profile-preferences-app');
  const { userTimeSettings } = gon?.features;
  const featureFlags = {
    userTimeSettings,
  };
  const shouldParse = [
    'languageChoices',
    'firstDayOfWeekChoicesWithDefault',
    'integrationViews',
    'userFields',
  ];

  const provide = Object.keys(el.dataset).reduce(
    (memo, key) => {
      let value = el.dataset[key];
      if (shouldParse.includes(key)) {
        try {
          value = JSON.parse(value);
        } catch (error) {
          // eslint-disable-next-line no-console
          console.warn(
            `Was not able to parse "${key}". The original value was:`,
            value,
            // eslint-disable-next-line @gitlab/require-i18n-strings
            'Error:',
            error,
          );
          value = null;
        }
      }

      return { ...memo, [key]: value };
    },
    { featureFlags },
  );

  return new Vue({
    el,
    name: 'ProfilePreferencesApp',
    provide,
    render: createElement => createElement(ProfilePreferences),
  });
};
