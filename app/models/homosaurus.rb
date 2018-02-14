class Homosaurus < ActiveFedora::Base

  has_and_belongs_to_many :broader, predicate: ::RDF::Vocab::SKOS.broader, class_name: "Homosaurus"
  has_and_belongs_to_many :narrower, predicate: ::RDF::Vocab::SKOS.narrower, class_name: "Homosaurus"
  has_and_belongs_to_many :related, predicate: ::RDF::Vocab::SKOS.related, class_name: "Homosaurus"

  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
    index.as :stored_sortable
  end

  property :prefLabel, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :altLabel, predicate: ::RDF::Vocab::SKOS.altLabel, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  property :description, predicate: ::RDF::RDFS.comment, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :description, predicate: ::RDF::RDFS.comment, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :issued, predicate: ::RDF::Vocab::DC.issued, multiple: false do |index|
    index.as :stored_sortable
  end

  property :modified, predicate: ::RDF::Vocab::DC.modified, multiple: false do |index|
    index.as :stored_sortable
  end

  property :exactMatch, predicate: ::RDF::Vocab::SKOS.exactMatch, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  property :closeMatch, predicate: ::RDF::Vocab::SKOS.closeMatch, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  def get_broadest(item)
    if item.broader.blank?
      @broadest_terms << item.id.split('/').last
    else
      item.broader.each do |current_broader|
        get_broadest(current_broader)
      end
    end
  end

end
