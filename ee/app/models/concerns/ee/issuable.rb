# frozen_string_literal: true

module EE
  module Issuable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    def supports_epic?
      is_a?(Issue) && !incident? && project.group.present?
    end

    def supports_health_status?
      false
    end
  end
end
