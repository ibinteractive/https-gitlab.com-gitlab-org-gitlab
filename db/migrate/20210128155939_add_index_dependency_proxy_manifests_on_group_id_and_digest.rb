# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexDependencyProxyManifestsOnGroupIdAndDigest < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_dependency_proxy_manifests_on_group_id_and_digest'

  disable_ddl_transaction!

  def up
    add_concurrent_index :dependency_proxy_manifests, [:group_id, :digest], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dependency_proxy_manifests, INDEX_NAME
  end
end
