class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events do |t|
      t.date :date_from
      t.date :date_to
      t.time :time_from
      t.time :time_to
      t.string :summary
      t.string :description
      t.string :uuid
      t.integer :sequence

      t.timestamps
    end
  end
end
