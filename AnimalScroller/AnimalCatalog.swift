// AnimalCatalog.swift
//
// All animal categories and their curated species lists.
// Every title is a real Wikipedia article that has a species photo.
// Add/remove entries freely — fetchMainImage returns nil for any that
// don't have a usable photo, so bad entries are just silently skipped.

import Foundation

// MARK: - Animal Category

enum AnimalCategory: String, CaseIterable, Identifiable, Hashable {
    case mammals    = "Mammals"
    case birds      = "Birds"
    case reptiles   = "Reptiles"
    case amphibians = "Amphibians"
    case insects    = "Insects"
    case fish       = "Fish & Sharks"
    case oceanLife  = "Ocean Life"
    case arachnids  = "Arachnids"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .mammals:    return "pawprint.fill"
        case .birds:      return "bird.fill"
        case .reptiles:   return "tortoise.fill"
        case .amphibians: return "drop.fill"
        case .insects:    return "ant.fill"
        case .fish:       return "fish.fill"
        case .oceanLife:  return "water.waves"
        case .arachnids:  return "ant.circle.fill"
        }
    }

    // Returns (Wikipedia article title, display name) pairs.
    // Titles with disambiguation use the full article name (e.g. "Fossa (animal)"),
    // while the display name stays human-readable (e.g. "Fossa").
    var animals: [(title: String, name: String)] {
        switch self {
        case .mammals:    return mammalList
        case .birds:      return birdList
        case .reptiles:   return reptileList
        case .amphibians: return amphibianList
        case .insects:    return insectList
        case .fish:       return fishList
        case .oceanLife:  return oceanLifeList
        case .arachnids:  return arachnidList
        }
    }
}

// MARK: - Mammals

private let mammalList: [(title: String, name: String)] = [
    // Big cats
    ("Lion", "Lion"), ("Tiger", "Tiger"), ("Leopard", "Leopard"),
    ("Jaguar", "Jaguar"), ("Snow leopard", "Snow Leopard"), ("Cheetah", "Cheetah"),
    ("Cougar", "Cougar"), ("Clouded leopard", "Clouded Leopard"),
    ("Ocelot", "Ocelot"), ("Serval", "Serval"),
    // Small cats
    ("Caracal", "Caracal"), ("Eurasian lynx", "Eurasian Lynx"), ("Bobcat", "Bobcat"),
    ("Fishing cat", "Fishing Cat"), ("Pallas's cat", "Pallas's Cat"),
    // Canids
    ("African wild dog", "African Wild Dog"), ("Gray wolf", "Gray Wolf"),
    ("Red fox", "Red Fox"), ("Arctic fox", "Arctic Fox"), ("Fennec fox", "Fennec Fox"),
    ("Coyote", "Coyote"), ("Dhole", "Dhole"), ("Maned wolf", "Maned Wolf"),
    ("Black-backed jackal", "Black-Backed Jackal"),
    // Bears
    ("Brown bear", "Brown Bear"), ("American black bear", "American Black Bear"),
    ("Polar bear", "Polar Bear"), ("Giant panda", "Giant Panda"),
    ("Spectacled bear", "Spectacled Bear"), ("Sun bear", "Sun Bear"),
    ("Sloth bear", "Sloth Bear"),
    // Mustelids & relatives
    ("Giant otter", "Giant Otter"), ("Sea otter", "Sea Otter"),
    ("Honey badger", "Honey Badger"), ("Wolverine", "Wolverine"),
    ("Striped skunk", "Striped Skunk"),
    // Other carnivores
    ("Spotted hyena", "Spotted Hyena"), ("Fossa (animal)", "Fossa"),
    ("Binturong", "Binturong"), ("Coati", "Coati"), ("Meerkat", "Meerkat"),
    ("Red panda", "Red Panda"), ("Raccoon", "Raccoon"), ("Kinkajou", "Kinkajou"),
    // Primates
    ("Western gorilla", "Western Gorilla"), ("Chimpanzee", "Chimpanzee"),
    ("Bonobo", "Bonobo"), ("Bornean orangutan", "Orangutan"),
    ("Mandrill", "Mandrill"), ("Gelada", "Gelada"),
    ("Ring-tailed lemur", "Ring-Tailed Lemur"), ("Aye-aye", "Aye-Aye"),
    ("Pygmy slow loris", "Slow Loris"), ("Philippine tarsier", "Tarsier"),
    ("Proboscis monkey", "Proboscis Monkey"), ("Golden snub-nosed monkey", "Golden Snub-Nosed Monkey"),
    // Anteaters, sloths, armadillos
    ("Giant anteater", "Giant Anteater"), ("Silky anteater", "Silky Anteater"),
    ("Hoffmann's two-toed sloth", "Two-Toed Sloth"),
    ("Brown-throated sloth", "Three-Toed Sloth"),
    ("Nine-banded armadillo", "Armadillo"), ("Giant armadillo", "Giant Armadillo"),
    // Marine mammals
    ("Blue whale", "Blue Whale"), ("Humpback whale", "Humpback Whale"),
    ("Orca", "Orca"), ("Common bottlenose dolphin", "Bottlenose Dolphin"),
    ("Narwhal", "Narwhal"), ("Beluga whale", "Beluga Whale"),
    ("Sperm whale", "Sperm Whale"), ("Gray whale", "Gray Whale"),
    ("Amazon river dolphin", "Amazon River Dolphin"),
    ("West Indian manatee", "Manatee"), ("Dugong", "Dugong"),
    ("Walrus", "Walrus"), ("Leopard seal", "Leopard Seal"),
    ("Northern elephant seal", "Northern Elephant Seal"),
    ("California sea lion", "California Sea Lion"),
    // Ungulates
    ("Okapi", "Okapi"), ("Reticulated giraffe", "Giraffe"),
    ("Hippopotamus", "Hippopotamus"), ("Pygmy hippopotamus", "Pygmy Hippopotamus"),
    ("White rhinoceros", "White Rhinoceros"), ("Black rhinoceros", "Black Rhinoceros"),
    ("Indian rhinoceros", "Indian Rhinoceros"), ("Malayan tapir", "Malayan Tapir"),
    ("Plains zebra", "Plains Zebra"), ("Asian elephant", "Asian Elephant"),
    ("Moose", "Moose"), ("Reindeer", "Reindeer"),
    ("Springbok", "Springbok"), ("Gemsbok", "Gemsbok"),
    ("Musk ox", "Musk Ox"), ("Pronghorn", "Pronghorn"),
    ("Saiga antelope", "Saiga Antelope"), ("Iberian ibex", "Iberian Ibex"),
    ("African buffalo", "African Buffalo"), ("Warthog", "Warthog"),
    // Monotremes & marsupials
    ("Platypus", "Platypus"), ("Short-beaked echidna", "Echidna"),
    ("Quokka", "Quokka"), ("Red kangaroo", "Red Kangaroo"),
    ("Koala", "Koala"), ("Common wombat", "Wombat"),
    ("Tasmanian devil", "Tasmanian Devil"), ("Sugar glider", "Sugar Glider"),
    // Others
    ("Pangolin", "Pangolin"), ("North American porcupine", "Porcupine"),
    ("Capybara", "Capybara"), ("Naked mole-rat", "Naked Mole-Rat"),
]

// MARK: - Birds

private let birdList: [(title: String, name: String)] = [
    // Eagles & raptors
    ("Bald eagle", "Bald Eagle"), ("Golden eagle", "Golden Eagle"),
    ("Harpy eagle", "Harpy Eagle"), ("Philippine eagle", "Philippine Eagle"),
    ("Steller's sea eagle", "Steller's Sea Eagle"),
    ("Wedge-tailed eagle", "Wedge-Tailed Eagle"),
    ("Peregrine falcon", "Peregrine Falcon"), ("Gyrfalcon", "Gyrfalcon"),
    ("Secretary bird", "Secretary Bird"), ("Osprey", "Osprey"),
    ("Red-tailed hawk", "Red-Tailed Hawk"), ("Snail kite", "Snail Kite"),
    // Owls
    ("Snowy owl", "Snowy Owl"), ("Great horned owl", "Great Horned Owl"),
    ("Barn owl", "Barn Owl"), ("Eurasian eagle-owl", "Eurasian Eagle-Owl"),
    ("Burrowing owl", "Burrowing Owl"), ("Spectacled owl", "Spectacled Owl"),
    ("Blakiston's fish owl", "Blakiston's Fish Owl"),
    // Penguins
    ("Emperor penguin", "Emperor Penguin"), ("King penguin", "King Penguin"),
    ("Rockhopper penguin", "Rockhopper Penguin"),
    ("African penguin", "African Penguin"),
    ("Chinstrap penguin", "Chinstrap Penguin"), ("Little penguin", "Little Penguin"),
    ("Macaroni penguin", "Macaroni Penguin"),
    // Parrots
    ("Scarlet macaw", "Scarlet Macaw"), ("Hyacinth macaw", "Hyacinth Macaw"),
    ("Kakapo", "Kakapo"), ("Kea", "Kea"),
    ("Sulphur-crested cockatoo", "Sulphur-Crested Cockatoo"),
    ("Major Mitchell's cockatoo", "Major Mitchell's Cockatoo"),
    ("Blue-and-yellow macaw", "Blue-and-Yellow Macaw"),
    ("Eclectus parrot", "Eclectus Parrot"),
    // Flamingos, storks, ibis
    ("Greater flamingo", "Greater Flamingo"),
    ("Roseate spoonbill", "Roseate Spoonbill"),
    ("Shoebill", "Shoebill"), ("Marabou stork", "Marabou Stork"),
    ("Jabiru", "Jabiru"), ("Scarlet ibis", "Scarlet Ibis"),
    ("African sacred ibis", "African Sacred Ibis"),
    ("Great blue heron", "Great Blue Heron"),
    // Seabirds
    ("Atlantic puffin", "Atlantic Puffin"),
    ("Wandering albatross", "Wandering Albatross"),
    ("Blue-footed booby", "Blue-Footed Booby"),
    ("Magnificent frigatebird", "Magnificent Frigatebird"),
    ("Great white pelican", "Great White Pelican"),
    ("Brown pelican", "Brown Pelican"),
    // Toucans & kingfishers
    ("Keel-billed toucan", "Keel-Billed Toucan"), ("Toco toucan", "Toco Toucan"),
    ("Common kingfisher", "Common Kingfisher"),
    ("Laughing kookaburra", "Laughing Kookaburra"),
    ("Rainbow bee-eater", "Rainbow Bee-Eater"),
    ("European roller", "European Roller"),
    ("Hoopoe", "Hoopoe"),
    ("Lilac-breasted roller", "Lilac-Breasted Roller"),
    // Hummingbirds
    ("Ruby-throated hummingbird", "Ruby-Throated Hummingbird"),
    ("Bee hummingbird", "Bee Hummingbird"),
    ("Anna's hummingbird", "Anna's Hummingbird"),
    ("Sword-billed hummingbird", "Sword-Billed Hummingbird"),
    ("Rufous hummingbird", "Rufous Hummingbird"),
    // Cranes & large birds
    ("Red-crowned crane", "Red-Crowned Crane"),
    ("Sarus crane", "Sarus Crane"), ("Wattled crane", "Wattled Crane"),
    ("Andean condor", "Andean Condor"), ("California condor", "California Condor"),
    // Ratites
    ("Ostrich", "Ostrich"), ("Common emu", "Emu"), ("Cassowary", "Cassowary"),
    ("Common rhea", "Common Rhea"),
    // Colorful birds
    ("Resplendent quetzal", "Resplendent Quetzal"),
    ("Victoria crowned pigeon", "Victoria Crowned Pigeon"),
    ("Nicobar pigeon", "Nicobar Pigeon"),
    ("Indian peafowl", "Peacock"),
    ("Golden pheasant", "Golden Pheasant"),
    ("Mandarin duck", "Mandarin Duck"), ("Wood duck", "Wood Duck"),
    ("Mute swan", "Mute Swan"), ("Whooper swan", "Whooper Swan"),
    ("Raggiana bird-of-paradise", "Bird-of-Paradise"),
    ("Wilson's bird-of-paradise", "Wilson's Bird-of-Paradise"),
    ("Superb lyrebird", "Superb Lyrebird"),
    ("Satin bowerbird", "Satin Bowerbird"),
    // Woodpeckers & corvids
    ("Pileated woodpecker", "Pileated Woodpecker"),
    ("Great spotted woodpecker", "Great Spotted Woodpecker"),
    ("Common raven", "Common Raven"), ("Eurasian magpie", "Eurasian Magpie"),
    ("Blue jay", "Blue Jay"),
    // Finches & small birds
    ("Gouldian finch", "Gouldian Finch"), ("Atlantic canary", "Atlantic Canary"),
    ("Superb fairywren", "Superb Fairywren"),
    ("Scarlet tanager", "Scarlet Tanager"),
    ("Painted bunting", "Painted Bunting"),
    ("European bee-eater", "European Bee-Eater"),
    ("Cock-of-the-rock", "Cock-of-the-Rock"),
]

// MARK: - Reptiles

private let reptileList: [(title: String, name: String)] = [
    // Crocodilians
    ("Saltwater crocodile", "Saltwater Crocodile"),
    ("Nile crocodile", "Nile Crocodile"),
    ("American alligator", "American Alligator"),
    ("Chinese alligator", "Chinese Alligator"),
    ("Gharial", "Gharial"), ("Black caiman", "Black Caiman"),
    ("Mugger crocodile", "Mugger Crocodile"), ("Dwarf crocodile", "Dwarf Crocodile"),
    // Tortoises & turtles
    ("Galápagos tortoise", "Galápagos Tortoise"),
    ("Aldabra giant tortoise", "Aldabra Giant Tortoise"),
    ("Leatherback sea turtle", "Leatherback Sea Turtle"),
    ("Green sea turtle", "Green Sea Turtle"),
    ("Hawksbill sea turtle", "Hawksbill Sea Turtle"),
    ("Loggerhead sea turtle", "Loggerhead Sea Turtle"),
    ("Mata mata", "Mata Mata"),
    ("Alligator snapping turtle", "Alligator Snapping Turtle"),
    ("Painted turtle", "Painted Turtle"),
    ("Pancake tortoise", "Pancake Tortoise"),
    ("Red-eared slider", "Red-Eared Slider"),
    ("Pig-nosed turtle", "Pig-Nosed Turtle"),
    // Lizards
    ("Komodo dragon", "Komodo Dragon"),
    ("Green iguana", "Green Iguana"), ("Marine iguana", "Marine Iguana"),
    ("Frilled-neck lizard", "Frilled-Neck Lizard"),
    ("Thorny devil", "Thorny Devil"),
    ("Bearded dragon", "Bearded Dragon"),
    ("Blue-tongued skink", "Blue-Tongued Skink"),
    ("Gila monster", "Gila Monster"), ("Mexican beaded lizard", "Mexican Beaded Lizard"),
    ("Green basilisk", "Green Basilisk"),
    ("Jackson's chameleon", "Jackson's Chameleon"),
    ("Panther chameleon", "Panther Chameleon"),
    ("Veiled chameleon", "Veiled Chameleon"),
    ("Parson's chameleon", "Parson's Chameleon"),
    ("Mossy leaf-tailed gecko", "Leaf-Tailed Gecko"),
    ("Tokay gecko", "Tokay Gecko"),
    ("Leopard gecko", "Leopard Gecko"), ("Crested gecko", "Crested Gecko"),
    ("Nile monitor", "Nile Monitor"), ("Lace monitor", "Lace Monitor"),
    ("Perentie", "Perentie"), ("Blue tree monitor", "Blue Tree Monitor"),
    ("Sailfin lizard", "Sailfin Lizard"),
    ("Argentine black and white tegu", "Argentine Black and White Tegu"),
    ("Common flying dragon", "Flying Dragon (lizard)"),
    ("Tuatara", "Tuatara"), ("Caiman lizard", "Caiman Lizard"),
    // Snakes
    ("Green tree python", "Green Tree Python"),
    ("Burmese python", "Burmese Python"),
    ("Reticulated python", "Reticulated Python"),
    ("Ball python", "Ball Python"),
    ("Green anaconda", "Green Anaconda"),
    ("Emerald tree boa", "Emerald Tree Boa"),
    ("King cobra", "King Cobra"),
    ("Inland taipan", "Inland Taipan"),
    ("Black mamba", "Black Mamba"), ("Green mamba", "Green Mamba"),
    ("Eastern diamondback rattlesnake", "Eastern Diamondback Rattlesnake"),
    ("Sidewinder", "Sidewinder (rattlesnake)"),
    ("Gaboon viper", "Gaboon Viper"), ("Puff adder", "Puff Adder"),
    ("Boomslang", "Boomslang"), ("Monocled cobra", "Monocled Cobra"),
    ("Red-bellied black snake", "Red-Bellied Black Snake"),
    ("Corn snake", "Corn Snake"), ("Eastern hognose snake", "Eastern Hog-Nosed Snake"),
    ("Boa constrictor", "Boa Constrictor"),
    ("Rainbow boa", "Rainbow Boa"),
    ("Copperhead (North America)", "Copperhead"),
    ("Cottonmouth", "Cottonmouth"),
    ("Spitting cobra", "Spitting Cobra"),
    ("Flying snake", "Chrysopelea"),
    ("Tentacled snake", "Tentacled Snake"),
    ("African egg-eating snake", "African Egg-Eating Snake"),
    ("Sunbeam snake", "Sunbeam Snake"),
    ("Timber rattlesnake", "Timber Rattlesnake"),
]

// MARK: - Amphibians

private let amphibianList: [(title: String, name: String)] = [
    // Frogs
    ("Red-eyed tree frog", "Red-Eyed Tree Frog"),
    ("Poison dart frog", "Poison Dart Frog"),
    ("Golden poison frog", "Golden Poison Frog"),
    ("Strawberry poison-dart frog", "Strawberry Poison-Dart Frog"),
    ("Tomato frog", "Tomato Frog"),
    ("Glass frog", "Glass Frog"),
    ("Goliath frog", "Goliath Frog"),
    ("African bullfrog", "African Bullfrog"),
    ("American bullfrog", "American Bullfrog"),
    ("Amazon milk frog", "Amazon Milk Frog"),
    ("Argentine horned frog", "Argentine Horned Frog"),
    ("Wallace's flying frog", "Wallace's Flying Frog"),
    ("Wood frog", "Wood Frog"),
    ("Waxy monkey tree frog", "Waxy Monkey Tree Frog"),
    ("White's tree frog", "White's Tree Frog"),
    ("Vietnamese mossy frog", "Vietnamese Mossy Frog"),
    ("Purple frog", "Purple Frog"),
    ("Desert rain frog", "Desert Rain Frog"),
    ("Darwin's frog", "Darwin's Frog"),
    ("Surinam toad", "Surinam Toad"),
    ("Common toad", "Common Toad"),
    ("American toad", "American Toad"),
    ("Cane toad", "Cane Toad"),
    ("European tree frog", "European Tree Frog"),
    ("Burrowing frog", "Burrowing Frog"),
    ("Paradox frog", "Paradox Frog"),
    ("Hairy frog", "Hairy Frog"),
    ("Titicaca water frog", "Titicaca Water Frog"),
    ("Tomato frog", "Tomato Frog"),
    ("Dumpy tree frog", "Australian Green Tree Frog"),
    ("Spider-man dart frog", "Oophaga speciosa"),
    ("Phantasmal poison frog", "Phantasmal Poison Frog"),
    ("Blue poison dart frog", "Blue Poison Dart Frog"),
    ("Dyeing poison dart frog", "Dyeing Poison Dart Frog"),
    ("Yellow-banded poison dart frog", "Yellow-Banded Poison Dart Frog"),
    // Salamanders & newts
    ("Axolotl", "Axolotl"),
    ("Chinese giant salamander", "Chinese Giant Salamander"),
    ("Japanese giant salamander", "Japanese Giant Salamander"),
    ("Fire salamander", "Fire Salamander"),
    ("Spotted salamander", "Spotted Salamander"),
    ("Tiger salamander", "Tiger Salamander"),
    ("Hellbender", "Hellbender"),
    ("Mudpuppy", "Mudpuppy"),
    ("Olm", "Olm"),
    ("Great crested newt", "Great Crested Newt"),
    ("Eastern newt", "Eastern Newt"),
    ("Rough-skinned newt", "Rough-Skinned Newt"),
    ("Spanish ribbed newt", "Spanish Ribbed Newt"),
    ("Alpine salamander", "Alpine Salamander"),
    ("Marbled salamander", "Marbled Salamander"),
    ("Pacific giant salamander", "Pacific Giant Salamander"),
    ("Red salamander", "Red Salamander"),
    ("Mandarin salamander", "Tylototriton verrucosus"),
    ("Smooth newt", "Smooth Newt"),
    ("Palmate newt", "Palmate Newt"),
    // Caecilians
    ("Caecilian", "Caecilian"),
    ("Ringed caecilian", "Ringed Caecilian"),
]

// MARK: - Insects

private let insectList: [(title: String, name: String)] = [
    // Butterflies
    ("Monarch butterfly", "Monarch Butterfly"),
    ("Blue morpho butterfly", "Blue Morpho"),
    ("Painted lady (butterfly)", "Painted Lady"),
    ("Red admiral", "Red Admiral"),
    ("Glasswing butterfly", "Glasswing Butterfly"),
    ("Queen Alexandra's birdwing", "Queen Alexandra's Birdwing"),
    ("Cairns birdwing", "Cairns Birdwing"),
    ("Zebra longwing", "Zebra Longwing"),
    ("Purple emperor (butterfly)", "Purple Emperor"),
    ("Peacock butterfly", "European Peacock"),
    ("Swallowtail butterfly", "Swallowtail Butterfly"),
    ("Common brimstone", "Common Brimstone"),
    ("Common blue (butterfly)", "Common Blue"),
    ("Large blue", "Large Blue"),
    ("Postman butterfly", "Postman Butterfly"),
    // Moths
    ("Atlas moth", "Atlas Moth"),
    ("Luna moth", "Luna Moth"),
    ("Death's-head hawk-moth", "Death's-Head Hawk-Moth"),
    ("Hummingbird hawk-moth", "Hummingbird Hawk-Moth"),
    ("Cecropia moth", "Cecropia Moth"),
    ("Polyphemus moth", "Polyphemus Moth"),
    ("Io moth", "Io Moth"),
    ("Silk moth", "Bombyx mori"),
    // Beetles
    ("Hercules beetle", "Hercules Beetle"),
    ("Goliath beetle", "Goliath Beetle"),
    ("Stag beetle", "Stag Beetle"),
    ("Dung beetle", "Dung Beetle"),
    ("Jewel beetle", "Buprestidae"),
    ("Bombardier beetle", "Bombardier Beetle"),
    ("Tiger beetle", "Tiger Beetle"),
    ("Firefly", "Firefly"),
    ("Ladybird", "Ladybird"),
    ("Rhinoceros beetle", "Rhinoceros Beetle"),
    ("Harlequin longhorn beetle", "Harlequin Beetle"),
    ("Violin beetle", "Violin Beetle"),
    ("Giraffe weevil", "Giraffe Weevil"),
    ("Tortoise beetle", "Tortoise Beetle"),
    ("Click beetle", "Click Beetle"),
    // Dragonflies & damselflies
    ("Emperor dragonfly", "Emperor Dragonfly"),
    ("Blue dasher", "Blue Dasher"),
    ("Common darter", "Common Darter"),
    ("Banded demoiselle", "Banded Demoiselle"),
    ("Common blue damselfly", "Common Blue Damselfly"),
    ("Wandering glider", "Wandering Glider"),
    ("Green darner", "Common Green Darner"),
    ("Twelve-spotted skimmer", "Twelve-Spotted Skimmer"),
    // Mantises
    ("Orchid mantis", "Orchid Mantis"),
    ("Devil's flower mantis", "Devil's Flower Mantis"),
    ("Dead leaf mantis", "Dead Leaf Mantis"),
    ("Spiny flower mantis", "Spiny Flower Mantis"),
    ("Giant Asian mantis", "Hierodula patellifera"),
    // Bees & wasps
    ("Western honey bee", "Honeybee"),
    ("Bumblebee", "Bumblebee"),
    ("Carpenter bee", "Carpenter Bee"),
    ("Tarantula hawk", "Tarantula Hawk"),
    ("Paper wasp", "Paper Wasp"),
    ("Blue-banded bee", "Blue-Banded Bee"),
    // Ants
    ("Leafcutter ant", "Leafcutter Ant"),
    ("Army ant", "Army Ant"),
    ("Bullet ant", "Bullet Ant"),
    ("Fire ant", "Fire Ant"),
    ("Weaver ant", "Weaver Ant"),
    ("Jack jumper ant", "Jack Jumper Ant"),
    // Other insects
    ("Leaf insect", "Leaf Insect"),
    ("Walking stick (insect)", "Stick Insect"),
    ("Giant weta", "Giant Weta"),
    ("Cicada", "Cicada"),
    ("Giant water bug", "Giant Water Bug"),
    ("Assassin bug", "Assassin Bug"),
    ("Spotted lanternfly", "Spotted Lanternfly"),
    ("Praying mantis", "Praying Mantis"),
    ("Silkworm", "Silkworm"),
    ("Christmas beetle", "Christmas Beetle"),
    ("Hornet", "Asian Giant Hornet"),
    ("Periodical cicada", "Periodical Cicadas"),
]

// MARK: - Fish & Sharks

private let fishList: [(title: String, name: String)] = [
    // Sharks
    ("Great white shark", "Great White Shark"),
    ("Whale shark", "Whale Shark"),
    ("Bull shark", "Bull Shark"),
    ("Tiger shark", "Tiger Shark"),
    ("Hammerhead shark", "Hammerhead Shark"),
    ("Nurse shark", "Nurse Shark"),
    ("Basking shark", "Basking Shark"),
    ("Shortfin mako shark", "Mako Shark"),
    ("Zebra shark", "Zebra Shark"),
    ("Wobbegong", "Wobbegong"),
    ("Blacktip reef shark", "Blacktip Reef Shark"),
    ("Blue shark", "Blue Shark"),
    ("Thresher shark", "Thresher Shark"),
    ("Leopard shark", "Leopard Shark"),
    ("Port Jackson shark", "Port Jackson Shark"),
    ("Epaulette shark", "Epaulette Shark"),
    ("Bamboo shark", "Bamboo Shark"),
    // Rays
    ("Manta ray", "Manta Ray"),
    ("Stingray", "Stingray"),
    ("Spotted eagle ray", "Spotted Eagle Ray"),
    ("Sawfish", "Sawfish"),
    ("Electric ray", "Electric Ray"),
    // Reef fish
    ("Clownfish", "Clownfish"),
    ("Red lionfish", "Red Lionfish"),
    ("Mandarin fish", "Mandarin Fish"),
    ("Pufferfish", "Pufferfish"),
    ("Moorish idol", "Moorish Idol"),
    ("Blue tang", "Blue Tang"),
    ("Flame angelfish", "Flame Angelfish"),
    ("Clown triggerfish", "Clown Triggerfish"),
    ("Parrotfish", "Parrotfish"),
    ("Surgeonfish", "Surgeonfish"),
    ("Batfish", "Batfish (Ogcocephalidae)"),
    ("Frogfish", "Frogfish"),
    ("Leafy seadragon", "Leafy Seadragon"),
    ("Weedy seadragon", "Weedy Seadragon"),
    ("Seahorse", "Seahorse"),
    ("Pipefish", "Pipefish"),
    ("Ribbon eel", "Ribbon Eel"),
    ("Moray eel", "Moray Eel"),
    ("Porcupinefish", "Porcupinefish"),
    // Open ocean
    ("Atlantic bluefin tuna", "Atlantic Bluefin Tuna"),
    ("Swordfish", "Swordfish"),
    ("Sailfish", "Sailfish"),
    ("Blue marlin", "Blue Marlin"),
    ("Flying fish", "Flying Fish"),
    ("Ocean sunfish", "Ocean Sunfish"),
    ("Oarfish", "Oarfish"),
    ("Barracuda", "Great Barracuda"),
    // Freshwater fish
    ("Piranha", "Piranha"),
    ("Electric eel", "Electric Eel"),
    ("Arapaima", "Arapaima"),
    ("Arowana", "Arowana"),
    ("Siamese fighting fish", "Siamese Fighting Fish"),
    ("Discus (fish)", "Discus (fish)"),
    ("Koi", "Koi"),
    ("Neon tetra", "Neon Tetra"),
    ("Archerfish", "Archerfish"),
    // Deep sea & ancient
    ("Anglerfish", "Anglerfish"),
    ("Blobfish", "Blobfish"),
    ("Coelacanth", "Coelacanth"),
    ("Lungfish", "Lungfish"),
    ("Sturgeon", "Sturgeon"),
    ("Gulper eel", "Pelican Eel"),
]

// MARK: - Ocean Life

private let oceanLifeList: [(title: String, name: String)] = [
    // Cephalopods
    ("Common octopus", "Octopus"),
    ("Giant Pacific octopus", "Giant Pacific Octopus"),
    ("Blue-ringed octopus", "Blue-Ringed Octopus"),
    ("Mimic octopus", "Mimic Octopus"),
    ("Common cuttlefish", "Common Cuttlefish"),
    ("Flamboyant cuttlefish", "Flamboyant Cuttlefish"),
    ("Giant squid", "Giant Squid"),
    ("Colossal squid", "Colossal Squid"),
    ("Humboldt squid", "Humboldt Squid"),
    ("Firefly squid", "Firefly Squid"),
    ("Nautilus", "Chambered Nautilus"),
    // Jellyfish & siphonophores
    ("Box jellyfish", "Box Jellyfish"),
    ("Moon jellyfish", "Moon Jellyfish"),
    ("Lion's mane jellyfish", "Lion's Mane Jellyfish"),
    ("Portuguese man o' war", "Portuguese Man o' War"),
    ("Barrel jellyfish", "Barrel Jellyfish"),
    ("Atolla jellyfish", "Atolla Jellyfish"),
    ("Immortal jellyfish", "Turritopsis dohrnii"),
    // Crustaceans
    ("American lobster", "American Lobster"),
    ("Spiny lobster", "Spiny Lobster"),
    ("Horseshoe crab", "Horseshoe Crab"),
    ("Mantis shrimp", "Mantis Shrimp"),
    ("Pistol shrimp", "Pistol Shrimp"),
    ("Japanese spider crab", "Japanese Spider Crab"),
    ("Coconut crab", "Coconut Crab"),
    ("Hermit crab", "Hermit Crab"),
    ("King crab", "King Crab"),
    ("Blue crab", "Blue Crab"),
    ("Dungeness crab", "Dungeness Crab"),
    ("Fiddler crab", "Fiddler Crab"),
    ("Brine shrimp", "Brine Shrimp"),
    // Echinoderms
    ("Crown-of-thorns starfish", "Crown-of-Thorns Starfish"),
    ("Sunflower sea star", "Sunflower Sea Star"),
    ("Chocolate chip sea star", "Chocolate Chip Sea Star"),
    ("Sea urchin", "Sea Urchin"),
    ("Sea cucumber", "Sea Cucumber"),
    ("Feather star", "Crinoid"),
    ("Brittle star", "Brittle Star"),
    // Molluscs (non-cephalopod)
    ("Giant clam", "Giant Clam"),
    ("Cone snail", "Cone Snail"),
    ("Flamingo tongue snail", "Flamingo Tongue Snail"),
    // Nudibranchs
    ("Glaucus atlanticus", "Blue Dragon"),
    ("Spanish dancer (nudibranch)", "Spanish Dancer"),
    ("Chromodoris lochi", "Chromodoris Nudibranch"),
    ("Flabellina (nudibranch)", "Flabellina"),
    ("Sea slug", "Sea Slug"),
    // Corals & sea anemones
    ("Sea anemone", "Sea Anemone"),
    ("Clownfish sea anemone", "Magnificent Sea Anemone"),
    ("Brain coral", "Brain Coral"),
    ("Staghorn coral", "Staghorn Coral"),
    ("Sea fan", "Sea Fan"),
    ("Bubble coral", "Bubble Coral"),
    // Worms & others
    ("Christmas tree worm", "Christmas Tree Worm"),
    ("Bobbit worm", "Bobbit Worm"),
    ("Feather duster worm", "Feather Duster Worm"),
    // Marine reptiles
    ("Sea snake", "Sea Snake"),
    ("Saltwater crocodile", "Saltwater Crocodile"),
    // Marine mammals (a selection)
    ("Orca", "Orca"),
    ("Blue whale", "Blue Whale"),
    ("Humpback whale", "Humpback Whale"),
    ("Narwhal", "Narwhal"),
    ("Dugong", "Dugong"),
    ("Walrus", "Walrus"),
    ("Leopard seal", "Leopard Seal"),
    ("California sea lion", "California Sea Lion"),
]

// MARK: - Arachnids

private let arachnidList: [(title: String, name: String)] = [
    // Tarantulas
    ("Goliath birdeater", "Goliath Birdeater"),
    ("Mexican red knee tarantula", "Mexican Red Knee Tarantula"),
    ("Cobalt blue tarantula", "Cobalt Blue Tarantula"),
    ("Chilean rose tarantula", "Chilean Rose Tarantula"),
    ("Pinktoe tarantula", "Pinktoe Tarantula"),
    ("Greenbottle blue tarantula", "Greenbottle Blue Tarantula"),
    ("King baboon spider", "King Baboon Spider"),
    ("Baboon spider", "Baboon Spider"),
    ("Skeleton tarantula", "Ephebopus murinus"),
    // Other spiders
    ("Black widow spider", "Black Widow Spider"),
    ("Brown recluse spider", "Brown Recluse Spider"),
    ("Sydney funnel-web spider", "Sydney Funnel-Web Spider"),
    ("Golden silk orb-weaver", "Golden Silk Orb-Weaver"),
    ("Peacock spider", "Peacock Spider"),
    ("Jumping spider", "Jumping Spider"),
    ("Huntsman spider", "Huntsman Spider"),
    ("Wolf spider", "Wolf Spider"),
    ("Crab spider", "Crab Spider"),
    ("Net-casting spider", "Net-Casting Spider"),
    ("Spitting spider", "Spitting Spider"),
    ("Trapdoor spider", "Trapdoor Spider"),
    ("Water spider", "Diving Bell Spider"),
    ("Orb-weaver spider", "Orb-Weaver Spider"),
    ("Brazilian wandering spider", "Brazilian Wandering Spider"),
    ("Six-eyed sand spider", "Six-Eyed Sand Spider"),
    ("Redback spider", "Redback Spider"),
    ("Daddy long-legs spider", "Pholcidae"),
    ("Bolas spider", "Bolas Spider"),
    ("Ogre-faced spider", "Net-Casting Spider"),
    ("Portia (spider)", "Portia Spider"),
    // Scorpions
    ("Deathstalker", "Deathstalker"),
    ("Emperor scorpion", "Emperor Scorpion"),
    ("Arizona bark scorpion", "Arizona Bark Scorpion"),
    ("Fat-tailed scorpion", "Fat-Tailed Scorpion"),
    ("Asian forest scorpion", "Asian Forest Scorpion"),
    ("Flat rock scorpion", "Flat Rock Scorpion"),
    ("Vinegaroon", "Vinegaroon"),
    ("Whip scorpion", "Whip Scorpion"),
    ("Pseudoscorpion", "Pseudoscorpion"),
    ("Wind scorpion", "Solifugae"),
    // Ticks & mites
    ("Tick", "Tick"),
    ("Red velvet mite", "Red Velvet Mite"),
    ("Harvestman", "Harvestman"),
    ("Clover mite", "Clover Mite"),
    // Other arachnids
    ("Whip spider", "Amblypygi"),
    ("Sea spider", "Sea Spider"),
    ("Ricinulei", "Hooded Tickspider"),
]
