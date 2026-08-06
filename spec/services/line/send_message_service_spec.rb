# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Line::SendMessageService do
  let(:uid)  { 'U1234567890abcdef' }
  let(:text) { 'テスト通知' }
  let(:mock_client)   { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }
  let(:mock_response) { double('Response') }

  before do
    allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(mock_client)
  end

  describe '.call' do
    subject { described_class.call(uid: uid, text: text) }

    context 'push_message が成功する場合' do
      before { allow(mock_client).to receive(:push_message).and_return(mock_response) }

      it 'レスポンスを返す' do
        expect(subject).to eq(mock_response)
      end
    end

    context 'push_message が例外を発生させる場合' do
      before { allow(mock_client).to receive(:push_message).and_raise(StandardError, 'API error') }

      it '例外を呼び出し元へ返す' do
        expect { subject }.to raise_error(StandardError, 'API error')
      end
    end
  end
end
