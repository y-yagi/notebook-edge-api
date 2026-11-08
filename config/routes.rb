Edgeway.application.routes.draw do |r|
  r.resources :notebooks, only: [:index, :create, :destroy] do |n|
    n.resources :pages
  end
end
