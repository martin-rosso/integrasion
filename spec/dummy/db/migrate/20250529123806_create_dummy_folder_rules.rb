class CreateDummyFolderRules < ActiveRecord::Migration[7.2]
  def change
    create_table :dummy_folder_rules do |t|
      t.integer :priority
      t.integer :sync_policy
      t.references :folder, null: false, foreign_key: { to_table: :nexo_folders }
      t.string :search_regex

      t.timestamps
    end
  end
end
