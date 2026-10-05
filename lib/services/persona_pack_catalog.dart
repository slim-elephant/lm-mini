/// Built-in 3D persona avatar pack shipped under assets/images/persona_pack/.
class PersonaPackEntry {
  final String id;
  final String assetPath;
  final String label;
  /// `male` or `female` — drives default Kokoro voice.
  final String gender;
  final List<String> tags;

  const PersonaPackEntry({
    required this.id,
    required this.assetPath,
    required this.label,
    required this.gender,
    required this.tags,
  });
}

class PersonaPackCatalog {
  PersonaPackCatalog._();

  static const assetDir = 'assets/images/persona_pack';

  static String assetFor(String id) => '$assetDir/$id.webp';

  static const List<PersonaPackEntry> entries = [
    PersonaPackEntry(
      id: 'astronaut_3d',
      assetPath: '$assetDir/astronaut_3d.webp',
      label: 'Astronaut',
      gender: 'male',
      tags: ['astronaut', 'space', 'scientist', 'explorer'],
    ),
    PersonaPackEntry(
      id: 'chef_3d',
      assetPath: '$assetDir/chef_3d.webp',
      label: 'Chef',
      gender: 'male',
      tags: ['chef', 'cook', 'food', 'kitchen'],
    ),
    PersonaPackEntry(
      id: 'cleric_3d',
      assetPath: '$assetDir/cleric_3d.webp',
      label: 'Cleric',
      gender: 'male',
      tags: ['cleric', 'priest', 'healer', 'fantasy', 'holy'],
    ),
    PersonaPackEntry(
      id: 'courier_3d',
      assetPath: '$assetDir/courier_3d.webp',
      label: 'Courier',
      gender: 'male',
      tags: ['courier', 'delivery', 'messenger', 'bike'],
    ),
    PersonaPackEntry(
      id: 'cowboy_3d',
      assetPath: '$assetDir/cowboy_3d.webp',
      label: 'Cowboy',
      gender: 'male',
      tags: ['cowboy', 'western', 'ranch', 'sheriff'],
    ),
    PersonaPackEntry(
      id: 'customer_service_3d',
      assetPath: '$assetDir/customer_service_3d.webp',
      label: 'Customer Service',
      gender: 'female',
      tags: ['support', 'customer', 'helpdesk', 'service', 'assistant'],
    ),
    PersonaPackEntry(
      id: 'devil_3d',
      assetPath: '$assetDir/devil_3d.webp',
      label: 'Devil',
      gender: 'male',
      tags: ['devil', 'demon', 'dark', 'fantasy', 'villain'],
    ),
    PersonaPackEntry(
      id: 'doctor_3d',
      assetPath: '$assetDir/doctor_3d.webp',
      label: 'Doctor',
      gender: 'male',
      tags: ['doctor', 'medic', 'physician', 'health'],
    ),
    PersonaPackEntry(
      id: 'dracula',
      assetPath: '$assetDir/dracula.webp',
      label: 'Dracula',
      gender: 'male',
      tags: ['dracula', 'vampire', 'gothic', 'horror'],
    ),
    PersonaPackEntry(
      id: 'elf_3d',
      assetPath: '$assetDir/elf_3d.webp',
      label: 'Elf',
      gender: 'female',
      tags: ['elf', 'fantasy', 'forest', 'archer', 'magic'],
    ),
    PersonaPackEntry(
      id: 'farmer_3d',
      assetPath: '$assetDir/farmer_3d.webp',
      label: 'Farmer',
      gender: 'male',
      tags: ['farmer', 'rural', 'agriculture', 'garden'],
    ),
    PersonaPackEntry(
      id: 'faun_3d',
      assetPath: '$assetDir/faun_3d.webp',
      label: 'Faun',
      gender: 'male',
      tags: ['faun', 'satyr', 'myth', 'nature', 'fantasy'],
    ),
    PersonaPackEntry(
      id: 'firefighter_3d',
      assetPath: '$assetDir/firefighter_3d.webp',
      label: 'Firefighter',
      gender: 'male',
      tags: ['firefighter', 'rescue', 'hero', 'emergency'],
    ),
    PersonaPackEntry(
      id: 'grim_reaper_3d',
      assetPath: '$assetDir/grim_reaper_3d.webp',
      label: 'Grim Reaper',
      gender: 'male',
      tags: ['reaper', 'death', 'skeleton', 'dark', 'gothic'],
    ),
    PersonaPackEntry(
      id: 'judge_3d',
      assetPath: '$assetDir/judge_3d.webp',
      label: 'Judge',
      gender: 'male',
      tags: ['judge', 'law', 'court', 'justice'],
    ),
    PersonaPackEntry(
      id: 'king_3d',
      assetPath: '$assetDir/king_3d.webp',
      label: 'King',
      gender: 'male',
      tags: ['king', 'royalty', 'crown', 'ruler'],
    ),
    PersonaPackEntry(
      id: 'manager_3d',
      assetPath: '$assetDir/manager_3d.webp',
      label: 'Manager',
      gender: 'male',
      tags: ['manager', 'business', 'boss', 'office', 'executive'],
    ),
    PersonaPackEntry(
      id: 'mask_3d',
      assetPath: '$assetDir/mask_3d.webp',
      label: 'Masked Figure',
      gender: 'male',
      tags: ['mask', 'mysterious', 'secret', 'spy', 'phantom'],
    ),
    PersonaPackEntry(
      id: 'mechanic_3d',
      assetPath: '$assetDir/mechanic_3d.webp',
      label: 'Mechanic',
      gender: 'male',
      tags: ['mechanic', 'engineer', 'tools', 'cars', 'repair'],
    ),
    PersonaPackEntry(
      id: 'monk_3d',
      assetPath: '$assetDir/monk_3d.webp',
      label: 'Monk',
      gender: 'male',
      tags: ['monk', 'zen', 'meditation', 'martial', 'wisdom'],
    ),
    PersonaPackEntry(
      id: 'ninja_3d',
      assetPath: '$assetDir/ninja_3d.webp',
      label: 'Ninja',
      gender: 'male',
      tags: ['ninja', 'assassin', 'stealth', 'japan', 'warrior'],
    ),
    PersonaPackEntry(
      id: 'ogre_3d',
      assetPath: '$assetDir/ogre_3d.webp',
      label: 'Ogre',
      gender: 'male',
      tags: ['ogre', 'monster', 'fantasy', 'brute'],
    ),
    PersonaPackEntry(
      id: 'ogre_warrior_3d',
      assetPath: '$assetDir/ogre_warrior_3d.webp',
      label: 'Ogre Warrior',
      gender: 'male',
      tags: ['ogre', 'warrior', 'fantasy', 'fighter', 'battle'],
    ),
    PersonaPackEntry(
      id: 'paramedic_3d',
      assetPath: '$assetDir/paramedic_3d.webp',
      label: 'Paramedic',
      gender: 'male',
      tags: ['paramedic', 'emt', 'ambulance', 'rescue', 'medic'],
    ),
    PersonaPackEntry(
      id: 'pilot_3d',
      assetPath: '$assetDir/pilot_3d.webp',
      label: 'Pilot',
      gender: 'male',
      tags: ['pilot', 'aviator', 'plane', 'airline', 'captain'],
    ),
    PersonaPackEntry(
      id: 'pirates_3d',
      assetPath: '$assetDir/pirates_3d.webp',
      label: 'Pirate',
      gender: 'male',
      tags: ['pirate', 'sea', 'captain', 'adventure'],
    ),
    PersonaPackEntry(
      id: 'police_3d',
      assetPath: '$assetDir/police_3d.webp',
      label: 'Police Officer',
      gender: 'male',
      tags: ['police', 'cop', 'officer', 'law'],
    ),
    PersonaPackEntry(
      id: 'referee_3d',
      assetPath: '$assetDir/referee_3d.webp',
      label: 'Referee',
      gender: 'male',
      tags: ['referee', 'sports', 'umpire', 'coach'],
    ),
    PersonaPackEntry(
      id: 'samurai_3d',
      assetPath: '$assetDir/samurai_3d.webp',
      label: 'Samurai',
      gender: 'male',
      tags: ['samurai', 'warrior', 'japan', 'katana', 'honor'],
    ),
    PersonaPackEntry(
      id: 'skull_warrior_3d',
      assetPath: '$assetDir/skull_warrior_3d.webp',
      label: 'Skull Warrior',
      gender: 'male',
      tags: ['skull', 'undead', 'warrior', 'dark', 'fantasy'],
    ),
    PersonaPackEntry(
      id: 'soldier_3d',
      assetPath: '$assetDir/soldier_3d.webp',
      label: 'Soldier',
      gender: 'male',
      tags: ['soldier', 'military', 'army', 'combat'],
    ),
    PersonaPackEntry(
      id: 'spartan_3d',
      assetPath: '$assetDir/spartan_3d.webp',
      label: 'Spartan',
      gender: 'male',
      tags: ['spartan', 'warrior', 'greek', 'shield', 'ancient'],
    ),
    PersonaPackEntry(
      id: 'stewardess_3d',
      assetPath: '$assetDir/stewardess_3d.webp',
      label: 'Flight Attendant',
      gender: 'female',
      tags: ['stewardess', 'flight', 'attendant', 'airline', 'travel'],
    ),
    PersonaPackEntry(
      id: 'super_hero_3d',
      assetPath: '$assetDir/super_hero_3d.webp',
      label: 'Super Hero',
      gender: 'male',
      tags: ['superhero', 'hero', 'comic', 'cape', 'power'],
    ),
    PersonaPackEntry(
      id: 'taxi_driver_3d',
      assetPath: '$assetDir/taxi_driver_3d.webp',
      label: 'Taxi Driver',
      gender: 'male',
      tags: ['taxi', 'driver', 'cab', 'city'],
    ),
    PersonaPackEntry(
      id: 'teacher_3d',
      assetPath: '$assetDir/teacher_3d.webp',
      label: 'Teacher',
      gender: 'female',
      tags: ['teacher', 'tutor', 'school', 'professor', 'educator'],
    ),
    PersonaPackEntry(
      id: 'thief_3d',
      assetPath: '$assetDir/thief_3d.webp',
      label: 'Thief',
      gender: 'male',
      tags: ['thief', 'rogue', 'burglar', 'sneak', 'fantasy'],
    ),
    PersonaPackEntry(
      id: 'viking_3d',
      assetPath: '$assetDir/viking_3d.webp',
      label: 'Viking',
      gender: 'male',
      tags: ['viking', 'norse', 'warrior', 'raider'],
    ),
    PersonaPackEntry(
      id: 'waiter_3d',
      assetPath: '$assetDir/waiter_3d.webp',
      label: 'Waiter',
      gender: 'male',
      tags: ['waiter', 'server', 'restaurant', 'hospitality'],
    ),
    PersonaPackEntry(
      id: 'wizard_3d',
      assetPath: '$assetDir/wizard_3d.webp',
      label: 'Wizard',
      gender: 'male',
      tags: ['wizard', 'mage', 'magic', 'sorcerer', 'fantasy'],
    ),
  ];

  static PersonaPackEntry? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Best-effort match when the model returns an unknown avatarId.
  static PersonaPackEntry matchFromText(String text, {String? preferredGender}) {
    final lower = text.toLowerCase();
    PersonaPackEntry? best;
    var bestScore = 0;
    for (final e in entries) {
      var score = 0;
      if (lower.contains(e.label.toLowerCase())) score += 5;
      for (final tag in e.tags) {
        if (lower.contains(tag)) score += 2;
      }
      if (preferredGender != null && e.gender == preferredGender) {
        score += 1;
      }
      if (score > bestScore) {
        bestScore = score;
        best = e;
      }
    }
    return best ?? entries.first;
  }

  static String catalogForPrompt() {
    final buf = StringBuffer();
    for (final e in entries) {
      buf.writeln(
        '- id=${e.id} | label=${e.label} | gender=${e.gender} | '
        'tags=${e.tags.join(",")}',
      );
    }
    return buf.toString();
  }
}
