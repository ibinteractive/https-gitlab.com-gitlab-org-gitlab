# frozen_string_literal: true

module EE
  module Notes
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(note)
        updated_note = super

        if updated_note&.errors&.empty?
          StatusPage.trigger_publish(project, current_user, updated_note)
        end

        updated_note
      end
    end
  end
end
