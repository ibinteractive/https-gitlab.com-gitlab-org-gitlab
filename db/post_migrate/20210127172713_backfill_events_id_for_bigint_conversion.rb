# frozen_string_literal: true

class BackfillEventsIdForBigintConversion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    backfill_conversion_of_integer_to_bigint :events, :id, batch_size: 7000,
      sub_batch_size: 100, sample_n_first_batches: 10
  end

  def down
    Gitlab::Database::BackgroundMigrationJob
      .for_migration_class('CopyColumnUsingBackgroundMigrationJob')
      .where('arguments ->> 2 = ?', 'events')
      .delete_all
  end
end
