# frozen_string_literal: true

require 'active_support'

module RescueRegistry
  autoload :ActionDispatch,       "rescue_registry/action_dispatch"
  autoload :Controller,            "rescue_registry/controller"
  autoload :ExceptionsApp,         "rescue_registry/exceptions_app"
  autoload :ExceptionHandler,      "rescue_registry/exception_handler"
  autoload :RailsExceptionHandler, "rescue_registry/exception_handler"
  autoload :Registry,              "rescue_registry/registry"

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

  REGISTRY_METHODS = %i[
    handler_for_exception
    handles_exception?
    status_code_for_exception
    response_for_debugging
    response_for_public
  ]

  REGISTRY_METHODS.each do |method|
    define_singleton_method(method) do |*args|
      return unless context.respond_to?(:rescue_registry)
      context.rescue_registry.public_send(method, *args)
    end
  end
end

ActiveSupport.on_load(:before_initialize) do
  ActionDispatch::ExceptionWrapper.singleton_class.prepend RescueRegistry::ActionDispatch::ExceptionWrapper
  ActionDispatch::DebugExceptions.prepend RescueRegistry::ActionDispatch::DebugExceptions
  ActionDispatch::ShowExceptions.prepend RescueRegistry::ActionDispatch::ShowExceptions
end

ActiveSupport.on_load(:action_controller) do
  include RescueRegistry::Controller
end

require 'rescue_registry/railtie'
