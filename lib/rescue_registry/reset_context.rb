module RescueRegistry
  class ResetContext
    def initialize(app)
      @app = app
    end

    def call(*args)
      warn "Didn't expect RescueRegistry context to already be set in middleware" if RescueRegistry.context
      @app.call(*args)
    ensure
      RescueRegistry.context = nil
    end
  end
end
