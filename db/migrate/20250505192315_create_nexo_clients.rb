class CreateNexoClients < ActiveRecord::Migration[7.2]
  def change
    create_table :nexo_clients do |t|
      t.integer :service
      t.string :secret
      t.integer :nc_status
      t.integer :brand_name

      t.timestamps
    end
  end
end
