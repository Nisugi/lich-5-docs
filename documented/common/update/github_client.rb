# frozen_string_literal: true

=begin
  HTTP client for GitHub API with caching and token auth.

  Provides JSON and raw GET requests with optional Bearer token auth from
  DATA_DIR/githubtoken.txt. Includes in-memory cache with TTL for API responses.
=end

module Lich
  module Util
    module Update
      # HTTP client for GitHub API with caching and token auth.
      #
      # Provides JSON and raw GET requests with optional Bearer token auth from
      # DATA_DIR/githubtoken.txt. Includes in-memory cache with TTL for API responses.
      # @example Creating a GitHub client
      #   client = Lich::Util::Update::GitHubClient.new
      class GitHubClient
        attr_reader :http_cache

        # Initializes a new GitHubClient instance.
        #
        # @param cache_ttl [Integer] The time-to-live for cache entries in seconds.
        # @return [GitHubClient]
        def initialize(cache_ttl: 60)
          @http_cache = {}
          @cache_ttl = cache_ttl
          @github_token = nil
          @github_token_loaded = false
        end

        # Fetches JSON data from the specified GitHub URL with caching.
        #
        # @param url [String] The GitHub API URL to fetch data from.
        # @return [Hash, nil] The parsed JSON data or nil if an error occurs.
        # @raise [StandardError] If there is a network error during fetching.
        # @example Fetching JSON data
        #   data = client.fetch_github_json("https://api.github.com/repos/user/repo")
        def fetch_github_json(url)
          now = Time.now.to_i
          entry = @http_cache[url]
          if entry && (now - entry[:ts] < @cache_ttl)
            return entry[:data]
          end
          begin
            raw = http_get(url)
            return nil unless raw

            data = JSON.parse(raw)
            @http_cache[url] = { ts: now, data: data }
            data
          rescue => e
            respond "Update notice: network error fetching #{url.split('/repos/').last || url} (fetch_github_json): #{e.message}"
            nil
          end
        end

        # Performs a GET request to the specified URL.
        #
        # @param url [String] The URL to send the GET request to.
        # @param auth [Boolean] Whether to include authentication token in the request (default: true).
        # @return [String, nil] The response body or nil if an error occurs.
        # @raise [StandardError] If there is a network error during the request.
        # @example Sending a GET request
        #   response = client.http_get("https://api.github.com/user")
        def http_get(url, auth: true)
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER

          request = Net::HTTP::Get.new(uri.request_uri)
          if auth
            token = github_token
            request['Authorization'] = token if token
          end

          response = http.request(request)
          unless response.code == '200'
            respond "[lich5-update: HTTP #{response.code} fetching #{uri.path}]"
            return nil
          end
          response.body
        rescue => e
          respond "[lich5-update: Network error: #{e.message}]"
          nil
        end

        # Retrieves the GitHub authentication token from the specified file.
        #
        # @return [String, nil] The Bearer token or nil if not found or empty.
        # @note The token is loaded only once and cached for subsequent calls.
        # @example Retrieving the GitHub token
        #   token = client.github_token
        def github_token
          return @github_token if @github_token_loaded

          @github_token_loaded = true
          token_path = File.join(DATA_DIR, 'githubtoken.txt')
          return nil unless File.exist?(token_path)

          token = File.read(token_path).strip
          if token.empty?
            respond "[lich5-update: GitHub token file is empty. Using unauthenticated access.]"
            return nil
          end

          @github_token = "Bearer #{token}"
        end
      end
    end
  end
end
