# frozen_string_literal: true

module Registrations
  class GroupsController < ApplicationController
    include GroupInviteMembers

    layout 'checkout'

    before_action :authorize_create_group!, only: :new
    before_action :check_experiment_enabled

    feature_category :navigation

    def new
      record_experiment_user(:trial_during_signup)
      @group = Group.new(visibility_level: helpers.default_group_visibility)
    end

    def create
      @group = Groups::CreateService.new(current_user, group_params).execute

      if @group.persisted?
        create_successful_flow
      else
        render action: :new
      end
    end

    protected

    def show_confirm_warning?
      false
    end

    private

    def create_successful_flow
      if helpers.in_trial_onboarding_flow?
        apply_trial_flow
      else
        standard_onboarding_flow
      end
    end

    def authorize_create_group!
      access_denied! unless can?(current_user, :create_group)
    end

    def check_experiment_enabled
      access_denied! unless experiment_enabled?(:onboarding_issues)
    end

    def group_params
      params.require(:group).permit(:name, :path, :visibility_level)
    end

    def apply_trial_flow
      if apply_trial
        record_experiment_user(:remove_known_trial_form_fields, namespace_id: @group.id)
        record_experiment_user(:trimmed_skip_trial_copy, namespace_id: @group.id)
        record_experiment_user(:trial_registration_with_social_signin, namespace_id: @group.id)

        experiment(:registration_group_invite, actor: @group) do |e|
          e.use { redirect_to new_users_sign_up_project_path(namespace_id: @group.id, trial: helpers.in_trial_during_signup_flow?, trial_onboarding_flow: true) } # control
          e.try(:invite_page) { redirect_to new_users_sign_up_group_invite_path(group_id: @group.id, trial: helpers.in_trial_during_signup_flow?, trial_onboarding_flow: true) } # with separate page
          e.track(:created, property: @group.id)
        end
      else
        render action: :new
      end
    end

    def standard_onboarding_flow
      record_experiment_user(:trial_during_signup, trial_chosen: helpers.in_trial_during_signup_flow?, namespace_id: @group.id)

      if experiment_enabled?(:trial_during_signup)
        trial_during_signup_flow if helpers.in_trial_during_signup_flow?

        redirect_to new_users_sign_up_project_path(namespace_id: @group.id, trial: helpers.in_trial_during_signup_flow?)
      else
        experiment(:registration_group_invite, actor: @group) do |e|
          e.use { invite_on_create } # control
          e.try(:invite_page) { redirect_to new_users_sign_up_group_invite_path(group_id: @group.id, trial: helpers.in_trial_during_signup_flow?) } # with separate page
          e.track(:created, property: @group.id)
        end
      end
    end

    def invite_on_create
      invite_members(@group)

      redirect_to new_users_sign_up_project_path(namespace_id: @group.id, trial: helpers.in_trial_during_signup_flow?)
    end

    def trial_during_signup_flow
      if create_lead && apply_trial
        record_experiment_conversion_event(:trial_during_signup)
      else
        render action: :new
      end
    end

    def create_lead
      trial_params = {
        trial_user: params.permit(
          :company_name,
          :company_size,
          :phone_number,
          :number_of_users,
          :country
        ).merge(
          work_email: current_user.email,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          uid: current_user.id,
          skip_email_confirmation: true,
          gitlab_com_trial: true,
          provider: 'gitlab',
          newsletter_segment: current_user.email_opted_in
        )
      }
      result = GitlabSubscriptions::CreateLeadService.new.execute(trial_params)
      flash[:alert] = result&.dig(:errors) unless result&.dig(:success)

      result&.dig(:success)
    end

    def apply_trial
      apply_trial_params = {
        uid: current_user.id,
        trial_user: params.permit(:glm_source, :glm_content).merge({
                                                                     namespace_id: @group.id,
                                                                     gitlab_com_trial: true,
                                                                     sync_to_gl: true
                                                                   })
      }

      result = GitlabSubscriptions::ApplyTrialService.new.execute(apply_trial_params)
      flash[:alert] = result&.dig(:errors) unless result&.dig(:success)

      result&.dig(:success)
    end
  end
end
