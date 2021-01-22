# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class PersistShiftsJob
      include ApplicationWorker

      idempotent!
      feature_category :incident_management

      def perform(rotation_id)
        @rotation = ::IncidentManagement::OncallRotation.find_by_id(rotation_id)

        return unless rotation

        generated_shifts = generate_shifts

        unless generated_shifts.success?
          log_error("Could not generate shifts. Error: #{generated_shifts.message}")
          return
        end

        generated_shifts = generated_shifts.payload[:shifts]

        IncidentManagement::OncallShift.bulk_insert!(generated_shifts)
      end

      private

      attr_reader :rotation

      def generate_shifts
        ::IncidentManagement::OncallShifts::ReadService.new(
          rotation,
          nil,
          start_time: shift_generation_start_time,
          end_time: Time.current,
          mode: :future,
          skip_user_check: true
        ).execute
      end

      # To avoid generating shifts in the past, which could lead to unnecessary processing,
      # we get the latest of rotation created time, rotation start time,
      # or the most recent shift.
      def shift_generation_start_time
        [
          rotation.created_at,
          rotation.starts_at,
          rotation.shifts.order_starts_at_desc.first&.ends_at
        ].compact.max
      end

      def log_error(msg)
        Gitlab::AppLogger.error(msg)
      end
    end
  end
end
