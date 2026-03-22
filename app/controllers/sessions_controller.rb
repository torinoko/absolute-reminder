class SessionsController < ApplicationController
  attr_reader :user
  def create
    @user = find_or_create_from_auth_hash(auth_hash)
    login if user
    ScheduleSync.call(user)
    create_line_profile
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
    OauthAuthenticator.call(auth_hash)
  end

  def create_line_profile
    line_uid = session[:pending_line_uid]
    line_auth_hash = { provider: :line, uid: line_uid,  }
    OauthAuthenticator.call(line_auth_hash)
  end
end
