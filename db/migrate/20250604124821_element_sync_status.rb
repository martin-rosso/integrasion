class ElementSyncStatus < ActiveRecord::Migration[7.2]
  def change
    add_column :nexo_elements, :ne_status, :integer, null: false
    remove_column :nexo_elements, :conflicted, :boolean, default: false, null: false

    add_column :nexo_element_versions, :nev_status, :integer, null: false

    add_index :nexo_element_versions, [:element_id, :sequence], unique: true, where: "sequence IS NOT NULL"
    add_index :nexo_element_versions, [:element_id, :etag], unique: true, where: "etag IS NOT NULL"
  end
end
