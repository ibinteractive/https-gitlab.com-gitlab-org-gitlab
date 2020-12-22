# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class PersistShiftsJob
      include ApplicationWorker

      idempotent!
      feature_category :incident_management

      START_DATE_OFFSET = 6.months

      def perform(rotation_id)
        rotation = ::IncidentManagement::OncallRotation.find_by_id(rotation_id)

        return unless rotation

        starts_at = START_DATE_OFFSET.ago
        ends_at = Time.current

        generate_shifts = ::IncidentManagement::OncallShifts::ReadService.new(
          rotation,
          nil,
          starts_at: starts_at,
          ends_at: ends_at,
          include_persisted: false,
          skip_user_check: true
        ).execute

        unless generate_shifts.success?
          log_error("Could not generate shifts. Error: #{generate_shifts.message}")
          return
        end

        generated_shifts = generate_shifts.payload[:shifts]

        IncidentManagement::OncallShift.bulk_insert!(generated_shifts)
      end

      private

      def log_error(msg)
        if Rails.env.production?
          # TODO
          Gitlab::AppLogger.warn(msg)
        else
          raise msg
        end
      end
    end
  end
end
