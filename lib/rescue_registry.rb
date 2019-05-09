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
    class_name = exception.is_a?(String) ? exception : exception.class.name
    # TODO: Maybe look for super-classes too?
    context.rescue_registry[class_name]
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

  def self.status_code_for_exception(class_name)
    handler_info_for_exception(class_name)&.first
  end

  def self.response_for_debugging(content_type, wrapper)
    status, handler = handler_for_exception(wrapper.exception)
    payload = handler.payload(show_details: true, traces: wrapper.traces)
    format, formatted_body = format_body(content_type, payload)
    [status, formatted_body, format]
  end

  def self.response_for_public(content_type, exception)
    status, handler = handler_for_exception(wrapper.exception)
    format, formatted_body = format_body(content_type, handler.payload)
    [status, formatted_body, format]
  end

  private

  def self.format_body(content_type, body)
    to_format = "to_#{content_type.to_sym}"

    if content_type && body.respond_to?(to_format)
      formatted_body = body.public_send(to_format)
      format = content_type
    else
      formatted_body = body.to_json
      format = Mime[:json]
    end

    [format, formatted_body]
  end
end

require 'rescue_registry/action_dispatch'
require 'rescue_registry/railtie'
