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

ActiveRecord::Schema[8.1].define(version: 2026_08_06_011321) do
  create_table "line_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_line_tokens_on_token", unique: true
  end

  create_table "notification_deliveries", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.string "channel", null: false
    t.datetime "claimed_at"
    t.datetime "created_at", null: false
    t.text "last_error"
    t.integer "schedule_reminder_id", null: false
    t.datetime "sent_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_reminder_id", "channel"], name: "index_notification_deliveries_on_reminder_and_channel", unique: true
    t.index ["schedule_reminder_id"], name: "index_notification_deliveries_on_schedule_reminder_id"
  end

  create_table "schedule_reminders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "job_id"
    t.integer "minutes", null: false
    t.integer "reminder_method", null: false
    t.integer "schedule_id", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_id"], name: "index_schedule_reminders_on_schedule_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "google_event_id", null: false
    t.datetime "start_at", null: false
    t.string "summary", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "google_event_id"], name: "index_schedules_on_user_id_and_google_event_id", unique: true
    t.index ["user_id"], name: "index_schedules_on_user_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.json "raw_info"
    t.string "refresh_token"
    t.datetime "token_expires_at"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["provider", "uid"], name: "index_user_profiles_on_provider_and_uid", unique: true
    t.index ["user_id", "provider", "uid"], name: "index_user_profiles_on_user_id_and_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "notification_deliveries", "schedule_reminders"
  add_foreign_key "schedule_reminders", "schedules"
  add_foreign_key "schedules", "users"
  add_foreign_key "user_profiles", "users"
end
