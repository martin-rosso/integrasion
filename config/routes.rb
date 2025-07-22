Nexo::Engine.routes.draw do
  resources :folders do
    member do
      post :sync
      post :full_sync
      post :incremental_sync
      post :check_status
      post :perform_operation
    end
  end

  resources :elements do
    member do
      post :resolve_conflict
      post :modify_local
      post :update_status
      post :perform_operation
    end
  end

  resources :element_versions do
    member do
      post :sync
    end
  end

  root to: redirect('folders')
end
