require "ostruct"
require "benchmark"
require_relative 'disk'

module Lich
  module Gemstone
    # Represents a group of members in the game.
    #
    # This class manages group membership, leader status, and group operations.
    #
    # @see Lich::Gemstone::Group::Observer For observing group-related events.
    class Group
      @@members ||= []
      @@leader  ||= nil
      @@checked ||= false
      @@status  ||= :closed

      # Clears the group members and resets the checked status.
      # @return [void]
      def self.clear()
        @@members = []
        @@checked = false
      end

      # Checks if the group has been checked.
      # @return [Boolean] true if checked, false otherwise.
      def self.checked?
        @@checked
      end

      # Adds members to the group unless they are already included.
      # @param members [Array<GameObj>] the members to add to the group.
      # @return [void]
      def self.push(*members)
        members.each do |member|
          @@members.push(member) unless include?(member)
        end
      end

      # Removes members from the group based on their IDs.
      # @param members [Array<GameObj>] the members to remove from the group.
      # @return [void]
      def self.delete(*members)
        gone = members.map(&:id)
        @@members.reject! do |m| gone.include?(m.id) end
      end

      # Refreshes the group members with a new list.
      # @param members [Array<GameObj>] the new members to set for the group.
      # @return [void]
      def self.refresh(*members)
        @@members = members.dup
      end

      # Returns a duplicate of the current group members.
      # @return [Array<GameObj>] the current members of the group.
      def self.members
        maybe_check
        @@members.dup
      end

      def self._members
        @@members
      end

      # Retrieves the disks associated with the group members.
      # @return [Array<Disk>] the disks of the group members.
      def self.disks
        return [Disk.find_by_name(Char.name)].compact if Group.leader? && members.empty?
        member_disks = members.map(&:noun).compact.map { |noun| Disk.find_by_name(noun) }.compact
        member_disks.push(Disk.find_by_name(Char.name)) if Disk.find_by_name(Char.name)
        return member_disks
      end

      def self.to_s
        @@members.to_s
      end

      # Sets the checked status of the group.
      # @param flag [Boolean] the new checked status.
      # @return [void]
      def self.checked=(flag)
        @@checked = flag
      end

      # Sets the status of the group.
      # @param state [Symbol] the new status of the group.
      # @return [void]
      def self.status=(state)
        @@status = state
      end

      # Returns the current status of the group.
      # @return [Symbol] the current status of the group.
      def self.status()
        @@status
      end

      # Checks if the group status is open.
      # @return [Boolean] true if the group is open, false otherwise.
      def self.open?
        maybe_check
        @@status.eql?(:open)
      end

      # Checks if the group status is closed.
      # @return [Boolean] true if the group is closed, false otherwise.
      def self.closed?
        not open?
      end

      # Checks the group status and clears members if necessary.
      # @return [Array<GameObj>] the current members of the group after checking.
      def self.check
        Group.clear()
        ttl = Time.now + 3
        Game._puts "<c>group\r\n"
        wait_until { Group.checked? or Time.now > ttl }
        @@members.dup
      end

      def self.maybe_check
        Group.check unless checked?
      end

      # Returns a list of characters that are not members of the group.
      # @return [Array<GameObj>] the non-member characters.
      def self.nonmembers
        GameObj.pcs.to_a.reject { |pc| ids.include?(pc.id) }
      end

      # Sets the leader of the group.
      # @param char [GameObj] the character to set as the leader.
      # @return [void]
      def self.leader=(char)
        @@leader = char
      end

      # Returns the current leader of the group.
      # @return [GameObj, nil] the current leader of the group or nil if none.
      def self.leader
        @@leader
      end

      # Checks if the current instance is the leader of the group.
      # @return [Boolean] true if this instance is the leader, false otherwise.
      def self.leader?
        @@leader.eql?(:self)
      end

      # Adds members to the group with checks for existing membership and status.
      # @param members [Array<GameObj, String>] the members to add to the group.
      # @return [Array<Hash>] results of the add operation for each member.
      def self.add(*members)
        members.map do |member|
          if member.is_a?(Array)
            Group.add(*member)
          else
            member = GameObj.pcs.find { |pc| pc.noun.eql?(member) } if member.is_a?(String)

            break if member.nil?

            result = dothistimeout("group ##{member.id}", 3, Regexp.union(
                                                               %r{You add #{member.noun} to your group},
                                                               %r{#{member.noun}'s group status is closed},
                                                               %r{But #{member.noun} is already a member of your group}
                                                             ))

            case result
            when %r{You add}, %r{already a member}
              Group.push(member)
              { ok: member }
            when %r{closed}
              Group.delete(member)
              { err: member }
            else
            end
          end
        end
      end

      # Returns the IDs of the current group members.
      # @return [Array<Integer>] the IDs of the group members.
      def self.ids
        @@members.map(&:id)
      end

      # Returns the nouns of the current group members.
      # @return [Array<String>] the nouns of the group members.
      def self.nouns
        @@members.map(&:noun)
      end

      # Checks if the specified members are included in the group.
      # @param members [Array<GameObj>] the members to check for inclusion.
      # @return [Boolean] true if all specified members are included, false otherwise.
      def self.include?(*members)
        members.all? { |m| ids.include?(m.id) }
      end

      # Checks if the group is in a broken state based on member status.
      # @return [Boolean] true if the group is broken, false otherwise.
      def self.broken?
        sleep(0.1) while Lich::Gemstone::Claim::Lock.locked?
        if Group.leader?
          return true if (GameObj.pcs.empty? || GameObj.pcs.nil?) && !@@members.empty?
          return false if (GameObj.pcs.empty? || GameObj.pcs.nil?) && @@members.empty?
          (GameObj.pcs.map(&:noun) & @@members.map(&:noun)).size < @@members.size
        else
          GameObj.pcs.find do |pc| pc.noun.eql?(Group.leader.noun) end.nil?
        end
      end

      # Handles calls to methods that are not defined on the group, delegating to members.
      # @param method [Symbol] the method name being called.
      # @param args [Array] the arguments for the method call.
      # @param block [Proc] an optional block for the method call.
      # @return [Object] the result of the delegated method call.
      def self.method_missing(method, *args, &block)
        @@members.send(method, *args, &block)
      end
    end

    class Group
      module Observer
        module Term
          JOIN    = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> joins your group.\r?\n?$}

          LEAVE   = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> leaves your group.\r?\n?$}

          ADD     = %r{^You add <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> to your group.\r?\n?$}

          REMOVE  = %r{^You remove <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> from the group.\r?\n?$}

          NOOP    = %r{^But <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> is already a member of your group!\r?\n?$}

          HAS_LEADER = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> designates you as the new leader of the group\.\r?\n?$}

          SWAP_LEADER = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> designates <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> as the new leader of the group.\r?\n?$}

          GAVE_LEADER_AWAY = %r{You designate <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> as the new leader of the group\.\r?\n?$}

          DISBAND = %r{^You disband your group}

          ADDED_TO_NEW_GROUP = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> adds you to <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> group.\r?\n?$}

          JOINED_NEW_GROUP = %r{You join <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a>\.\r?\n?$}

          LEADER_ADDED_MEMBER = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> adds <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> to <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> group\.\r?\n?$}

          LEADER_REMOVED_MEMBER = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> removes <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> from the group\.\r?\n?$}

          HOLD_RESERVED_FIRST = %r{^You grab <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}

          # Matches when you hold someone's hand (neutral demeanor)
          HOLD_NEUTRAL_FIRST = %r{^You reach out and hold <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}

          # Matches when you take someone's hand (friendly demeanor)
          HOLD_FRIENDLY_FIRST = %r{^You gently take hold of <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}

          # Matches when you clasp someone's hand (warm demeanor)
          HOLD_WARM_FIRST = %r{^You clasp <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand tenderly.\r?\n?$}

          HOLD_RESERVED_SECOND = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> grabs your hand.\r?\n?$}

          # Matches when someone holds your hand (neutral demeanor)
          HOLD_NEUTRAL_SECOND = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> reaches out and holds your hand.\r?\n?$}

          # Matches when someone takes your hand (friendly demeanor)
          HOLD_FRIENDLY_SECOND = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> gently takes hold of your hand.\r?\n?$}

          # Matches when someone clasps your hand (warm demeanor)
          HOLD_WARM_SECOND = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> clasps your hand tenderly.\r?\n?$}

          HOLD_RESERVED_THIRD = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> grabs <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}

          # Matches when you observe someone holding another's hand (neutral demeanor)
          HOLD_NEUTRAL_THIRD = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> reaches out and holds <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}

          # Matches when you observe someone taking another's hand (friendly demeanor)
          HOLD_FRIENDLY_THIRD = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> gently takes hold of <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand.\r?\n?$}

          # Matches when you observe someone clasping another's hand (warm demeanor)
          HOLD_WARM_THIRD = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> clasps <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> hand tenderly.\r?\n?$}

          OTHER_JOINED_GROUP = %r{^<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>\w+?)</a> joins <a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a> group.\r?\n?$}

          # Matches when not in any group
          NO_GROUP = /^You are not currently in a group/

          MEMBER   = /^You are (?:leading|grouped with) (.*)/

          STATUS   = /^Your group status is currently (?<status>open|closed)\./

          # UI indicator showing group is empty
          GROUP_EMPTIED    = %[<indicator id='IconJOINED' visible='n'/>]

          # UI indicator showing group exists
          GROUP_EXISTS     = %[<indicator id='IconJOINED' visible='y'/>]

          # Text indicating leadership transfer
          GIVEN_LEADERSHIP = %[designates you as the new leader of the group.]

          # Combined regex matching any group-related message
          ANY = Regexp.union(
            JOIN,
            LEAVE,
            ADD,
            REMOVE,
            DISBAND,
            NOOP,
            STATUS,
            NO_GROUP,
            MEMBER,
            HAS_LEADER,
            SWAP_LEADER,
            LEADER_ADDED_MEMBER,
            LEADER_REMOVED_MEMBER,
            ADDED_TO_NEW_GROUP,
            JOINED_NEW_GROUP,
            GAVE_LEADER_AWAY,
            HOLD_RESERVED_FIRST,
            HOLD_NEUTRAL_FIRST,
            HOLD_FRIENDLY_FIRST,
            HOLD_WARM_FIRST,
            HOLD_RESERVED_SECOND,
            HOLD_NEUTRAL_SECOND,
            HOLD_FRIENDLY_SECOND,
            HOLD_WARM_SECOND,
            HOLD_RESERVED_THIRD,
            HOLD_NEUTRAL_THIRD,
            HOLD_FRIENDLY_THIRD,
            HOLD_WARM_THIRD,
            OTHER_JOINED_GROUP,
          )

          # Regex for extracting character data from XML tags
          EXIST = %r{<a exist="(?<id>[\d-]+)" noun="(?<noun>[A-Za-z]+)">(?<name>[\w']+?)</a>}
        end

        def self.exist(xml)
          xml.scan(Group::Observer::Term::EXIST).map { |id, _noun, _name| GameObj[id] }
        end

        def self.wants?(line)
          line.strip.match(Term::ANY) or
            line.include?(Term::GROUP_EMPTIED)
        end

        def self.consume(line, match_data)
          if line.include?(Term::GIVEN_LEADERSHIP)
            return Group.leader = :self
          end

          ## Group indicator changed!
          if line.include?(Term::GROUP_EMPTIED)
            Group.leader = :self
            return Group._members.clear
          end

          people = exist(line)

          if line.include?("You are leading")
            Group.leader = :self
          elsif line.include?("You are grouped with")
            Group.leader = people.first
          end

          case line
          when Term::NO_GROUP, Term::DISBAND
            Group.leader = :self
            return Group._members.clear
          when Term::STATUS
            Group.status = match_data[:status].to_sym
            return Group.checked = true
          when Term::GAVE_LEADER_AWAY
            Group.push(people.first)
            return Group.leader = people.first
          when Term::ADDED_TO_NEW_GROUP, Term::JOINED_NEW_GROUP
            Group.checked = false
            Group.push(people.first)
            return Group.leader = people.first
          when Term::SWAP_LEADER
            (old_leader, new_leader) = people
            Group.push(*people) if Group.include?(old_leader) or Group.include?(new_leader)
            return Group.leader = new_leader
          when Term::LEADER_ADDED_MEMBER
            (leader, added) = people
            Group.push(added) if Group.include?(leader)
          when Term::LEADER_REMOVED_MEMBER
            (leader, removed) = people
            return Group.delete(removed) if Group.include?(leader)
          when Term::JOIN, Term::ADD, Term::NOOP
            return Group.push(*people)
          when Term::MEMBER
            return Group.refresh(*people)
          when Term::HOLD_FRIENDLY_FIRST, Term::HOLD_NEUTRAL_FIRST, Term::HOLD_RESERVED_FIRST, Term::HOLD_WARM_FIRST
            return Group.push(people.first)
          when Term::HOLD_FRIENDLY_SECOND, Term::HOLD_NEUTRAL_SECOND, Term::HOLD_RESERVED_SECOND, Term::HOLD_WARM_SECOND
            Group.checked = false
            Group.push(people.first)
            return Group.leader = people.first
          when Term::HOLD_FRIENDLY_THIRD, Term::HOLD_NEUTRAL_THIRD, Term::HOLD_RESERVED_THIRD, Term::HOLD_WARM_THIRD
            (leader, added) = people
            Group.push(added) if Group.include?(leader)
          when Term::OTHER_JOINED_GROUP
            (added, leader) = people
            Group.push(added) if Group.include?(leader)
          when Term::LEAVE, Term::REMOVE
            return Group.delete(*people)
          end
        end
      end
    end
  end
end
