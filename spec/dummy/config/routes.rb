Rails.application.routes.draw do
  mount Integrasion::Engine => "/integrasion"

  resources :third_party_integrations
end
