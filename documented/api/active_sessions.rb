
module Lich
  module API
    # Returns a snapshot of the active sessions.
    #
    # @return [Hash] a hash containing session information including source, total, connected, detachable, and sessions.
    # @api private
    def self.active_session_snapshot
      return {
        source: 'ActiveSessionsAPI',
        total: 0,
        connected: 0,
        detachable: 0,
        sessions: []
      } unless defined?(Lich::InternalAPI::ActiveSessions)

      Lich::InternalAPI::ActiveSessions.snapshot
    end

    # Retrieves the list of active sessions.
    #
    # @return [Array<Hash>] an array of active session hashes.
    # @api private
    def self.active_sessions
      active_session_snapshot[:sessions] || []
    end

    # Provides information about the active session service availability.
    #
    # @return [Hash] a hash containing source and service availability status.
    # @api private
    def self.active_session_service_info
      return {
        source: 'ActiveSessionsAPI',
        service_available: false
      } unless defined?(Lich::InternalAPI::ActiveSessions)

      Lich::InternalAPI::ActiveSessions.service_info
    end
  end
end
