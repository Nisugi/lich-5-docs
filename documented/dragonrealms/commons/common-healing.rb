
module Lich
  module DragonRealms
    module DRCH
      module_function

      # Strips XML tags from the given lines.
      #
      # @param lines [Array<String>] the lines containing XML to be stripped
      # @return [Array<String>] the lines without XML tags
      def strip_xml(lines)
        DRC.strip_xml(lines)
      end

      # Checks if there are any tendable bleeders.
      #
      # @return [Boolean] true if there are tendable bleeders, false otherwise
      def has_tendable_bleeders?
        check_health.has_tendable_bleeders?
      end

      # Checks the health status of the character.
      #
      # @return [HealthResult] an object containing health information
      def check_health
        health_lines = Lich::Util.issue_command(
          'health',
          /^Your body feels\b/,
          /<prompt/,
          usexml: true,
          quiet: true,
          include_end: false
        )
        if health_lines.nil?
          Lich::Messaging.msg("bold", "DRCH: Failed to capture HEALTH output (timeout).")
          return HealthResult.new
        end

        parse_health_lines(strip_xml(health_lines))
      end

      # Parses the health lines to extract health information.
      #
      # @param health_lines [Array<String>] the lines containing health information
      # @return [HealthResult] an object containing parsed health data
      def parse_health_lines(health_lines)
        parasites_regex = Regexp.union(PARASITES_REGEX)
        wounds_line = nil
        parasites_line = nil
        lodged_line = nil
        diseased = false
        poisoned = false

        health_lines.each do |line|
          case line
          when /^Your body feels\b/, /^Your spirit feels\b/, /^You are .*fatigued/, /^You feel fully rested/
            next
          when /^You have (?!no significant injuries)(?!.* lodged .* in(?:to)? your)(?!.* infection)(?!.* poison(?:ed)?)(?!.* #{parasites_regex})/
            wounds_line = line
          when /^You have .* lodged .* in(?:to)? your/
            lodged_line = line
          when /^You have a .* on your/, parasites_regex
            parasites_line = line
          when /^You have a dormant infection/, /^Your wounds are infected/, /^Your body is covered in open oozing sores/
            diseased = true
          when /^You have .* poison(?:ed)?/, /^You feel somewhat tired and seem to be having trouble breathing/
            poisoned = true
          end
        end

        bleeders = parse_bleeders(health_lines)
        wounds = parse_wounds(wounds_line)
        parasites = parse_parasites(parasites_line)
        lodged_items = parse_lodged_items(lodged_line)
        score = calculate_score(wounds)

        HealthResult.new(
          wounds: wounds,
          bleeders: bleeders,
          parasites: parasites,
          lodged: lodged_items,
          poisoned: poisoned,
          diseased: diseased,
          score: score
        )
      end

      # Allows an empath to perceive their own health status.
      #
      # @return [HealthResult, nil] an object containing health information or nil if the empath cannot perceive health
      def perceive_health
        unless DRStats.empath?
          Lich::Messaging.msg("bold", "DRCH: Only empaths can perceive health.")
          return nil
        end

        lines = Lich::Util.issue_command(
          'perceive health self',
          /injuries include\.\.\.|feel only an aching emptiness/,
          /<prompt/,
          usexml: true,
          quiet: true,
          include_end: false,
          timeout: 15
        )
        if lines.nil?
          Lich::Messaging.msg("bold", "DRCH: Failed to capture PERCEIVE HEALTH output (timeout).")
          return nil
        end

        lines = strip_xml(lines)

        if lines.any? { |line| line =~ /feel only an aching emptiness/ }
          waitrt?
          return check_health
        end

        perceived = parse_perceived_health_lines(lines)
        health_data = check_health

        waitrt?

        HealthResult.new(
          wounds: perceived.wounds,
          bleeders: health_data.bleeders,
          parasites: health_data.parasites,
          lodged: health_data.lodged,
          poisoned: health_data.poisoned,
          diseased: health_data.diseased,
          vitality: perceived.vitality,
          dead: perceived.dead,
          score: perceived.score
        )
      end

      # Allows an empath to perceive the health status of another character.
      #
      # @param target [String] the name of the target character
      # @return [HealthResult, nil] an object containing health information or nil if the empath cannot perceive health
      def perceive_health_other(target)
        unless DRStats.empath?
          Lich::Messaging.msg("bold", "DRCH: Only empaths can perceive health of others.")
          return nil
        end

        touch_lines = Lich::Util.issue_command(
          "touch #{target}",
          /You sense a successful empathic link|Touch what|feels cold|avoids your touch|You quickly recoil/,
          /<prompt/,
          usexml: true,
          quiet: true,
          include_end: false,
          timeout: 10
        )
        if touch_lines.nil?
          Lich::Messaging.msg("bold", "DRCH: Failed to capture TOUCH output for #{target} (timeout).")
          return nil
        end

        touch_lines = strip_xml(touch_lines)

        if touch_lines.any? { |line| line =~ /Touch what|feels cold|avoids your touch|You quickly recoil/ }
          Lich::Messaging.msg("bold", "DRCH: Unable to perceive health of #{target}.")
          return nil
        end

        # Extract actual character name from the empathic link message.
        # The target passed to the method may be abbreviated or differently cased.
        touch_lines.each do |line|
          match = line.match(/between you and (?<name>\w+)\./)
          if match
            target = match[:name]
            break
          end
        end

        parse_perceived_health_lines(touch_lines)
      end

      # Parses the lines perceived from another character's health.
      #
      # @param lines [Array<String>] the lines containing perceived health information
      # @return [HealthResult] an object containing parsed health data
      def parse_perceived_health_lines(lines)
        parasites_regex = Regexp.union(PARASITES_REGEX)
        poisons_regex = Regexp.union([
                                       /^[\w]+ (?:has|have) a .* poison/,
                                       /having trouble breathing/,
                                       /Cyanide poison/
                                     ])
        diseases_regex = Regexp.union([
                                        /^[\w]+ wounds are (?:badly )?infected/,
                                        /^[\w]+ (?:has|have) a dormant infection/,
                                        /^[\w]+ (?:body|skin) is covered (?:in|with) open oozing sores/
                                      ])
        dead_regex = /^(?:He|She) is dead/
        vitality_regex = /has (\d+)% vitality remaining/

        perceived_wounds = Hash.new { |h, k| h[k] = [] }
        perceived_parasites = Hash.new { |h, k| h[k] = [] }
        perceived_poison = false
        perceived_disease = false
        perceived_vitality = 100
        wound_body_part = nil
        dead = false

        lines.each do |line|
          case line
          when dead_regex
            dead = true
          when vitality_regex
            perceived_vitality = Regexp.last_match(1).to_i
          when diseases_regex
            perceived_disease = true
          when poisons_regex
            perceived_poison = true
          when parasites_regex
            match = line.match(/.* on (?:his|her|your) (?<body_part>[\w\s]*)/)
            body_part = match[:body_part] if match
            perceived_parasites[1] << Wound.new(body_part: body_part, severity: 1)
          when /^Wounds to the /
            match = line.match(/^Wounds to the (?<body_part>.+):/)
            wound_body_part = match[:body_part] if match
            perceived_wounds[wound_body_part] = []
          when /^(?:Fresh|Scars) (?:External|Internal)/
            match = line.match(PERCEIVE_HEALTH_SEVERITY_REGEX)
            next unless match
            next unless wound_body_part

            severity = WOUND_SEVERITY[match[:severity]]
            perceived_wounds[wound_body_part] << Wound.new(
              body_part: wound_body_part,
              severity: severity,
              is_internal: match[:location] == 'Internal',
              is_scar: match[:freshness] == 'Scars'
            )
          end
        end

        # Bucket wounds by severity.
        wounds = Hash.new { |h, k| h[k] = [] }
        perceived_wounds.values.flatten.each do |wound|
          wounds[wound.severity] << wound
        end

        HealthResult.new(
          wounds: wounds,
          parasites: perceived_parasites,
          poisoned: perceived_poison,
          diseased: perceived_disease,
          dead: dead,
          vitality: perceived_vitality,
          score: calculate_score(wounds)
        )
      end

      # Parses the health lines to extract information about bleeders.
      #
      # @param health_lines [Array<String>] the lines containing health information
      # @return [Hash] a hash containing bleeders categorized by severity
      def parse_bleeders(health_lines)
        bleeders = Hash.new { |h, k| h[k] = [] }
        return bleeders unless health_lines.grep(/^Bleeding|^\s*\bArea\s+Rate\b/).any?

        health_lines
          .drop_while { |line| !(BLEEDER_LINE_REGEX =~ line) }
          .take_while { |line| BLEEDER_LINE_REGEX =~ line }
          .each do |line|
            match = line.match(WOUND_BODY_PART_REGEX)
            next unless match

            body_part = match.names.find { |name| match[name.to_sym] }
            body_part = match[:part] if body_part == 'part'
            body_part = body_part.gsub('l.', 'left').gsub('r.', 'right')

            rate_match = line.match(/(?:head|eye|neck|chest|abdomen|back|arm|hand|leg|tail|skin)\s+(?<rate>.+)/)
            next unless rate_match

            bleed_rate = rate_match[:rate].strip
            bleed_info = BLEED_RATE_TO_SEVERITY[bleed_rate]
            next unless bleed_info

            bleeders[bleed_info[:severity]] << Wound.new(
              body_part: body_part,
              severity: bleed_info[:severity],
              bleeding_rate: bleed_rate,
              is_internal: line.start_with?('inside')
            )
          end

        bleeders
      end

      # Parses a line describing wounds to extract detailed information.
      #
      # @param wounds_line [String] the line containing wound information
      # @return [Hash] a hash containing wounds categorized by severity
      def parse_wounds(wounds_line)
        wounds = Hash.new { |h, k| h[k] = [] }
        return wounds unless wounds_line

        wounds_line = wounds_line.gsub(WOUND_COMMA_SEPARATOR, '')
        wounds_line = wounds_line.gsub(/^You have\s+/, '').gsub(/\.$/, '')
        wounds_line.split(',').map(&:strip).each do |wound|
          WOUND_SEVERITY_REGEX_MAP.each do |regex, template|
            match = wound.match(regex)
            next unless match

            body_part = match.names.find { |name| match[name.to_sym] }
            body_part = match[:part] if body_part == 'part'

            wounds[template[:severity]] << Wound.new(
              body_part: body_part,
              severity: template[:severity],
              is_internal: template[:internal],
              is_scar: template[:scar]
            )
          end
        end

        wounds
      end

      # Parses a line describing parasites to extract detailed information.
      #
      # @param parasites_line [String] the line containing parasite information
      # @return [Hash] a hash containing parasites categorized by severity
      def parse_parasites(parasites_line)
        parasites = Hash.new { |h, k| h[k] = [] }
        return parasites unless parasites_line

        parasites_line = parasites_line.gsub(/^You have\s+/, '').gsub(/\.$/, '')
        parasites_line.split(',').map(&:strip).each do |parasite|
          match = parasite.match(PARASITE_BODY_PART_REGEX)
          next unless match

          parasites[1] << Wound.new(
            body_part: match[:part],
            severity: 1,
            is_parasite: true
          )
        end

        parasites
      end

      # Parses a line describing lodged items to extract detailed information.
      #
      # @param lodged_line [String] the line containing lodged item information
      # @return [Hash] a hash containing lodged items categorized by severity
      def parse_lodged_items(lodged_line)
        lodged_items = Hash.new { |h, k| h[k] = [] }
        return lodged_items unless lodged_line

        lodged_line = lodged_line.gsub(/^You have\s+/, '').gsub(/\.$/, '')
        lodged_line.split(',').map(&:strip).each do |wound|
          match = wound.match(LODGED_BODY_PART_REGEX)
          next unless match

          body_part = match.names.find { |name| match[name.to_sym] }
          body_part = match[:part] if body_part == 'part'

          severity_match = wound.match(/\blodged\s+(?<depth>.+)\s+in(?:to)? your\b/)
          next unless severity_match

          severity = LODGED_SEVERITY[severity_match[:depth]]

          lodged_items[severity] << Wound.new(
            body_part: body_part,
            severity: severity,
            is_lodged_item: true
          )
        end

        lodged_items
      end

      # Binds a wound on the specified body part of a character.
      #
      # @param body_part [String] the body part to bind
      # @param person [String] the person to bind (default is 'my')
      # @return [Boolean] true if the binding was successful, false otherwise
      def bind_wound(body_part, person = 'my')
        result = DRC.bput("tend #{person} #{body_part}", *TEND_SUCCESS_PATTERNS, *TEND_FAILURE_PATTERNS, *TEND_DISLODGE_PATTERNS)
        waitrt?
        case result
        when *TEND_DISLODGE_PATTERNS
          dislodge_match = result.match(/^You \w+ remove (?:a|the|some) (?<item>.+) from/)
          DRCI.dispose_trash(dislodge_match[:item], get_settings.worn_trashcan, get_settings.worn_trashcan_verb) if dislodge_match
          bind_wound(body_part, person)
        when *TEND_FAILURE_PATTERNS
          false
        else
          true
        end
      end

      # Unwraps a wound on the specified body part of a character.
      #
      # @param body_part [String] the body part to unwrap
      # @param person [String] the person to unwrap (default is 'my')
      # @return [Boolean] true if the unwrapping was successful, false otherwise
      def unwrap_wound(body_part, person = 'my')
        DRC.bput("unwrap #{person} #{body_part}", 'You unwrap .* bandages', 'That area is not tended', 'You may undo the affects of TENDing')
        waitrt?
      end

      # Checks if the character has the skill to tend to a wound based on its bleed rate.
      #
      # @param bleed_rate [String] the bleed rate of the wound
      # @param internal [Boolean] whether the wound is internal (default is false)
      # @return [Boolean] true if the character is skilled enough, false otherwise
      def skilled_to_tend_wound?(bleed_rate, internal = false)
        bleed_info = BLEED_RATE_TO_SEVERITY[bleed_rate]
        return false unless bleed_info

        skill_target = internal ? :skill_to_tend_internal : :skill_to_tend
        min_skill = bleed_info[skill_target]
        return false if min_skill.nil?

        DRSkill.getrank('First Aid') >= min_skill
      end

      # Calculates a score based on the severity of wounds.
      #
      # @param wounds_by_severity [Hash] a hash of wounds categorized by severity
      # @return [Integer] the calculated score
      def calculate_score(wounds_by_severity)
        wounds_by_severity.map { |severity, wound_list| (severity**2) * wound_list.count }.reduce(:+) || 0
      end

      # Represents the health status of a character.
      #
      # Contains information about wounds, bleeders, parasites, and other health-related data.
      class HealthResult
        attr_reader :wounds, :bleeders, :parasites, :lodged,
                    :poisoned, :diseased, :score, :dead, :vitality

        def initialize(wounds: {}, bleeders: {}, parasites: {}, lodged: {},
                       poisoned: false, diseased: false, score: 0, dead: false,
                       vitality: 100)
          @wounds = wounds
          @bleeders = bleeders
          @parasites = parasites
          @lodged = lodged
          @poisoned = poisoned
          @diseased = diseased
          @score = score
          @dead = dead
          @vitality = vitality
        end

        def [](key)
          send(key.to_sym)
        end

        def injured?
          score > 0
        end

        def bleeding?
          bleeders.values.flatten.any?(&:bleeding?)
        end

        def has_tendable_bleeders?
          bleeders.values.flatten.any?(&:tendable?)
        end
      end

      # Represents a wound on a character.
      #
      # Contains details about the wound's location, severity, and other characteristics.
      class Wound
        attr_reader :body_part, :severity, :bleeding_rate

        def initialize(body_part: nil, severity: nil, bleeding_rate: nil,
                       is_internal: false, is_scar: false,
                       is_parasite: false, is_lodged_item: false)
          @body_part = body_part&.downcase
          @severity = severity
          @bleeding_rate = bleeding_rate&.downcase
          @internal = !!is_internal
          @scar = !!is_scar
          @parasite = !!is_parasite
          @lodged_item = !!is_lodged_item
        end

        def bleeding?
          !@bleeding_rate.nil? && !@bleeding_rate.empty? && @bleeding_rate != '(tended)'
        end

        def internal?
          @internal
        end

        def scar?
          @scar
        end

        def parasite?
          @parasite
        end

        def lodged?
          @lodged_item
        end

        def tendable?
          return true if parasite?
          return true if lodged?
          return false if @body_part =~ /skin/
          return false unless bleeding?
          return false if @bleeding_rate =~ /tended|clotted/

          DRCH.skilled_to_tend_wound?(@bleeding_rate, internal?)
        end

        def location
          internal? ? 'internal' : 'external'
        end

        def type
          scar? ? 'scar' : 'wound'
        end

        def to_h
          {
            body_part: @body_part,
            severity: @severity,
            bleeding_rate: @bleeding_rate,
            internal: @internal,
            scar: @scar,
            parasite: @parasite,
            lodged_item: @lodged_item
          }
        end

        def to_s
          parts = [@body_part || 'unknown']
          parts << "severity:#{@severity}" if @severity
          parts << "bleeding:#{@bleeding_rate}" if @bleeding_rate
          parts << location
          parts << type
          parts << 'parasite' if parasite?
          parts << 'lodged' if lodged?
          "Wound(#{parts.join(', ')})"
        end
      end
    end
  end
end
