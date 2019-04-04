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
    root to: "devise/sessions#new"
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

    resources :booking_details, only: [:index, :show] do
        patch :booking, on: :member
        patch :send_under_negotiation, on: :member
        resources :booking_detail_schemes, except: [:destroy], controller: 'booking_details/booking_detail_schemes'

        resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts'
        resources :booking_detail_schemes, except: [:destroy]
        # resources :receipts, only: [:index]
      end
      
    resources :accounts
    resources :phases
    resources :erp_models, only: %i[index new create edit update]
    resources :sync_logs, only: %i[index] do
      get 'resync', on: :member
    end
    resources :emails, :smses, only: %i[index show]
    resource :client, except: [:show, :new, :create] do
      resources :templates, only: [:edit, :update, :index]
    end
    namespace :audit do
      resources :records, only: [:index]
      resources :entries, only: [:show]
    end

    resources :receipts, only: [:index, :show] do
      get :export, on: :collection
      get :resend_success, on: :member
    end

    resources :project_units, only: [:index, :show, :edit, :update] do
      member do
        get :print
        # get :send_under_negotiation
      end

      collection do
        get :export
        get :mis_report
      end
    end

    scope ":request_type" do
      resources :accounts, controller: 'accounts'
    end

    resources :users do

      member do
        get :resend_confirmation_instructions
        get :update_password
        get :resend_password_instructions
        get :print
      end

      collection do
        get '/new/:role', action: 'new', as: :new_by_role
        get :export
      end

      match :confirm_via_otp, action: 'confirm_via_otp', as: :confirm_via_otp, on: :member, via: [:get, :patch]

      resources :receipts, only: [:index, :new, :create, :edit, :update ] do
        get :resend_success, on: :member
        get :lost_receipt, on: :collection

      end

      resources :user_kycs, except: [:show, :destroy], controller: 'user_kycs'

      resources :project_units, only: [:index] do
        get :print, on: :member
      end
      resources :searches, except: [:destroy], controller: '/searches' do
        get :"3d", on: :collection, action: "three_d", as: "three_d"
        post :hold, on: :member
        post :update_scheme, on: :member
        get :checkout, on: :member
        post :make_available, on: :member
        get '/gateway-payment/:receipt_id', to: 'searches#gateway_payment', on: :member
        get :payment, on: :member
        get ":step", on: :member, to: "searches#show", as: :step
      end

      scope ":request_type" do
        resources :user_requests, except: [:destroy], controller: 'user_requests'
      end

      resources :booking_details, only: [:index, :show] do
        patch :booking, on: :member
        patch :send_under_negotiation, on: :member
        resources :booking_detail_schemes, only: [:index], controller: 'booking_details/booking_detail_schemes'

        resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts'
        # resources :booking_detail_schemes, except: [:destroy]
        # resources :receipts, only: [:index]
      end

    end

    resources :user_kycs, only: %i[index show], controller: 'user_kycs'
    scope ":request_type" do
      resources :user_requests, except: [:destroy], controller: 'user_requests' do
        get 'export', action: 'export', on: :collection, as: :export
      end
    end
    resources :schemes, except: [:destroy], controller: 'schemes', only_non_customizable_schemes: true do
      get :payment_adjustments_for_unit, on: :member
    end
  end

  # home & globally accessible
  match 'payment/:receipt_id/process_payment/:ignore', to: 'payment#process_payment', via: [:get, :post]
  get :register, to: 'home#register', as: :register
  post :check_and_register, to: 'home#check_and_register', as: :check_and_register

  scope :custom do
    match :inventory, to: 'custom#inventory', as: :custom_inventory, via: [:get]
  end

  scope :dashboard do
    # read only pages
    get '', to: 'dashboard#index', as: :dashboard
    get 'faqs', to: 'dashboard#faqs', as: :dashboard_faqs
    get 'gallery', to: 'dashboard#gallery', as: :dashboard_gallery
    get 'documents', to: 'dashboard#documents', as: :dashboard_documents
    get 'rera', to: 'dashboard#rera', as: :dashboard_rera
    get 'tds-process', to: 'dashboard#tds_process', as: :dashboard_tds_process
    get 'terms-and-conditions', to: 'dashboard#terms_and_condition', as: :dashboard_terms_and_condition
    get "gamify-unit-selection", to: "dashboard#gamify_unit_selection"
    resource :user do
      resources :searches, except: [:destroy], controller: 'searches' do
        get :"3d", on: :collection, action: "three_d", as: "three_d"
        post :hold, on: :member
        get 'tower/details', on: :collection, action: :tower, as: :tower
        get :checkout, on: :member
        post :update_scheme, on: :member
        post :make_available, on: :member
        get '/gateway-payment/:receipt_id', to: 'searches#gateway_payment', on: :member
        get :payment, on: :member
        get ":step", on: :member, to: "searches#show", as: :step
      end
    end
    resources :searches, except: [:destroy], controller: 'searches'
  end

  namespace :buyer do

    resources :emails, :smses, only: %i[index show]
    resources :project_units, only: [:index, :show, :edit, :update] 
    resources :users, only: [:show, :update, :edit] do
      member do
        get :update_password
      end

      resources :booking_details, only: [:index, :show] do
        resources :booking_detail_schemes, except: [:destroy], controller: 'booking_details/booking_detail_schemes'

        resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts'
      end

    end
    resources :receipts, only: [:index, :new, :create, :show ]
    resources :referrals, only: [:index, :create, :new] do
      post :generate_code, on: :collection
    end

    resources :user_kycs, except: [:show, :destroy], controller: 'user_kycs'
    resources :booking_details, only: [:update] do
      patch :booking, on: :member
      resources :booking_detail_schemes, except: [:destroy]

        resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts'
    end


    scope ":request_type" do
      resources :user_requests, except: [:destroy], controller: 'user_requests'
    end

  end

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create, :update]
    end
  end
  match '/sell_do/lead_created', to: "api/sell_do/leads#lead_created", via: [:get, :post]
  match '/sell_do/pushed_to_sales', to: "api/sell_do/leads#pushed_to_sales", via: [:get, :post]

end
