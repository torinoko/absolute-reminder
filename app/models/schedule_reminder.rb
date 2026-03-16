class ScheduleReminder < ApplicationRecord
  belongs_to :schedule

  enum :method, { popup: 0, email: 1 }

  validates :minutes, presence: true, numericality: true
  validates :method, presence: true
end
