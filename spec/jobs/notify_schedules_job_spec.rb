# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotifySchedulesJob do
  let(:user) { create(:user) }
  let(:schedule) do
    Schedule.create!(
      user:, google_event_id: 'event-1', start_at: 1.hour.from_now, summary: '予定！'
    )
  end
  let(:reminder) { ScheduleReminder.create!(schedule:, reminder_method: :popup, minutes: 10) }

  before do
    create(:user_profile, user:, provider: 'line', uid: 'line-uid')
    create(:user_profile, user:, provider: 'discord', uid: 'discord-uid')
    allow(Line::SendMessageService).to receive(:call)
    allow(Discord::SendMessageService).to receive(:call)
  end

  it '同じジョブを再実行しても送信済みチャネルを重複送信しない' do
    described_class.new.perform(schedule_reminder_id: reminder.id)
    described_class.new.perform(schedule_reminder_id: reminder.id)

    expect(Line::SendMessageService).to have_received(:call).once
    expect(Discord::SendMessageService).to have_received(:call).once
    expect(reminder.notification_deliveries.where(status: 'sent').count).to eq(2)
  end

  it '一方のチャネルが失敗しても、他方を送信して失敗を再試行可能にする' do
    allow(Line::SendMessageService).to receive(:call).and_raise('LINE API error')

    expect {
      described_class.new.perform(schedule_reminder_id: reminder.id)
    }.to raise_error(NotificationDeliveryError, /LINE API error/)

    expect(Discord::SendMessageService).to have_received(:call).once
    expect(reminder.notification_deliveries.find_by(channel: 'line').status).to eq('failed')
    expect(reminder.notification_deliveries.find_by(channel: 'discord').status).to eq('sent')
  end
end
