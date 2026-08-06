# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScheduleSyncJob do
  describe '#perform' do
    it 'ユーザーごとの同期ジョブをキューに積む' do
      users = create_list(:user, 2)
      allow(UserScheduleSyncJob).to receive(:perform_later)

      described_class.new.perform

      users.each do |user|
        expect(UserScheduleSyncJob).to have_received(:perform_later).with(user_id: user.id)
      end
    end
  end
end

RSpec.describe UserScheduleSyncJob do
  describe '#perform' do
    it '指定されたユーザーだけを同期する' do
      user = create(:user)
      allow(ScheduleSync).to receive(:call)

      described_class.new.perform(user_id: user.id)

      expect(ScheduleSync).to have_received(:call).with(user)
    end

    it '削除済みユーザーは無視する' do
      expect { described_class.perform_now(user_id: -1) }.not_to raise_error
    end
  end
end
