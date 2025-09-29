Rails.application.routes.draw do

  get "up" => "rails/health#show", as: :rails_health_check
  resources :translations, only: [:new, :create]

  root "documents#new"

  resources :documents do
    member do
      patch :update_layout   # AJAX save from browser editor
      get   :export          # download rebuilt PDF
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
