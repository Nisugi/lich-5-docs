module Lich
  module DragonRealms
    # Represents a Slack bot for interacting with the Slack API.
    # @example Creating a new Slack bot instance
    #   bot = Lich::DragonRealms::SlackBot.new
    class SlackBot
      class Error < StandardError; end
      class NetworkError < Error; end
      class ApiError < Error; end

      class ThrottlingError < ApiError
        attr_reader :retry_after

        def initialize(msg, retry_after = nil)
          super(msg)
          @retry_after = retry_after
        end
      end

      attr_reader :error_message

      # The timeout duration for lnet connection attempts (in seconds).
      LNET_CONNECTION_TIMEOUT = 30

      # Consider lnet connection stale if no activity for 2 minutes
      # The duration to consider lnet connection stale if no activity occurs (in seconds).
      LNET_ACTIVITY_TIMEOUT = 120

      # Base delay for exponential backoff on API retries.
      # Slack recommends waiting at least 30 seconds before retrying after rate limits.
      # See: https://api.slack.com/docs/rate-limits
      # The base delay for exponential backoff on API retries (in seconds).
      BASE_RETRY_DELAY_SECONDS = 30

      # Maximum delay before giving up on retries (2 minutes)
      # The maximum delay before giving up on retries (in seconds).
      MAX_RETRY_DELAY_SECONDS = 120

      # Initializes a new instance of SlackBot.
      # @return [SlackBot]
      # @raise [Error] if lnet connection fails or Slack token is not found.
      def initialize
        @api_url = 'https://slack.com/api/'
        @initialized = false
        @error_message = nil

        unless authed?(UserVars.slack_token)
          unless lnet_connected?
            unless Script.running?('lnet')
              unless Script.exists?('lnet')
                @error_message = "lnet.lic not found - cannot retrieve Slack token"
                return
              end
              start_script('lnet')
            end
            start_time = Time.now
            until lnet_connected?
              if (Time.now - start_time) > LNET_CONNECTION_TIMEOUT
                @error_message = "lnet did not connect within #{LNET_CONNECTION_TIMEOUT} seconds."
                return
              end
              pause 1
            end
          end

          @lnet = (Script.running + Script.hidden).find { |val| val.name == 'lnet' }
          unless find_token
            @error_message = "Unable to locate a Slack token"
            return
          end
        end

        begin
          @users_list = post('users.list', { 'token' => UserVars.slack_token })
        rescue ApiError => e
          Lich.log "error fetching user list: #{e.message}"
          @users_list = { 'members' => [] }
        end

        @initialized = true
      end

      # Checks if the Slack bot has been initialized.
      # @return [Boolean] true if initialized, false otherwise.
      def initialized?
        @initialized
      end

      def lnet_connected?
        return false unless defined?(LNet)
        return false unless LNet.server
        return false if LNet.server.closed?

        # Check last activity if method exists
        if LNet.respond_to?(:last_recv) && LNet.last_recv
          return false if (Time.now - LNet.last_recv) > LNET_ACTIVITY_TIMEOUT
        end

        true
      rescue IOError, Errno::EBADF, Errno::EPIPE, NoMethodError
        false
      end

      def authed?(token)
        return false unless token
        begin
          post('auth.test', { 'token' => token })['ok']
        rescue ApiError, NetworkError
          false
        end
      end

      # Requests a Slack token from the specified lichbot.
      # @param lichbot [String] The name of the lichbot to request the token from.
      # @return [String, false] The Slack token if found, false otherwise.
      def request_token(lichbot)
        ttl = 10
        send_time = Time.now
        @lnet.unique_buffer.push("chat to #{lichbot} RequestSlackToken")
        loop do
          line = get
          pause 0.05
          return false if Time.now - send_time > ttl

          case line
          when /\[Private\]-.*:#{lichbot}: "slack_token: (.*)"/
            msg = Regexp.last_match(1)
            return msg != 'Not Found' ? msg : false
          when /\[server\]: "no user .*/
            return false
          end
        end
      end

      # Attempts to find a valid Slack token from known lichbots.
      # @return [Boolean] true if a valid token is found, false otherwise.
      def find_token
        lichbots = %w[Quilsilgas]
        echo 'Looking for a token...'
        pause until @lnet

        lichbots.any? do |bot|
          token = request_token(bot)
          authed = authed?(token) if token
          UserVars.slack_token = token if token && authed
          authed
        end
      end

      # Sends a POST request to the Slack API.
      # @param method [String] The API method to call.
      # @param params [Hash] The parameters to send with the request.
      # @return [Hash] The response body from the Slack API.
      # @raise [ApiError] if the Slack API returns an error.
      # @raise [NetworkError] if a network error occurs.
      def post(method, params)
        retries = 0
        max_retries = 5

        begin
          uri = URI.parse("#{@api_url}#{method}")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          req = Net::HTTP::Post.new(uri.path)
          req.set_form_data(params)

          res = http.request(req)

          if res.code == '429'
            retry_after = res['Retry-After']&.to_i
            raise ThrottlingError.new("Throttled by Slack API", retry_after)
          end

          raise NetworkError, "HTTP Error: #{res.code} #{res.message}" unless res.is_a?(Net::HTTPSuccess)

          body = JSON.parse(res.body)
          raise ApiError, "Slack API Error: #{body['error']}" unless body['ok']

          return body
        rescue JSON::ParserError => e
          raise ApiError, "Failed to parse Slack API response: #{e.message}"
        rescue ThrottlingError => e
          raise ApiError, "Throttled by Slack API. Max retries (#{max_retries}) exceeded." if retries >= max_retries
          delay = e.retry_after || (BASE_RETRY_DELAY_SECONDS * (2**retries))
          if delay > MAX_RETRY_DELAY_SECONDS
            raise ApiError, "Throttled by Slack API. Retry delay (#{delay}s) exceeds maximum."
          end
          Lich.log "Throttled by Slack API. Retrying in #{delay} seconds..."
          sleep delay
          retries += 1
          retry
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, SocketError => e
          raise NetworkError, "Network error. Max retries (#{max_retries}) exceeded." if retries >= max_retries
          delay = BASE_RETRY_DELAY_SECONDS * (2**retries)
          if delay > MAX_RETRY_DELAY_SECONDS
            raise NetworkError, "Network error. Retry delay (#{delay}s) exceeds maximum."
          end
          Lich.log "Network error: #{e.message}. Retrying in #{delay} seconds..."
          sleep delay
          retries += 1
          retry
        end
      end

      # Sends a direct message to a specified user on Slack.
      # @param username [String] The username of the recipient.
      # @param message [String] The message to send.
      # @return [void]
      # @raise [Error] if the DM channel cannot be found.
      def direct_message(username, message)
        begin
          dm_channel = get_dm_channel(username)
          raise Error, "Could not find DM channel for #{username}" unless dm_channel

          params = { 'token' => UserVars.slack_token, 'channel' => dm_channel, 'text' => "#{checkname}: #{message}", 'as_user' => true }
          post('chat.postMessage', params)
        rescue Error => e
          Lich.log "Failed to send Slack message to #{username}: #{e.message}"
        end
      end

      # Retrieves the direct message channel ID for a specified user.
      # @param username [String] The username of the user.
      # @return [String, nil] The DM channel ID if found, nil otherwise.
      def get_dm_channel(username)
        user = @users_list['members'].find { |u| u['name'] == username }
        user ? user['id'] : nil
      end
    end
  end
end
