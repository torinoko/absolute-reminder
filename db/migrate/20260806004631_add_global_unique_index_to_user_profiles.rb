# frozen_string_literal: true

class AddGlobalUniqueIndexToUserProfiles < ActiveRecord::Migration[8.1]
  def change
    # An external account (for example, a Google `sub` or a LINE user ID) must
    # never be linked to more than one application user. Application-level
    # validation alone cannot protect against concurrent OAuth callbacks.
    add_index :user_profiles, [:provider, :uid], unique: true
  end
end
