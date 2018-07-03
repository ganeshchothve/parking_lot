require "sidekiq/web"
Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV_CONFIG[:sidekiq][:username] && password == ENV_CONFIG[:sidekiq][:password]
  end if Rails.env.production? || Rails.env.staging?
  mount Sidekiq::Web, at: "/sidekiq"

  root to: "home#register"
  get "/welcome", to: "home#index"
  get "employee-register", to: "home#employee_register", as: :employee_register
  get "external-register", to: "home#external_register", as: :external_register
  get "priority-register", to: "home#employee_register"

  devise_for :users, controllers: {confirmations: 'local_devise/confirmations',
                                   registrations: 'local_devise/registrations',
                                   unlocks: 'local_devise/unlocks',
                                   passwords: 'local_devise/passwords'}


  as :user do
    put '/user/confirmation', to: 'local_devise/confirmations#update', :as => :update_user_confirmation
  end

  #TODO_Pankit - ASSET_PATH wont work if we uncomment the below scope
  scope "*assetable_type/:assetable_id" do
    resources :assets, controller: :assets, as: :assetables
  end
  get :register, to: 'home#register', as: :register
  post :check_and_register, to: 'home#check_and_register', as: :check_and_register
  resources :channel_partners, except: [:destroy] do
    get 'export', action: 'export', on: :collection, as: :export
  end
  namespace :admin do
    resources :receipts, only: [:index, :show], controller: '/receipts' do
      get 'export', action: 'export', on: :collection, as: :export
    end
    resources :project_units, only: [:index, :edit, :update] do
      get 'eoi', action: 'eoi', on: :member, as: :eoi
      get 'breakup', action: 'breakup', on: :member, as: :breakup
      get 'export', action: 'export', on: :collection, as: :export
    end
    resources :users do
      get :resend_confirmation_instructions, action: 'resend_confirmation_instructions', as: :resend_confirmation_instructions, on: :member
      get :resend_password_instructions, action: 'resend_password_instructions', as: :resend_password_instructions, on: :member
      get '/new/:role', action: 'new', on: :collection, as: :new_by_role
      get 'export', action: 'export', on: :collection, as: :export
      resources :receipts, only: [:update, :edit, :show, :index, :new, :create], controller: '/receipts'
      resources :user_kycs, except: [:show, :destroy], controller: '/user_kycs'
      resources :project_units, only: [:index] do
        resources :receipts, only: [:update, :edit, :show, :index, :new, :create], controller: '/receipts'
      end
      resources :user_requests, except: [:destroy], controller: 'user_requests'
    end
    resources :discounts, except: [:destroy], controller: 'discounts' do
      get :approve_via_email, on: :member, action: 'approve_via_email'
    end
    resources :user_kycs, only: [:index], controller: '/user_kycs'
    resources :user_requests, except: [:destroy], controller: 'user_requests' do
	get 'export', action: 'export', on: :collection, as: :export
	end
  end

  match 'payment/:receipt_id/process_payment/:ignore', to: 'payment#process_payment', via: [:get, :post]

  get '/dashboard/faqs', to: 'dashboard#faqs'
  get '/dashboard/rera', to: 'dashboard#rera'
  get '/dashboard/tds-process', to: 'dashboard#tds_process'
  get '/dashboard/terms-and-conditions', to: 'dashboard#terms_and_condition'

  scope :dashboard do
    get 'make-remaining-payment/:project_unit_id', to: 'dashboard#make_remaining_payment'
    get 'booking-details', to: 'dashboard#booking_details'
    get 'cancel-booking', to: 'dashboard#cancel_booking'
    get 'kyc-form', to: 'dashboard#kyc_form'
    get 'add-booking', to: 'dashboard#add_booking'
    get ':project_unit_id/payment-breakup', to: 'dashboard#payment_breakup'
    get 'receipt', to: 'dashboard#receipt'
    get 'payment-success', to: 'dashboard#payment_success'
    get 'sales-booking', to: 'dashboard#sales_booking'
    post 'get_towers', to: 'dashboard#get_towers'
    post 'get_units', to: 'dashboard#get_units'
    post 'get_unit_details', to: 'dashboard#get_unit_details'
    get 'receipt-print/:id', to: 'dashboard#receipt_print'
    get 'get_eoi_receipt/:id', to: 'dashboard#eoi_receipt', as: :dashboard_eoi_receipt
    get 'receipt_print/:id', to: 'dashboard#receipt_print', as: :dashboard_receipt_print
    get 'send_receipt_mail/:id', to: 'dashboard#receipt_mail', as: :dashboard_receipt_mail
    get '', to: 'dashboard#index', as: :dashboard
    # get :project_units, to: 'dashboard#project_units', as: :dashboard_project_units
    get :project_units_new, to: 'dashboard#project_units_new', as: :dashboard_project_units_new
    get '/:receipt_id/razorpay-payment', to: 'dashboard#razorpay_payment'
    get '/apartment-selector/:configuration/:project_tower_id/:unit_id', to: 'dashboard#project_units', stage: 'kyc_details', :constraints => {:configuration => /[^\/]+/}
    get '/apartment-selector/:configuration/:project_tower_id', to: 'dashboard#project_units', stage: 'select_apartment', :constraints => {:configuration => /[^\/]+/}
    get '/apartment-selector/:configuration', to: 'dashboard#project_units', stage: 'choose_tower', :constraints => {:configuration => /[^\/]+/}
    get '/apartment-selector', to: 'dashboard#project_units', stage: 'apartment_selector'
    get '/3d-apartment-selector', to: 'dashboard#project_units_3d'

    get '/foyr-unit-status/:project_unit_id', to: 'dashboard#foyr_unit_status'

    get 'project_units/:project_unit_id', to: 'dashboard#project_unit', as: :dashboard_project_unit
    post 'project_units/:project_unit_id', to: 'dashboard#update_project_unit', as: :dashboard_update_project_unit
    post 'hold_project_unit/:project_unit_id', to: 'dashboard#hold_project_unit', as: :dashboard_hold_project_unit
    post 'update_co_applicants/:project_unit_id', to: 'dashboard#update_co_applicants', as: :dashboard_update_co_applicants
    get 'checkout/(:project_unit_id)', to: 'dashboard#checkout', as: :dashboard_checkout
    get 'checkout_via_email/:project_unit_id/:receipt_id', to: 'dashboard#checkout_via_email', as: :dashboard_checkout_via_email
    get "gamify-unit-selection", to: "dashboard#gamify_unit_selection"
    match 'payment/(:project_unit_id)', to: 'dashboard#payment', as: :dashboard_payment, via: [:get, :patch]
    resources :receipts
    resource :user do
      resources :user_requests, except: [:destroy], controller: 'admin/user_requests'
    end
    resources :user_kycs, except: [:show, :destroy]
  end

  # match '/api/sell_do/create_developer', to: 'api/sell_do#update', via: [:get, :post]
  # match '/api/sell_do/create_project', to: "api/sell_do#update", via: [:get, :post]
  # match '/api/sell_do/create_project_tower', to: "api/sell_do#update", via: [:get, :post]
  # match '/api/sell_do/create_unit_configuration', to: "api/sell_do#update", via: [:get, :post]
  # match '/api/sell_do/create_project_unit', to: "api/sell_do#update", via: [:get, :post]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
