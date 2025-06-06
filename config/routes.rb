Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  
  namespace :api do
    namespace :v1 do
      resources :jobs, only: [:index, :show, :create, :destroy] do
        member do
          patch :retry
        end
      end
      
      get 'queue/stats', to: 'queue#stats'
    end
  end
  
  mount ActionCable.server => '/cable'
end