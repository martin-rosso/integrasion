class CreateNexoTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :nexo_tokens do |t|
      t.references :integration, null: false, foreign_key: { to_table: :nexo_integrations }
      t.string :secret
      t.integer :tpt_status, null: false
      t.string :environment, null: false

      t.timestamps
    end
  end
end
