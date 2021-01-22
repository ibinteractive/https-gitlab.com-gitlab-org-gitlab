# frozen_string_literal: true

module Packages
  module Nuget
    class SearchService < BaseService
      include ::Packages::FinderHelper
      include Gitlab::Utils::StrongMemoize
      include ActiveRecord::ConnectionAdapters::Quoting

      MAX_PER_PAGE = 30
      MAX_VERSIONS_PER_PACKAGE = 10
      PRE_RELEASE_VERSION_MATCHING_TERM = '%-%'

      DEFAULT_OPTIONS = {
        include_prerelease_versions: true,
        per_page: Kaminari.config.default_per_page,
        padding: 0
      }.freeze

      def initialize(current_user, project_or_group, search_term, options = {})
        @current_user = current_user
        @project_or_group = project_or_group
        @search_term = search_term
        @options = DEFAULT_OPTIONS.merge(options)

        raise ArgumentError, 'negative per_page' if per_page < 0
        raise ArgumentError, 'negative padding' if padding < 0
      end

      def execute
        Result.new(
          total_count: non_paginated_matching_package_names.count,
          results: search_packages
        )
      end

      private

      def search_packages
        # custom query to get package names and versions as expected from the nuget search api
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24182#technical-notes
        # and https://docs.microsoft.com/en-us/nuget/api/search-query-service-resource
        subquery_name = :partition_subquery
        arel_table = Arel::Table.new(subquery_name)
        column_names = Packages::Package.column_names.map do |cn|
          "#{subquery_name}.#{quote_column_name(cn)}"
        end

        # rubocop: disable CodeReuse/ActiveRecord
        pkgs = Packages::Package
        pkgs = pkgs.with(project_ids_cte.to_arel) if use_project_ids_cte?
        pkgs = pkgs.select(column_names.join(','))
                   .from(package_names_partition, subquery_name)
                   .where(arel_table[:row_number].lteq(MAX_VERSIONS_PER_PACKAGE))

        return pkgs if include_prerelease_versions?

        # we can't use pkgs.without_version_like since we have a custom from
        pkgs.where.not(arel_table[:version].matches(PRE_RELEASE_VERSION_MATCHING_TERM))
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def package_names_partition
        # rubocop: disable CodeReuse/ActiveRecord
        table_name = quote_table_name(Packages::Package.table_name)
        name_column = "#{table_name}.#{quote_column_name('name')}"
        created_at_column = "#{table_name}.#{quote_column_name('created_at')}"
        select_sql = "ROW_NUMBER() OVER (PARTITION BY #{name_column} ORDER BY #{created_at_column} DESC) AS row_number, #{table_name}.*"

        nuget_packages.select(select_sql)
                      .with_name(paginated_matching_package_names)
                      .where(project_id: project_ids)
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def paginated_matching_package_names
        pkgs = base_matching_package_names
        pkgs.page(0) # we're using a padding
            .per(per_page)
            .padding(padding)
      end

      def non_paginated_matching_package_names
        # rubocop: disable CodeReuse/ActiveRecord
        pkgs = base_matching_package_names
        pkgs = pkgs.with(project_ids_cte.to_arel) if use_project_ids_cte?
        pkgs
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def base_matching_package_names
        strong_memoize(:base_matching_package_names) do
          # rubocop: disable CodeReuse/ActiveRecord
          pkgs = nuget_packages.order_name
                               .select_distinct_name
                               .where(project_id: project_ids)
          pkgs = pkgs.without_version_like(PRE_RELEASE_VERSION_MATCHING_TERM) unless include_prerelease_versions?
          pkgs = pkgs.search_by_name(@search_term) if @search_term.present?
          pkgs
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end

      def nuget_packages
        Packages::Package.nuget
                         .has_version
                         .without_nuget_temporary_name
      end

      def project_ids_cte
        return unless use_project_ids_cte?

        strong_memoize(:project_ids_cte) do
          query = projects_visible_to_user(@current_user, within_group: @project_or_group)
          Gitlab::SQL::CTE.new(:project_ids, query.select(:id))
        end
      end

      def project_ids
        return @project_or_group.id if project?

        if use_project_ids_cte?
          # rubocop: disable CodeReuse/ActiveRecord
          Project.select(:id)
                 .from(project_ids_cte.table)
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end

      def use_project_ids_cte?
        group?
      end

      def project?
        @project_or_group.is_a?(::Project)
      end

      def group?
        @project_or_group.is_a?(::Group)
      end

      def include_prerelease_versions?
        @options[:include_prerelease_versions]
      end

      def padding
        @options[:padding]
      end

      def per_page
        [@options[:per_page], MAX_PER_PAGE].min
      end

      class Result
        include ActiveModel::Model

        attr_accessor :results, :total_count
      end
    end
  end
end
