Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [ :new, :create ]
  resource :profile, only: [ :edit, :update ]

  # Catálogo e Lookbook Público
  root "products#index"
  resources :products, only: [ :index, :show ] do
    member do
      post :calculate_shipping
    end
    resource :favorite, only: [ :create, :destroy ]
    resources :questions, only: [ :create ]
    resources :offers, only: [ :create ]
  end
  resources :questions, only: [] do
    member do
      patch :answer
    end
  end
  resources :sellers, only: [ :show ]
  resources :favorites, only: [ :index ]

  # Carrinho de Compras
  resource :cart, only: [ :show, :destroy ]
  resources :cart_items, only: [ :create, :update, :destroy ]

  # Checkout & Pedidos
  resources :orders, only: [ :new, :create, :show ] do
    member do
      patch :confirm_delivery
      patch :simulate_payment
    end
    resources :reviews, only: [ :create ]
    collection do
      post :calculate_shipping
    end
  end

  # Painel de Administração (Dona da Loja)
  namespace :admin do
    root to: "products#index"
    resources :products
    resources :sales, only: [ :index, :show, :update ]
    resource :financial, only: [ :show ]
    resources :payouts, only: [ :create ]
    resources :offers, only: [ :index, :update ]
    resources :ad_credits, only: [ :new, :create ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
