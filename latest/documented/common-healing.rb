# The main module for the Lich project.
module Lich
  # Module for DragonRealms functionality.
  module DragonRealms
    # Module containing healing-related methods and functionality.
    module DRCH
      module_function

      # Checks if there are any tendable bleeding wounds.
      # @return [Boolean] true if there are tendable bleeders, false otherwise
      # @example
      #   if has_tendable_bleeders?
      #     puts 'You have wounds that can be tended.'
      #   end
      def has_tendable_bleeders?
        health_data = check_health
        return true if health_data['bleeders'].values.flatten.any? { |wound| wound.tendable? }

        return false
      end

      # Uses HEALTH command to check for poisons, diseases, bleeders, parasites, and lodged items.
      # Based on this diagnostic information, you should be able to prioritize how you heal
      # yourself with medicinal potions and salves, or healing spells.
      # Uses the HEALTH command to check for poisons, diseases, bleeders, parasites, and lodged items.
      # Based on this diagnostic information, you should be able to prioritize how you heal yourself.
      # @return [Hash] A hash containing health data including wounds, bleeders, parasites, lodged items, poisoned, diseased, and score.
      # @example
      #   health_data = check_health
      #   puts health_data['wounds']
      # @note This method may incur a delay due to server response.
      def check_health
        parasites_regex = Regexp.union($DRCH_PARASITES_REGEX_LIST)
        wounds_line = nil
        parasites_line = nil
        lodged_line = nil
        diseased = false
        poisoned = false

        DRC.bput('health', 'You have', 'You feel somewhat tired and seem to be having trouble breathing', 'Your wounds', 'Your body')
        pause 0.5
        health_lines = reget(50).map(&:strip).reverse

        health_lines.each do |line|
          case line
          when /^Your body feels\b.*(?:strength|battered|beat up|bad shape|death's door|dead)/
            # While iterating the game output in reverse,
            # this line represents the start of `HEALTH` command
            # so we can now break out of the loop and avoid
            # parsing text prior to the latest HEALTH command.
            # We don't need to parse this line, just use implicit `health` numeric variable.
            break
          when /Your spirit feels\b.*(?:mighty and unconquerable|full of life|strong|wavering slightly|shaky|weak|cold|empty|lifeless|dead)/
            # This line is your spirit health.
            # We don't need to parse this line, just use implicit `spirit` numeric variable.
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

        return {
          'wounds'    => wounds,
          'bleeders'  => bleeders,
          'parasites' => parasites,
          'lodged'    => lodged_items,
          'poisoned'  => poisoned,
          'diseased'  => diseased,
          'score'     => score
        }
      end

      # Uses PERCEIVE HEALTH SELF command to check for wounds and scars.
      # Returns a map of any wounds where the keys
      # are the severity and the values are the list of wounds.
      # Uses the PERCEIVE HEALTH SELF command to check for wounds and scars.
      # Returns a map of any wounds where the keys are the severity and the values are the list of wounds.
      # @return [Hash] A hash containing perceived health data including wounds and score.
      # @example
      #   perceived_health = perceive_health
      #   puts perceived_health['wounds']
      def perceive_health
        return unless DRStats.empath?

        case DRC.bput('perceive health self', 'feel only an aching emptiness', 'Roundtime')
        when 'feel only an aching emptiness'
          # Empath is permashocked and cannot perceive wounds.
          return check_health
        end

        perceived_health_data = parse_perceived_health

        # Return same response as `check_health` but with wound details per perceive health.
        health_data = check_health
        health_data['wounds'] = perceived_health_data['wounds']
        health_data['score'] = perceived_health_data['score']

        # The `perceive health self` command incurs roundtime. We delayed waiting until now so that
        # the script can use that time to parse the output rather than waiting unnecessarily.
        waitrt?
        return health_data
      end

      # Checks the health of another target using the PERCEIVE HEALTH command.
      # @param target [String] The name of the target to perceive health for.
      # @return [Hash, nil] A hash containing perceived health data for the target or nil if unable to perceive.
      # @example
      #   target_health = perceive_health_other('John')
      #   puts target_health['wounds']
      def perceive_health_other(target)
        return unless DRStats.empath?

        case DRC.bput("touch #{target}", 'Touch what', 'feels cold and you are unable to sense anything', 'avoids your touch', 'You sense a successful empathic link has been forged between you and (?<name>\w+)\.', /^You quickly recoil/)
        when 'avoids your touch', 'feels cold and you are unable to sense anything', 'Touch what', /^You quickly recoil/
          return nil
        when /You sense a successful empathic link has been forged between you and (?<name>\w+)\./
          # The target passed to the method might be abbreviated
          # or not match the exact casing as the person's actual name.
          # Since this value becomes part of regex patterns later,
          # make sure we're using the actual character's name.
          target = Regexp.last_match[:name]
        end

        return parse_perceived_health(target)
      end

      # Examples of what this parses can be found in test/test_check_health.rb
      # Parses the output of the PERCEIVE HEALTH command.
      # @param target [String, nil] The target to perceive health for, defaults to nil for self.
      # @return [Hash, nil] A hash containing perceived health data or nil if parsing fails.
      # @example
      #   health_data = parse_perceived_health('John')
      #   puts health_data['wounds']
      def parse_perceived_health(target = nil)
        pause 0.5 # Pause to wait for the full response to come back from the server

        stop_line = target.nil? ? 'Your injuries include...' : "You sense a successful empathic link has been forged between you and #{target}\."
        health_lines = reget(100).map(&:strip).reverse
        if !health_lines.include?(stop_line)
          return
        end

        parasites_regex = Regexp.union($DRCH_PARASITES_REGEX_LIST)

        poisons_regex = Regexp.union([
                                       /^[\w]+ (?:has|have) a .* poison/,
                                       /having trouble breathing/,
                                       /Cyanide poison/
                                     ])

        diseases_regex = Regexp.union([
                                        /^[\w]+ wounds are (badly )?infected/,
                                        /^[\w]+ (?:has|have) a dormant infection/,
                                        /^[\w]+ (?:body|skin) is covered (?:in|with) open oozing sores/
                                      ])

        dead_regex = Regexp.union([
                                    /^(He|She) is dead/
                                  ])

        perceived_wounds = Hash.new { |h, k| h[k] = [] }
        perceived_parasites = Hash.new { |h, k| h[k] = [] }
        perceived_poison = false
        perceived_disease = false
        wound_body_part = nil
        dead = false

        health_lines
          .take_while { |line| line != stop_line }
          .reverse # put back in normal order so we parse <body part> line then <wound> lines
          .each do |line|
            case line
            when dead_regex
              dead = true
            when diseases_regex
              perceived_disease = true
            when poisons_regex
              perceived_poison = true
            when parasites_regex
              line =~ /.* on (?:his|her|your) (?<body_part>[\w\s]*)/
              body_part = Regexp.last_match(1)
              severity = 1
              perceived_parasites[severity] << Wound.new(
                body_part: body_part,
                severity: severity
              )
            when /^Wounds to the (.+):/
              wound_body_part = Regexp.last_match(1)
              perceived_wounds[wound_body_part] = []
            when /^(Fresh|Scars) (External|Internal)/
              # Do regex then grab matches for wound details.
              line =~ $DRCH_PERCEIVE_HEALTH_SEVERITY_REGEX
              severity = $DRCH_WOUND_TO_SEVERITY_MAP[Regexp.last_match[:severity]]
              is_internal = Regexp.last_match[:location] == 'Internal'
              is_scar = Regexp.last_match[:freshness] == 'Scars'
              perceived_wounds[body_part] << Wound.new(
                body_part: wound_body_part,
                severity: severity,
                is_internal: is_internal,
                is_scar: is_scar
              )
            end
          end

        # Now go through the preceived wounds map (key=body part)
        # and bucket the wounds by severity into the 'wounds' map (key=severity).
        wounds = Hash.new { |h, k| h[k] = [] }
        perceived_wounds.values.flatten.each do |wound|
          wounds[wound.severity] << wound
        end

        return {
          'wounds'    => wounds,
          'parasites' => perceived_parasites,
          'poisoned'  => perceived_poison,
          'diseased'  => perceived_disease,
          'dead'      => dead,
          'score'     => calculate_score(wounds)
        }
      end

      # Given lines of text from the HEALTH command output in reverse,
      # returns a map of any bleeding wounds where the keys
      # are the severity and the values are the list of bleeding wounds.
      # Parses the bleeding wounds from the HEALTH command output.
      # @param health_lines [Array<String>] Lines of text from the HEALTH command output.
      # @return [Hash] A hash of bleeding wounds categorized by severity.
      # @example
      #   bleeders = parse_bleeders(health_lines)
      #   puts bleeders
      def parse_bleeders(health_lines)
        bleeders = Hash.new { |h, k| h[k] = [] }
        bleeder_line_regex = /^\b(inside\s+)?((l\.|r\.|left|right)\s+)?(head|eye|neck|chest|abdomen|back|arm|hand|leg|tail|skin)\b/
        if health_lines.grep(/^Bleeding|^\s*\bArea\s+Rate\b/).any?
          health_lines
            .drop_while { |line| !(bleeder_line_regex =~ line) }
            .take_while { |line| bleeder_line_regex =~ line }
            .each do |line|
              # Do regex then look for the body part match.
              line =~ $DRCH_WOUND_BODY_PART_REGEX
              body_part = Regexp.last_match.names.find { |x| Regexp.last_match[x.to_sym] }
              body_part = Regexp.last_match[:part] if body_part == 'part'
              # Standardize on full word for 'left' and 'right'.
              # Internal bleeders use the abbreviations.
              body_part = body_part.gsub('l.', 'left').gsub('r.', 'right')
              # Check for the bleeding severity.
              bleed_rate = /(?:head|eye|neck|chest|abdomen|back|arm|hand|leg|tail|skin)\s+(.+)/.match(line)[1]
              severity = $DRCH_BLEED_RATE_TO_SEVERITY_MAP[bleed_rate][:severity]
              # Check if internal or not. Want an actual boolean result here, not just "truthy/falsey".
              is_internal = line =~ /^inside/ ? true : false
              bleeders[severity] << Wound.new(
                body_part: body_part,
                severity: severity,
                bleeding_rate: bleed_rate,
                is_internal: is_internal
              )
            end
        end
        return bleeders
      end

      # Given the line of text from the HEALTH command output that expresses
      # external and internal wounds and scars, returns a map of any wounds where
      # the keys are the severity and the values are the list of wounds.
      # Parses the wounds from the HEALTH command output.
      # @param wounds_line [String] The line of text containing wound descriptions.
      # @return [Hash] A hash of wounds categorized by severity.
      # @example
      #   wounds = parse_wounds(wounds_line)
      #   puts wounds
      def parse_wounds(wounds_line)
        wounds = Hash.new { |h, k| h[k] = [] }
        if wounds_line
          # Remove commas within wound text so we can split on each wound phrase.
          # For example "a bruised, swollen and slashed left eye" => "a bruised swollen and slashed left eye"
          wounds_line = wounds_line.gsub($DRCH_WOUND_COMMA_SEPARATOR, '')
          # Remove the tidbits at the start and end of the sentence that aren't pertinent.
          wounds_line = wounds_line.gsub(/^You have\s+/, '').gsub(/\.$/, '')
          wounds_line.split(',').map(&:strip).each do |wound|
            $DRCH_WOUND_SEVERITY_REGEX_MAP.each do |regex, template|
              next unless wound =~ regex

              body_part = Regexp.last_match.names.find { |x| Regexp.last_match[x.to_sym] }
              body_part = Regexp.last_match[:part] if body_part == 'part'
              wounds[template[:severity]] << Wound.new(
                body_part: body_part,
                severity: template[:severity],
                is_internal: template[:internal],
                is_scar: template[:scar]
              )
            end
          end
        end
        return wounds
      end

      # Given the line of text from the HEALTH command output that expresses
      # parasites latched to you, returns a map of any parasites where the keys
      # are the severity and the values are the list of wounds.
      # Parses the parasites from the HEALTH command output.
      # @param parasites_line [String] The line of text containing parasite descriptions.
      # @return [Hash] A hash of parasites categorized by severity.
      # @example
      #   parasites = parse_parasites(parasites_line)
      #   puts parasites
      def parse_parasites(parasites_line)
        parasites = Hash.new { |h, k| h[k] = [] }
        if parasites_line
          # Remove the tidbits at the start and end of the sentence that aren't pertinent.
          parasites_line = parasites_line.gsub(/^You have\s+/, '').gsub(/\.$/, '')
          parasites_line.split(',').map(&:strip).each do |parasite|
            # Do regex then look for the body part match.
            parasite =~ $DRCH_PARASITE_BODY_PART_REGEX
            body_part = Regexp.last_match[:part].to_s
            severity = 1
            parasites[severity] << Wound.new(
              body_part: body_part,
              severity: severity,
              is_parasite: true
            )
          end
        end
        return parasites
      end

      # Given the line of text from the HEALTH command output
      # that expresses items lodged into you,
      # returns a map of any lodged items where the keys
      # are the severity and the values are the list of wounds.
      # Parses the lodged items from the HEALTH command output.
      # @param lodged_line [String] The line of text containing lodged item descriptions.
      # @return [Hash] A hash of lodged items categorized by severity.
      # @example
      #   lodged_items = parse_lodged_items(lodged_line)
      #   puts lodged_items
      def parse_lodged_items(lodged_line)
        lodged_items = Hash.new { |h, k| h[k] = [] }
        if lodged_line
          # Remove the tidbits at the start and end of the sentence that aren't pertinent.
          lodged_line = lodged_line.gsub(/^You have\s+/, '').gsub(/\.$/, '')
          lodged_line.split(',').map(&:strip).each do |wound|
            # Do regex then look for the body part match.
            wound =~ $DRCH_LODGED_BODY_PART_REGEX
            body_part = Regexp.last_match.names.find { |x| Regexp.last_match[x.to_sym] }
            body_part = Regexp.last_match[:part] if body_part == 'part'
            # Check for the lodged severity.
            severity = /\blodged\s+(.*)\s+in(?:to)? your\b/.match(wound)[1]
            severity = $DRCH_LODGED_TO_SEVERITY_MAP[severity]
            lodged_items[severity] << Wound.new(
              body_part: body_part,
              severity: severity,
              is_lodged_item: true
            )
          end
        end
        return lodged_items
      end

      # Tends to a specified wound on the body.
      # @param body_part [String] The body part to tend.
      # @param person [String] The person to tend, defaults to 'my'.
      # @return [Boolean] true if tending was successful, false otherwise.
      # @example
      #   success = bind_wound('left arm')
      #   puts 'Wound tended successfully!' if success
      def bind_wound(body_part, person = 'my')
        # Either you tended it or it already has bandages on. Good job!
        tend_success = [
          /You work carefully at tending/,
          /You work carefully at binding/,
          /That area has already been tended to/,
          /That area is not bleeding/
        ]
        # Yeouch, you couldn't tend the wound. Might have made it worse!
        tend_failure = [
          /You fumble/,
          /too injured for you to do that/,
          /TEND allows for the tending of wounds/,
          /^You must have a hand free/
        ]
        # You dislodged ammo or a parasite, discard it. Note, some parasites go away and don't
        # end up in your hand. Fine, it'll just fail to dispose.
        tend_dislodge = [
          /^You \w+ remove (a|the|some) (.*) from/,
          /^As you reach for the clay fragment/
        ]

        result = DRC.bput("tend #{person} #{body_part}", *tend_success, *tend_failure, *tend_dislodge)
        waitrt?
        case result
        when *tend_dislodge
          DRCI.dispose_trash(Regexp.last_match(2), get_settings.worn_trashcan, get_settings.worn_trashcan_verb)
          bind_wound(body_part, person)
        when *tend_failure
          false
        else
          true
        end
      end

      # Unwraps bandages from a specified wound.
      # @param body_part [String] The body part to unwrap.
      # @param person [String] The person to unwrap, defaults to 'my'.
      # @return [void]
      # @example
      #   unwrap_wound('left arm')
      def unwrap_wound(body_part, person = 'my')
        DRC.bput("unwrap #{person} #{body_part}", 'You unwrap .* bandages', 'That area is not tended', 'You may undo the affects of TENDing')
        waitrt?
      end

      # Skill check to tend a bleeding wound.
      # If you're not skilled enough you may make things worse and incur long roundtime.
      # Checks if the player has the required skill to tend a bleeding wound.
      # @param bleed_rate [String] The rate of bleeding.
      # @param internal [Boolean] Indicates if the wound is internal, defaults to false.
      # @return [Boolean] true if skilled enough to tend, false otherwise.
      # @example
      #   if skilled_to_tend_wound?('light')
      #     puts 'You can tend this wound.'
      #   end
      def skilled_to_tend_wound?(bleed_rate, internal = false)
        skill_target = internal ? :skill_to_tend_internal : :skill_to_tend
        min_skill = $DRCH_BLEED_RATE_TO_SEVERITY_MAP[bleed_rate][skill_target]
        return false if min_skill.nil?

        DRSkill.getrank('First Aid') >= min_skill
      end

      # Compute a weighted summary score from a wound list.
      # Commonly used for thresholding for healing activities
      # Computes a weighted summary score from a list of wounds.
      # @param wounds_by_severity [Hash] A hash of wounds categorized by severity.
      # @return [Integer] The calculated score based on the wounds.
      # @example
      #   score = calculate_score(wounds)
      #   puts 'Total score: #{score}'
      def calculate_score(wounds_by_severity)
        wounds_by_severity.map { |severity, wound_list| (severity**2) * wound_list.count }.reduce(:+) || 0
      end

      # Represents a wound on a character's body.
      # @example
      #   wound = Wound.new(body_part: 'left arm', severity: 2)
      class Wound
        attr_accessor :body_part, :severity, :bleeding_rate

        # The part of the body that's wounded, like 'left hand' or 'abdomen'.
        # At this time, at what rate is the wound bleeding, like 'light' or 'moderate(tended)'.
        # Initializes a new Wound object.
        # @param body_part [String] The part of the body that's wounded.
        # @param severity [Integer] The severity of the wound.
        # @param bleeding_rate [String] The rate at which the wound is bleeding.
        # @param is_internal [Boolean] Indicates if the wound is internal.
        # @param is_scar [Boolean] Indicates if the wound is a scar.
        # @param is_parasite [Boolean] Indicates if the wound is a parasite.
        # @param is_lodged_item [Boolean] Indicates if the wound is a lodged item.
        # @return [Wound] The initialized Wound object.
        def initialize(
          body_part: nil,
          severity: nil,

          bleeding_rate: nil,
          is_internal: false,
          is_scar: false,
          is_parasite: false,
          is_lodged_item: false
        )
          @body_part = body_part.nil? ? nil : body_part.downcase
          @severity = severity
          @bleeding_rate = bleeding_rate.nil? ? nil : bleeding_rate.downcase
          @is_internal = !!is_internal
          @is_scar = !!is_scar
          @is_parasite = !!is_parasite
          @is_lodged_item = !!is_lodged_item
        end

        # Checks if the wound is currently bleeding.
        # @return [Boolean] true if the wound is bleeding, false otherwise.
        def bleeding?
          return !@bleeding_rate.nil? && !@bleeding_rate.empty? && @bleeding_rate != '(tended)'
        end

        # Checks if the wound is internal.
        # @return [Boolean] true if the wound is internal, false otherwise.
        def internal?
          return @is_internal
        end

        # Checks if the wound is a scar.
        # @return [Boolean] true if the wound is a scar, false otherwise.
        def scar?
          return @is_scar
        end

        # Checks if the wound is a parasite.
        # @return [Boolean] true if the wound is a parasite, false otherwise.
        def parasite?
          return @is_parasite
        end

        # Checks if the wound is a lodged item.
        # @return [Boolean] true if the wound is a lodged item, false otherwise.
        def lodged?
          return @is_lodged_item
        end

        # Checks if the wound can be tended to.
        # @return [Boolean] true if the wound is tendable, false otherwise.
        def tendable?
          return true if parasite?
          return true if lodged?
          return false if @body_part =~ /skin/
          return false if !bleeding?
          return false if @bleeding_rate =~ /tended|clotted/

          return DRCH.skilled_to_tend_wound?(@bleeding_rate, internal?)
        end

        # Returns the location type of the wound (internal or external).
        # @return [String] 'internal' or 'external'.
        def location
          internal? ? 'internal' : 'external'
        end

        # Returns the type of the wound (scar or wound).
        # @return [String] 'scar' or 'wound'.
        def type
          scar? ? 'scar' : 'wound'
        end
      end
    end
  end
end
