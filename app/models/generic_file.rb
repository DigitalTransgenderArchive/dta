# encoding: utf-8

class GenericFile < ActiveFedora::Base
  has_and_belongs_to_many :institutions, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOf, class_name: "Institution"

  has_many :old_institutions, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember, class_name: "Institution"

  has_many :collections, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, class_name: "Collection"

  has_subresource "ocr"
  has_subresource "content", class_name: 'FileContentDatastream'
  has_subresource "thumbnail"

  # Get permissions
  #has_many :permissions, predicate: ::ACL.accessTo, inverse_of: :access_to

  # From other
  property :label, predicate: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, multiple: false

  property :depositor, predicate: ::RDF::URI.new("http://id.loc.gov/vocabulary/relators/dpt"), multiple: false do |index|
    index.as :symbol, :stored_searchable
  end

  property :arkivo_checksum, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#arkivoChecksum'), multiple: false

  property :relative_path, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#relativePath'), multiple: false

  property :import_url, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#importUrl'), multiple: false do |index|
    index.as :symbol
  end

  property :part_of, predicate: ::RDF::Vocab::DC.isPartOf
  property :resource_type, predicate: ::RDF::Vocab::DC.type do |index|
    index.as :stored_searchable, :facetable
  end
  property :title, predicate: ::RDF::Vocab::DC.title do |index|
    index.as :stored_searchable, :facetable
  end
  property :creator, predicate: ::RDF::Vocab::DC.creator do |index|
    index.as :stored_searchable, :facetable
  end
  property :contributor, predicate: ::RDF::Vocab::DC.contributor do |index|
    index.as :stored_searchable, :facetable
  end
  property :description, predicate: ::RDF::Vocab::DC.description do |index|
    index.type :text
    index.as :stored_searchable
  end
  property :tag, predicate: ::RDF::Vocab::DC.relation do |index|
    index.as :stored_searchable, :facetable
  end
  property :rights, predicate: ::RDF::Vocab::DC.rights do |index|
    index.as :stored_searchable
  end
  property :publisher, predicate: ::RDF::Vocab::DC.publisher do |index|
    index.as :stored_searchable, :facetable
  end
  property :date_created, predicate: ::RDF::Vocab::DC.created do |index|
    index.as :stored_searchable
  end

  # We reserve date_uploaded for the original creation date of the record.
  # For example, when migrating data from a fedora3 repo to fedora4,
  # fedora's system created date will reflect the date when the record
  # was created in fedora4, but the date_uploaded will preserve the
  # original creation date from the old repository.
  property :date_uploaded, predicate: ::RDF::Vocab::DC.dateSubmitted, multiple: false do |index|
    index.type :date
    index.as :stored_sortable
  end

  property :date_modified, predicate: ::RDF::Vocab::DC.modified, multiple: false do |index|
    index.type :date
    index.as :stored_sortable
  end
  property :subject, predicate: ::RDF::Vocab::DC.subject do |index|
    index.as :stored_searchable, :facetable
  end
  property :language, predicate: ::RDF::Vocab::DC.language do |index|
    index.as :stored_searchable, :facetable
  end
  property :identifier, predicate: ::RDF::Vocab::DC.identifier do |index|
    index.as :stored_searchable
  end
  property :based_near, predicate: ::RDF::Vocab::FOAF.based_near do |index|
    index.as :stored_searchable, :facetable
  end
  property :related_url, predicate: ::RDF::RDFS.seeAlso do |index|
    index.as :stored_searchable
  end
  property :bibliographic_citation, predicate: ::RDF::Vocab::DC.bibliographicCitation do |index|
    index.as :stored_searchable
  end
  property :source, predicate: ::RDF::Vocab::DC.source do |index|
    index.as :stored_searchable
  end
  # End From Other


  property :toc, predicate: ::RDF::Vocab::DC.tableOfContents, multiple: false do |index|
    index.as :stored_searchable
  end

  property :analog_format, predicate: ::RDF::Vocab::DC.format, multiple: false do |index|
    index.as :stored_searchable
  end
  
  property :digital_format, predicate: ::RDF::Vocab::DC11.format, multiple: false do |index|
    index.as :stored_searchable
  end
  
  property :temporal_coverage, predicate: ::RDF::Vocab::DC.temporal do |index|
    index.as :stored_searchable
  end
  
  property :date_issued, predicate: ::RDF::Vocab::DC.issued do |index|
    index.as :stored_searchable
  end
  #::RDF::SCHEMA.
  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
    index.as :stored_searchable, :symbol
  end
  
  property :alternative, predicate: ::RDF::Vocab::DC.alternative do |index|
    index.as :stored_searchable
  end

  #http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#adultContent is boolean only :(
  #FIXME: Both rights and flagged have multiple set to true and their forms generate with that...
  #FIXME: MULTIPLE SHOULD BE FALSE!!! Main page gives an error though if it is... ><
  property :flagged, predicate: ::RDF::URI.new('http://digitaltransgenderarchive.net/ns/flagged'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :lcsh_subject, predicate: ::RDF::Vocab::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :other_subject, predicate: ::RDF::Vocab::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :homosaurus_subject, predicate: ::RDF::Vocab::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :is_shown_at, predicate: ::RDF::Vocab::EDM.isShownAt, multiple: false do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :preview, predicate: ::RDF::Vocab::EDM.preview, multiple: false do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :hosted_elsewhere, predicate: ::RDF::URI.new('http://digitaltransgenderarchive.net/ns/hosted_elsewhere'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :rights_free_text, predicate: ::RDF::Vocab::DC11.rights, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

end
