# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

genre_hash = {
    "Advertisements" => "Advertisements",
    "Albums" => "Albums",
    "Art" => "Art",
    "Articles" => "Articles",
    "Awards" => "Awards",
    "Autobiographies" => "Autobiographies",
    "Bibliographies" => "Bibliographies",
    "Birth Certificates" => "Birth Certificates",
    "Books" => "Books",
    "Calendars" => "Calendars",
    "Cards" => "Cards",
    "Catalogs" => "Catalogs",
    "Charts" => "Charts",
    "Clippings" => "Clippings",
    "Correspondence" => "Correspondence",
    "Dictionaries" => "Dictionaries",
    "Diaries" => "Diaries",
    "Directories" => "Directories",
    "Documents" => "Documents",
    "Drama" => "Drama",
    "Drawings" => "Drawings",

    "Ephemera" => "Ephemera",
    "Encyclopedias" => "Encyclopedias",
    "Erotica" => "Erotica",
    "Essays" => "Essays",
    "Fiction" => "Fiction",
    "Finding Aids" => "Finding Aids",
    "Government Publications" => "Government Publications",
    "Government Records" => "Government Records",
    "Handbooks" => "Handbooks",
    "Leaflets" => "Leaflets",
    "Lecture Notes" => "Lecture Notes",
    "Legal Cases" => "Legal Cases",
    "Manuscripts" => "Manuscripts",
    "Maps" => "Maps",
    "Motion Pictures" => "Motion Pictures",
    "Musical Notation" => "Musical Notation",
    "Newsletters" => "Newsletters",
    "Newspapers" => "Newspapers",
    "Oral Histories" => "Oral Histories",
    "Paintings" => "Paintings",

    "Pamphlets" => "Pamphlets",
    "Periodicals" => "Periodicals",
    "Petitions" => "Petitions",
    "Photographs" => "Photographs",
    "Physical Objects" => "Physical Objects",
    "Poetry" => "Poetry",
    "Posters" => "Posters",
    "Press Releases" => "Press Releases",
    "Prints" => "Prints",
    "Programs" => "Programs",
    "Records" => "Records",
    "Reviews" => "Reviews",
    "Sound Recordings" => "Sound Recordings",
    "Speeches" => "Speeches",
    "Surveys" => "Surveys",
    "Theses" => "Theses",
    "Transcriptions" => "Transcriptions",
    "Websites" => "Websites",
    "Yearbooks" => "Yearbooks"
}
genre_hash.each do |key, val|
  Genre.create(label: val)
end

resource_types = {
    "Artifact" => "http://id.loc.gov/vocabulary/resourceTypes/art",
    "Audio" => "http://id.loc.gov/vocabulary/resourceTypes/aud",
    "Cartographic" => "http://id.loc.gov/vocabulary/resourceTypes/car",
    "Collection" => "http://id.loc.gov/vocabulary/resourceTypes/col",
    "Dataset" => "http://id.loc.gov/vocabulary/resourceTypes/dat",
    "Digital [indicates born­digital]" => "http://id.loc.gov/vocabulary/resourceTypes/dig",
    "Manuscript" => "http://id.loc.gov/vocabulary/resourceTypes/man",
    "Mixed material" => "http://id.loc.gov/vocabulary/resourceTypes/mix",
    "Moving image" => "http://id.loc.gov/vocabulary/resourceTypes/mov",
    "Multimedia" => "http://id.loc.gov/vocabulary/resourceTypes/mul",
    "Notated music" => "http://id.loc.gov/vocabulary/resourceTypes/not",
    "Still Image" => "http://id.loc.gov/vocabulary/resourceTypes/img",
    "Tactile" => "http://id.loc.gov/vocabulary/resourceTypes/tac",
    "Text" => "http://id.loc.gov/vocabulary/resourceTypes/txt",
    "Unspecified" => "http://id.loc.gov/vocabulary/resourceTypes/unk"
}

resource_types.each do |key, val|
  ResourceType.create(label: key, uri: val)
end

cc_licenses = {
    'Contact host institution for more information' => 'Contact host institution for more information',
    'No known restrictions on use' => 'No known restrictions on use',
    'All rights reserved' => 'All rights reserved'
}

cc_licenses.each do |key, val|
  Rights.create(label: key)
end

