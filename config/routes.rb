Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "mypage", to: "mypages#show", as: :mypage

  resources :tdee_profiles, only: [ :new, :create, :show ]
  resources :user_allergens, only: [ :new, :create ]
  resources :menus, only: [ :index, :create, :show ] do
    # 献立の再生成（既存の献立を削除して新しい献立を作り直す）
    post :regenerate, on: :member
    # 献立の保存（会員のみ。保存済みフラグを立てて履歴に残す）
    patch :save, on: :member
  end

  root "static_pages#top"
end
