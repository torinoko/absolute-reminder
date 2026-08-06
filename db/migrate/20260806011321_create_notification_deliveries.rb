# frozen_string_literal: true

class CreateNotificationDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_deliveries do |t|
      t.references :schedule_reminder, null: false, foreign_key: true
      t.string :channel, null: false
      t.string :status, null: false, default: 'pending'
      t.integer :attempts, null: false, default: 0
      t.datetime :claimed_at
      t.datetime :sent_at
      t.text :last_error
      t.timestamps
    end

    add_index :notification_deliveries, [:schedule_reminder_id, :channel], unique: true,
              name: 'index_notification_deliveries_on_reminder_and_channel'
  end
end
