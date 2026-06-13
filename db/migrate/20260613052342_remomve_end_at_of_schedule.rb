class RemomveEndAtOfSchedule < ActiveRecord::Migration[8.1]
  def change
    remove_column :schedules, :end_at, :datetime
  end
end
