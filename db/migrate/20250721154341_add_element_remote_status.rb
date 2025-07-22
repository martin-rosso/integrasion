class AddElementRemoteStatus < ActiveRecord::Migration[7.2]
  def change
    add_column :nexo_elements, :ne_remote_status, :integer
  end
end
