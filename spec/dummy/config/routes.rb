Rails.application.routes.draw do
  get "/rescue" => "rescue#index"
  get "/other" => "other#error"
end
