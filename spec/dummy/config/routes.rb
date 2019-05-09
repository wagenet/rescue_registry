Rails.application.routes.draw do
  get "/rescue" => "rescue#index"
  get "/rescue/rails" => "rescue#rails"
end
