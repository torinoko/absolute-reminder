class ApplicationController < ActionController::Base
  stale_when_importmap_changes
  helper_method :current_user, :user_signed_in?, :application_name

  def application_name
    Config::APPLICATION_NAME
  end

  def current_user
    return if session[:user_id].blank?

    @current_user ||= User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end

  private

  def login(user)
    session[:user_id] = user.id
  end

  def logout
    session.delete(:user_id)
    @current_user = nil
  end
end
