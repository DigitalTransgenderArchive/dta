require 'uri'

module Mei
  class Geonames

    include Mei::WebServiceBase

    def request_options
      {:params => {:featureClass => "#{@type}", :style => 'full', :maxRows => 20, :name_startsWith => "#{@escaped_query}", :username=>"boston_library"}, accept: :json}
    end

    def initialize(e)
      @type = e
    end

    def search q
      @raw_response = get_json(build_query_url(q))
      parse_authority_response
    end


    def build_query_url q
      @escaped_query = URI.escape(q)
      @escaped_query = q
      return "http://api.geonames.org/searchJSON"
    end

    #result["geonames"].first["name"]
    #result["geonames"].first["geonameId"]
    #bbox
    #adminId1
    #adminId2
    def parse_authority_response
      end_response = []

      @raw_response["geonames"].each do |geoname|
        #count = ObjectHomosaurusSubject.joins(:homosaurus_subject).where(homosaurus_subjects: {uri: 'http://homosaurus.org/terms/crossdressing'}).size
        #count = ActiveFedora::Base.find_with_conditions("based_near_ssim:#{solr_clean("http://www.geonames.org/#{geoname["geonameId"]}")}", rows: '100', fl: 'id' ).length
        count = ObjectGeoname.joins(:geoname).where(geonames: {uri: "http://www.geonames.org/#{geoname['geonameId']}"}).size
        if count >= 99
          count = "99+"
        else
          count = count.to_s
        end

        end_response << {
            "uri_link" => "http://www.geonames.org/#{geoname["geonameId"]}" || "missing!",
            "label" => geoname["name"],
            "broader" => broader(geoname),
            "narrower" => narrower(geoname),
            "variants" => variants(geoname),
            "count" => count
        }
      end

      end_response
    end



    def broader(row)
      broader_list = []
      if row["fcl"] == "P" || row["fcl"] == "S" || row["fcl"] == "A"
        broader_list << {:uri_link=>"http://www.geonames.org/#{row["adminId1"]}", :label=>row["adminName1"]} if row["adminId1"].present? && row["adminName1"].present?
        broader_list << {:uri_link=>"http://www.geonames.org/#{row["adminId2"]}", :label=>row["adminName2"]} if row["adminId2"].present? && row["adminName2"].present?
        broader_list << {:uri_link=>"http://www.geonames.org/#{row["countryId"]}", :label=>row["countryName"]} if row["countryId"].present? && row["countryName"].present?
      end

      return broader_list
    end

    def narrower(row)
      return []
    end

    def variants(row)
      varient_list = []
      if row["alternateNames"].present?
        row["alternateNames"].each do |variant|
          #if ['eng'].include?( variant["lang"])
          varient_list <<  variant["name"]
          #end
        end
      end

     return varient_list
    end


    def solr_clean(term)
      return term.gsub('\\', '\\\\').gsub(':', '\\:').gsub(' ', '\ ')
    end


  end
end
