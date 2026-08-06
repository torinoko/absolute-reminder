# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OauthAuthenticator do
  let(:uid) { 'google_uid_123' }
  let(:auth_hash) do
    {
      provider: 'google_oauth2',
      uid: uid,
      info: { email: 'test@example.com', name: 'Test User' },
      credentials: { token: 'access_token', refresh_token: 'refresh_token' },
      extra: { raw_info: { sub: uid } }
    }
  end

  subject { described_class.call(auth_hash) }

  describe '.call' do
    context '新規ユーザーの場合' do
      it 'User を作成する' do
        expect { subject }.to change(User, :count).by(1)
      end

      it 'Google OAuth2 の UserProfile を作成する' do
        expect { subject }.to change(UserProfile, :count).by(1)
      end

      it 'ユーザーを返す' do
        result = subject
        expect(result).to be_a(User)
        expect(result.email).to eq('test@example.com')
      end
    end

    context '既存ユーザーの場合' do
      let!(:user)    { create(:user, email: 'old@example.com') }
      let!(:profile) { create(:user_profile, user: user, provider: 'google_oauth2', uid: uid) }

      it '新たに User を作成しない' do
        expect { subject }.not_to change(User, :count)
      end

      it '既存ユーザーを返す' do
        expect(subject).to eq(user)
      end

      it 'メールアドレスを更新する' do
        subject
        expect(user.reload.email).to eq('test@example.com')
      end
    end

    context 'pending_line_uid が設定されている場合' do
      subject { described_class.call(auth_hash, pending_line_uid: 'line_uid_456', pending_line_token: 'token') }

      it 'UserProfile を 2 件作成する (Google + LINE)' do
        expect { subject }.to change(UserProfile, :count).by(2)
      end

      it 'LINE プロファイルが作成される' do
        subject
        expect(UserProfile.find_by(provider: 'line', uid: 'line_uid_456')).not_to be_nil
      end
    end

    context 'ActiveRecord::RecordInvalid が発生する場合' do
      before { allow(User).to receive(:create!).and_raise(ActiveRecord::RecordInvalid) }

      it 'nil を返す' do
        expect(subject).to be_nil
      end
    end
  end
end
