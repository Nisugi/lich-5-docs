# Represents the withered shadow-cloaked draugr
# @example Creating a draugr
#   draugr = { name: "Withered shadow-cloaked draugr", level: 108 }
{
  # The name of the draugr
  name: "Withered shadow-cloaked draugr",
  noun: "",
  # The URL for more information about the draugr
  url: "https://gswiki.play.net/Withered_shadow-cloaked_draugr",
  picture: "",
  # The level of the draugr
  level: 108,
  # The family classification of the draugr
  family: "Gigas",
  # The type classification of the draugr
  type: "Biped",
  # Indicates if the draugr is undead
  undead: true,
  # Indicates if the draugr is a boss
  boss: false,
  # Other classifications for the draugr
  otherclass: [
    # Indicates the draugr is a corporeal undead
    "Corporeal undead"
  ],
  # Areas where the draugr can be found
  areas: [
    # The Hinterwilds area where the draugr appears
    { name: "Hinterwilds", rooms: [] }
  ],
  # Indicates if the draugr has a battle cry
  bcs: true,
  max_hp: nil,
  speed: nil,
  # The height of the draugr in inches
  height: 30,
  # The size classification of the draugr
  size: "huge",
  # Attributes related to the draugr's attacks
  attack_attributes: {
    # List of physical attacks the draugr can perform
    physical_attacks: [
      {
        # The name of the physical attack
        name: "greatsword",
        # The attack strength of the greatsword
        as: "592"
      }
    ],
    bolt_spells: [],
    warding_spells: [],
    offensive_spells: [],
    maneuvers: [],
    special_abilities: [],
    special_notes: []
  },
  # Attributes related to the draugr's defenses
  defense_attributes: {
    # The armor strength of the draugr
    asg: "7",
    immunities: [],
    melee: nil,
    ranged: nil,
    bolt: nil,
    udf: nil,
    bar_td: nil,
    cle_td: nil,
    emp_td: nil,
    pal_td: nil,
    ran_td: nil,
    sor_td: nil,
    wiz_td: nil,
    mje_td: nil,
    mne_td: nil,
    mjs_td: nil,
    mns_td: nil,
    mnm_td: nil,
    defensive_spells: [],
    defensive_abilities: [],
    special_defenses: []
  },
  # Any special attributes not covered elsewhere
  special_other: "",
  # List of abilities the draugr has
  abilities: [],
  alchemy: [],
  # Treasure dropped by the draugr
  treasure: {
    # The amount of coins dropped
    coins: nil,
    # The magic items dropped
    magic_items: nil,
    # The gems dropped
    gems: nil,
    # The boxes dropped
    boxes: nil,
    # The skin dropped
    skin: nil,
    # Any other items dropped
    other: nil,
    # Indicates if blunt weapons are required to defeat the draugr
    blunt_required: false
  },
  # Messaging related to the draugr
  messaging: {
    description: "Utterly immense, the draugr's humanoid shape is comprised wholly of inky shadows that drip and pool at its intangible feet.  Cruel eyes of frigid light glare from a face of sharp lines and malevolent angles.  The shade's arms are lightless and devoid of all but the most rudimentary features, but are massively thick and traced with intricate lines of blazing blue radiance.",
    general_advice: "* Taking out a draugr's greatsword and leaving them swinging a closed fist is as close to taking out the draugr as can be short of actually killing it, so [[Disarm Weapon]], [[Vibration Chant (1002)]], or even [[Limb Disruption (708)]] work great here. DoT spells like [[Condemn (309)]] and [[Earthen Fury (917)]] are liable to also sever an arm by sheer probability given enough rounds of going off.\n* In lieu of killing a draugr or getting rid of its weapon, another strong option is taking out its legs or inflicting [[Rooted]] since draugrs rely heavily on high [[attack strength|AS]] or maneuvers to be effective. [[Hamstring]] (despite [[Major Bleed]] not affecting [[undead]]), [[Cripple]], [[Pin Down]], and other options can do the trick.\n* In lieu of any of the above, draugrs are also [[square]] enemies in light armor, so low [[TD]] and low [[CvA]] leaves them pretty vulnerable to most [[CS]]-based attacks despite their high level."
  }
}
