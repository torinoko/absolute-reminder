# frozen_string_literal: true

class ScheduleReminder < ApplicationRecord
  belongs_to :schedule

  enum :reminder_method, { popup: 0, email: 1 }

  validates :minutes, presence: true, numericality: true
  validates :reminder_method, presence: true
end
