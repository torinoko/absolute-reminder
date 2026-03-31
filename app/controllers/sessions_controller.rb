class SessionsController < ApplicationController
  attr_reader :user

  def create
    @user = find_or_create_from_auth_hash(auth_hash)
    if user
      login
      ScheduleSync.call(user)
    end
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
    pending_uid   = session[:pending_line_uid]
    pending_token = session[:pending_line_token]
    OauthAuthenticator.call(auth_hash, pending_line_uid: pending_uid, pending_line_token: pending_token)
  end
end
