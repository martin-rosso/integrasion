Rails.application.routes.draw do
  mount Integrasion::Engine => "/integrasion"

  resources :third_party_integrations do
    member do
      post :revoke_authorization
    end
  end

  get "/u/google/callback" => "third_party_integrations#callback", as: :third_party_integrations_callback
  root to: redirect("/third_party_integrations")
end
