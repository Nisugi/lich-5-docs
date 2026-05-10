# frozen_string_literal: true

require_relative 'eaccess'

module Lich
  module Common
    module Authentication
      # Exception raised for fatal authentication errors.
      #
      # @see EAccess::AuthenticationError
      class FatalAuthError < StandardError; end

      # Retry configuration for transient SSL/network errors
      # These errors are often temporary and resolve on retry:
      # - SSL_read: unexpected eof while reading (server closed connection)
      # - Connection reset by peer
      # - Connection timed out
      MAX_AUTH_RETRIES = 3
      AUTH_RETRY_BASE_DELAY = 5 # seconds, doubles each retry: 5s, 10s, 20s

      # Known fatal error codes that should not be retried
      # REJECT = bad credentials, NORECORD = account not found, INVALID = invalid request
      # PASSWORD = wrong password, CHARACTER_NOT_FOUND = character not in account
      FATAL_ERROR_CODES = %w[REJECT NORECORD INVALID PASSWORD CHARACTER_NOT_FOUND].freeze

      # Authenticates a user with the provided credentials.
      #
      # @param account [String] the account name
      # @param password [String] the account password
      # @param character [String, nil] optional character name for authentication
      # @param game_code [String, nil] optional game code for authentication
      # @param legacy [Boolean] whether to use legacy authentication method
      # @return [Boolean] true if authentication is successful
      # @raise FatalAuthError if a fatal authentication error occurs
      def self.authenticate(account:, password:, character: nil, game_code: nil, legacy: false)
        with_retry do
          if character && game_code
            EAccess.auth(
              account: account,
              password: password,
              character: character,
              game_code: game_code
            )
          elsif legacy
            EAccess.auth(
              account: account,
              password: password,
              legacy: true
            )
          else
            EAccess.auth(
              account: account,
              password: password
            )
          end
        end
      end

      # Retries the given block of code for transient authentication errors.
      #
      # @yield block of code to execute
      # @return [Object] the result of the block if successful
      # @raise FatalAuthError if a fatal authentication error occurs
      # @raise StandardError if all retries are exhausted
      def self.with_retry
        last_error = nil

        MAX_AUTH_RETRIES.times do |attempt|
          begin
            result = yield

            # Success - log if this was a retry
            if attempt.positive?
              Lich.log "info: Authentication succeeded on attempt #{attempt + 1}"
            end

            return result
          rescue EAccess::AuthenticationError => e
            # Check if this is a fatal auth failure
            if FATAL_ERROR_CODES.any? { |code| e.error_code&.include?(code) }
              Lich.log "error: Authentication fatally failed: #{e.message}"
              raise FatalAuthError, e.message
            end

            # Transient auth error - allow retry
            last_error = e

            if attempt < MAX_AUTH_RETRIES - 1
              delay = AUTH_RETRY_BASE_DELAY * (2**attempt)
              Lich.log "warn: Authentication attempt #{attempt + 1}/#{MAX_AUTH_RETRIES} failed: " \
                       "#{e.message}, retrying in #{delay}s..."
              sleep(delay)
            end
          rescue FatalAuthError
            # Don't retry fatal auth failures - re-raise immediately
            raise
          rescue StandardError => e
            last_error = e

            if attempt < MAX_AUTH_RETRIES - 1
              delay = AUTH_RETRY_BASE_DELAY * (2**attempt)
              Lich.log "warn: Authentication attempt #{attempt + 1}/#{MAX_AUTH_RETRIES} failed: " \
                       "#{e.message}, retrying in #{delay}s..."
              sleep(delay)
            end
          end
        end

        # All retries exhausted - re-raise the last error
        Lich.log "error: Authentication failed after #{MAX_AUTH_RETRIES} attempts: #{last_error&.message}"
        raise last_error
      end
    end
  end
end
