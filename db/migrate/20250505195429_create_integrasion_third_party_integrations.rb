class CreateIntegrasionThirdPartyIntegrations < ActiveRecord::Migration[7.2]
  def change
    create_table :integrasion_third_party_integrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :integrasion_third_party_client, null: false, foreign_key: true
      t.string :third_party_id_user
      t.string :scope
      t.datetime :expires_at
      t.integer :tpi_status

      t.timestamps
    end
  end
end
