class CreateNexoElements < ActiveRecord::Migration[7.2]
  def change
    create_table :nexo_elements do |t|
      t.references :folder, null: false, foreign_key: { to_table: :nexo_folders }
      t.integer :synchronizable_id, null: false, index: true
      t.string :synchronizable_type, null: false, index: true
      t.string :uuid
      t.boolean :flagged_for_removal, null: false
      t.integer :removal_reason
      t.boolean :conflicted, null: false, default: false
      t.datetime :discarded_at, index: true

      t.timestamps
    end
  end
end
