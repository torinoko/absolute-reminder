class AddEndAtToSchedule < ActiveRecord::Migration[8.1]
  def change
    add_column :schedules, :end_at, :datetime
  end
end
