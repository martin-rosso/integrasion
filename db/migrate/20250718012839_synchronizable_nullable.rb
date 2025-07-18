class SynchronizableNullable < ActiveRecord::Migration[7.2]
  def change
    change_column_null :nexo_elements, :synchronizable_id, true
    change_column_null :nexo_elements, :synchronizable_type, true
  end
end
