Rails.application.routes.draw do
  mount Nexo::Engine => "/nexo"

  resources :integrations do
    member do
      post :revoke_authorization
    end
  end

  mount GoodJob::Engine => 'good_job'

  get "/u/google/callback" => "integrations#callback", as: :integrations_callback
  root to: redirect("/integrations")
end
