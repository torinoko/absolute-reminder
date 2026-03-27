# frozen_string_literal: true

class ScheduleSyncJob < ApplicationJob
  queue_as :default

  def perform
    User.eager_load(:user_profiles).find_each do |user|
      ScheduleSync.call(user)
    end
  end
end
