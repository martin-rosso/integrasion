class CreateIntegrasionThirdPartyIntegrations < ActiveRecord::Migration[7.2]
  def change
    create_table :integrasion_third_party_integrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :third_party_client, null: false, foreign_key: { to_table: :integrasion_third_party_clients }
      t.string :third_party_id_user
      t.string :scope
      t.datetime :expires_at
      t.integer :tpi_status

      t.timestamps
    end
  end
end
