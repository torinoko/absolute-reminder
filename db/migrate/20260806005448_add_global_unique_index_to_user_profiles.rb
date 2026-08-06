# frozen_string_literal: true

class AddGlobalUniqueIndexToUserProfiles < ActiveRecord::Migration[8.1]
  def change
    add_index :user_profiles, [:provider, :uid], unique: true unless index_exists?(:user_profiles, [:provider, :uid], unique: true)
  end
end
