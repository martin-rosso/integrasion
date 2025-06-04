Nexo::Engine.routes.draw do
  resources :elements do
    member do
      post :fetch_remote
      post :resolve_conflict
      post :modify_local
      post :update_status
    end
  end

  resources :element_versions do
    member do
      post :sync
    end
  end

  root to: redirect('elements')
end
