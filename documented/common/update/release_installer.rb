# frozen_string_literal: true

=begin
  Installs Lich5 from GitHub releases (stable and beta).

  Handles release announcements, tarball downloads, Ruby compatibility
  checks, and file extraction. Delegates to FileUpdater for data/script
  updates and SnapshotManager for backups.
=end

module Lich
  module Util
    module Update
      # Handles the installation of Lich5 from GitHub releases.
      #
      # This class manages release announcements, tarball downloads,
      # Ruby compatibility checks, and file extraction. It delegates
      # to FileUpdater for data/script updates and SnapshotManager
      # for backups.
      #
      # @see Lich::Util::Update::FileUpdater
      # @see Lich::Util::Update::SnapshotManager
      class ReleaseInstaller
        # Top-level files (besides lib/ and lich.rbw) to copy from release archive.
        # lich.rbw is handled separately due to its dynamic target name.
        TOP_LEVEL_FILES = %w[Gemfile LICENSE].freeze

        # Initializes a new ReleaseInstaller instance.
        # @param client [Object] the client used to interact with GitHub
        # @param resolver [Object] the resolver for versioning
        # @param snapshot_manager [SnapshotManager] the manager for snapshots
        # @return [void]
        def initialize(client, resolver, snapshot_manager)
          @client = client
          @resolver = resolver
          @snapshot_manager = snapshot_manager
          @current = LICH_VERSION
          @update_to = nil
          @holder = nil
          @new_features = nil
          @zipfile = nil
        end

        # Announces the availability of a new version of Lich.
        # This method checks the current version against the latest
        # available version and responds accordingly.
        # @return [void]
        def announce
          prep_update
          if "#{LICH_VERSION}".chr == '5'
            if Gem::Version.new(@current) < Gem::Version.new(@update_to)
              unless @new_features.empty?
                respond ''
                _respond monsterbold_start() + "*** NEW VERSION AVAILABLE ***" + monsterbold_end()
                respond ''
                respond ''
                respond ''
                respond @new_features
                respond ''
                respond ''
                respond "If you are interested in updating, run '#{$clean_lich_char}lich5-update --update' now."
                respond ''
              end
            else
              respond ''
              respond "Lich version #{LICH_VERSION} is good.  Enjoy!"
              respond ''
            end
          else
            respond "This script does not support Lich #{LICH_VERSION}."
          end
        end

        # Prepares for an update by fetching the latest release information.
        # @return [void]
        def prep_update
          latest = @client.fetch_github_json("https://api.github.com/repos/#{GITHUB_REPO}/releases/latest")
          if latest.is_a?(Hash) && latest['prerelease']
            all = @client.fetch_github_json("https://api.github.com/repos/#{GITHUB_REPO}/releases")
            if all.is_a?(Array)
              stable = all.select { |r| !r['prerelease'] && r['tag_name'] }.max_by { |r| @resolver.version_key(r['tag_name']) }
              latest = stable if stable
            end
          end
          unless latest.is_a?(Hash)
            respond "Update notice: could not read latest release payload (prep_update)."
            return
          end

          @holder = latest['assets']
          release_asset = @holder && @holder.find { |x| x['name'] =~ /\b#{ASSET_TARBALL_NAME}\b/ }
          unless release_asset
            respond "Update notice: no release tarball found in assets (prep_update)."
            return
          end
          @update_to = latest['tag_name'].to_s.sub('v', '')
          @new_features = latest['body'].to_s.gsub(/\#\# What's Changed.+$/m, '').gsub(/<!--[\s\S]*?-->/, '')
          @zipfile = release_asset.fetch('browser_download_url')
        end

        # Prepares for beta testing of the next Lich release.
        # @param type [String, nil] the type of beta test (optional)
        # @param requested_file [String, nil] the requested file for the beta test (optional)
        # @return [void]
        def prep_betatest(type = nil, requested_file = nil)
          if type.nil?
            respond 'You are electing to participate in the beta testing of the next Lich release.'
            respond 'This beta test will include only Lich code, and does not include Ruby upates.'
            respond 'While we will do everything we can to ensure you have a smooth experience, '
            respond 'it is a test, and untoward things can result.  Please confirm your choice:'
            respond "Please confirm your participation:  #{$clean_lich_char}send Y or #{$clean_lich_char}send N"
            respond "You have 10 seconds to confirm, otherwise will be cancelled."

            client_sock = $_CLIENT_ || $_DETACHABLE_CLIENT_
            unless client_sock
              respond 'No client connection available. Aborting beta test request.'
              return
            end
            deadline = Time.now + 10
            line = nil
            loop do
              remaining = deadline - Time.now
              break if remaining <= 0

              reader = Thread.new { client_sock.gets }
              if reader.join(remaining)
                line = reader.value
                break if line.is_a?(String) && line.strip =~ /^(?:<c>)?(?:#{$clean_lich_char}send|#{$clean_lich_char}s) /i
              else
                reader.kill
                break
              end
            end

            if line.is_a?(String) && line =~ /send Y|s Y/i
              beta_response = 'accepted'
              respond 'Beta test installation accepted.  Thank you for considering!'
            else
              beta_response = 'rejected'
              respond 'Aborting beta test installation request.  Thank you for considering!'
              respond
            end

            if beta_response =~ /accepted/
              ref = @resolver.resolve_channel_ref(:beta)
              if ref.nil?
                respond 'No viable beta found. Aborting beta update.'
                return
              end

              releases_url = "https://api.github.com/repos/#{GITHUB_REPO}/releases"
              update_info = URI.parse(releases_url).open.read
              releases = JSON.parse(update_info)
              record = releases.find { |r| r['prerelease'] && r['tag_name'] == (ref.start_with?('v') ? ref : "v#{ref}") }

              if record
                record.each do |entry, value|
                  if entry.include? 'tag_name'
                    @update_to = value.sub('v', '')
                  elsif entry.include? 'assets'
                    @holder = value
                  elsif entry.include? 'body'
                    @new_features = value.gsub(/\#\# What's Changed.+$/m, '').gsub(/<!--[\s\S]*?-->/, '')
                  end
                end
                release_asset = @holder && @holder.find { |x| x['name'] =~ /\b#{ASSET_TARBALL_NAME}\b/ }
                if release_asset
                  @zipfile = release_asset.fetch('browser_download_url')
                else
                  @zipfile = "https://codeload.github.com/#{GITHUB_REPO}/tar.gz/#{ref}"
                end
              else
                @update_to = ref.sub(/^v/, '')
                @zipfile = "https://codeload.github.com/#{GITHUB_REPO}/tar.gz/#{ref}"
              end
              download_release_update
            elsif beta_response =~ /rejected/
              nil
            else
              respond 'This is not where I want to be on a beta test request.'
              respond
            end
          else
            file_updater = FileUpdater.new(@client, @resolver)
            file_updater.update_file(type, requested_file, 'beta')
          end
        end

        # Downloads the release update for Lich5.
        # This method handles the downloading and extraction of the
        # update tarball, as well as compatibility checks.
        # @return [void]
        def download_release_update
          prep_update if @update_to.nil? || @update_to.empty?
          if Gem::Version.new("#{@update_to}") <= Gem::Version.new("#{@current}") && !defined?(LICH_BRANCH)
            respond ''
            respond "Lich version #{LICH_VERSION} is good.  Enjoy!"
            respond ''
          else
            respond
            respond 'Getting ready to update.  First we will create a'
            respond 'snapshot in case there are problems with the update.'

            @snapshot_manager.snapshot

            respond
            respond "Downloading Lich5 version #{@update_to}"
            respond
            filename = "lich5-#{@update_to}"
            File.open(File.join(TEMP_DIR, "#{filename}.tar.gz"), "wb") do |file|
              file.write URI.parse(@zipfile).open.read
            end

            FileUtils.mkdir_p(File.join(TEMP_DIR, filename))
            Gem::Package.new("").extract_tar_gz(File.open(File.join(TEMP_DIR, "#{filename}.tar.gz"), "rb"),
                                                File.join(TEMP_DIR, filename))
            new_target = Dir.children(File.join(TEMP_DIR, filename))
            FileUtils.cp_r(File.join(TEMP_DIR, filename, new_target[0]), TEMP_DIR)
            FileUtils.remove_dir(File.join(TEMP_DIR, filename))
            FileUtils.mv(File.join(TEMP_DIR, new_target[0]), File.join(TEMP_DIR, filename))

            source_dir = File.join(TEMP_DIR, filename)

            unless check_ruby_compatibility(source_dir, @update_to)
              FileUtils.remove_dir(source_dir) if File.directory?(source_dir)
              FileUtils.rm(File.join(TEMP_DIR, "#{filename}.tar.gz")) if File.exist?(File.join(TEMP_DIR, "#{filename}.tar.gz"))
              return
            end

            unless perform_update(source_dir, @update_to)
              FileUtils.remove_dir(source_dir) if File.directory?(source_dir)
              FileUtils.rm(File.join(TEMP_DIR, "#{filename}.tar.gz")) if File.exist?(File.join(TEMP_DIR, "#{filename}.tar.gz"))
              return
            end

            FileUtils.remove_dir(source_dir)
            FileUtils.rm(File.join(TEMP_DIR, "#{filename}.tar.gz"))

            Lich::Util::Update.clear_branch_tracking

            respond
            respond "Lich5 has been updated to Lich5 version #{@update_to}"
            respond "You should exit the game, then log back in.  This will start the game"
            respond "with your updated Lich.  Enjoy!"
          end
        end

        # Performs the update of Lich from the specified source directory.
        # @param source_dir [String] the directory containing the new version
        # @param version [String] the version to update to
        # @return [Boolean] true if the update was successful, false otherwise
        def perform_update(source_dir, version)
          unless validate_lich_structure(source_dir)
            respond "Error: extracted source is missing required files. Aborting update to protect installation."
            return false
          end

          FileUtils.rm_rf(Dir.glob(File.join(LIB_DIR, "*")))

          respond
          respond 'Copying updated lich files to their locations.'

          FileUtils.copy_entry(File.join(source_dir, "lib"), File.join(LIB_DIR))
          respond
          respond "All Lich lib files have been updated."
          respond

          # Copy top-level release files to LICH_DIR
          TOP_LEVEL_FILES.each do |filename|
            src = File.join(source_dir, filename)
            if File.exist?(src)
              FileUtils.cp(src, File.join(LICH_DIR, filename))
              respond "Updated #{filename}."
            end
          end

          file_updater = FileUpdater.new(@client, @resolver)
          file_updater.update_core_data_and_scripts(version)

          lich_to_update = File.join(LICH_DIR, File.basename($PROGRAM_NAME))
          update_to_lich = File.join(source_dir, "lich.rbw")
          File.open(update_to_lich, 'rb') { |r| File.open(lich_to_update, 'wb') { |w| w.write(r.read) } }
          true
        end

        # Validates the structure of the Lich installation directory.
        # @param dir [String] the directory to validate
        # @return [Boolean] true if the structure is valid, false otherwise
        def validate_lich_structure(dir)
          required_items = ['lib', 'lich.rbw'] + TOP_LEVEL_FILES
          required_items.all? { |item| File.exist?(File.join(dir, item)) }
        end

        # Checks if the Ruby version is compatible with the specified Lich version.
        # @param source_dir [String] the directory containing the new version
        # @param version [String] the version to check compatibility against
        # @return [Boolean] true if compatible, false otherwise
        def check_ruby_compatibility(source_dir, version)
          version_file_path = File.join(source_dir, "lib", "version.rb")
          if File.exist?(version_file_path)
            version_file_content = File.read(version_file_path)
            if (match = version_file_content.match(/REQUIRED_RUBY\s*=\s*["']([^"']+)["']/))
              required_ruby_version = match[1]
              current_ruby_version = RUBY_VERSION
              if Gem::Version.new(current_ruby_version) < Gem::Version.new(required_ruby_version)
                respond
                respond "*** UPDATE ABORTED ***"
                respond
                respond "Lich version #{version} requires Ruby #{required_ruby_version} or higher."
                respond "Your current Ruby version is #{current_ruby_version}."
                respond
                respond "Please update your Ruby installation before updating Lich."
                respond
                respond "DragonRealms - https://github.com/elanthia-online/lich-5/wiki/Documentation-for-Installing-and-Upgrading-Lich"
                respond "Gemstone IV  - https://gswiki.play.net/Lich:Software/Installation"
                respond
                return false
              end
            end
          end
          true
        end

        # Extracts the Lich version from the specified version file.
        # @param version_file_path [String] the path to the version file
        # @return [String, nil] the extracted version or nil if not found
        def extract_version_from_file(version_file_path)
          return nil unless File.exist?(version_file_path)

          version_file_content = File.read(version_file_path)
          if version_file_content =~ /LICH_VERSION\s*=\s*['"]([^'"]+)['"]/
            return $1
          end
          nil
        end
      end
    end
  end
end
