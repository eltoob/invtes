Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    root to: "events#index"
    resources :events, only: [ :index, :show ] do
      member do
        get :export, defaults: { format: :csv }
        post :send_reminders
      end
      resources :rsvps, only: [ :destroy ]
    end
  end

  root "home#index"

  # Smart URL for each event: yoursite.com/<slug>
  get  "/:slug",      to: "invitations#show",  as: :invitation,
                      constraints: { slug: /[a-z0-9]+(?:-[a-z0-9]+)*/ }
  post "/:slug/rsvp", to: "rsvps#create",      as: :invitation_rsvp,
                      constraints: { slug: /[a-z0-9]+(?:-[a-z0-9]+)*/ }
end
