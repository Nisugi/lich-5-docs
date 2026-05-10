# Lich5 carveout to better manage semver

# The current version of the Lich5 project.
# This constant is used to manage the versioning of the project.
# @example Accessing the version
#   puts LICH_VERSION
LICH_VERSION = '5.17.1' # x-release-please-version
# The minimum required Ruby version for the Lich5 project.
# This constant ensures compatibility with the project's code.
# @example Checking Ruby version
#   if RUBY_VERSION < REQUIRED_RUBY
#     raise "Ruby version must be at least #{REQUIRED_RUBY}"
#   end
REQUIRED_RUBY = '2.6'
# The recommended Ruby version for optimal performance in the Lich5 project.
# This constant suggests the best version to use for development.
# @example Using recommended Ruby version
#   puts "For best results, use Ruby #{RECOMMENDED_RUBY}"
RECOMMENDED_RUBY = '3.2'
