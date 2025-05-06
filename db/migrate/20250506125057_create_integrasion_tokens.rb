class CreateIntegrasionTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :integrasion_tokens do |t|
      t.references :integration, null: false, foreign_key: { to_table: :integrasion_integrations }
      t.json :secret
      t.integer :tpt_status, null: false
      t.string :environment, null: false

      t.timestamps
    end
  end
end
