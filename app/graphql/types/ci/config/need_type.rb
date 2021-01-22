# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    module Config
      class NeedType < BaseObject
        graphql_name 'CiConfigNeed'

        field :name, GraphQL::STRING_TYPE, null: true,
              description: 'Name of the need.'
      end
    end
  end
end
