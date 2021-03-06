# frozen_string_literal: true

module EE
  module Gitlab
    module SnippetSearchResults
      extend ::Gitlab::Utils::Override

      # Special scope for .com
      # https://gitlab.com/gitlab-org/gitlab/issues/26123
      override :finder_params
      def finder_params
        return super unless ::Gitlab.com?
        return super unless ::Feature.enabled?(:restricted_snippet_scope_search, default_enabled: true)

        { authorized_and_user_personal: true }
      end
    end
  end
end
