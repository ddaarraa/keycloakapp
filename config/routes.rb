
# Rails.application.routes.draw do
#   root 'home#index'

#   # Authentication routes
#   get 'login', to: 'sessions#new'
#   post 'login', to: 'sessions#create'
#   delete 'logout', to: 'sessions#destroy', as: 'logout'

#   get 'kings', to: 'kings#new'

#   # Protected route example
#   get 'dashboard', to: 'dashboard#index'

#   # Add more routes as needed
# end

Rails.application.routes.draw do
  root "main#index"
  get 'login', to: 'sessions#login'
  get 'auth/callback', to: 'sessions#callback'
  get "logout", to: "sessions#destroy"

  get "about", to: "about#index"
  # Your other routes
end
