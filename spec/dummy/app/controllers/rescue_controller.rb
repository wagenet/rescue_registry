class RescueController < ApplicationController
  class CustomStatusError < StandardError; end
  class CustomTitleError < StandardError; end
  class MessageTrueError < StandardError; end
  class MessageProcError < StandardError; end
  class MetaProcError < StandardError; end
  class LogFalseError < StandardError; end
  class CustomHandlerError < StandardError; end
  class RailsError < StandardError; end
  class SubclassedError < CustomStatusError; end

  class CustomErrorHandler < RescueRegistry::ExceptionHandler
    def status_code(e)
      302
    end
  end

  register_exception CustomStatusError, status: 401
  register_exception CustomTitleError, title: "My Title"
  # register_exception MessageTrueError, message: true
  # register_exception MessageProcError, message: ->(e) { e.class.name.upcase }
  # register_exception MetaProcError, meta: ->(e) { {class_name: e.class.name.upcase} }
  # register_exception LogFalseError, log: false
  # register_exception CustomHandlerError, handler: CustomErrorHandler
  register_exception RailsError, status: 403, handler: RescueRegistry::RailsExceptionHandler

  def index
    raise "RescueController::#{params[:exception]}".constantize
  end
end
