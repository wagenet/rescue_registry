class RescueController < ApplicationController
  class CustomStatusError < StandardError; end
  class CustomTitleError < StandardError; end
  class DetailExceptionError < StandardError; end
  class DetailProcError < StandardError; end
  class DetailStringError < StandardError; end
  class MetaProcError < StandardError; end
  class LogFalseError < StandardError; end
  class CustomHandlerError < StandardError; end
  class RailsError < StandardError; end
  class SubclassedError < CustomStatusError; end

  class CustomErrorHandler < RescueRegistry::ExceptionHandler
    def self.default_status
      302
    end

    def title
      "Custom Title"
    end
  end

  register_exception CustomStatusError, status: 401
  register_exception CustomTitleError, title: "My Title"
  register_exception DetailExceptionError, detail: :exception
  register_exception DetailProcError, detail: -> (e) { e.class.name.upcase }
  register_exception DetailStringError, detail: "Custom Detail"
  register_exception MetaProcError, meta: -> (e) { { class_name: e.class.name.upcase } }
  register_exception CustomHandlerError, handler: CustomErrorHandler
  register_exception RailsError, status: 403, handler: RescueRegistry::RailsExceptionHandler
  register_exception ActiveRecord::RecordNotFound, status: :passthrough

  def index
    exception_name = params[:exception]
    exception_name = "RescueController::#{exception_name}" unless exception_name.starts_with?("::")
    raise exception_name.constantize, "Exception in #index"
  end
end
