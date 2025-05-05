class CreateIntegrasionThirdPartyClients < ActiveRecord::Migration[7.2]
  def change
    create_table :integrasion_third_party_clients do |t|
      t.integer :service
      t.json :secret
      t.integer :tcp_status
      t.integer :brand_name
      t.boolean :user_integrations_allowed
      t.string :available_scopes

      t.timestamps
    end
  end
end
