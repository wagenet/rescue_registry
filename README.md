# RescueRegistry

RescueRegistry improves error handling with Rails while still hewing as close to the defaults as possible.



## Features

### Better than `rescue_from`
`rescue_from` works fine, but it it's a big hammer. Using it completely bypasses Rail's built-in exception handling middlewares,
which actually do some nice things for us (e.g. automatically handling different data formats). RescueRegistry allows the built-in
middleware to handle the exceptions but with our custom handlers.

### Better default exception handling
Rails also has some built-in support for assigning different exception classes to status types (See `config.action_dispatch.rescue_responses`).
Unfortunately, all this allows you to do is assign a status code. If you want more complex error handling, or to use different codes in
different controllers, you're out of luck. With RescueRegistry you can register an exception with a custom handler or with different status
codes in different controllers.

## In Action

### graphiti-rails
The [graphiti-rails gem](https://github.com/wagenet/graphiti-rails) uses RescueRegistry to facilitate better JSON:API error handling, since
Rails' out-of-the-box behavior doesn't adhere to the JSON:API spec.

## Usage

Example usages:

```ruby
class MyController < ActionController::Base
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
  register_exception CustomStatusError, status: 422, code: :name_invalid
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'rescue_registry'
```

## Contributing
We'd love to have your help improving rescue_registry, send a PR!

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
