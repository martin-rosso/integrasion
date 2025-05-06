class CreateIntegrasionThirdPartyTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :integrasion_third_party_tokens do |t|
      t.integer :service
      t.references :third_party_integration, null: false, foreign_key: { to_table: :integrasion_third_party_integrations }
      t.string :id_user
      t.json :secret

      t.timestamps
    end
  end
end
