# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Discord::SendMessageService do
  let(:uid)  { '123456789' }
  let(:text) { 'テスト通知' }

  describe '.call' do
    subject { described_class.call(uid: uid, text: text) }

    context 'DM 作成とメッセージ送信が成功する場合' do
      before do
        stub_request(:post, 'https://discord.com/api/v10/users/@me/channels')
          .to_return(status: 200,
                     body: { 'id' => 'ch_999' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, 'https://discord.com/api/v10/channels/ch_999/messages')
          .to_return(status: 200, body: {}.to_json)
      end

      it 'Net::HTTPSuccess を返す' do
        expect(subject).to be_a(Net::HTTPSuccess)
      end
    end

    context 'DM チャンネル作成が失敗する場合 (403)' do
      before do
        stub_request(:post, 'https://discord.com/api/v10/users/@me/channels')
          .to_return(status: 403, body: 'Forbidden')
      end

      it '例外を呼び出し元へ返す' do
        expect { subject }.to raise_error(RuntimeError, /Discord DM channel error/)
      end
    end

    context 'DM 作成レスポンスが不正な JSON の場合' do
      before do
        stub_request(:post, 'https://discord.com/api/v10/users/@me/channels')
          .to_return(status: 200, body: 'invalid json',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it '例外を呼び出し元へ返す' do
        expect { subject }.to raise_error(RuntimeError, /Discord JSON parse error/)
      end
    end
  end
end
