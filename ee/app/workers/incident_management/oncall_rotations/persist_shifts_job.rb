# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class PersistShiftsJob
      include ApplicationWorker

      idempotent!
      feature_category :incident_management

      def perform(rotation_id)
        rotation = ::IncidentManagement::OncallRotation.find_by_id(rotation_id)

        return unless rotation

        generated_shifts = generate_shifts(rotation)

        unless generated_shifts.success?
          log_error("Could not generate shifts. Error: #{generated_shifts.message}")
          return
        end

        generated_shifts = generated_shifts.payload[:shifts]

        IncidentManagement::OncallShift.bulk_insert!(generated_shifts)
      end

      private

      def generate_shifts(rotation)
        # To avoid generating shifts in the past, which could lead to unnecessary processing,
        # we get the latest of rotation created time, rotation start time,
        # or the most recent shift.
        starts_at = [
          rotation.created_at,
          rotation.starts_at,
          rotation.shifts.order_starts_at_desc.first&.starts_at
        ].compact.max

        ::IncidentManagement::OncallShifts::ReadService.new(
          rotation,
          nil,
          start_time: starts_at,
          end_time: Time.current,
          mode: :future,
          skip_user_check: true
        ).execute
      end

      def log_error(msg)
        Gitlab::AppLogger.error(msg)
      end
    end
  end
end
