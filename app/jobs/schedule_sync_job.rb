# frozen_string_literal: true

class ScheduleSyncJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      ScheduleSync.call(user)
    end
  end
end
