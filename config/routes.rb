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
    passwords: 'local_devise/passwords',
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  devise_scope :user do
    post 'users/otp', :to => 'local_devise/sessions#otp', :as => :users_otp
    post 'users/notification_tokens', to: 'users/notification_tokens#update', as: :user_notification_tokens
  end

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  root 'channel_partners#new'

  as :user do
    put '/user/confirmation', to: 'local_devise/confirmations#update', :as => :update_user_confirmation
  end

  scope "*assetable_type/:assetable_id" do
    resources :assets, controller: :assets, as: :assetables do
      patch :create, on: :collection
    end
  end
  scope "*notable_type/:notable_id" do
    resources :notes, controller: :notes, as: :notables
  end
  resources :channel_partners, except: [:destroy] do
    get 'export', action: 'export', on: :collection, as: :export
    post :change_state, on: :member
  end

  get '/s/:code', to: 'shortened_urls#redirect_to_url'

  namespace :admin do
    resources :meetings, except: [:destroy]
    resources :api_logs, only: [:index]
    resources :cp_lead_activities do
      member do
        get 'extend_validity'
        patch 'update_extension'
        get 'accompanied_credit'
        patch 'update_accompanied_credit'
      end
    end

    resources :portal_stage_priorities, only: [:index] do
      patch :reorder, on: :collection
    end
    resources :checklists

    resources :bulk_upload_reports, except: [:edit, :update, :destroy] do
      get :show_errors, on: :member
    end

    resources :booking_details, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        patch :booking
        patch :send_under_negotiation
        get :generate_booking_detail_form
        get :send_booking_detail_form_notification
        get :tasks
        get :cost_sheet
        get :doc, path: 'doc/:type'
      end
      get :mis_report, on: :collection
      get :searching_for_towers, on: :collection
      get :status_chart, on: :collection
      resources :booking_detail_schemes, except: [:destroy], controller: 'booking_details/booking_detail_schemes'

      resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts' do
        get :lost_receipt, on: :collection
      end
      # resources :receipts, only: [:index]

      resources :invoices, only: [:index, :new, :create, :edit, :update], controller: 'booking_details/invoices' do
        member do
          patch :change_state
          get :raise_invoice
        end
      end
    end

    # for Billing Team
    resources :invoices, only: [:index, :show, :edit, :update], controller: 'booking_details/invoices' do
      get :generate_invoice, on: :member
      get :update_gst, on: :member
      get :export, on: :collection
      resources :incentive_deductions, except: :destroy, controller: 'invoices/incentive_deductions' do
        post :change_state, on: :member
      end
    end

    resources :accounts
    resources :phases
    resources :erp_models, only: %i[index new create edit update]
    resources :sync_logs, only: %i[index create] do
      patch :resync, on: :member
    end
    resources :emails, only: %i[index show] do
      get :monthly_count, on: :collection
    end
    resources :smses, only: %i[index show] do
      get :sms_pulse, on: :collection
    end
    resources :push_notifications, only: %i[index show new create]
    resource :client, except: [:show, :new, :create] do
      resources :templates, only: [:edit, :update, :index]
      get 'document_sign/prompt'
      get 'document_sign/callback'
    end
    namespace :audit do
      resources :records, only: [:index]
      resources :entries, only: [:show]
    end

    namespace :crm do
      resources :base do
        get :choose_crm, on: :collection
        scope ":type" do
          resources :api, except: :index do
            get :show_response
        end
        end
      end
    end

    resources :receipts, only: %i[index show] do
      collection do
        get :export
        get :payment_mode_chart
        get :frequency_chart
        get :status_chart
      end
      member do
        get 'resend_success'
        get 'edit_token_number'
        patch 'update_token_number'
      end
    end

    resources :developers, except: [:destroy]
    resources :projects, except: [:destroy] do
      get :collaterals, on: :member
      get :collaterals, on: :collection
    end
    resources :project_towers, only: [:index]
    resources :project_units, only: [:index, :show, :edit, :update] do
      member do
        get :print
        patch :release_unit
        get :quotation
        get :send_cost_sheet_and_payment_schedule
      end

      collection do
        get :unit_configuration_chart
        get :inventory_snapshot
        get :export
      end
    end

    scope ":request_type" do
      resources :accounts, controller: 'accounts'
    end

    resources :site_visits, only: [:index] do
      member do
        get 'sync_with_selldo'
      end
    end
    resources :leads, only: [:index, :show, :edit, :update, :new] do
      collection do
        get :export
      end
      member do
        get 'sync_notes'
        get :send_payment_link
      end
      resources :site_visits, only: [:new, :create, :index]
      resources :receipts, only: [:index, :new, :create, :edit, :update ] do
        get :resend_success, on: :member
        get :lost_receipt, on: :collection
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

      resources :user_kycs, except: [:show, :destroy], controller: 'user_kycs'

      resources :booking_details, only: [:index, :show] do
        patch :booking, on: :member
        patch :send_under_negotiation, on: :member
        resources :booking_detail_schemes, only: [:index], controller: 'booking_details/booking_detail_schemes'

        resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts'
        # resources :booking_detail_schemes, except: [:destroy]
        # resources :receipts, only: [:index]
      end

      scope ":request_type" do
        resources :user_requests, except: [:destroy], controller: 'user_requests'
      end

      resources :project_units, only: [:index] do
        get :print, on: :member
        get :quotation, on: :member
      end
    end # end resources :leads block

    resources :users do
      member do
        get :resend_confirmation_instructions
        get :update_password
        get :resend_password_instructions
        get :print
        patch :confirm_user
        get :block_lead
        patch :unblock_lead
        patch :reactivate_account
      end

      collection do
        get '/new/:role', action: 'new', as: :new_by_role
        get :export
        get :portal_stage_chart
        get :channel_partner_performance
      end

      match :confirm_via_otp, action: 'confirm_via_otp', as: :confirm_via_otp, on: :member, via: [:get, :patch]

      resources :leads, only: :index
      resources :interested_projects, only: [:index, :create, :edit, :update]
    end # end resources :users block

    resources :user_kycs, only: %i[index show], controller: 'user_kycs'
    scope ":request_type" do
      resources :user_requests, except: [:destroy], controller: 'user_requests' do
        get 'export', action: 'export', on: :collection, as: :export
      end
    end
    resources :schemes, except: [:destroy] do
      get :payment_adjustments_for_unit, on: :member
    end

    resources :incentive_schemes, except: [:destroy] do
      member do
        get :end_scheme
        patch :end_scheme
      end
    end
  end

  # home & globally accessible
  match 'payment/:receipt_id/process_payment/:ignore', to: 'payment#process_payment', via: [:get, :post]
  get :register, to: 'home#register', as: :register
  post :check_and_register, to: 'home#check_and_register', as: :check_and_register
  get :welcome, as: :welcome, to: 'home#welcome'
  get :terms_and_conditions, as: :terms_and_conditions, to: 'home#terms_and_conditions'
  get :privacy_policy, as: :privacy_policy, to: 'home#privacy_policy'
  get :"cp-enquiryform", as: :cp_enquiryform, to: 'home#cp_enquiryform'
  
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
    get :dashboard_counts, to: "dashboard#dashboard_counts"
    get :invoice_summary, to: "dashboard#invoice_summary"
    get :cp_performance, to: "dashboard#cp_performance"
    get :project_wise_invoice_summary, to: "dashboard#project_wise_invoice_summary"
    get :project_wise_incentive_deduction_summary, to: "dashboard#project_wise_incentive_deduction_summary"
    get :invoice_ageing_report, to: "dashboard#invoice_ageing_report"
    get :billing_team_dashboard, to: "dashboard#billing_team_dashboard"
    get :project_wise_summary, to: "dashboard#project_wise_summary"
    get :incentive_plans_started, to: "dashboard#incentive_plans_started"
    get :incentive_plans_summary, to: "dashboard#incentive_plans_summary"
    get :channel_partner_dashboard_counts, to: "dashboard#channel_partner_dashboard_counts"
    #get :download_brochure, to: 'dashboard#download_brochure'
    resource :lead do
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
    resources :meetings, only: [:index, :update, :show]
    resources :schemes, only: [:index]

    resources :booking_details, only: [:index, :show, :update] do
      member do
        get :generate_booking_detail_form
        patch :booking
        get :doc, path: 'doc/:type'
      end
      resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts'
      resources :booking_detail_schemes, except: [:destroy], controller: 'booking_details/booking_detail_schemes'
    end

    resources :emails, :smses, :push_notifications, only: %i[index show]
    resources :project_units, only: [:index, :show, :edit, :update] do
      get :quotation, on: :member
    end
    resources :users, only: [:show, :update, :edit] do
      member do
        get :iris_confirm
        get :update_password
      end
    end

    resources :receipts, only: [:index, :show] do
      get :resend_success, on: :member
    end

    resources :leads, only: [:show] do
      resources :booking_details, only: [:index, :show] do
        resources :booking_detail_schemes, except: [:destroy]

        resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts'
      end

      resources :receipts, only: [:new, :create]
      resources :user_kycs, except: [:show, :destroy], controller: 'user_kycs'

      scope ":request_type" do
        resources :user_requests, except: [:destroy], controller: 'user_requests'
      end
    end # end resources :leads

    resources :referrals, only: [:index, :create, :new] do
      post :generate_code, on: :collection
    end

  end

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create, :update]
      resources :leads, only: [:create, :update]
      resources :user_kycs, only: [:create, :update]
      resources :channel_partners, only: [:create, :update]
      resources :receipts, only: [:create, :update]
      resources :booking_details, only: [:create, :update]
      resources :user_requests, only: :create
    end
  end

  #broker routes for New HTML design
  get 'broker/home', to: 'broker#index'
  get 'broker/project-details', to: 'broker#project_details'
  get 'broker/project-details-new', to: 'broker#project_details_new'
  get 'broker/project', to: 'broker#project'
  get 'broker/project', to: 'broker#project'
  get 'broker/terms-and-conditions', to: 'broker#terms_and_conditions'
  get 'broker/privacy-policy', to: 'broker#privacy_policy'
  get 'broker/cp-enquiryform', to: 'broker#cp_enquiryform'
  get 'broker/cp-page', to: 'broker#cp_page'
  get 'broker/cp-campaign-1', to: 'broker#cp_campaign_1'
  get 'broker/cp-campaign-2', to: 'broker#cp_campaign_2'
  get 'broker/cp-campaign-3', to: 'broker#cp_campaign_3'
  get 'broker/cp-campaign-4', to: 'broker#cp_campaign_4'
  get 'broker/cp-campaign-5', to: 'broker#cp_campaign_5'
  get 'broker/cp-campaign-6', to: 'broker#cp_campaign_6'
  get 'broker/cp-campaign-7', to: 'broker#cp_campaign_7'
  get 'broker/cp-campaign-8', to: 'broker#cp_campaign_8'
  get 'broker/cp-campaign-9', to: 'broker#cp_campaign_9'
  get 'broker/cp-campaign-10', to: 'broker#cp_campaign_10'
  get 'broker/cp-campaign-11', to: 'broker#cp_campaign_11'
  get 'broker/cp-campaign-12', to: 'broker#cp_campaign_12'
  #Broker Campaign Manager
  get 'broker/cp-campaign-manager-1', to: 'broker#cp_campaign_manager_1'

  match '/sell_do/lead_created', to: "api/sell_do/leads#lead_created", via: [:get, :post]
  match '/sell_do/site_visit_updated', to: "api/sell_do/leads#site_visit_updated", via: [:get, :post]
  match '/sell_do/pushed_to_sales', to: "api/sell_do/leads#pushed_to_sales", via: [:get, :post]
  match '/zoho/download', to: "api/zoho/assets#download", via: [:get, :post]

end
