# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserProfile, type: :model do
  describe 'external account uniqueness' do
    let(:provider) { 'google_oauth2' }
    let(:uid) { 'google-user-123' }

    before { create(:user_profile, provider:, uid:) }

    it 'does not allow the same provider account to be linked to another user' do
      duplicate = build(:user_profile, provider:, uid:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.of_kind?(:uid, :taken)).to be(true)
    end

    it 'allows the same uid for a different provider' do
      profile = build(:user_profile, provider: 'discord', uid:)

      expect(profile).to be_valid
    end
  end
end
