# frozen_string_literal: true

=begin
  Bulk SHA-based repository sync for script repositories.

  Downloads scripts and data files from configured SCRIPT_REPOS and
  user-registered custom repos, skipping files that match local SHA1.
  Supports both :all (auto-sync all .lic) and :explicit (tracked list) modes.
=end

module Lich
  module Util
    module Update
      # Handles the synchronization of script repositories.
      #
      # This class is responsible for downloading scripts and data files from
      # configured SCRIPT_REPOS and user-registered custom repositories, while
      # skipping files that match local SHA1.
      #
      # @see Lich::Util::Update
      class ScriptSync
        # Initializes a new ScriptSync instance.
        # @param client [Object] the client used to fetch data from repositories
        # @return [void]
        def initialize(client)
          @client = client
        end

        # Synchronizes all configured repositories.
        #
        # This method iterates through all SCRIPT_REPOS and custom repositories,
        # syncing each one.
        # @return [void]
        def sync_all_repos
          SCRIPT_REPOS.each_key { |repo_key| sync_repo(repo_key) }
          CustomRepos.all.each_key { |repo_key| sync_repo(repo_key) }
        end

        # Synchronizes a specific repository based on the provided key.
        #
        # @param repo_key [String] the key of the repository to sync
        # @param force [Boolean] whether to force sync even if local SHA matches
        # @return [void]
        def sync_repo(repo_key, force: false)
          config = SCRIPT_REPOS[repo_key]
          unless config
            # Check custom repos
            reg = CustomRepos.all[repo_key]
            if reg
              config = CustomRepos.build_config(repo_key, reg)
            else
              known = (SCRIPT_REPOS.keys + CustomRepos.all.keys).join(', ')
              respond "[lich5-update: Unknown repository '#{repo_key}'. Known: #{known}]"
              return
            end
          end

          if config[:game_filter] && XMLData.game !~ config[:game_filter]
            return
          end

          tree_data = @client.fetch_github_json(config[:api_url])
          unless tree_data && tree_data['tree']
            respond "[lich5-update: Failed to fetch tree for #{repo_key}.]"
            return
          end
          tree = tree_data['tree']

          name = config[:display_name] || repo_key
          syncable = filter_syncable_scripts(tree, config)
          StatusReporter.respond_mono("[lich5-update: Syncing #{name} (#{syncable.length} scripts)...]")

          # Custom repos write to their per-repo subdir; built-in repos to SCRIPT_DIR
          dest = config[:dest_dir] || SCRIPT_DIR
          FileUtils.mkdir_p(dest) if config[:custom]

          local_shas = FileWriter.build_local_sha_map(dest)
          downloaded_scripts = []
          failed_scripts = []
          syncable.each do |entry|
            filename = File.basename(entry['path'])
            next if !force && local_shas[filename] == entry['sha']

            content = @client.http_get("#{config[:raw_base_url]}/#{entry['path']}", auth: false)
            unless content
              failed_scripts << filename
              next
            end

            begin
              FileWriter.safe_write(File.join(dest, filename), content)
              downloaded_scripts << filename
            rescue StandardError => e
              respond "[lich5-update: write failed for #{filename}: #{e.message}]"
              failed_scripts << filename
            end
          end

          downloaded_other = {}
          failed_other = {}
          (config[:subdirs] || {}).each do |subdir_name, subconfig|
            files, failures = sync_subdir(tree, config, subdir_name, subconfig)
            downloaded_other[subdir_name] = files unless files.empty?
            failed_other[subdir_name] = failures unless failures.empty?
          end

          StatusReporter.render_sync_summary(name, syncable.length, downloaded_scripts, downloaded_other, config[:subdirs]&.keys || [], failed_scripts, failed_other)
        end

        # Synchronizes a subdirectory within a repository.
        #
        # @param tree [Array<Hash>] the tree structure of the repository
        # @param config [Hash] the configuration for the repository
        # @param _subdir_name [String] the name of the subdirectory (unused)
        # @param subconfig [Hash] the configuration for the subdirectory
        # @return [Array<Array<String>>] an array containing two arrays: downloaded and failed files
        def sync_subdir(tree, config, _subdir_name, subconfig)
          pattern = subconfig[:pattern]
          dest = subconfig[:dest]
          return [[], []] unless pattern && dest

          FileUtils.mkdir_p(dest)
          entries = tree.select { |e| e['path'] =~ pattern && e['type'] == 'blob' }
          return [[], []] if entries.empty?

          local_shas = FileWriter.build_local_sha_map(dest, subconfig[:glob] || '*.yaml')
          downloaded = []
          failed = []
          entries.each do |entry|
            filename = File.basename(entry['path'])
            next if local_shas[filename] == entry['sha']

            content = @client.http_get("#{config[:raw_base_url]}/#{entry['path']}", auth: false)
            unless content
              failed << filename
              next
            end

            begin
              FileWriter.safe_write(File.join(dest, filename), content)
              downloaded << filename
            rescue StandardError => e
              respond "[lich5-update: write failed for #{filename}: #{e.message}]"
              failed << filename
            end
          end
          [downloaded, failed]
        end

        # Filters the scripts that can be synchronized based on the configuration.
        #
        # @param tree [Array<Hash>] the tree structure of the repository
        # @param config [Hash] the configuration for filtering scripts
        # @return [Array<Hash>] an array of syncable script entries
        def filter_syncable_scripts(tree, config)
          candidates = tree.select { |e| e['path'] =~ config[:script_pattern] && e['type'] == 'blob' }

          case config[:tracking_mode]
          when :all
            candidates.reject { |e| File.basename(e['path']).include?('-setup') }
          when :explicit
            tracked = TrackedScripts.new.tracked_scripts(config)
            candidates.select { |e| tracked.include?(File.basename(e['path'])) }
          else
            candidates
          end
        end
      end
    end
  end
end
