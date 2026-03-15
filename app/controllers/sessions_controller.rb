class SessionsController < ApplicationController
  def create
    user = find_or_create_from_auth_hash(auth_hash)
    login(user) if user
    redirect_to root_path
  end

  def destroy
    logout
    redirect_to root_path
  end

  private

  def auth_hash
    request.env['omniauth.auth']
  end

  def find_or_create_from_auth_hash(auth_hash)
    email = auth_hash['info']['email']
    User.find_or_create_by(email:) do |user|
      user.update!(uid: auth_hash['uid'], name: auth_hash['info']['name'])
    end
  end
end
