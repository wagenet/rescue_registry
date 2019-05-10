class RescueController < ApplicationController
  class RailsError < StandardError; end
  class OtherError < StandardError; end

  register_exception StandardError, status: 401
  register_exception RailsError, status: 403, handler: RescueRegistry::RailsExceptionHandler

  def index
    raise StandardError
  end

  def rails
    raise RailsError
  end

  def other
    raise OtherError
  end
end
