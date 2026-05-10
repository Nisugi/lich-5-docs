
module Lich
  module Gemstone
    module Infomon
      # Synchronizes the character's infomon settings.
      #
      # This method checks for active spells that may interfere with the sync process,
      # retrieves various character information, and updates the last sync date and version.
      # @return [void]
      # @note This method may disable certain spells during the sync process.
      def self.sync
        # since none of this information is 3rd party displayed, silence is golden.
        shroud_detected = false
        respond 'Infomon sync requested.'
        if Effects::Spells.active?(1212)
          respond 'ATTENTION:  SHROUD DETECTED - disabling Shroud of Deception to sync character\'s infomon setting'
          while Effects::Spells.active?(1212)
            dothistimeout('STOP 1212', 3, /^With a moment's concentration, you terminate the Shroud of Deception spell\.$|^Stop what\?$/)
            sleep(0.5)
          end
          shroud_detected = true
        end
        request = { 'info full'          => /<a exist=.+#{XMLData.name}/,
                    'skill'              => /<a exist=.+#{XMLData.name}/,
                    'spell'              => %r{<output class="mono"/>},
                    'experience'         => %r{<output class="mono"/>},
                    'society'            => %r{<pushBold/>},
                    'citizenship'        => /^You don't seem|^You currently have .+ in/,
                    'armor list all'     => /<a exist=.+#{XMLData.name}/,
                    'cman list all'      => /<a exist=.+#{XMLData.name}/,
                    'feat list all'      => /<a exist=.+#{XMLData.name}/,
                    'shield list all'    => /<a exist=.+#{XMLData.name}/,
                    'weapon list all'    => /<a exist=.+#{XMLData.name}/,
                    'ascension list all' => /<a exist=.+#{XMLData.name}/,
                    'resource'           => /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/,
                    'warcry'             => /^You have learned the following War Cries:|^You must be an active member of the Warrior Guild to use this skill/,
                    'profile full'       => %r{<output class="mono"/>} }

        request.each do |command, start_capture|
          respond "Retrieving character #{command}." if $infomon_debug
          Lich::Util.issue_command(command.to_s, start_capture, /<prompt/, include_end: true, timeout: 5, silent: false, usexml: true, quiet: true)
          respond "Did #{command}." if $infomon_debug
        end
        respond 'Requested Infomon sync complete.'
        respond 'ATTENTION:  TEND TO YOUR SHROUD!' if shroud_detected
        Infomon.set('infomon.last_sync_date', Time.now.to_i)
        Infomon.set('infomon.last_sync_version', LICH_VERSION)
      end

      # Resets the infomon data and re-synchronizes it.
      #
      # This method deletes the character table, recreates it, and then repopulates it.
      # @return [void]
      # @note This is a destructive operation and should be used with caution.
      def self.redo!
        # Destructive - deletes char table, recreates it, then repopulates it
        respond 'Infomon complete reset reqeusted.'
        Infomon.reset!
        Infomon.sync
        respond 'Infomon reset is now complete.'
      end

      # Displays stored information for the character.
      #
      # This method retrieves and formats the stored infomon data for display.
      # @param full [Boolean] whether to display all data or only non-zero values
      # @return [void]
      # @example
      #   Infomon.show(true) # Displays all stored information
      #   Infomon.show # Displays only non-zero values
      def self.show(full = false)
        response = []
        # display all stored db values
        respond "Displaying stored information for #{XMLData.name}"
        # Flush async SQL queue before reading from DB to ensure consistency
        Infomon.flush
        Infomon.table.map([:key, :value]).each { |k, v|
          response << "#{k} : #{v.inspect}\n"
        }
        unless full
          response.each { |_line|
            response.reject! do |line|
              line.match?(/\s:\s0$/)
            end
          }
        end
        respond response
      end

      # Checks if a refresh of the infomon database is needed.
      #
      # This method determines if the database structure has changed or if the
      # stored version is outdated, necessitating a refresh.
      # @return [Boolean] true if a refresh is needed, false otherwise
      # @note The refresh criteria include the last sync date and version.
      def self.db_refresh_needed?
        # Change date below to the last date of infomon.db structure change to allow for a forced reset of data.
        # Change Lich version below to also force a refresh of DB as well due to new API/methods used by infomon (introduction of CHE and account subscription status for example).
        return true if Infomon.get("infomon.last_sync_date").nil?
        return true if Infomon.get("infomon.last_sync_date") < Time.new(2025, 6, 26, 20, 0, 0).to_i
        return true if Gem::Version.new("5.12.2") > Gem::Version.new(Infomon.get("infomon.last_sync_version"))
        return false
      end
    end
  end
end
