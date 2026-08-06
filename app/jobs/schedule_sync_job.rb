# frozen_string_literal: true

class ScheduleSyncJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      UserScheduleSyncJob.perform_later(user_id: user.id)
    end
  end
end

class UserScheduleSyncJob < ApplicationJob
  queue_as :google_sync
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id:)
    ScheduleSync.call(User.find(user_id))
  end
end
