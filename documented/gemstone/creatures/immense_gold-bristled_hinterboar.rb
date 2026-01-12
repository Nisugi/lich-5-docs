# Represents an immense gold-bristled hinterboar
#
# This data structure contains various attributes of the immense gold-bristled hinterboar, including its level, family, type, attack and defense attributes, and messaging.
# @example Creating an immense gold-bristled hinterboar
#   hinterboar = {
#     name: "immense gold-bristled hinterboar",
#     level: 102,
#     family: "suine"
#   }
{
  # The name of the creature.
  name: "immense gold-bristled hinterboar",
  noun: "",
  # The URL for more information about the creature.
  url: "https://gswiki.play.net/Immense_gold-bristled_hinterboar",
  picture: "",
  # The level of the immense gold-bristled hinterboar.
  level: 102,
  # The family classification of the creature.
  family: "suine",
  # The type of the creature.
  type: "quadruped",
  undead: false,
  # Indicates if the creature is a boss.
  boss: false,
  otherclass: [],
  # The areas where the immense gold-bristled hinterboar can be found.
  areas: [
    { name: "Hinterwilds", rooms: [] }
  ],
  # Indicates if the creature has battle characteristics.
  bcs: true,
  # The maximum hit points of the creature.
  max_hp: 600,
  speed: nil,
  # The height of the immense gold-bristled hinterboar.
  height: 25,
  # The size classification of the creature.
  size: "huge",
  attack_attributes: {
    # The physical attacks available to the immense gold-bristled hinterboar.
    physical_attacks: [
      {
        # The name of the physical attack.
        name: "stomp",
        as: (515..529)
      },
      {
        # The name of the physical attack.
        name: "impale",
        as: (509..523)
      },
      {
        # The name of the physical attack.
        name: "charge (attack)",
        as: (529)
      }
    ],
    bolt_spells: [],
    warding_spells: [],
    offensive_spells: [],
    # The maneuvers available to the immense gold-bristled hinterboar.
    maneuvers: [
      {
        # The name of the maneuver.
        name: "boarrush"
      },
      {
        # The name of the maneuver.
        name: "feint"
      }
    ],
    special_abilities: [],
    special_notes: []
  },
  # The defense attributes of the immense gold-bristled hinterboar.
  defense_attributes: {
    # The armor class of the creature.
    asg: "1",
    immunities: [],
    # The melee defense value.
    melee: (546),
    ranged: nil,
    # The bolt defense range.
    bolt: (451..460),
    udf: (582..584),
    # The bar type defense range.
    bar_td: (402..409),
    cle_td: nil,
    # The emp type defense value.
    emp_td: (404),
    pal_td: nil,
    # The ranged type defense value.
    ran_td: (360),
    sor_td: (431),
    # The wizard type defense value.
    wiz_td: nil,
    mje_td: nil,
    # The mental type defense range.
    mne_td: (454..467),
    mjs_td: (405),
    mns_td: nil,
    mnm_td: nil,
    defensive_spells: [],
    defensive_abilities: [],
    special_defenses: []
  },
  # Any special attributes not covered elsewhere.
  special_other: "",
  abilities: [],
  alchemy: [],
  # The treasure attributes of the immense gold-bristled hinterboar.
  treasure: {
    coins: nil,
    magic_items: nil,
    gems: nil,
    boxes: nil,
    # The skin type of the creature.
    skin: "golden hinterboar mane",
    other: nil,
    blunt_required: false
  },
  # The messaging attributes for the immense gold-bristled hinterboar.
  messaging: {
    # A description of the immense gold-bristled hinterboar.
    description: "Squinty eyes the color of molten copper dart here and there as if the immense boar is always on the alert for predators, but given its tremendous mass, it likely has little cause for worry.  The hinterboar's pelt is a glittering, metallic golden in hue, but is shot through with a hypnotic pattern of duskier bristles.  The line of raised bristles down the center of the beast's spine seems to radiate faint luminescence, warm and honey-hued.",
    arrival: [
      "Heavy hoofbeats herald the arrival of an immense gold-bristled hinterboar.",
      "An immense gold-bristled hinterboar trots in with its tusks lifted skyward.  Its great hooves shake the ground with every step."
    ],
    # The messaging when the creature flees.
    flee: "An immense gold-bristled hinterboar charges {direction}, shaking the ground with each hoofbeat.",
    # The messaging when the creature dies.
    death: "With a final discordant squeal, an immense gold-bristled hinterboar's great head sinks to the ground as its form goes still.",
    # The messaging when the creature decays.
    decay: "An immense gold-bristled hinterboar's form succumbs to decay, collapsing into ruined meat and patchy bristles.",
    search: [
      "An immense gold-bristled hinterboar puts its snout to the ground and snuffles for unseen prey.",
      "An immense gold-bristled hinterboar snuffles at the ground, trying to ferret out hidden threats."
    ],
    # The messaging when the creature charges.
    charge: "Lowering its head, an immense gold-bristled hinterboar barrels into a merciless charge at you!",
    # The messaging for the boarrush maneuver.
    boarrush: "An immense gold-bristled hinterboar scrapes the ground with one forehoof before lowering its huge head.  It barrels into a mighty charge, hooves pounding across the ground as it races toward you.",
    # The messaging for the impale attack.
    impale: "Murder in its eyes, an immense gold-bristled hinterboar tries to gore you with its tusks!",
    # The messaging for the feint maneuver.
    feint: "An immense gold-bristled hinterboar feints low.",
    # The messaging for the stomp attack.
    stomp: "Rearing up on its hind legs, an immense gold-bristled hinterboar stomps at you with its huge hooves!"
  }
}

=begin
description, arrival, flee, death, decay, search, spell_prep, creature specific

  An immense gold-bristled hinterboar puts its snout to the ground and snuffles for unseen prey.
  An immense gold-bristled hinterboar snuffles at the ground, trying to ferret out hidden threats.

  An immense gold-bristled hinterboar charges west, shaking the ground with each hoofbeat.

=end
