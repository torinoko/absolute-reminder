class CreateSchedule < ActiveRecord::Migration[8.1]
  def change
    create_table "schedules", force: :cascade do |t|
      t.references :user, null: false, foreign_key: true
      t.string "google_event_id", null: false
      t.datetime "start_at", null: false
      t.string "summary", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    add_index :schedules, [:user_id, :google_event_id], unique: true
  end
end
