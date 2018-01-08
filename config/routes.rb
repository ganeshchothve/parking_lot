Rails.application.routes.draw do
  root to: "home#index"
  devise_for :users
  get :register, to: 'home#register', as: :register
  post :check_and_register, to: 'home#check_and_register', as: :check_and_register
  resources :channel_partners, except: [:destroy]
  namespace :admin do
    resources :project_units, only: [:index]
    resources :users, except: [:update] do
      get '/new/:role', action: 'new', on: :collection, as: :new_by_role
      resources :receipts, only: [:update, :edit, :show, :index, :new, :create], controller: '/receipts'
      resources :user_kycs, except: [:show, :destroy], controller: '/user_kycs'
    end
    resources :user_kycs, only: [:index], controller: '/user_kycs'
    resources :user_requests, except: [:destroy]
  end

  get 'payment/:gateway/process_payment', to: 'payment#process_payment'

  get :dashboard, to: 'dashboard#index', as: :dashboard
  scope :dashboard do
    get :project_units, to: 'dashboard#project_units', as: :dashboard_project_units
    get 'project_units/:project_unit_id', to: 'dashboard#project_unit', as: :dashboard_project_unit
    post 'project_units/:project_unit_id', to: 'dashboard#update_project_unit', as: :dashboard_update_project_unit
    post 'hold_project_unit/:project_unit_id', to: 'dashboard#hold_project_unit', as: :dashboard_hold_project_unit
    get 'checkout/(:project_unit_id)', to: 'dashboard#checkout', as: :dashboard_checkout
    match 'payment/(:project_unit_id)', to: 'dashboard#payment', as: :dashboard_payment, via: [:get, :patch]
    resources :receipts
    resources :user_kycs, except: [:show, :destroy]
  end

  scope :api do
    get '/sell_do/create_project', controller: "sell_do"
    get '/sell_do/create_project_tower', controller: "sell_do"
    get '/sell_do/create_project_unit', controller: "sell_do"
    get '/sell_do/create_uc', controller: "sell_do"
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
