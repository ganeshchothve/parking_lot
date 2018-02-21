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

  scope "*assetable_type/:assetable_id" do
    resources :assets, controller: :assets
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
      resources :user_requests, except: [:destroy], controller: 'user_requests'
    end
    resources :user_kycs, only: [:index], controller: '/user_kycs'
    resources :user_requests, except: [:destroy], controller: 'user_requests'
  end

  get '/dashboard/booking-details', to: 'dashboard#booking_details'
  get '/dashboard/cancel-booking', to: 'dashboard#cancel_booking'
  get '/dashboard/kyc-form', to: 'dashboard#kyc_form'
  get '/dashboard/add-booking', to: 'dashboard#add_booking'
  get '/dashboard/payment-breakup', to: 'dashboard#payment_breakup'
  get '/dashboard/receipt', to: 'dashboard#receipt'
  get '/dashboard/sales-booking', to: 'dashboard#sales_booking'
  post '/dashboard/get_towers', to: 'dashboard#get_towers'
  post '/dashboard/get_units', to: 'dashboard#get_units'
  post '/dashboard/get_unit_details', to: 'dashboard#get_unit_details'

  match 'payment/:receipt_id/process_payment/:ignore', to: 'payment#process_payment', via: [:get, :post]

  get :dashboard, to: 'dashboard#index', as: :dashboard
  scope :dashboard do
    get :project_units, to: 'dashboard#project_units', as: :dashboard_project_units
    get :project_units_new, to: 'dashboard#project_units_new', as: :dashboard_project_units_new
    get 'project_units/:project_unit_id', to: 'dashboard#project_unit', as: :dashboard_project_unit
    post 'project_units/:project_unit_id', to: 'dashboard#update_project_unit', as: :dashboard_update_project_unit
    post 'hold_project_unit/:project_unit_id', to: 'dashboard#hold_project_unit', as: :dashboard_hold_project_unit
    get 'checkout/(:project_unit_id)', to: 'dashboard#checkout', as: :dashboard_checkout
    get 'checkout_via_email/:project_unit_id/:receipt_id', to: 'dashboard#checkout_via_email', as: :dashboard_checkout_via_email
    match 'payment/(:project_unit_id)', to: 'dashboard#payment', as: :dashboard_payment, via: [:get, :patch]
    resources :receipts
    resource :user do
      resources :user_requests, except: [:destroy], controller: 'admin/user_requests'
    end
    resources :user_kycs, except: [:show, :destroy]
  end

  match '/api/sell_do/create_developer', to: 'api/sell_do#update', via: [:get, :post]
  match '/api/sell_do/create_project', to: "api/sell_do#update", via: [:get, :post]
  match '/api/sell_do/create_project_tower', to: "api/sell_do#update", via: [:get, :post]
  match '/api/sell_do/create_unit_configuration', to: "api/sell_do#update", via: [:get, :post]
  match '/api/sell_do/create_project_unit', to: "api/sell_do#update", via: [:get, :post]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
