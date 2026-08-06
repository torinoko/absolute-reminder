# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Discord::Callbacks', type: :request do
  let(:user)  { create(:user) }
  let(:state) { 'test_state_abc123' }

  describe 'GET /discord/callback' do
    context 'ログインしていない場合' do
      it '403 を返す' do
        get discord_callback_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'ログイン済みの場合' do
      before do
        log_in_as(user)
        # state をセッションに仕込む
        allow_any_instance_of(ActionDispatch::Request)
          .to receive(:session).and_wrap_original do |m, *args|
          sess = m.call(*args)
          sess[:discord_oauth_state] = state
          sess
        end
      end

      context 'code パラメータがない場合' do
        it '400 を返す' do
          get discord_callback_path, params: { state: state }
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'state が不一致の場合' do
        it '400 を返す' do
          get discord_callback_path, params: { code: 'some_code', state: 'wrong_state' }
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'Discord トークン交換が失敗する場合' do
        before do
          stub_request(:post, 'https://discord.com/api/oauth2/token')
            .to_return(status: 400, body: 'Bad Request')
        end

        it '400 を返す' do
          get discord_callback_path, params: { code: 'bad_code', state: state }
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'Discord /users/@me が失敗する場合' do
        before do
          stub_request(:post, 'https://discord.com/api/oauth2/token')
            .to_return(status: 200, body: { access_token: 'token' }.to_json)
          stub_request(:get, 'https://discord.com/api/users/@me')
            .to_return(status: 403, body: 'Forbidden')
        end

        it '400 を返す' do
          get discord_callback_path, params: { code: 'valid_code', state: state }
          expect(response).to have_http_status(:bad_request)
        end
      end

      context '正常フローの場合' do
        before do
          stub_request(:post, 'https://discord.com/api/oauth2/token')
            .to_return(status: 200, body: { access_token: 'discord_token' }.to_json)
          stub_request(:get, 'https://discord.com/api/users/@me')
            .to_return(status: 200, body: { id: 'discord_uid_999', username: 'tester' }.to_json)
        end

        it 'root にリダイレクトする' do
          get discord_callback_path, params: { code: 'valid_code', state: state }
          expect(response).to redirect_to(root_path)
        end

        it 'Discord の UserProfile が作成される' do
          expect {
            get discord_callback_path, params: { code: 'valid_code', state: state }
          }.to change(UserProfile, :count).by(1)
          expect(UserProfile.find_by(provider: 'discord', uid: 'discord_uid_999')).not_to be_nil
        end
      end
    end
  end
end
