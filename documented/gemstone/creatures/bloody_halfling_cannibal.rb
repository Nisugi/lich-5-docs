# Represents a bloody halfling cannibal in the game.
# @example
#   bloody_halfling_cannibal = {
#     name: "bloody halfling cannibal"
#   }
{
  # The name of the creature.
  # @return [String] The name of the bloody halfling cannibal.
  name: "bloody halfling cannibal",
  noun: "",
  # The URL for more information about the creature.
  # @return [String] The URL of the bloody halfling cannibal.
  url: "https://gswiki.play.net/Bloody_halfling_cannibal",
  picture: "",
  # The level of the creature.
  # @return [Integer] The level of the bloody halfling cannibal.
  level: 101,
  # The family classification of the creature.
  # @return [String] The family of the bloody halfling cannibal.
  family: "humanoid",
  # The type classification of the creature.
  # @return [String] The type of the bloody halfling cannibal.
  type: "biped",
  undead: false,
  # Indicates if the creature is a boss.
  # @return [Boolean] Whether the bloody halfling cannibal is a boss.
  boss: false,
  otherclass: [],
  areas: [
    { name: "Hinterwilds", rooms: [] }
  ],
  # Indicates if the creature has a battle cry.
  # @return [Boolean] Whether the bloody halfling cannibal has a battle cry.
  bcs: true,
  # The maximum hit points of the creature.
  # @return [Integer] The maximum hit points of the bloody halfling cannibal.
  max_hp: 300,
  speed: nil,
  # The height of the creature in feet.
  # @return [Integer] The height of the bloody halfling cannibal.
  height: 3,
  # The size classification of the creature.
  # @return [String] The size of the bloody halfling cannibal.
  size: "small",
  # The attack attributes of the creature.
  attack_attributes: {
    # The list of physical attacks the creature can perform.
    physical_attacks: [
      {
        # The name of the physical attack.
        # @return [String] The name of the bite attack.
        name: "bite",
        # The attack strength of the physical attack.
        # @return [Range] The attack strength of the bite attack.
        as: 474
      },
      {
        name: "grimy little fists",
        as: (464..544)
      },
      {
        name: "hurtle",
        as: (327..564)
      },
      {
        name: "wiry arms",
        as: (464..544)
      }
    ],
    bolt_spells: [],
    warding_spells: [],
    offensive_spells: [],
    maneuvers: [
      {
        # The name of the maneuver.
        # @return [String] The name of the cannibalize maneuver.
        name: "cannibalize"
      }
    ],
    special_abilities: [
      {
        # The name of the special ability.
        # @return [String] The name of the hunger ability.
        name: "hunger",
        # The note associated with the special ability.
        # @return [String] The note for the hunger ability.
        note: "+80 AS"
      },
    ],
    special_notes: []
  },
  defense_attributes: {
    # The armor class of the creature.
    # @return [String] The armor class of the bloody halfling cannibal.
    asg: "12",
    immunities: [],
    melee: (379..383),
    ranged: (353..366),
    bolt: (353..366),
    udf: (586..805),
    bar_td: (364..379),
    cle_td: nil,
    emp_td: nil,
    pal_td: nil,
    ran_td: (335..350),
    sor_td: nil,
    wiz_td: nil,
    mje_td: nil,
    mne_td: 428,
    mjs_td: nil,
    mns_td: 381,
    mnm_td: nil,
    defensive_spells: [],
    defensive_abilities: [
      {
        name: "unstun",
        note: "able to break stuns"
      },
      {
        name: "vanish",
        note: "able to evade an attack by hiding in the shadows"
      }
    ],
    special_defenses: []
  },
  special_other: "",
  abilities: [],
  alchemy: [],
  # The treasure attributes of the creature.
  treasure: {
    # Indicates if the creature drops coins.
    # @return [Boolean] Whether the bloody halfling cannibal drops coins.
    coins: true,
    magic_items: nil,
    # Indicates if the creature drops gems.
    # @return [Boolean] Whether the bloody halfling cannibal drops gems.
    gems: true,
    # Indicates if the creature drops boxes.
    # @return [Boolean] Whether the bloody halfling cannibal drops boxes.
    boxes: true,
    skin: false,
    # Other items that the creature may drop.
    # @return [String] Other treasure dropped by the bloody halfling cannibal.
    other: "gigas artifact",
    blunt_required: false
  },
  messaging: {
    description: "A skim of dark, congealing blood slicks the features of the raw-boned halfling.  {pronoun} eyes are black as burnt coals and feverish with single-minded hunger, a hunger that has burnt away every last shred of fat from {pronoun} body and left behind only knotted sinew.  The cannibal's teeth are sharpened to jagged points, and from between them darts a tiny pink tongue that is constantly tasting the air.  {pronoun} wears tattered, weather-eaten remains of furs and homespun fabric.  They, too, are soaked red with blood.",
    # The messages displayed when the creature arrives.
    arrival: [
      "Accompanied by the fetid stench of old meat, a bloody halfling cannibal races into the area with a froth of bloody saliva on {pronoun} lips.",
      "You hear soft footfalls."
    ],
    # The messages displayed when the creature flees.
    flee: [
      "Licking {pronoun} lips ravenously, a bloody halfling cannibal creeps {direction}.",
      "You hear soft footfalls."
    ],
    # The message displayed when the creature dies.
    # @return [String] The death message of the bloody halfling cannibal.
    death: "A monstrous, too-wide smile spreads across the cannibal's face as {pronoun} collapses to the ground, dead.",
    # The message displayed when the creature decays.
    # @return [String] The decay message of the bloody halfling cannibal.
    decay: "A bloody halfling cannibal's body rots away, leaving only a small stain on the ground.",
    search: [
      "A bloody halfling cannibal sniffs at the air, {pronoun} eyes glinting as {pronoun} searches the shadows.",
      "a bloody halfling cannibal's eyes dart around, suspicion warring with hunger in {pronoun} beady eyes."
    ],
    hide: "A bloody halfling cannibal darts into the shadows.",
    vanish: "As you move to attack a bloody halfling cannibal, the cannibal shrinks away from you, baring sharpened teeth as {pronoun} darts into the shadows!",
    hunger: "A bloody halfling cannibal's eyes grow bloodshot with ravening hunger!",
    unstun: "A bloody halfling cannibal gurgles out an animalistic shriek of rage, {pronoun} eyes filling with bloody blackness as {pronoun} surges back into action!",
    cannibalize: "A bloody halfling cannibal falls into a lopsided crouch.  The muscles of {pronoun} hindquarters tense as {pronoun} springs toward you, sharpened teeth gnashing.",
    wiry_arms: [
      "A bloody halfling cannibal throws her wiry arms around you, fueled by panicked hunger!",
      "With an ululating shriek, a bloody halfling cannibal leaps from the shadows and throws {pronoun} wiry arms around you, fueled by panicked hunger!"
    ],
    hurtle: [
      "A bloody halfling cannibal hurtles at you, swinging wildly with a twisted obsidian dagger!",
      "With an ululating shriek, a bloody halfling cannibal leaps from the shadows and hurtles at you, swinging wildly with a twisted obsidian dagger!"
    ],
    bite: "A bloody halfling cannibal bares {pronoun} sharpened teeth as {pronoun} tries to bite into you!",
    grimy_little_fists: "A bloody halfling cannibal hammers blindly at you with grimy little fists!",
    general_advice: "* Despite being the lowest level creature in the [[Hinterwilds]], cannibals can't be underestimated or ignored, especially if the Boreal Forest has started filling up. Cannibals' namesake biting maneuver can be lethal if its [[standard maneuver roll]] gets a significant bonus from other creatures in the area stunning or otherwise disabling a character. Cannibals also take advantage of stealth, which means they can get stance pushdown from [[ambush]] mechanics in situations where you might never have seen them coming. As such, even in cases where relatively low-mana-cost AoE spells like [[Censure (316)]], [[Elemental Wave (410)]], or [[Grasp of the Grave (709)]] might seem unnecessary for the number of visible creatures, sometimes they can still be helpful in revealing the invisible threat of cannibals.",

  }
}
