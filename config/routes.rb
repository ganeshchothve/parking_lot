Rails.application.routes.draw do
  devise_for :users
  root to: "home#index"

  get :register, to: 'home#register', as: :register
  post :check_and_register, to: 'home#check_and_register', as: :check_and_register

  namespace :admin do
    resources :project_units
    resources :users
    resources :receipts
    resources :user_requests
  end

  get :dashboard, to: 'dashboard#index', as: :dashboard
  scope :dashboard do
    get :project_units, to: 'dashboard#project_units', as: :dashboard_project_units
    get 'project_units/:project_unit_id', to: 'dashboard#project_unit', as: :dashboard_project_unit
    get :receipts, to: 'dashboard#receipts', as: :dashboard_receipts
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
