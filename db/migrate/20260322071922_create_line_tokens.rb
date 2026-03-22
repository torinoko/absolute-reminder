class CreateLineTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :line_tokens do |t|
      t.string :uid, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :line_tokens, :token, unique: true
  end
end
