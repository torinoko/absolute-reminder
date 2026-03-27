Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root 'reminders#index'
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'logout', to: 'sessions#destroy'

  namespace :line_bot do
    get 'oauth', to: 'oauth#show'
    post 'webhook', to: 'oauth#create'
  end

  namespace :discord do
    get 'setup', to: 'oauth#new'
    get "webhook", to: 'oauth#create'
  end
end
