# frozen_string_literal: true

require_relative '../../common/watchable'

# Lich module for the DragonRealms game integration.
# This module contains the DRInfomon functionality for managing game state.
# @example Including the Lich module
#   include Lich
module Lich
  module DragonRealms
    module DRInfomon
      extend Lich::Common::Watchable
      # Populates initial game state after login by issuing
      # game commands whose output is parsed by DRParser.
      #
      # Uses ExecScript so that fput blocks until the game
      # responds, guaranteeing DRParser.parse has processed
      # every response line before the next command is sent.
      #
      # Called once from the game lifecycle hook in games.rb
      # after the character name is known and the session is ready.
      #
      # Detection from scripts:
      #   DRInfomon.startup_complete? - true after all startup commands have finished.
      #     Use this to avoid sending duplicate info/played/exp/ability commands.
      @@startup_complete = false

      # Checks if the startup process is complete.
      # @return [Boolean] true if startup commands have finished, false otherwise.
      def self.startup_complete?
        @@startup_complete
      end

      # Starts a thread to monitor the game state and execute startup commands.
      # @note This method will block until the character is ready.
      # @raise [StandardError] if an error occurs during the startup process.
      # @example Starting the watch process
      #   DRInfomon.watch!
      def self.watch!
        @startup_thread ||= Thread.new do
          begin
            # Wait for character to be ready
            sleep 0.1 until GameBase::Game.autostarted? && XMLData.name && !XMLData.name.empty?

            # Run startup once
            startup
          rescue StandardError => e
            Lich::Messaging.msg('error', 'DRInfomon: Error in startup thread')
            Lich::Messaging.msg('error', "DRInfomon: #{e.inspect}")
            Lich::Messaging.msg('error', "DRInfomon: #{e.backtrace.join("\n")}")
          end
        end
      end

      # Executes the startup script to initialize game state.
      # @example Running the startup process
      #   DRInfomon.startup
      def self.startup
        ExecScript.start(startup_script, { quiet: true, name: 'drinfomon_startup' })
      end

      # Provides the script to be executed during startup.
      # @return [String] The startup script containing game commands.
      def self.startup_script
        <<~SCRIPT
          # Populate stats, race, guild, circle, etc.
          Lich::Util.issue_command("info", /^Name/, /^<output class=""/, quiet: true, timeout: 1) unless dead?

          # Populate account name and subscription level
          Lich::Util.issue_command("played", /^Account Info for/, quiet: true, timeout: 1)

          # Populate all skill ranks and learning rates
          Lich::Util.issue_command("exp all 0", /^Circle: \\d+/, /^EXP HELP/, quiet: true, timeout: 1)

          # Populate known spells/abilities/khri
          # The `ability` command works for all guilds:
          #   - Magic guilds: proxies to `spells`, parsed by check_known_spells
          #   - Barbarians: parsed by check_known_barbarian_abilities
          #   - Thieves: parsed by check_known_thief_khri
          Lich::Util.issue_command("ability", /^You (?:know the Berserks|recall the spells you have learned from your training)|^From (?:your apprenticeship you remember practicing|the \\w+ tree)/, /^You (?:recall that you have \\d+ training sessions|can use SPELL STANCE \\[HELP\\]|have \\d+ available slot)/, quiet: true, timeout: 1)

          # Ensure ShowRoomID and MonsterBold flags are enabled (one-time per character)
          unless UserVars.dependency_setflags
            flags = Array(Lich::Util.issue_command("flag", /^Usage/, /^For other setting options, see AVOID, SET, and TOGGLE/, quiet: true, timeout: 1, usexml: false))
            required = ["ShowRoomID", "MonsterBold"]
            required.each do |flag|
              fput("flag \#{flag} on") unless flags.any? { |f| f.match?(/\#{Regexp.escape(flag)}\\s+ON/) }
            end
            # Re-query to verify flags applied; only mark sentinel if all confirmed
            flags = Array(Lich::Util.issue_command("flag", /^Usage/, /^For other setting options, see AVOID, SET, and TOGGLE/, quiet: true, timeout: 1, usexml: false))
            UserVars.dependency_setflags = Time.now if required.all? { |flag| flags.any? { |f| f.match?(/\#{Regexp.escape(flag)}\\s+ON/) } }
          end

          Lich::DragonRealms::DRInfomon.startup_completed!
        SCRIPT
      end

      # Marks the startup process as complete and triggers post-startup checks.
      # @example Completing the startup process
      #   DRInfomon.startup_completed!
      def self.startup_completed!
        @@startup_complete = true
        PostLoad.game_loaded! if defined?(PostLoad)
        post_startup_checks
      end

      # Performs checks after the startup process is complete.
      # @note This includes warnings about obsolete scripts and data files.
      # @raise [StandardError] if an error occurs during the checks.
      def self.post_startup_checks
        warn_obsolete_scripts
        warn_obsolete_data_files
        warn_custom_scripts
        $setupfiles.reload if defined?($setupfiles) && $setupfiles
      rescue StandardError => e
        safe_message('error', "DRInfomon: post_startup_checks failed: #{e.message}")
        safe_log("DRInfomon: post_startup_checks error: #{e.inspect}\n\t#{e.backtrace&.first(5)&.join("\n\t")}")
      end

      # Sends a message safely, checking if the messaging system is available.
      # @param type [String] The type of message (e.g., 'error', 'info').
      # @param text [String] The message text to send.
      def self.safe_message(type, text)
        if defined?(Lich::Messaging) && Lich::Messaging.respond_to?(:msg)
          Lich::Messaging.msg(type, text)
        else
          safe_log(text)
        end
      end

      # Logs a message safely, checking if the logging system is available.
      # @param text [String] The message text to log.
      def self.safe_log(text)
        if defined?(Lich) && Lich.respond_to?(:log)
          Lich.log(text)
        else
          $stderr.puts(text)
        end
      end

      # Script names that are obsolete and should be deleted.
      # Checked on login to warn users about stale files.
      # List of obsolete script names that should be deleted.
      # Checked on login to warn users about stale files.
      DR_OBSOLETE_SCRIPTS = %w[
        events slackbot spellmonitor exp-monitor
        common-travel common-validation common drinfomon equipmanager
        common-money common-moonmage common-summoning common-theurgy common-arcana
        bootstrap common-crafting common-healing-data common-healing common-items
        update-shops
      ].freeze

      # Data filenames that are obsolete and should be deleted.
      # List of obsolete data filenames that should be deleted.
      DR_OBSOLETE_DATA_FILES = %w[].freeze

      # Warns users about obsolete scripts that should be deleted.
      # @example Checking for obsolete scripts
      #   DRInfomon.warn_obsolete_scripts
      def self.warn_obsolete_scripts
        DR_OBSOLETE_SCRIPTS.each do |script_name|
          path = File.join(SCRIPT_DIR, "#{script_name}.lic")
          next unless File.exist?(path)

          _respond Lich::Messaging.monsterbold("--- Lich: '#{script_name}.lic' is obsolete and should be deleted from #{SCRIPT_DIR}. It is no longer needed and may cause problems.")
        end
      end

      # Warns users about obsolete data files that should be deleted.
      # @example Checking for obsolete data files
      #   DRInfomon.warn_obsolete_data_files
      def self.warn_obsolete_data_files
        data_dir = File.join(SCRIPT_DIR, 'data')
        DR_OBSOLETE_DATA_FILES.each do |filename|
          path = File.join(data_dir, filename)
          next unless File.exist?(path)

          _respond Lich::Messaging.monsterbold("--- Lich: '#{filename}' is obsolete and can be safely deleted from #{data_dir}.")
        end
      end

      # Warns users about custom scripts that shadow curated scripts.
      # @example Checking for custom scripts
      #   DRInfomon.warn_custom_scripts
      def self.warn_custom_scripts
        custom_dir = File.join(SCRIPT_DIR, 'custom')
        return unless File.directory?(custom_dir)

        custom_scripts = Dir.entries(custom_dir).select { |f| f.end_with?('.lic') }
        curated_scripts = Dir.entries(SCRIPT_DIR).select { |f| f.end_with?('.lic') }
        shadowed = custom_scripts.select { |script| curated_scripts.include?(script) }

        unless shadowed.empty?
          Lich::Messaging.msg("info", "NOTE: The following curated scripts are in your custom folder and will not receive updates")
          Lich::Messaging.msg("info", shadowed.join(', '))
        end
      end
    end
  end

  module Common
    CORE_DR_STARTUP = true
  end
end
