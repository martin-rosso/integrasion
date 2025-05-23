class CreateNexoFolders < ActiveRecord::Migration[7.2]
  def change
    create_table :nexo_folders do |t|
      t.references :integration, null: false, foreign_key: { to_table: :nexo_integrations }
      # FIXME: rename to nexo_protocol
      t.integer :protocol, null: false
      t.string :external_identifier
      t.string :name
      t.string :description
      t.datetime :discarded_at, index: true

      t.timestamps
    end
  end
end
