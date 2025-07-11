class FolderSyncDirection < ActiveRecord::Migration[7.2]
  def change
    add_column :nexo_folders, :sync_direction, :integer
    change_column_null :nexo_folders, :sync_direction, false, 0

    add_column :nexo_folders, :nf_status, :integer, null: false, default: 0
  end
end
