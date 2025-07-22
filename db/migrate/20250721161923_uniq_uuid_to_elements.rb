class UniqUuidToElements < ActiveRecord::Migration[7.2]
  def change
    add_index :nexo_elements, [:folder_id, :uuid], unique: true, where: "discarded_at IS NULL"
  end
end
