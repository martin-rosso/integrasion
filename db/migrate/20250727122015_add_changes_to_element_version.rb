class AddChangesToElementVersion < ActiveRecord::Migration[7.2]
  def change
    add_column :nexo_element_versions, :fields_changed, :string
  end
end
