
module Lich
  # Provides methods to interact with active sessions.
  # @example Using the API to get active sessions
  #   sessions = Lich::API.active_sessions
  module API
    # Returns a snapshot of the active session information.
    # @return [Hash] A hash containing session details including source, total, connected, detachable, and sessions.
    # @example Getting active session snapshot
    #   snapshot = Lich::API.active_session_snapshot
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
    # @return [Array] An array of active session objects.
    # @example Getting active sessions
    #   sessions = Lich::API.active_sessions
    def self.active_sessions
      active_session_snapshot[:sessions] || []
    end

    # Provides information about the active session service availability.
    # @return [Hash] A hash containing service information including source and service availability status.
    # @example Getting active session service info
    #   service_info = Lich::API.active_session_service_info
    def self.active_session_service_info
      return {
        source: 'ActiveSessionsAPI',
        service_available: false
      } unless defined?(Lich::InternalAPI::ActiveSessions)

      Lich::InternalAPI::ActiveSessions.service_info
    end
  end
end
