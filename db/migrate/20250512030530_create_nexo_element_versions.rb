class CreateNexoElementVersions < ActiveRecord::Migration[7.2]
  def change
    create_table :nexo_element_versions do |t|
      t.references :element, null: false, foreign_key: { to_table: :nexo_elements }
      t.string :payload
      t.string :etag
      t.integer :sequence
      t.integer :origin, null: false

      t.timestamps
    end
  end
end
