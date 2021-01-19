# frozen_string_literal: true

module Types
  module CiConfiguration
    module Fuzzing
      class Type < BaseObject
        graphql_name 'FuzzingCiConfiguration'
        description "Represents the CI configuration for a project's fuzzing scans."

        field :scan_modes, [ScanModeType], null: true,
          description: 'All possible scan modes.'

        field :scan_profiles, [ScanProfileType], null: true,
          description: 'Default scan profiles provided by GitLab.'
      end
    end
  end
end
