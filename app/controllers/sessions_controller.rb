class SessionsController < ApplicationController
  attr_reader :user

  def create
    @user = find_or_create_from_auth_hash(auth_hash)
    login if user
    ScheduleSync.call(user)
    redirect_to root_path
  end

  def destroy
    logout
    redirect_to root_path
  end

  private

  def login
    session[:user_id] = user.id
  end

  def logout
    session.delete(:user_id)
    @current_user = nil
  end

  def auth_hash
    request.env['omniauth.auth']
  end

  def find_or_create_from_auth_hash(auth_hash)
    user = OauthAuthenticator.call(auth_hash)
    uid = session[:pending_line_uid]
    if uid
      access_token = session[:pending_line_token]
      OauthAuthenticator.call({ provider: :line, uid:, access_token:})
    end
    user
  end
end
