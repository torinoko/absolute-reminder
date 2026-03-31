# frozen_string_literal: true

class ApplicationController < ActionController::Base
  stale_when_importmap_changes
  helper_method :current_user, :user_signed_in?, :application_name

  def application_name
    ENV.fetch('APPLICATION_NAME', nil)
  end

  def current_user
    return if session[:user_id].blank?

    @current_user ||= User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end

  def require_login
    raise ActionController::Forbidden if current_user.blank?
  end
end
