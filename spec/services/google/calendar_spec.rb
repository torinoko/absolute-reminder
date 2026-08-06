# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Google::Calendar do
  let(:user) { build_stubbed(:user) }

  def build_event(summary:, date_time:)
    start_obj = double('EventDateTime', date_time: date_time)
    double('Event',
           id: SecureRandom.hex(8),
           summary: summary,
           start: start_obj)
  end

  let(:valid_event)   { build_event(summary: 'テスト予定！', date_time: 1.hour.from_now) }
  let(:past_event)    { build_event(summary: '過去の予定！', date_time: 1.hour.ago) }
  let(:no_bang_event) { build_event(summary: 'キーワードなし', date_time: 1.hour.from_now) }
  let(:all_day_event) { build_event(summary: '終日！', date_time: nil) }

  let(:mock_auth)    { instance_double(Signet::OAuth2::Client) }
  let(:mock_service) { instance_double(Google::Apis::CalendarV3::CalendarService) }

  before do
    allow_any_instance_of(Google::Client).to receive(:execute).and_yield(mock_auth)
    allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(mock_service)
    allow(mock_service).to receive(:authorization=)
    result = double('Events', items: events)
    allow(mock_service).to receive(:list_events).and_return(result)
  end

  describe '.call' do
    subject { described_class.call(user) }

    context 'キーワードを含む未来のイベント' do
      let(:events) { [valid_event] }

      it '返す' do
        expect(subject).to eq([valid_event])
      end
    end

    context '過去のイベント' do
      let(:events) { [past_event] }

      it '除外する' do
        expect(subject).to be_empty
      end
    end

    context 'キーワード（！）を含まないイベント' do
      let(:events) { [no_bang_event] }

      it '除外する' do
        expect(subject).to be_empty
      end
    end

    context '終日イベント（date_time が nil）' do
      let(:events) { [all_day_event] }

      it '除外する' do
        expect(subject).to be_empty
      end
    end

    context '複数イベントが混在する場合' do
      let(:events) { [valid_event, past_event, no_bang_event, all_day_event] }

      it 'valid_event のみ返す' do
        expect(subject).to eq([valid_event])
      end
    end
  end
end
