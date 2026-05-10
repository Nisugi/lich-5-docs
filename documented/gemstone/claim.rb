module Lich
  module Claim
    Lock            = Mutex.new
    @claimed_room ||= nil
    @last_room    ||= nil
    @mine         ||= false
    @buffer         = []
    @others         = []
    @timestamp      = Time.now

    # Claims a room by its ID.
    #
    # @param id [Integer] the ID of the room to claim
    # @return [void]
    # @example Claim a room
    #   Lich::Claim.claim_room(5)
    def self.claim_room(id)
      @claimed_room = id.to_i
      @timestamp    = Time.now
      Log.out("claimed #{@claimed_room}", label: %i(claim room)) if defined?(Log)
      Lock.unlock
    end

    # Returns the ID of the currently claimed room.
    # @return [Integer, nil] the ID of the claimed room or nil if none
    def self.claimed_room
      @claimed_room
    end

    # Returns the ID of the last room checked.
    # @return [Integer, nil] the ID of the last room or nil if none
    def self.last_room
      @last_room
    end

    # Acquires the lock if it is not already owned.
    # @return [void]
    def self.lock
      Lock.lock if !Lock.owned?
    end

    # Releases the lock if it is owned.
    # @return [void]
    def self.unlock
      Lock.unlock if Lock.owned?
    end

    # Checks if the current instance is the one that claimed the room.
    # @return [Boolean] true if this instance claimed the room, false otherwise
    def self.current?
      Lock.synchronize { @mine.eql?(true) }
    end

    # Checks if the specified room has been checked.
    #
    # @param room [Integer, nil] the room ID to check; defaults to the last room
    # @return [Boolean] true if the room has been checked, false otherwise
    def self.checked?(room = nil)
      Lock.synchronize { XMLData.room_id == (room || @last_room) }
    end

    # Provides information about the current claim status and room details.
    # @return [String] a formatted string containing the claim information
    def self.info
      rows = [['XMLData.room_id', XMLData.room_id, 'Current room according to the XMLData'],
              ['Claim.mine?', Claim.mine?, 'Claim status on the current room'],
              ['Claim.claimed_room', Claim.claimed_room, 'Room id of the last claimed room'],
              ['Claim.checked?', Claim.checked?, "Has Claim finished parsing ROOMID\ndefault: the current room"],
              ['Claim.last_room', Claim.last_room, 'The last room checked by Claim, regardless of status'],
              ['Claim.others', Claim.others.join("\n"), "Other characters in the room\npotentially less grouped characters"]]
      info_table = Terminal::Table.new :headings => ['Property', 'Value', 'Description'],
                                       :rows     => rows,
                                       :style    => { :all_separators => true }
      Lich::Messaging.mono(info_table.to_s)
    end

    # Checks if this instance is the one that currently owns the claim.
    # @return [Boolean] true if this instance owns the claim, false otherwise
    def self.mine?
      self.current?
    end

    # Returns a list of other characters in the room.
    # @return [Array<String>] an array of character names
    def self.others
      @others
    end

    # Returns a list of members in the group if defined.
    # @return [Array<String>] an array of member nouns or an empty array if not defined
    def self.members
      return [] unless defined? Group

      begin
        if Group.checked?
          return Group.members.map(&:noun)
        else
          return []
        end
      rescue
        return []
      end
    end

    # Returns a list of connected clusters if defined.
    # @return [Array] an array of connected clusters or an empty array if not defined
    def self.clustered
      begin
        return [] unless defined? Cluster
        Cluster.connected
      rescue
        return []
      end
    end

    # Handles the claim parsing for a given room and character list.
    #
    # @param nav_rm [Integer] the room ID being navigated to
    # @param pcs [Array<String>] the list of character names present
    # @return [void]
    # @raise StandardError if an error occurs during parsing
    def self.parser_handle(nav_rm, pcs)
      echo "Claim handled #{nav_rm} with xmlparser" if $claim_debug
      begin
        @others = pcs - self.clustered - self.members
        @last_room = nav_rm
        unless @others.empty?
          @mine = false
          return
        end
        @mine = true
        self.claim_room nav_rm unless nav_rm.nil?
      rescue StandardError => e
        if defined?(Log)
          Log.out(e)
        else
          respond("Claim Parser Error: #{e}")
        end
      ensure
        Lock.unlock if Lock.owned?
      end
    end
  end
  # end
end
