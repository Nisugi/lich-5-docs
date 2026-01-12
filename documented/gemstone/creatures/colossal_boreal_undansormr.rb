{
  # The name of the creature.
  name: "Colossal boreal undansormr",
  noun: "",
  # The URL for more information about the creature.
  url: "https://gswiki.play.net/Colossal_boreal_undansormr",
  picture: "",
  # The level of the creature.
  level: 111,
  # The family classification of the creature.
  family: "Worm",
  # The type classification of the creature.
  type: "Worm",
  # Indicates if the creature is undead.
  undead: false,
  # Indicates if the creature is a boss.
  boss: false,
  otherclass: [],
  # The areas where the creature can be found.
  areas: [
    # An area where the creature can be found.
    { name: "Hinterwilds", rooms: [] }
  ],
  # Indicates if the creature has a battle class.
  bcs: true,
  max_hp: nil,
  speed: nil,
  height: nil,
  size: nil,
  # The attack attributes of the creature.
  attack_attributes: {
    # The physical attacks available to the creature.
    physical_attacks: [
      # A physical attack.
      {
        name: "",
        # The attack strength of the physical attack.
        as: "AS"
      }
    ],
    bolt_spells: [],
    warding_spells: [],
    offensive_spells: [],
    maneuvers: [],
    special_abilities: [],
    special_notes: []
  },
  # The defense attributes of the creature.
  defense_attributes: {
    # The armor class of the creature.
    asg: nil,
    # The immunities of the creature.
    immunities: [],
    melee: nil,
    ranged: nil,
    bolt: nil,
    udf: nil,
    # The bar type damage threshold.
    bar_td: "460",
    cle_td: nil,
    # The emp type damage threshold.
    emp_td: "488..519",
    pal_td: nil,
    ran_td: nil,
    sor_td: nil,
    wiz_td: nil,
    # The magic evasion type damage threshold.
    mje_td: "557..572",
    mne_td: nil,
    mjs_td: nil,
    mns_td: nil,
    mnm_td: nil,
    defensive_spells: [],
    defensive_abilities: [],
    special_defenses: []
  },
  special_other: "",
  abilities: [],
  alchemy: [],
  # The treasure dropped by the creature.
  treasure: {
    # The amount of coins dropped.
    coins: nil,
    magic_items: nil,
    gems: nil,
    boxes: nil,
    skin: nil,
    other: nil,
    blunt_required: false
  },
  # Messaging related to the creature.
  messaging: {
    general_advice: "* Undansormrs have great amounts of health, pretty high [[DS]], exceptional [[TD]], decent [[Standard maneuver roll|maneuver]] defense by virtue of their high level if nothing else, immunity to being knocked prone, and no limbs to get rid of to make them less effective. However, [[Brawling|unarmed combat]] can kill undansormrs reasonably effectively with focused mstrikes, [[Fury]], or stray tiered-up shots to the head (one of the only body parts this worm-like creature does have). Even a [[pure]] (with trained Brawling and [[Combat Maneuvers]]) can make unarmed combat work against them with minor setup of stunning the undansormr first to increase MM and more than overcome the UAF vs. UDF gap."
  }
}
