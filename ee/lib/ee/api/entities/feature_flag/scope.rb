# frozen_string_literal: true

module EE
  module API
    module Entities
      class FeatureFlag < Grape::Entity
        class Scope < Grape::Entity
          expose :id
          expose :environment_scope
        end
      end
    end
  end
end
