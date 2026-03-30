Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root 'reminders#index'
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'logout', to: 'sessions#destroy'

  namespace :line_bot do
    get 'setup', to: 'setup#show'
    post 'webhook', to: 'webhook#create'
  end

  namespace :discord do
    get 'setup', to: 'setup#show'
    get "webhook", to: 'webhook#create'
  end
end
