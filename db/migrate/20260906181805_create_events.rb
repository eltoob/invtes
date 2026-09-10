class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.datetime :starts_at, null: false
      t.string :timezone, null: false, default: "America/New_York"
      t.string :location
      t.text :details
      t.datetime :reminder_at
      t.text :reminder_message
      t.datetime :reminder_sent_at

      t.timestamps
    end
    add_index :events, :slug, unique: true
    add_index :events, :reminder_at
  end
end
