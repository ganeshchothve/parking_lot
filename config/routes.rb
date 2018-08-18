require "sidekiq/web"
Rails.application.routes.draw do
  # sidekiq
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV_CONFIG[:sidekiq][:username] && password == ENV_CONFIG[:sidekiq][:password]
  end if Rails.env.production? || Rails.env.staging?
  mount Sidekiq::Web, at: "/sidekiq"

  # user & devise related
  devise_for :users, controllers: {
    confirmations: 'local_devise/confirmations',
    registrations: 'local_devise/registrations',
    sessions: 'local_devise/sessions',
    unlocks: 'local_devise/unlocks',
    passwords: 'local_devise/passwords'
  }

  devise_scope :user do
    post 'users/otp', :to => 'local_devise/sessions#otp', :as => :users_otp
  end

  as :user do
    put '/user/confirmation', to: 'local_devise/confirmations#update', :as => :update_user_confirmation
  end

  scope "*assetable_type/:assetable_id" do
    resources :assets, controller: :assets, as: :assetables
  end
  scope "*notable_type/:notable_id" do
    resources :notes, controller: :notes, as: :notables
  end
  resources :channel_partners, except: [:destroy] do
    get 'export', action: 'export', on: :collection, as: :export
  end
  namespace :admin do
    resource :client, except: [:show, :new, :create] do
      resources :sms_templates, only: [:edit, :update, :index]
    end
    resources :receipts, only: [:index, :show], controller: '/receipts' do
      get 'export', action: 'export', on: :collection, as: :export
      get :resend_success, on: :member, as: :resend_success
    end
    resources :project_units, only: [:index, :edit, :update] do
      get 'export', action: 'export', on: :collection, as: :export
      get 'mis_report', action: 'mis_report', on: :collection, as: :mis_report
    end
    resources :users do
      get :resend_confirmation_instructions, action: 'resend_confirmation_instructions', as: :resend_confirmation_instructions, on: :member
      match 'update_password', on: :member, via: [:get, :patch], action: "update_password", as: :update_password
      get :resend_password_instructions, action: 'resend_password_instructions', as: :resend_password_instructions, on: :member
      match :confirm_via_otp, action: 'confirm_via_otp', as: :confirm_via_otp, on: :member, via: [:get, :patch]
      get '/new/:role', action: 'new', on: :collection, as: :new_by_role
      get 'export', action: 'export', on: :collection, as: :export
      get 'print', action: 'print', on: :member, as: :print
      resources :receipts, only: [:update, :edit, :show, :index, :new, :create], controller: '/receipts' do
        get :direct, on: :collection, as: :direct
        get :resend_success, on: :member, as: :resend_success
      end
      resources :user_kycs, except: [:show, :destroy], controller: '/user_kycs'
      resources :project_units, only: [:index] do
        resources :receipts, only: [:update, :edit, :show, :index, :new, :create], controller: '/receipts'
      end
      resources :searches, except: [:destroy], controller: '/searches' do
        post :hold, on: :member
        get :checkout, on: :member
        post :make_available, on: :member
        get '/razorpay-payment/:receipt_id', to: 'searches#razorpay_payment', on: :member
        get :payment, on: :member
        get ":step", on: :member, to: "searches#show", as: :step
      end
      resources :user_requests, except: [:destroy], controller: 'user_requests'
      resources :booking_details, only: [:update], controller: 'booking_details'
    end
    resources :discounts, except: [:destroy], controller: 'discounts' do
      get :approve_via_email, on: :member, action: 'approve_via_email'
    end
    resources :user_kycs, only: [:index], controller: '/user_kycs' do
      get 'export', action: 'export', on: :collection, as: :export
    end
    resources :user_requests, except: [:destroy], controller: 'user_requests' do
      get 'export', action: 'export', on: :collection, as: :export
    end
  end

  # home & globally accessible
  match 'payment/:receipt_id/process_payment/:ignore', to: 'payment#process_payment', via: [:get, :post]
  get :register, to: 'home#register', as: :register
  post :check_and_register, to: 'home#check_and_register', as: :check_and_register
  root to: "home#register"

  scope :dashboard do
    # read only pages
    get '', to: 'dashboard#index', as: :dashboard
    get 'faqs', to: 'dashboard#faqs', as: :dashboard_faqs
    get 'documents', to: 'dashboard#documents', as: :dashboard_documents
    get 'rera', to: 'dashboard#rera', as: :dashboard_rera
    get 'tds-process', to: 'dashboard#tds_process', as: :dashboard_tds_process
    get 'terms-and-conditions', to: 'dashboard#terms_and_condition', as: :dashboard_terms_and_condition

    # related to apartment selector
    get '/apartment-selector/:configuration/:project_tower_id/:unit_id', to: 'dashboard#project_units', stage: 'kyc_details', :constraints => {:configuration => /[^\/]+/}
    get '/apartment-selector/:configuration/:project_tower_id', to: 'dashboard#project_units', stage: 'select_apartment', :constraints => {:configuration => /[^\/]+/}
    get '/apartment-selector/:configuration', to: 'dashboard#project_units', stage: 'choose_tower', :constraints => {:configuration => /[^\/]+/}
    get '/apartment-selector', to: 'dashboard#project_units', stage: 'apartment_selector', as: :dashboard_project_units

    # project unit & payment related
    get 'make-remaining-payment/:project_unit_id', to: 'dashboard#make_remaining_payment'
    get ':project_unit_id/payment-breakup', to: 'dashboard#payment_breakup'
    get "gamify-unit-selection", to: "dashboard#gamify_unit_selection"
    resource :user do
      resources :user_requests, except: [:destroy], controller: 'admin/user_requests'
      match 'update_password', via: [:get, :patch], action: "update_password", as: :update_password, controller: 'admin/users'
      resources :user_kycs, except: [:show, :destroy], controller: 'user_kycs'
      resources :searches, except: [:destroy], controller: 'searches' do
        post :hold, on: :member
        get 'tower/details', on: :collection, action: :tower, as: :tower
        get :checkout, on: :member
        post :make_available, on: :member
        get '/razorpay-payment/:receipt_id', to: 'searches#razorpay_payment', on: :member
        get :payment, on: :member
        get ":step", on: :member, to: "searches#show", as: :step
      end
      resources :receipts, only: [:update, :edit, :show, :index, :new, :create], controller: 'receipts' do
        get :direct, on: :collection, as: :direct
      end
    end
    resources :user_kycs, except: [:show, :destroy]
    resources :searches, except: [:destroy], controller: 'searches'
  end

  match '/sell_do/lead_created', to: "api/sell_do/leads#lead_created", via: [:get, :post]
  match '/sell_do/pushed_to_sales', to: "api/sell_do/leads#pushed_to_sales", via: [:get, :post]
end
