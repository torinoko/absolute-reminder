class CreateScheduleReminder < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_reminders do |t|
      t.references :schedule, null: false, foreign_key: true
      t.integer :minutes, null: false
      t.integer :reminder_method, null: false
      t.string :job_id

      t.timestamps
    end
  end
end
