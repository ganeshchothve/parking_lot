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
  }, skip: [ :registrations ], skip_helpers: [ :registrations ]

  namespace :mp do
    get 'about', to: 'dashboard#about'
    resources :users do
      collection do
        get :signup
        post :register
      end
    end
  end

  devise_scope :user do
    post 'users/otp', :to => 'local_devise/sessions#otp', :as => :users_otp
    post 'users/notification_tokens', to: 'users/notification_tokens#update', as: :user_notification_tokens
  end

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end


  root to: redirect('users/sign_in')

  as :user do
    put '/user/confirmation', to: 'local_devise/confirmations#update', :as => :update_user_confirmation
  end

  scope "*assetable_type/:assetable_id" do
    resources :assets, controller: :assets, as: :assetables do
      patch :create, on: :collection
    end
  end
  scope "*public_assetable_type/:public_assetable_id" do
    resources :public_assets, controller: :public_assets, as: :public_assetables do
      patch :create, on: :collection
    end
  end

  scope "*notable_type/:notable_id" do
    resources :notes, controller: :notes, as: :notables
  end
  scope "*videoable_type/:videoable_id" do
    resources :videos, controller: :videos, as: :videoables
  end
  resources :channel_partners, except: [:destroy] do
    get 'export', action: 'export', on: :collection, as: :export
    post :change_state, on: :member
    get 'asset_form', on: :member
    post 'register', on: :collection, to: "channel_partners#find_or_create_cp_user"
    get 'add_user_account', on: :collection
    # TODO: Change this routes
    get :new_channel_partner, on: :collection
    post :create_channel_partner, on: :collection

    get :new_company, on: :collection
    post :create_company, on: :collection
  end

  # New v2 routes required for mobile apps, when old routes are needed to deprecate
  post '/v2/channel_partners/register', to: "channel_partners#register_cp_user", format: :json

  get '/s/:code', to: 'shortened_urls#redirect_to_url'

  namespace :admin do
    resources :discounts do
      get 'update_coupons', on: :collection
    end
    resources :customer_searches, except: :destroy
    resources :campaigns, except: [:destroy]
    resources :meetings, except: [:destroy]
    resources :announcements
    resources :api_logs, only: [:index]
    resources :cp_lead_activities do
      member do
        get 'extend_validity'
        patch 'update_extension'
        get 'accompanied_credit'
        patch 'update_accompanied_credit'
      end
    end

    scope "*subject_class/:subject_class_id" do
      resources :templates, only: [], controller: :templates, as: :custom_templates do
        get :choose_template_for_print, on: :collection
      end
    end

    resources :portal_stage_priorities, only: [:index] do
      patch :reorder, on: :collection
    end
    resources :checklists

    resources :bulk_upload_reports, except: [:edit, :update, :destroy] do
      member do
        get :show_errors
        get :upload_error_exports
      end
    end

    resources :banner_assets
    resources :workflows do
      get 'pipeline_stages', to: 'workflows#pipeline_stages', on: :collection
      member do
        patch :enable_disable_workflow
      end
    end

    resources :payment_types

    resources :booking_details, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        patch :booking
        patch :send_under_negotiation
        patch :send_blocked
        get :generate_booking_detail_form
        get :send_booking_detail_form_notification
        get :tasks
        get :cost_sheet
        get :doc, path: 'doc/:type'
        patch :move_to_next_state
        patch :move_to_next_approval_state
        get :reject
      end
      get :mis_report, on: :collection
      get :searching_for_towers, on: :collection
      get :status_chart, on: :collection
      get :new_booking_without_inventory, on: :collection
      get :edit_booking_without_inventory, on: :member
      post :create_booking_without_inventory, on: :collection
      patch :update_booking_without_inventory, on: :member
      get :new_booking_on_project, on: :collection
      post :process_booking_on_project, on: :collection
      resources :booking_detail_schemes, except: [:destroy], controller: 'booking_details/booking_detail_schemes'

      resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts' do
        get :lost_receipt, on: :collection
      end
      # resources :receipts, only: [:index]
    end

    scope "*invoiceable_type/:invoiceable_id" do
      resources :invoices, only: [:index, :new, :create, :edit, :update], controller: 'invoices', as: :invoiceable do
        member do
          patch :change_state
          get :raise_invoice
        end
      end
    end

    # for Billing Team
    resources :invoices, only: [:index, :show, :edit, :update], controller: 'invoices' do
      get :generate_invoice, on: :member
      get :update_gst, on: :member
      get :export, on: :collection
      get :new_send_invoice_to_poc, on: :member
      post :send_invoice_to_poc, on: :collection
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
      post :resend_email, on: :member
    end
    resources :smses, only: %i[index show] do
      get :sms_pulse, on: :collection
    end
    resources :push_notifications, only: %i[index show new create]
    resource :client, except: [:new, :create] do
      resources :templates, only: [:edit, :update, :index, :new, :create] do
        get :print_template, on: :collection
      end
      get 'document_sign/prompt'
      get 'document_sign/callback'
      get 'get_regions'
      get :kylas_api_key, on: :member
      put :kylas_api_key, on: :member
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
      post :sync_on_selldo, on: :member
      get :third_party_inventory, on: :collection
      get :sync_kylas_products, on: :collection

      resources :unit_configurations, only: [:index, :edit, :update], controller: 'projects/unit_configurations'
      resources :token_types, except: [:destroy, :show], controller: 'projects/token_types' do
        member do
          get :token_init
          get :token_de_init
        end
      end
      resources :time_slots, controller: 'projects/time_slots'
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

    resources :site_visits, only: [:index, :edit, :update, :show] do
      member do
        get 'sync_with_selldo'
        patch :change_state
        get :reject
      end
      get :export, on: :collection
    end
    resources :leads, only: [:index, :show, :edit, :update, :new] do
      collection do
        get :export
        get :search_by
        post :search_inventory
        get :new_kylas_associated_lead
        post :create_kylas_associated_lead
        get :new_kylas_lead
        post :create_kylas_lead
        post :bulk_job_new
        post :bulk_job_create
      end
      member do
        get 'sync_notes'
        get :send_payment_link
        get :reassign_lead
        patch :assign_sales
        patch :reassign_sales
        patch :accept_lead
        patch :move_to_next_state
      end
      resources :site_visits, only: [:new, :create, :index, :update]
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
        patch :send_blocked, on: :member
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
        get :reset_password_after_first_login
        get :resend_password_instructions
        get :print
        patch :confirm_user
        get :block_lead
        patch :unblock_lead
        patch :reactivate_account
        patch :move_to_next_state
        patch :change_state
        get :approve_reject_company_user
        patch :update_player_ids
      end

      collection do
        get '/new/:role', action: 'new', as: :new_by_role
        get :export
        get :portal_stage_chart
        get :channel_partner_performance
        get :partner_wise_performance
        get :search_by
        get :site_visit_project_wise
        get :site_visit_partner_wise
        get :sync_kylas_users
      end

      match :confirm_via_otp, action: 'confirm_via_otp', as: :confirm_via_otp, on: :member, via: [:get, :patch]

      resources :leads, only: :index
      resources :interested_projects, only: [:index, :create, :edit, :update]
    end # end resources :users block

    resources :interested_projects, only: [:subscribe_projects] do
      collection do
          post :subscribe_projects
        end
    end

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

    resources :variable_incentive_schemes, except: [:destroy] do
      member do
        get :end_scheme
        patch :end_scheme
        get :vis_details
      end
      collection do
        get :vis_details
        get :export
      end
    end

    resources :referrals, only: [:index, :create, :new] do
      post :generate_code, on: :collection
    end

    resources :bulk_jobs, only: [:index] do
    end
  end

  # home & globally accessible
  match 'payment/:receipt_id/process_payment/:ignore', to: 'payment#process_payment', via: [:get, :post]
  get :register, to: 'home#register', as: :register
  post :check_and_register, to: 'home#check_and_register', as: :check_and_register
  get :terms_and_conditions, as: :terms_and_conditions, to: 'home#terms_and_conditions'
  get :privacy_policy, as: :privacy_policy, to: 'home#privacy_policy'
  get :not_authorized, to: 'home#not_authorized', as: :not_authorized

  get 'admin/select_clients', to: 'home#select_client', as: :admin_select_clients
  post 'select_client', to: 'home#select_client', as: :select_client

  get 'signed_up/:user_id', to: 'home#signed_up', as: :signed_up
  get 'cp_signed_up_with_inactive_account/:user_id', to: 'home#cp_signed_up_with_inactive_account', as: :cp_signed_up_with_inactive_account

  scope :custom do
    match 'inventory/:id', to: 'custom#inventory', as: :custom_inventory, via: [:get]
  end

  scope :dashboard do
    # read only pages
    get '', to: 'dashboard#index', as: :dashboard
    get 'faqs', to: 'dashboard#faqs', as: :dashboard_faqs
    get 'gallery', to: 'dashboard#gallery', as: :dashboard_gallery
    get 'documents', to: 'dashboard#documents', as: :dashboard_documents
    get 'rera', to: 'dashboard#rera', as: :dashboard_rera
    get 'tds-process', to: 'dashboard#tds_process', as: :dashboard_tds_process
    get "gamify-unit-selection", to: "dashboard#gamify_unit_selection"
    get :dashboard_counts, to: "dashboard#dashboard_counts"
    get :invoice_summary, to: "dashboard#invoice_summary"
    get :cp_performance, to: "dashboard#cp_performance"
    get :cp_status, to: "dashboard#cp_status"
    get :project_wise_invoice_summary, to: "dashboard#project_wise_invoice_summary"
    get :project_wise_incentive_deduction_summary, to: "dashboard#project_wise_incentive_deduction_summary"
    get :city_wise_booking_report, to: "dashboard#city_wise_booking_report"
    get :invoice_ageing_report, to: "dashboard#invoice_ageing_report"
    get :billing_team_dashboard, to: "dashboard#billing_team_dashboard"
    get :project_wise_summary, to: "dashboard#project_wise_summary"
    get :project_wise_leads, to: "dashboard#project_wise_leads"
    get :cp_variable_incentive_scheme_report, to: "dashboard#cp_variable_incentive_scheme_report"
    get :variable_incentive_scheme_report, to: "dashboard#variable_incentive_scheme_report"
    get "channel_partners_leaderboard/:id", to: "dashboard#channel_partners_leaderboard", as: :channel_partners_leaderboard
    get "channel_partners_leaderboard_without_layout/:id", to: "dashboard#channel_partners_leaderboard_without_layout", as: :channel_partners_leaderboard_without_layout
    get :top_channel_partners_by_incentives, to: "dashboard#top_channel_partners_by_incentives"
    get :average_incentive_per_booking, to: "dashboard#average_incentive_per_booking"
    get :highest_incentive_per_booking, to: "dashboard#highest_incentive_per_booking"
    get :incentive_predictions, to: "dashboard#incentive_predictions"
    get :achieved_target, to: "dashboard#achieved_target"
    get :incentive_plans_started, to: "dashboard#incentive_plans_started"
    get :incentive_plans_summary, to: "dashboard#incentive_plans_summary"
    get :channel_partner_dashboard_counts, to: "dashboard#channel_partner_dashboard_counts"
    get :project_wise_tentative_revenue, to: "dashboard#project_wise_tentative_revenue"
    get :project_wise_actual_revenue, to: "dashboard#project_wise_actual_revenue"
    #get :download_brochure, to: 'dashboard#download_brochure'
    get :sales_board, to: 'dashboard#sales_board'
    get :project_wise_booking_details_counts, to: 'dashboard#project_wise_booking_details_counts'
    get :project_wise_conversion_report, to: 'dashboard#project_wise_conversion_report'
    get :receipts_details_report, to: 'dashboard#receipts_details_report'
    get :team_lead_dashboard, to: 'dashboard#team_lead_dashboard'
    # get :dashboard_landing_page, to: 'dashboard#dashboard_landing_page'
    get :payout_dashboard, to: 'dashboard#payout_dashboard'
    get :payout_list, to: 'dashboard#payout_list'
    get :payout_show, to: 'dashboard#payout_show'

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

    scope "*subject_class/:subject_class_id" do
      resources :templates, only: [], controller: :templates, as: :custom_templates do
        get :choose_template_for_print, on: :collection
      end
    end

    resource :client, only: [] do
      resources :templates, only: [] do
        get :print_template, on: :collection
      end
    end

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
      collection do
        get 'select_projects'
        post 'select_project'
      end
    end

    resources :receipts, only: [:index, :show, :new, :create] do
      get :resend_success, on: :member
    end

    scope ":request_type" do
      resources :user_requests, except: [:destroy], controller: 'user_requests'
    end

    resources :user_kycs, except: [:show, :destroy], controller: 'user_kycs'

    resources :referrals, only: [:index, :create, :new] do
      post :generate_code, on: :collection
    end

    resources :leads, only: [:index, :show, :edit, :update, :new] do
      collection do
        get :export
        get :search_by
        post :search_inventory
      end

      resources :user_kycs, except: [:show, :destroy], controller: 'user_kycs'

      resources :booking_details, only: [:index, :show] do
        patch :booking, on: :member
        patch :send_under_negotiation, on: :member
        patch :send_blocked, on: :member
        resources :booking_detail_schemes, only: [:index], controller: 'booking_details/booking_detail_schemes'

        resources :receipts, only: [:index, :new, :create], controller: 'booking_details/receipts'
        # resources :booking_detail_schemes, except: [:destroy]
        # resources :receipts, only: [:index]
      end
    end
  end

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create, :update] do
        post :create_or_update_user, on: :collection
      end
      resources :leads, only: [:create, :update]
      resources :user_kycs, only: [:create, :update]
      resources :channel_partners, only: [:create, :update]
      resources :receipts, only: [:create, :update]
      resources :booking_details, only: [:create, :update]
      resources :user_requests, only: :create
    end
  end

  # Kylas Authentication Logic
  get 'kylas-auth', to: 'kylas_auth#authenticate'

  match '/sell_do/:project_id/lead_created', to: "api/sell_do/leads#lead_created", via: [:get, :post]
  match '/sell_do/:project_id/lead_updated', to: "api/sell_do/leads#lead_updated", via: [:get, :post]
  match '/sell_do/:project_id/site_visit_created', to: "api/sell_do/leads#site_visit_created", via: [:get, :post]
  match '/sell_do/:project_id/site_visit_updated', to: "api/sell_do/leads#site_visit_updated", via: [:get, :post]
  match '/sell_do/pushed_to_sales', to: "api/sell_do/leads#pushed_to_sales", via: [:get, :post]
  match '/zoho/download', to: "api/zoho/assets#download", via: [:get, :post]
  match '/user/signup', to: "admin/users#signup", via: [:get]
  match '/user/register', to: "admin/users#register", via: [:post]
end
