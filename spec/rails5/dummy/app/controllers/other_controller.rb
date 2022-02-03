class OtherController < ApplicationController
  def error
    raise OtherGlobalError
  end
end
