# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it '同じ表示名のユーザーを許可する' do
    create(:user, name: '山田太郎')
    another_user = build(:user, name: '山田太郎')

    expect(another_user).to be_valid
  end
end
