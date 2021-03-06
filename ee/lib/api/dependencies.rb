# frozen_string_literal: true

module API
  class Dependencies < Grape::API
    helpers do
      def dependencies_by(params)
        pipeline = ::Security::ReportFetchService.new(user_project, ::Ci::JobArtifact.dependency_list_reports).pipeline

        return [] unless pipeline

        ::Security::DependencyListService.new(pipeline: pipeline, params: params).execute
      end
    end

    before do
      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project dependencies' do
        success ::EE::API::Entities::Dependency
      end

      params do
        optional :package_manager,
                 type: Array[String],
                 desc: "Returns dependencies belonging to specified package managers: #{::Security::DependencyListService::FILTER_PACKAGE_MANAGERS_VALUES.join(', ')}.",
                 values: ::Security::DependencyListService::FILTER_PACKAGE_MANAGERS_VALUES
      end

      get ':id/dependencies' do
        authorize! :read_dependencies, user_project

        track_event('view_dependencies')

        dependencies = dependencies_by(declared_params.merge(project: user_project))

        present dependencies, with: ::EE::API::Entities::Dependency, user: current_user, project: user_project
      end
    end
  end
end
