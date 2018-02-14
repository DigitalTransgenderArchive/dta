class Institution < ActiveFedora::Base
  include Pid

  #contains "content", class_name: 'FileContentDatastream'
  #contains "thumbnail"

  has_subresource "content", class_name: 'FileContentDatastream'
  has_subresource "thumbnail"

  has_many :members, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection, class_name: "Collection"

  has_many :files, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOf, class_name: "GenericFile"

  property :date_created, predicate: ::RDF::Vocab::DC.created, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol, :facetable
  end

  property :name, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol, :facetable
  end

  property :description, predicate: ::RDF::RDFS.comment, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :contact_person, predicate: ::RDF::URI.new("http://digitaltransgenderarchive.net/ns/contactPerson"), multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol
  end

  property :address, predicate: ::RDF::Vocab::SCHEMA.address, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol
  end

  property :email, predicate: ::RDF::Vocab::SCHEMA.email, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol
  end

  property :phone, predicate: ::RDF::Vocab::SCHEMA.telephone, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol
  end
  
  property :institution_url, predicate: ::RDF::RDFS.seeAlso, multiple: false do |index|
    index.as :stored_searchable
  end

  def label
    return self.name
  end

end
