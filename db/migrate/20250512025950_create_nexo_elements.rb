class CreateNexoElements < ActiveRecord::Migration[7.2]
  def change
    create_table :nexo_elements do |t|
      t.references :folder, null: false, foreign_key: { to_table: :nexo_folders }
      t.integer :synchronizable_id, null: false, index: true
      t.string :synchronizable_type, null: false, index: true
      t.boolean :flag_deletion, null: false
      t.integer :deletion_reason

      t.timestamps
    end
  end
end
