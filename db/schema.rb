# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_10_022104) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "details"
    t.datetime "ends_at"
    t.string "location"
    t.string "name", null: false
    t.datetime "reminder_at"
    t.text "reminder_message"
    t.datetime "reminder_sent_at"
    t.string "slug", null: false
    t.datetime "starts_at", null: false
    t.string "timezone", default: "America/New_York", null: false
    t.datetime "updated_at", null: false
    t.index ["reminder_at"], name: "index_events_on_reminder_at"
    t.index ["slug"], name: "index_events_on_slug", unique: true
  end

  create_table "rsvps", force: :cascade do |t|
    t.boolean "attending", default: true, null: false
    t.datetime "confirmation_sent_at"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.integer "guests_count", default: 0, null: false
    t.string "name", null: false
    t.text "note"
    t.string "phone", null: false
    t.datetime "reminder_sent_at"
    t.datetime "updated_at", null: false
    t.index ["event_id", "phone"], name: "index_rsvps_on_event_id_and_phone", unique: true
    t.index ["event_id"], name: "index_rsvps_on_event_id"
  end

  add_foreign_key "rsvps", "events"
end
