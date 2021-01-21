# frozen_string_literal: true

class AddKeepLatestArtifactsToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :keep_latest_artifact, :boolean, default: true, null: false
  end
end
