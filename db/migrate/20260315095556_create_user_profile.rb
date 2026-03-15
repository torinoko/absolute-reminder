class CreateUserProfile < ActiveRecord::Migration[8.1]
  def change
    create_table "user_profiles", force: :cascade do |t|
      t.references :user, null: false, foreign_key: true
      t.string "provider", null: false
      t.string "uid", null: false
      t.string "access_token"
      t.string "refresh_token"
      t.datetime "token_expires_at"
      t.json "raw_info"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    add_index :user_profiles, [ :user_id, :provider, :uid ], unique: true
  end
end
