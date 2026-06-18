Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  devise_for :users, controllers: { registrations: "users/registrations", sessions: "users/sessions" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "pricing", to: "pricing#index"

  get "dashboard", to: "dashboard#show"

  namespace :stripe do
    resource :checkout, only: %i[create new]
    resource :billing_portal, only: :create
    post "webhooks", to: "webhooks#create"
  end

  get "checkout/success", to: "stripe/checkouts#success"
  get "checkout/cancel", to: "stripe/checkouts#cancel"

  resources :invitations, only: %i[new create destroy]
  get "invitations/:token/accept", to: "invitation_acceptances#new", as: :accept_invitation
  post "invitations/:token/accept", to: "invitation_acceptances#create"

  resource :locale, only: :update

  namespace :admin do
    root to: "dashboard#show"

    resources :accounts, only: %i[index show edit update] do
      resource :subscription, only: %i[edit update]
      post :reset_subscription, on: :member
    end

    resources :plans do
      resources :prices, only: %i[new create edit update]
    end

    resources :features
  end

  root "home#index"
end
