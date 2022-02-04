# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2022-02-03
### Changed
- Removed upper version bound to support Ruby 3.1. (thanks @nulldotpro)

## [0.3.0] - 2021-05-11
### Changed
- For better JSONAPI spec compliance, errors payloads will not include the `details` key when value is `null`.
- Error payloads will not include the `meta` key when value is an empty object.

## [0.2.5] - 2021-03-09
### Added
- `code` can now be provided as an argument to `register_exception` - #29 (thanks @amaierhofer)

## [0.2.4] - 2021-01-22
### Fixed
- Support Ruby 3 (thanks @zvkemp and @ef4)

## [0.2.3] - 2020-09-01
### Fixed
- Properly handle exceptions for invalid format types - #25 (thanks @shanet)

### Changed
- Lower minimum Ruby requirement to 2.3 (thanks @elDub)

## [0.2.2] - 2019-06-13
### Changed
- Lower minimum Ruby requirement to 2.3 (thanks @elDub)

## [0.2.1] - 2019-05-22
### Added
- RescueRegistry::RailsTestingHelpers provides some helpers for easier testing in Rails applications.

## [0.2.0] - 2019-05-21
### Added
- Support for non-Rails applications.
### Changed
- Passthrough statuses are currently only support for Rails applications.
- Added a new Rails middleware for handling the current context.
### Fixed
- Registry is now properly inherited so that new registrations in subclasses do not affect the parent.
- Default exception handler now works property in the root context.

## [0.1.0] - 2019-05-15
### Added
- Everything, it's the first release!
