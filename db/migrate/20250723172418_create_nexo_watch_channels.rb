class CreateNexoWatchChannels < ActiveRecord::Migration[7.2]
  def change
    create_table :nexo_watch_channels do |t|
      t.references :folder, null: false, foreign_key: { to_table: :nexo_folders }

      t.integer :nwc_status, null: false
      t.integer :touch_count, null: false, default: 0
      t.datetime :touched_at

      t.string :payload

      t.datetime :expires_at

      # A UUID or similar unique string that identifies this channel.
      t.string :id_channel

      # An opaque ID that identifies the resource being watched on this
      # channel. Stable across different API versions.
      t.string :id_resource

      t.string :secret_token

      t.string :address

      t.timestamps
    end
  end
end
