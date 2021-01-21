# frozen_string_literal: true

module Types
  module Ci
    class ApplicationSettingType < BaseObject
      graphql_name 'CiApplicationSettings'

      authorize :read_application_setting

      field :keep_latest_artifact, GraphQL::BOOLEAN_TYPE, null: true,
        description: 'Whether to keep the latest builds artifacts.'
    end
  end
end
