class CreateIntegrasionThirdPartyTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :integrasion_third_party_tokens do |t|
      t.references :third_party_integration, null: false, foreign_key: { to_table: :integrasion_third_party_integrations }
      t.json :secret
      t.integer :tpt_status, null: false
      t.string :environment, null: false

      t.timestamps
    end
  end
end
