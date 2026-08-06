# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScheduleSync do
  let(:user) { create(:user) }
  let(:start_at) { Time.zone.parse('2026-08-06 12:00:00') }
  let(:job) { instance_double('ConfiguredJob', job_id: 'job-1') }

  def event_with(minutes:, summary: '予定！')
    start = double('EventStart', date_time: start_at)
    reminder = double('EventReminder', reminder_method: 'popup', minutes:)
    reminders = double('EventReminders', overrides: [reminder])
    double('Event', id: 'event-1', start:, summary:, reminders:)
  end

  before do
    allow(NotifySchedulesJob).to receive(:set).and_return(job)
    allow(job).to receive(:perform_later).and_return(job)
  end

  it 'リマインダーだけが変更された場合も、同一トランザクションで更新して再予約する' do
    schedule = Schedule.create!(user:, google_event_id: 'event-1', start_at:, summary: '予定！')
    ScheduleReminder.create!(schedule:, reminder_method: :popup, minutes: 10)
    allow(Google::Calendar).to receive(:call).with(user).and_return([event_with(minutes: 20)])

    described_class.call(user)

    expect(schedule.reload.schedule_reminders.pluck(:minutes)).to eq([20])
    expect(job).to have_received(:perform_later).once
  end

  it 'リマインダー保存に失敗した場合、既存のリマインダーを残す' do
    schedule = Schedule.create!(user:, google_event_id: 'event-1', start_at:, summary: '予定！')
    ScheduleReminder.create!(schedule:, reminder_method: :popup, minutes: 10)
    allow(Google::Calendar).to receive(:call).with(user).and_return([event_with(minutes: nil)])

    expect { described_class.call(user) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(schedule.reload.schedule_reminders.pluck(:minutes)).to eq([10])
  end

  it '同期結果に存在しない同期期間内の予定を削除する' do
    stale = Schedule.create!(
      user:, google_event_id: 'deleted-event', start_at: 2.hours.from_now, summary: '削除予定！'
    )
    outside_window = Schedule.create!(
      user:, google_event_id: 'outside-window', start_at: 2.days.from_now, summary: '将来予定！'
    )
    allow(Google::Calendar).to receive(:call).with(user).and_return([event_with(minutes: 20)])

    described_class.call(user)

    expect(Schedule.exists?(stale.id)).to be(false)
    expect(Schedule.exists?(outside_window.id)).to be(true)
  end

  it 'Google APIが失敗した場合はローカル予定を削除しない' do
    stale = Schedule.create!(
      user:, google_event_id: 'deleted-event', start_at: 2.hours.from_now, summary: '削除予定！'
    )
    allow(Google::Calendar).to receive(:call).with(user).and_raise(StandardError, 'Google API error')

    expect { described_class.call(user) }.to raise_error(StandardError, 'Google API error')
    expect(Schedule.exists?(stale.id)).to be(true)
  end
end
