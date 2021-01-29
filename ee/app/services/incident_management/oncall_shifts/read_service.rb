# frozen_string_literal: true

module IncidentManagement
  module OncallShifts
    class ReadService
      MAXIMUM_TIMEFRAME = 1.month

      # @param rotation [IncidentManagement::OncallRotation]
      # @param current_user [User]
      # @param params [Hash<Symbol,Any>]
      # @option params - start_time [Time]
      # @option params - end_time [Time]
      # @option params - mode [:combined, :predicted, :historic]
      def initialize(rotation, current_user, start_time:, end_time:, mode: :combined)
        @rotation = rotation
        @current_user = current_user
        @start_time = start_time
        @end_time = end_time
        @mode = mode
        @current_time = Time.current
      end

      def execute
        return error_no_license unless available?
        return error_no_permissions unless allowed?
        return error_invalid_range unless start_before_end?
        return error_excessive_range unless under_max_timeframe?

        case mode
        when :combined
          persisted_shifts = find_shifts(start_time, [end_time, current_time].min)
          generated_shifts = generate_shifts([start_time, current_time].max, end_time)

          if persisted_shifts.present?
            last_persisted_shift = persisted_shifts.last

            # Remove duplicate or overlapping shifts
            # (persisted shift end time > any generated shift start time)
            generated_shifts.reject! { |generated_shift| last_persisted_shift.ends_at > generated_shift.starts_at }
          end

          shifts = Array(persisted_shifts).concat(generated_shifts)
        when :predicted
          shifts = generate_shifts(start_time, end_time)
        when :historic
          shifts = find_shifts(start_time, end_time)
        end

        success(shifts)
      end

      private

      attr_reader :rotation, :current_user, :start_time, :end_time, :mode, :current_time

      def generate_shifts(starts_at, ends_at)
        ::IncidentManagement::OncallShiftGenerator
          .new(rotation)
          .for_timeframe(starts_at: starts_at, ends_at: ends_at)
      end

      def find_shifts(starts_at, ends_at)
        rotation.shifts.for_timeframe(starts_at, ends_at).order_starts_at_desc
      end

      def available?
        ::Gitlab::IncidentManagement.oncall_schedules_available?(rotation.project)
      end

      def allowed?
        Ability.allowed?(current_user, :read_incident_management_oncall_schedule, rotation)
      end

      def start_before_end?
        start_time < end_time
      end

      def under_max_timeframe?
        end_time.to_date <= start_time.to_date + MAXIMUM_TIMEFRAME
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(shifts)
        ServiceResponse.success(payload: { shifts: shifts })
      end

      def error_no_permissions
        error(_('You have insufficient permissions to view shifts for this rotation'))
      end

      def error_no_license
        error(_('Your license does not support on-call rotations'))
      end

      def error_invalid_range
        error(_('`start_time` should precede `end_time`'))
      end

      def error_excessive_range
        error(_('`end_time` should not exceed one month after `start_time`'))
      end
    end
  end
end
