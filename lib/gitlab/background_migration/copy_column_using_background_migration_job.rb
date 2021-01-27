# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration that extends CopyColumn to update the value of a
    # column using the value of another column in the same table.
    #
    # - The {start_id, end_id} arguments are at the start so that it can be used
    #   with `queue_background_migration_jobs_by_range_at_intervals`
    # - Provides support for background job tracking through the use of
    #   Gitlab::Database::BackgroundMigrationJob
    # - Uses sub-batching so that we can keep each update's execution time at
    #   low 100s ms, while being able to update more records per 2 minutes
    #   that we allow background migration jobs to be scheduled one after the other
    # - We skip the NULL checks as they may result in not using an index scan
    # - The table that is migrated does _not_ need `id` as the primary key
    #   We use the provided primary_key column to perform the update.
    class CopyColumnUsingBackgroundMigrationJob
      include Gitlab::Database::DynamicModelHelpers

      PAUSE_SECONDS = 0.1

      # start_id - The start ID of the range of rows to update.
      # end_id - The end ID of the range of rows to update.
      # table - The name of the table that contains the columns.
      # primary_key - The primary key column of the table.
      # copy_from - The column containing the data to copy.
      # copy_to - The column to copy the data to.
      # sub_batch_size - We don't want updates to take more than ~100ms
      #                  This allows us to run multiple smaller batches during
      #                  the minimum 2.minute interval that we can schedule jobs
      def perform(start_id, end_id, table, primary_key, copy_from, copy_to, sub_batch_size)
        quoted_copy_from = connection.quote_column_name(copy_from)
        quoted_copy_to = connection.quote_column_name(copy_to)

        parent_batch_relation = relation_scoped_to_range(table, primary_key, start_id, end_id)

        query_events = []
        callback = lambda do |name, start, finish, id, payload|
          query_events << { duration: (finish - start), sql: payload[:sql] } if payload[:name] =~ /Update All/
        end

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          parent_batch_relation.each_batch(column: primary_key, of: sub_batch_size) do |sub_batch|
            sub_batch.update_all("#{quoted_copy_to}=#{quoted_copy_from}")

            sleep(PAUSE_SECONDS)
          end
        end

        analyze_and_report_queries(table, start_id, end_id, query_events)

        # We have to add all arguments when marking a job as succeeded as they
        #  are all used to track the job by `queue_background_migration_jobs_by_range_at_intervals`
        mark_job_as_succeeded(start_id, end_id, table, primary_key, copy_from, copy_to, sub_batch_size)
      end

      private

      def connection
        ActiveRecord::Base.connection
      end

      def logger
        @logger ||= ::Gitlab::BackgroundMigration::Logger.build
      end

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(self.class.name, arguments)
      end

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(source_table).where(source_key_column => start_id..stop_id)
      end

      def analyze_and_report_queries(table, start_id, end_id, query_events)
        return if query_events.empty?

        sorted_events = query_events.sort_by { |query_event| query_event[:duration] }

        mean_query_time = calculate_mean_query_time(sorted_events)
        median_query_time = calculate_median_query_time(sorted_events)
        longest_query_event = sorted_events.last

        logger.info(<<~MSG)
          CopyColumnUsingBackgroundMigrationJob for #{table}=(#{start_id},#{end_id}):
            mean query time: #{mean_query_time}s
            median query time: #{median_query_time}s
            longest query event: #{longest_query_event[:duration]}s - #{longest_query_event[:sql]}
        MSG
      end

      def calculate_mean_query_time(query_events)
        query_events.reduce(0) { |total, query_event| total + query_event[:duration] } / query_events.size
      end

      def calculate_median_query_time(sorted_events)
        number_of_events = sorted_events.size
        center_index = number_of_events / 2

        if number_of_events.even?
          (sorted_events[center_index][:duration] + sorted_events[center_index + 1][:duration]) / 2
        else
          sorted_events[center_index][:duration]
        end
      end
    end
  end
end
