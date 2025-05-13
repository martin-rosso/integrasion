class CreateNexoFolders < ActiveRecord::Migration[7.2]
  def change
    create_table :nexo_folders do |t|
      t.references :integration, null: false, foreign_key: { to_table: :nexo_integrations }
      t.integer :protocol, null: false
      t.string :external_identifier
      t.string :name

      t.timestamps
    end
  end
end
