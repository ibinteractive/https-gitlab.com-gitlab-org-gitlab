import * as getters from 'ee/subscriptions/new/store/getters';
import * as constants from 'ee/subscriptions/new/constants';

constants.STEPS = ['firstStep', 'secondStep'];

const state = {
  currentStep: 'secondStep',
  isSetupForCompany: true,
  isNewUser: true,
  availablePlans: [
    {
      value: 'firstPlan',
      text: 'first plan',
    },
  ],
  selectedPlan: 'firstPlan',
  country: 'Country',
  streetAddressLine1: 'Street address line 1',
  streetAddressLine2: 'Street address line 2',
  city: 'City',
  countryState: 'State',
  zipCode: 'Zip code',
  organizationName: 'Organization name',
  paymentMethodId: 'Payment method ID',
  numberOfUsers: 1,
};

describe('Subscriptions Getters', () => {
  describe('currentStep', () => {
    it('returns the states currentStep', () => {
      expect(getters.currentStep(state)).toBe('secondStep');
    });
  });

  describe('stepIndex', () => {
    it('returns a function', () => {
      expect(getters.stepIndex()).toBeInstanceOf(Function);
    });

    it('returns a function that returns the index of the given step', () => {
      expect(getters.stepIndex()('secondStep')).toBe(1);
    });
  });

  describe('currentStepIndex', () => {
    it('returns a function', () => {
      expect(getters.currentStepIndex(state, getters)).toBeInstanceOf(Function);
    });

    it('calls the stepIndex function with the current step name', () => {
      const stepIndexSpy = jest.spyOn(getters, 'stepIndex');
      getters.currentStepIndex(state, getters);

      expect(stepIndexSpy).toHaveBeenCalledWith('secondStep');
    });
  });

  describe('selectedPlanText', () => {
    it('returns the text for selectedPlan', () => {
      expect(
        getters.selectedPlanText(state, { selectedPlanDetails: { text: 'selected plan' } }),
      ).toBe('selected plan');
    });
  });

  describe('selectedPlanDetails', () => {
    it('returns the details for the selected plan', () => {
      expect(getters.selectedPlanDetails(state)).toEqual({
        value: 'firstPlan',
        text: 'first plan',
      });
    });
  });

  describe('endDate', () => {
    it('returns a date 1 year after the startDate', () => {
      expect(getters.endDate({ startDate: new Date('2020-01-07') })).toBe(
        new Date('2021-01-07').getTime(),
      );
    });
  });

  describe('totalExVat', () => {
    it('returns the number of users times the selected plan price', () => {
      expect(getters.totalExVat({ numberOfUsers: 5 }, { selectedPlanPrice: 10 })).toBe(50);
    });
  });

  describe('vat', () => {
    it('returns the tax rate times the total ex vat', () => {
      expect(getters.vat({ taxRate: 0.08 }, { totalExVat: 100 })).toBe(8);
    });
  });

  describe('totalAmount', () => {
    it('returns the total ex vat plus the vat', () => {
      expect(getters.totalAmount({}, { totalExVat: 100, vat: 8 })).toBe(108);
    });
  });

  describe('name', () => {
    it('returns the organization name when setting up for a company and when it is present', () => {
      expect(
        getters.name({ isSetupForCompany: true, organizationName: 'My organization' }, getters),
      ).toBe('My organization');
    });

    it('returns the selected group name a group is selected', () => {
      expect(
        getters.name(
          { isSetupForCompany: true },
          { isGroupSelected: true, selectedGroupName: 'Selected group' },
        ),
      ).toBe('Selected group');
    });

    it('returns the default text when setting up for a company and the organization name is not present', () => {
      expect(getters.name({ isSetupForCompany: true }, { isGroupSelected: false })).toBe(
        'Your organization',
      );
    });

    it('returns the full name when not setting up for a company', () => {
      expect(
        getters.name({ isSetupForCompany: false, fullName: 'My name' }, { isGroupSelected: false }),
      ).toBe('My name');
    });
  });

  describe('usersPresent', () => {
    it('returns true when the number of users is greater than zero', () => {
      expect(getters.usersPresent({ numberOfUsers: 1 })).toBe(true);
    });

    it('returns false when the number of users is zero', () => {
      expect(getters.usersPresent({ numberOfUsers: 0 })).toBe(false);
    });
  });

  describe('isGroupSelected', () => {
    it('returns true when the selectedGroup is not null and does not equal "true"', () => {
      expect(getters.isGroupSelected({ selectedGroup: 1 })).toBe(true);
    });

    it('returns false when the selectedGroup is null', () => {
      expect(getters.isGroupSelected({ selectedGroup: null })).toBe(false);
    });

    it('returns false when the selectedGroup equals "new"', () => {
      expect(getters.isGroupSelected({ selectedGroup: constants.NEW_GROUP })).toBe(false);
    });
  });

  describe('selectedGroupUsers', () => {
    it('returns 1 when no group is selected', () => {
      expect(
        getters.selectedGroupUsers(
          { groupData: [{ numberOfUsers: 3, value: 123 }], selectedGroup: 123 },
          { isGroupSelected: false },
        ),
      ).toBe(1);
    });

    it('returns the number of users of the selected group when a group is selected', () => {
      expect(
        getters.selectedGroupUsers(
          { groupData: [{ numberOfUsers: 3, value: 123 }], selectedGroup: 123 },
          { isGroupSelected: true },
        ),
      ).toBe(3);
    });
  });

  describe('selectedGroupName', () => {
    it('returns null when no group is selected', () => {
      expect(
        getters.selectedGroupName(
          { groupData: [{ text: 'Selected group', value: 123 }], selectedGroup: 123 },
          { isGroupSelected: false },
        ),
      ).toBe(null);
    });

    it('returns the text attribute of the selected group when a group is selected', () => {
      expect(
        getters.selectedGroupName(
          { groupData: [{ text: 'Selected group', value: 123 }], selectedGroup: 123 },
          { isGroupSelected: true },
        ),
      ).toBe('Selected group');
    });
  });

  describe('selectedGroupId', () => {
    it('returns null when no group is selected', () => {
      expect(getters.selectedGroupId({ selectedGroup: 123 }, { isGroupSelected: false })).toBe(
        null,
      );
    });

    it('returns the id of the selected group when a group is selected', () => {
      expect(getters.selectedGroupId({ selectedGroup: 123 }, { isGroupSelected: true })).toBe(123);
    });
  });

  describe('confirmOrderParams', () => {
    it('returns the params to confirm the order', () => {
      expect(getters.confirmOrderParams(state, { selectedGroupId: 11 })).toEqual({
        setup_for_company: true,
        selected_group: 11,
        new_user: true,
        customer: {
          country: 'Country',
          address_1: 'Street address line 1',
          address_2: 'Street address line 2',
          city: 'City',
          state: 'State',
          zip_code: 'Zip code',
          company: 'Organization name',
        },
        subscription: {
          plan_id: 'firstPlan',
          payment_method_id: 'Payment method ID',
          quantity: 1,
        },
      });
    });
  });
});
