class InsectDetail {
  final String commonName;
  final String scientificName;
  final String description;
  final List<String> tags;
  final String dangerLevel;
  final String size;
  final String habitat;
  final String behavior;

  const InsectDetail({
    required this.commonName,
    required this.scientificName,
    required this.description,
    required this.tags,
    required this.dangerLevel,
    required this.size,
    required this.habitat,
    required this.behavior,
  });
}

// Mock Data
final Map<String, InsectDetail> insectDetails = {
  'Butterfly': InsectDetail(
    commonName: 'Butterfly',
    scientificName: 'Lepidoptera',
    description:
        'Butterflies are insects in the macrilepidopteran clade Rhopalocera from the order Lepidoptera, which also includes moths. They are known for their large, often brightly coloured wings and distinct fluttering flight.',
    tags: ['POLLINATOR', 'MIGRATORY', 'DIURNAL'],
    dangerLevel: 'Harmless',
    size: 'Varies (1 - 30 cm)',
    habitat: 'Worldwide (except Antarctica)',
    behavior:
        'Butterflies feed primarily on nectar from flowers which they sip with their proboscis. They are important pollinators.',
  ),
  'Grasshopper': InsectDetail(
    commonName: 'Grasshopper',
    scientificName: 'Caelifera',
    description:
        'Grasshoppers are a group of insects belonging to the suborder Caelifera. They are typically ground-dwelling insects with powerful hind legs which allow them to escape from threats by leaping vigorously.',
    tags: ['HERBIVORE', 'JUMPING', 'DIURNAL'],
    dangerLevel: 'Harmless',
    size: '1 - 7 cm',
    habitat: 'Grasslands, meadows, pastures',
    behavior:
        'Most are herbivorous, feeding on grasses and leaves. Some species can form swarms and become serious pests (locusts).',
  ),
  'Ladybug': InsectDetail(
    commonName: 'Ladybug',
    scientificName: 'Coccinellidae',
    description:
        'Coccinellidae is a widespread family of small beetles. They are commonly yellow, orange, or red with small black spots on their wing covers, with black legs, heads and antennae.',
    tags: ['BENEFICIAL', 'PREDATOR', 'DIURNAL'],
    dangerLevel: 'Harmless',
    size: '0.8 - 1.8 mm',
    habitat: 'Gardens, agricultural fields',
    behavior:
        'Most ladybugs are beneficial predators that eat aphids and other scale insects, making them popular biological control agents.',
  ),
  'Wasp': InsectDetail(
    commonName: 'Wasp',
    scientificName: 'Hymenoptera (Apocrita)',
    description:
        'Wasps are insects of the order Hymenoptera and suborder Apocrita that is neither a bee nor an ant. There are solitary and social wasps.',
    tags: ['PREDATOR', 'AGGRESSIVE', 'DIURNAL'],
    dangerLevel: 'Stinging',
    size: 'Varies (0.1 - 5 cm)',
    habitat: 'Nests in soil, wood, or paper nests',
    behavior:
        'Many wasps are predatory or parasitic. Social wasps defend their nests aggressively and can sting repeatedly.',
  ),
  'Bee': InsectDetail(
    commonName: 'Bee',
    scientificName: 'Anthophila',
    description:
        'Bees are flying insects closely related to wasps and ants, known for their role in pollination and producing honey and beeswax.',
    tags: ['POLLINATOR', 'SOCIAL', 'BENEFICIAL'],
    dangerLevel: 'Stinging',
    size: '0.2 - 4 cm',
    habitat: 'Gardens, meadows, forests',
    behavior:
        'Bees feed on nectar and pollen. Many are social insects living in colonies with a queen, while others are solitary.',
  ),
  'Beetle': InsectDetail(
    commonName: 'Beetle',
    scientificName: 'Coleoptera',
    description:
        'Beetles are a group of insects that form the order Coleoptera. Their front pair of wings is hardened into wing-cases, elytra, distinguishing them from most other insects. They are the most diverse group of animals.',
    tags: ['DECOMPOSER', 'NOCTURNAL', 'ARMORED'],
    dangerLevel: 'Harmless',
    size: 'Microscopic to 17 cm',
    habitat: 'Almost every habitat on Earth',
    behavior:
        'Beetles have diverse diets including plants, other insects, carrion, and fungi. They undergo complete metamorphosis.',
  ),
  'Dragonfly': InsectDetail(
    commonName: 'Dragonfly',
    scientificName: 'Odonata (Anisoptera)',
    description:
        'A dragonfly is an insect belonging to the order Odonata. Adult dragonflies are characterized by large, multifaceted eyes, two pairs of strong, transparent wings, and an elongated body.',
    tags: ['PREDATOR', 'AQUATIC NYMPH', 'FAST FLIER'],
    dangerLevel: 'Harmless',
    size: '2 - 15 cm',
    habitat: 'Near water bodies (wetlands, lakes)',
    behavior:
        'Dragonflies are agile fliers and voracious predators, catching mosquitoes and other small insects mid-air.',
  ),
  'Spider': InsectDetail(
    commonName: 'Spider',
    scientificName: 'Araneae',
    description:
        'Spiders are air-breathing arthropods that have eight legs, chelicerae with fangs generally able to inject venom, and spinnerets that extrude silk. They are the largest order of arachnids.',
    tags: ['PREDATOR', 'WEB WEAVER', 'NOCTURNAL'],
    dangerLevel: 'Mild Venom',
    size: '0.37 mm - 90 mm',
    habitat: 'Worldwide',
    behavior:
        'All spiders are predators, mostly feeding on insects. Many build webs to trap prey, while others are active hunters.',
  ),
  'Mosquito': InsectDetail(
    commonName: 'Mosquito',
    scientificName: 'Culicidae',
    description:
        'Mosquitoes are a group of fly-like nuisance insects in the family Culicidae. They have a slender segmented body, one pair of wings, one pair of halteres, three pairs of long hair-like legs, and elongated mouthparts.',
    tags: ['PARASITE', 'DISEASE VECTOR', 'CREPUSCULAR'],
    dangerLevel: 'Disease Vector',
    size: '3 - 6 mm',
    habitat: 'Near stagnant water',
    behavior:
        'Females of most species pierce the hosts\' skin to consume blood, which is needed for egg production. They are vectors for many diseases.',
  ),
  'Fly': InsectDetail(
    commonName: 'Fly',
    scientificName: 'Diptera',
    description:
        'True flies are insects of the order Diptera, possessing a single pair of wings on the mesothorax and a pair of halteres, derived from the hind wings, on the metathorax.',
    tags: ['SCAVENGER', 'PEST', 'DIURNAL'],
    dangerLevel: 'Disease Vector',
    size: 'Varies',
    habitat: 'Worldwide',
    behavior:
        'Flies have a liquid diet. They are important pollinators and decomposers, though some are pests or disease vectors.',
  ),
};
