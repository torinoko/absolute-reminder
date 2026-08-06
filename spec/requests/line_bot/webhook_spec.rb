# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LineBot::Webhooks', type: :request do
  let(:body)      { '{"events":[],"destination":"test"}' }
  let(:headers)   { { 'Content-Type' => 'application/json', 'X-Line-Signature' => 'sig' } }

  describe 'POST /line_bot/webhook' do
    context '署名検証が失敗する場合' do
      before do
        parser = instance_double(Line::Bot::V2::WebhookParser)
        allow(Line::Bot::V2::WebhookParser).to receive(:new).and_return(parser)
        allow(parser).to receive(:parse).and_raise(StandardError, 'invalid signature')
      end

      it '400 を返す' do
        post line_bot_webhook_path, params: body, headers: headers
        expect(response).to have_http_status(:bad_request)
      end
    end

    context '有効な FollowEvent の場合' do
      let(:follow_event) { double('FollowEvent', source: double(user_id: 'U_test_uid'), reply_token: 'r_token') }

      before do
        # case/when の === をスタブ
        allow(Line::Bot::V2::Webhook::FollowEvent).to receive(:===).with(follow_event).and_return(true)

        parser = instance_double(Line::Bot::V2::WebhookParser)
        allow(Line::Bot::V2::WebhookParser).to receive(:new).and_return(parser)
        allow(parser).to receive(:parse).and_return([follow_event])

        mock_client = instance_double(Line::Bot::V2::MessagingApi::ApiClient)
        allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:reply_message)
      end

      it '200 を返す' do
        post line_bot_webhook_path, params: body, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'LineToken を作成する' do
        expect {
          post line_bot_webhook_path, params: body, headers: headers
        }.to change(LineToken, :count).by(1)
      end

      it 'LineToken の uid が正しい' do
        post line_bot_webhook_path, params: body, headers: headers
        expect(LineToken.last.uid).to eq('U_test_uid')
      end
    end
  end
end
