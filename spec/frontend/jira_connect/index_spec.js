import waitForPromises from 'helpers/wait_for_promises';
import { initJiraConnect } from '~/jira_connect';
import { removeSubscription } from '~/jira_connect/api';

jest.mock('~/jira_connect/api', () => ({ removeSubscription: jest.fn().mockResolvedValue() }));

describe('JiraConnect', () => {
  const mockAPLocation = 'test/location';
  window.AP = {
    getLocation: jest.fn().mockImplementation((callback) => {
      return callback(mockAPLocation);
    }),
    navigator: {
      reload: jest.fn(),
    },
  };

  describe('Sign in links', () => {
    beforeEach(() => {
      setFixtures(`
          <a class="js-jira-connect-sign-in" href="https://gitlab.com">Sign In</a>
        `);

      initJiraConnect();
    });

    it('have `return_to` query parameter', () => {
      const el = document.querySelector('.js-jira-connect-sign-in');
      expect(el.href).toContain(`return_to=${mockAPLocation}`);
    });
  });

  describe('`remove subscription` buttons', () => {
    beforeEach(() => {
      setFixtures(`
          <a href="https://gitlab.com/sub1" class="remove-subscription">Remove</a>
          <a href="https://gitlab.com/sub2" class="remove-subscription">Remove</a>
          <a href="https://gitlab.com/sub3" class="remove-subscription">Remove</a>
        `);

      initJiraConnect();
    });

    describe('on click', () => {
      it('calls `removeSubscription`', () => {
        Array.from(document.querySelectorAll('.remove-subscription')).forEach(
          (removeSubscriptionButton) => {
            removeSubscriptionButton.click();

            waitForPromises();

            expect(removeSubscription).toHaveBeenCalledWith(removeSubscriptionButton.href);
            expect(removeSubscription).toHaveBeenCalledTimes(1);

            removeSubscription.mockClear();
          },
        );
      });
    });
  });
});
