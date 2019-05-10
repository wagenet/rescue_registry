# frozen_string_literal: true

module RescueRegistry
  autoload :Controller,            "rescue_registry/controller"
  autoload :ExceptionsApp,         "rescue_registry/exceptions_app"
  autoload :ExceptionHandler,      "rescue_registry/exception_handler"
  autoload :RailsExceptionHandler, "rescue_registry/exception_handler"

  class HandlerNotFound < StandardError; end

  def self.context
    Thread.current[:rescue_registry_context]
  end

  def self.context=(value)
    Thread.current[:rescue_registry_context] = value
  end

  def self.with_context(value)
    original = context
    self.context = value
    yield
  ensure
    self.context = original
  end

  def self.handler_info_for_exception(exception)
    return unless context.respond_to?(:rescue_registry)

    exception_class =
      case exception
      when String
        exception.safe_constantize
      when Class
        exception
      else
        exception.class
      end

    return unless exception_class

    raise ArgumentError, "#{exception_class} is not an Exception" unless exception_class <= Exception

    # Reverse so most recently defined takes precedence
    registry = context.rescue_registry.to_a.reverse

    # Look for an exact class, then for the superclass and so on.
    # There might be a more efficient way to do this, but this is pretty readable
    match_class = exception_class
    loop do
      if (found = registry.find { |(klass, _)| klass == match_class })
        return found.last
      elsif match_class == Exception
        # We've exhausted our options
        return nil
      end

      match_class = match_class.superclass
    end
  end

  def self.handler_for_exception(exception)
    handler_info = handler_info_for_exception(exception)
    raise HandlerNotFound, "no handler found for #{exception.class}" unless handler_info

    status, handler_class, handler_options = handler_info
    handler = handler_class.new(exception, **handler_options)

    [status, handler]
  end

  def self.handles_exception?(exception)
    handler_info_for_exception(exception).present?
  end

  def self.status_code_for_exception(exception)
    handler_info_for_exception(exception)&.first
  end

  def self.response_for_debugging(content_type, wrapper)
    status, handler = handler_for_exception(wrapper.exception)
    body = handler.payload(show_details: true, traces: wrapper.traces)

    to_format = "to_#{content_type.to_sym}"

    if content_type && body.respond_to?(to_format)
      formatted_body = body.public_send(to_format)
      format = content_type
    else
      formatted_body = body.to_json
      format = Mime[:json]
    end

    [status, formatted_body, format]
  end

  def self.response_for_public(content_type, exception)
    status, handler = handler_for_exception(exception)
    body = handler.payload

    to_format = "to_#{content_type.to_sym}"

    if content_type && body.respond_to?(to_format)
      formatted_body = body.public_send(to_format)
      format = content_type
    else
      format = Mime[:html]
    end

    [status, formatted_body, format]
  end
end

ActiveSupport.on_load(:action_controller) do
  include RescueRegistry::Controller
end

require 'rescue_registry/action_dispatch'
require 'rescue_registry/railtie'
