Rails.application.routes.draw do
  get "/rescue" => "rescue#index"
  get "/rescue/rails" => "rescue#rails"
  get "/rescue/other" => "rescue#other"
end
