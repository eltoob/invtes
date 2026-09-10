class CreateRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :rsvps do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone, null: false
      t.boolean :attending, null: false, default: true
      t.integer :guests_count, null: false, default: 0
      t.text :note
      t.datetime :confirmation_sent_at
      t.datetime :reminder_sent_at

      t.timestamps
    end
    add_index :rsvps, [ :event_id, :phone ], unique: true
  end
end
