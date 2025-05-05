Rails.application.routes.draw do
  mount Integrasion::Engine => "/integrasion"

  resources :third_party_integrations

  get "/u/google/callback" => "third_party_integrations#callback", as: :third_party_integrations_callback
end
