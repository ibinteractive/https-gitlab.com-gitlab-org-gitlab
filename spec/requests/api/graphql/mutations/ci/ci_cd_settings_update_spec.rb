# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CiCdSettingsUpdate' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, ci_keep_latest_artifact: true) }
  let(:variables) { { full_path: project.full_path, keep_latest_artifact: false } }
  let(:mutation) { graphql_mutation(:ci_cd_settings_update, variables) }

  context 'when unauthorized' do
    let(:user) { create(:user) }

    shared_examples 'unauthorized' do
      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end

    context 'when not a project member' do
      it_behaves_like 'unauthorized'
    end

    context 'when a non-admin project member' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  context 'when authorized' do
    let_it_be(:user) { project.owner }

    it 'updates ci cd settings' do
      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.ci_keep_latest_artifact).to eq(false)
    end

    context 'when bad arguments are provided' do
      let(:variables) { { full_path: '', keep_latest_artifact: false } }

      it 'returns the errors' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end
end
