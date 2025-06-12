class GoogleSyncTokens < ActiveRecord::Migration[7.2]
  def change
    add_column :nexo_folders, :google_next_sync_token, :string
  end
end
