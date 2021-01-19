# frozen_string_literal: true

class AddProxySettingsToJiraTrackerDataTextLimit < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :jira_tracker_data, :encrypted_proxy_address, 2798
    add_text_limit :jira_tracker_data, :encrypted_proxy_address_iv, 255
    add_text_limit :jira_tracker_data, :encrypted_proxy_port, 29
    add_text_limit :jira_tracker_data, :encrypted_proxy_port_iv, 255
    add_text_limit :jira_tracker_data, :encrypted_proxy_username, 371
    add_text_limit :jira_tracker_data, :encrypted_proxy_username_iv, 255
    add_text_limit :jira_tracker_data, :encrypted_proxy_password, 371
    add_text_limit :jira_tracker_data, :encrypted_proxy_password_iv, 255
  end

  def down
    remove_text_limit :jira_tracker_data, :encrypted_proxy_address
    remove_text_limit :jira_tracker_data, :encrypted_proxy_address_iv
    remove_text_limit :jira_tracker_data, :encrypted_proxy_port
    remove_text_limit :jira_tracker_data, :encrypted_proxy_port_iv
    remove_text_limit :jira_tracker_data, :encrypted_proxy_username
    remove_text_limit :jira_tracker_data, :encrypted_proxy_username_iv
    remove_text_limit :jira_tracker_data, :encrypted_proxy_password
    remove_text_limit :jira_tracker_data, :encrypted_proxy_password_iv
  end
end
