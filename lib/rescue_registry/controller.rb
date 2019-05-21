module RescueRegistry
  module Controller
    extend ActiveSupport::Concern

    included do
      include Context
    end

    def process_action(*args)
      if RescueRegistry.context
        # Controller logger isn't yet available
        Rails.logger.warn "Didn't expect RescueRegistry context to be set in controller"
        Rails.logger.debug caller.join("\n")
      end

      # Setting something globally is not very nice, but it allows us to access it without
      # having to change a whole lot of internal Rails APIs. This especially matters when
      # getting the status code via ExceptionWrapper.
      # We don't unset here so that it is available to middleware
      # Unsetting happens in ActionDispatch::ShowExceptions. This _should_ be ok since we shouldn't
      # be processing multiple requests in the same thread.
      RescueRegistry.context = self

      super
    end
  end
end
