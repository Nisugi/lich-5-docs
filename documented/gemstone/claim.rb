# The Lich module provides functionality for managing claims in a game environment.
# @example Including the Lich module
#   include Lich
module Lich
  module Claim
    # A mutex used for synchronizing access to claim operations.
    Lock            = Mutex.new
    # The ID of the currently claimed room.
    @claimed_room ||= nil
    # The ID of the last room that was checked.
    @last_room    ||= nil
    # Indicates whether this instance owns the current claim.
    @mine         ||= false
    # A buffer for storing temporary data related to claims.
    @buffer         = []
    # A list of other characters in the room.
    @others         = []
    # The timestamp of the last claim action.
    @timestamp      = Time.now

    # Claims a room with the given ID.
    # @param id [Integer] The ID of the room to claim.
    # @return [void]
    # @raise [StandardError] If there is an issue claiming the room.
    # @example Claiming a room
    #   Lich::Claim.claim_room(123)
    def self.claim_room(id)
      @claimed_room = id.to_i
      @timestamp    = Time.now
      Log.out("claimed #{@claimed_room}", label: %i(claim room)) if defined?(Log)
      Lock.unlock
    end

    # Returns the ID of the currently claimed room.
    # @return [Integer, nil] The ID of the claimed room or nil if none is claimed.
    def self.claimed_room
      @claimed_room
    end

    # Returns the ID of the last room that was checked.
    # @return [Integer, nil] The ID of the last room checked or nil if none.
    def self.last_room
      @last_room
    end

    # Acquires the lock for the claim operations.
    # @return [void]
    def self.lock
      Lock.lock if !Lock.owned?
    end

    # Releases the lock for the claim operations.
    # @return [void]
    def self.unlock
      Lock.unlock if Lock.owned?
    end

    # Checks if the current claim belongs to this instance.
    # @return [Boolean] True if the current claim is owned by this instance, false otherwise.
    def self.current?
      Lock.synchronize { @mine.eql?(true) }
    end

    # Checks if the specified room has been checked.
    # @param room [Integer, nil] The room ID to check; defaults to the last room if nil.
    # @return [Boolean] True if the room has been checked, false otherwise.
    def self.checked?(room = nil)
      Lock.synchronize { XMLData.room_id == (room || @last_room) }
    end

    # Provides information about the current claim status and related data.
    # @return [String] A formatted string containing the claim information.
    # @example Getting claim info
    #   puts Lich::Claim.info
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

    # Checks if the current instance is the owner of the claim.
    # @return [Boolean] True if this instance owns the claim, false otherwise.
    def self.mine?
      self.current?
    end

    # Returns a list of other characters in the room.
    # @return [Array] An array of other character identifiers.
    def self.others
      @others
    end

    # Returns a list of members in the group if defined.
    # @return [Array] An array of member nouns or an empty array if not defined.
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

    # Returns a list of clustered characters if defined.
    # @return [Array] An array of clustered character identifiers or an empty array if not defined.
    def self.clustered
      begin
        return [] unless defined? Cluster
        Cluster.connected
      rescue
        return []
      end
    end

    # Handles the parsing of claims based on the provided room and character data.
    # @param nav_rm [Integer] The room ID being navigated to.
    # @param pcs [Array] An array of character identifiers present in the room.
    # @return [void]
    # @raise [StandardError] If there is an error during parsing.
    # @example Handling a claim
    #   Lich::Claim.parser_handle(123, ['char1', 'char2'])
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
