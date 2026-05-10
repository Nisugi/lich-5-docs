# frozen_string_literal: true

=begin
  Resolves update channel names to git references.

  Determines the appropriate git ref (tag or branch) for stable and beta
  channels by querying GitHub releases and branches. Handles semantic
  versioning comparison to find the latest eligible beta.
=end

module Lich
  module Util
    module Update
      # Resolves update channel names to git references.
      #
      # Determines the appropriate git ref (tag or branch) for stable and beta
      # channels by querying GitHub releases and branches. Handles semantic
      # versioning comparison to find the latest eligible beta.
      # @example Creating a channel resolver
      #   resolver = Lich::Util::Update::ChannelResolver.new(client)
      class ChannelResolver
        # Initializes a new ChannelResolver.
        # @param client [Object] The client used to fetch GitHub data.
        # @return [ChannelResolver]
        def initialize(client)
          @client = client
        end

        # Resolves the channel reference based on the provided channel name.
        #
        # This method determines the appropriate git reference for the given channel.
        # @param channel [Symbol, String] The channel name, can be :stable or :beta.
        # @return [String, nil] The resolved git reference or nil if not found.
        # @example Resolving a channel reference
        #   ref = resolver.resolve_channel_ref(:beta)
        def resolve_channel_ref(channel)
          case channel
          when :stable, 'production'
            STABLE_REF
          when :beta
            env = ENV['LICH_BETA_REF']
            return env unless env.nil? || env.empty?

            stable_tag = latest_stable_tag
            stable_major, stable_minor, stable_patch = major_minor_patch_from(stable_tag)
            return nil unless stable_major

            tag = latest_prerelease_tag_greater_than(stable_major, stable_minor, stable_patch)
            return tag if tag

            branch = latest_prefixed_branch_greater_than(BETA_BRANCH_PREFIX, stable_major, stable_minor, stable_patch)
            return branch if branch

            nil
          else
            STABLE_REF
          end
        end

        # Fetches the latest stable tag from GitHub releases.
        # @return [String, nil] The latest stable tag or nil if not found.
        # @example Fetching the latest stable tag
        #   tag = resolver.latest_stable_tag
        def latest_stable_tag
          releases = @client.fetch_github_json("https://api.github.com/repos/#{GITHUB_REPO}/releases")
          return nil unless releases.is_a?(Array)

          stable = releases.select { |r| !r['prerelease'] && r['tag_name'] }.max_by { |r| version_key(r['tag_name']) }
          stable && stable['tag_name']
        end

        # Finds the latest prerelease tag greater than the specified version.
        # @param stable_major [Integer] The major version of the stable release.
        # @param stable_minor [Integer] The minor version of the stable release.
        # @param stable_patch [Integer] The patch version of the stable release (default: 0).
        # @return [String, nil] The latest prerelease tag or nil if not found.
        # @example Finding a prerelease tag
        #   tag = resolver.latest_prerelease_tag_greater_than(1, 0)
        def latest_prerelease_tag_greater_than(stable_major, stable_minor, stable_patch = 0)
          releases = @client.fetch_github_json("https://api.github.com/repos/#{GITHUB_REPO}/releases")
          return nil unless releases.is_a?(Array)

          prereleases = releases.select { |r| r['prerelease'] && r['tag_name'] }
          return nil if prereleases.empty?

          candidates = prereleases.select do |r|
            maj, min, patch = major_minor_patch_from(r['tag_name'])
            next false unless maj && min

            (maj > stable_major) ||
              (maj == stable_major && min > stable_minor) ||
              (maj == stable_major && min == stable_minor && patch > stable_patch)
          end
          return nil if candidates.empty?

          tag = candidates.max_by { |r| version_key(r['tag_name']) }['tag_name']
          tag.sub(/^v/, '')
        end

        # Finds the latest branch with a specified prefix greater than the given version.
        # @param prefix [String] The prefix to filter branches.
        # @param stable_major [Integer] The major version of the stable release.
        # @param stable_minor [Integer] The minor version of the stable release.
        # @param stable_patch [Integer] The patch version of the stable release (default: 0).
        # @return [String, nil] The latest branch name or nil if not found.
        # @example Finding a prefixed branch
        #   branch = resolver.latest_prefixed_branch_greater_than("beta-", 1, 0)
        def latest_prefixed_branch_greater_than(prefix, stable_major, stable_minor, stable_patch = 0)
          branches = @client.fetch_github_json("https://api.github.com/repos/#{GITHUB_REPO}/branches?per_page=100")
          return nil unless branches.is_a?(Array)

          names = branches.map { |b| b['name'] }.compact
          candidates = names.select { |n| n.start_with?(prefix) }
          filtered = candidates.select do |n|
            maj, min, patch = major_minor_patch_from(n)
            maj && min && (
              (maj > stable_major) ||
              (maj == stable_major && min > stable_minor) ||
              (maj == stable_major && min == stable_minor && patch > stable_patch)
            )
          end
          return nil if filtered.empty?

          begin
            filtered.max_by { |n| version_key(n) }
          rescue => e
            respond "Update notice: ordering branches (latest_prefixed_branch_greater_than): #{e.message}"
            filtered.sort.last
          end
        end

        # Generates a version key from a tag or branch name for comparison.
        # @param tag_or_name [String] The tag or branch name to generate a version key from.
        # @return [Gem::Version] The generated version key.
        def version_key(tag_or_name)
          s = tag_or_name.to_s.sub(/^v/, '')
          if s =~ /(\d+\.\d+(?:\.\d+)?(?:-[0-9A-Za-z\.]+)?)/
            s = Regexp.last_match(1)
          end
          s = s.gsub('-beta.', '.beta.').gsub(/-beta(?!\.)/, '.beta')
          Gem::Version.new(s)
        end

        # Extracts the major, minor, and patch version numbers from a version string.
        # @param str [String] The version string to parse.
        # @return [Array<Integer, Integer, Integer>] An array containing major, minor, and patch version numbers.
        def major_minor_patch_from(str)
          return [nil, nil, nil] if str.nil?

          s = str.to_s.sub(/^v/, '')
          if s =~ /(\d+)\.(\d+)\.(\d+)/
            [$1.to_i, $2.to_i, $3.to_i]
          elsif s =~ /(\d+)\.(\d+)/
            [$1.to_i, $2.to_i, 0]
          else
            [nil, nil, nil]
          end
        end

        # Extracts the major and minor version numbers from a version string.
        # @param str [String] The version string to parse.
        # @return [Array<Integer, Integer>] An array containing major and minor version numbers.
        def major_minor_from(str)
          maj, min, _patch = major_minor_patch_from(str)
          [maj, min]
        end
      end
    end
  end
end
