class CreateIntegrasionThirdPartyIntegrations < ActiveRecord::Migration[7.2]
  def change
    create_table :integrasion_third_party_integrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :third_party_client, null: false, foreign_key: { to_table: :integrasion_third_party_clients }
      t.string :name
      t.string :scope
      t.datetime :expires_at

      t.datetime :discarded_at

      t.timestamps
    end
  end
end
