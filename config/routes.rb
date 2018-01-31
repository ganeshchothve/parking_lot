require "sidekiq/web"
Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV_CONFIG[:sidekiq][:username] && password == ENV_CONFIG[:sidekiq][:password]
  end if Rails.env.production? || Rails.env.staging?
  mount Sidekiq::Web, at: "/sidekiq"

  root to: "home#index"

  devise_for :users, :controllers => { confirmations: "confirmations" }
  as :user do
    put '/user/confirmation', to: 'confirmations#update', :as => :update_user_confirmation
  end

  get :register, to: 'home#register', as: :register
  post :check_and_register, to: 'home#check_and_register', as: :check_and_register
  resources :channel_partners, except: [:destroy] do
    get 'export', action: 'export', on: :collection, as: :export
  end
  namespace :admin do
    resources :receipts, only: [:index], controller: '/receipts' do
      get 'export', action: 'export', on: :collection, as: :export
    end
    resources :project_units, only: [:index]
    resources :users, except: [:update] do
      get '/new/:role', action: 'new', on: :collection, as: :new_by_role
      get 'export', action: 'export', on: :collection, as: :export
      resources :receipts, only: [:update, :edit, :show, :index, :new, :create], controller: '/receipts'
      resources :user_kycs, except: [:show, :destroy], controller: '/user_kycs'
      resources :project_units, only: [:index] do
        resources :receipts, only: [:update, :edit, :show, :index, :new, :create], controller: '/receipts'
      end
    end
    resources :user_kycs, only: [:index], controller: '/user_kycs'
    resources :user_requests, except: [:destroy]
  end

  get '/dashboard/booking-details', to: 'dashboard#booking_details'
  get '/dashboard/cancel-booking', to: 'dashboard#cancel_booking'
  get '/dashboard/kyc-form', to: 'dashboard#kyc_form'
  get '/dashboard/add-booking', to: 'dashboard#add_booking'
  post '/dashboard/get_towers', to: 'dashboard#get_towers'
  post '/dashboard/get_units', to: 'dashboard#get_units'
  post '/dashboard/get_unit_details', to: 'dashboard#get_unit_details'

  match 'payment/:receipt_id/process_payment', to: 'payment#process_payment', via: [:get, :post]

  get :dashboard, to: 'dashboard#index', as: :dashboard
  scope :dashboard do
    get :project_units, to: 'dashboard#project_units', as: :dashboard_project_units
    get :project_units_new, to: 'dashboard#project_units_new', as: :dashboard_project_units_new
    get 'project_units/:project_unit_id', to: 'dashboard#project_unit', as: :dashboard_project_unit
    post 'project_units/:project_unit_id', to: 'dashboard#update_project_unit', as: :dashboard_update_project_unit
    post 'hold_project_unit/:project_unit_id', to: 'dashboard#hold_project_unit', as: :dashboard_hold_project_unit
    get 'checkout/(:project_unit_id)', to: 'dashboard#checkout', as: :dashboard_checkout
    match 'payment/(:project_unit_id)', to: 'dashboard#payment', as: :dashboard_payment, via: [:get, :patch]
    resources :receipts
    resources :user_kycs, except: [:show, :destroy]
  end

  match '/api/sell_do/create_developer', controller: 'api/sell_do', via: [:get, :post]
  match '/api/sell_do/create_project', controller: "api/sell_do", via: [:get, :post]
  match '/api/sell_do/create_project_tower', controller: "api/sell_do", via: [:get, :post]
  match '/api/sell_do/create_project_unit', controller: "api/sell_do", via: [:get, :post]
  match '/api/sell_do/create_uc', controller: "api/sell_do", via: [:get, :post]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
