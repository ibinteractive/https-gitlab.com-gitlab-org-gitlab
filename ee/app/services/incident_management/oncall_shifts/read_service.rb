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
      # @option params - mode [:combined, :future, :historic]
      def initialize(rotation, current_user, start_time:, end_time:, mode: :combined, skip_user_check: false)
        @rotation = rotation
        @current_user = current_user
        @start_time = start_time
        @end_time = end_time
        @mode = mode
        @skip_user_check = skip_user_check
      end

      def execute
        return error_no_license unless available?
        return error_no_permissions unless allowed?
        return error_invalid_range unless start_before_end?
        return error_excessive_range unless under_max_timeframe?

        case mode
        when :combined
          current_time = Time.current
          persisted_shifts = rotation.shifts.for_timeframe(start_time, current_time) if current_time >= start_time
          generated_shifts = generate_shifts(current_time, end_time)

          if persisted_shifts.present?
            last_persisted_shift = persisted_shifts.last

            # Remove duplicate or overlapping shifts
            # (persisted shift end time > any generated shift start time)
            generated_shifts.reject! do |generated|
              last_persisted_shift.ends_at > generated.starts_at ||
              (generated.starts_at == last_persisted_shift.starts_at && last_persisted_shift.ends_at == generated.ends_at)
            end

            # join the historical shifts & the generated shifts, removing the duplicate
            @shifts = persisted_shifts + generated_shifts
          else
            @shifts = generated_shifts
          end
        when :future
          @shifts = generate_shifts_and_remove_persisted
        when :historic
          @shifts = find_persisted_shifts
        end

        success(shifts)
      end

      private

      attr_reader :rotation, :current_user, :start_time, :end_time, :mode, :skip_user_check, :shifts

      def generate_shifts_and_remove_persisted
        generated_shifts = generate_shifts(start_time, end_time)
        persisted_shifts = find_persisted_shifts

        generated_shifts.reject { |shift| overlapping_shift?(shift, persisted_shifts) }
      end

      def generate_shifts(start_time, end_time)
        ::IncidentManagement::OncallShiftGenerator
          .new(rotation)
          .for_timeframe(starts_at: start_time, ends_at: end_time)
      end

      def combine_persisted_and_generated_shifts
        persisted_shifts = rotation.shifts.for_timeframe(start_time, end_time)

        (generated_shifts << persisted_shifts).flatten.sort_by(&:starts_at)
      end

      def persisted_shifts
        @persisted_shifts ||= rotation.shifts.for_timeframe(start_time, end_time)
      end

      def find_persisted_shifts
        rotation.shifts.for_timeframe(start_time, end_time)
      end

      def overlapping_shift?(new_shift, shifts)
        shifts.any? { |persisted| persisted.starts_at < new_shift.ends_at && new_shift.starts_at < persisted.ends_at }
      end

      def available?
        ::Gitlab::IncidentManagement.oncall_schedules_available?(rotation.project)
      end

      def allowed?
        return true if skip_user_check

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
