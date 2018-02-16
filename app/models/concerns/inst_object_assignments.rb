module InstObjectAssignments

  def add_image(value, mime_type, original_name=nil)
    sha256 = InstImageFile.calculate_sha256 value
    obj = InstImageFile.find_or_create_by(sha256: sha256, mime_type: mime_type)
    if original_name.present?
      obj.original_filename = original_name.gsub(File.extname(original_name), '')
      obj.original_extension = File.extname(original_name)
    end
    self.inst_image_files << obj
    obj.content = value
    obj.low_res = true
    obj.fedora_imported = true
  end

  def geonames=(value)
    val = value
      if val.class == String
        ld = Geonames.find_by(uri: val)
        if ld.blank?
          geojson_hash_base = {type: 'Feature', geometry: {type: 'Point'}}
          r = RestClient.get 'http://api.geonames.org/getJSON', {:params => {:geonameId=>"#{val.split('/').last}", :username=>"boston_library"}, accept: :json}
          result = JSON.parse(r)
          # FIXME: This indicates a bad geographic element... need to verify on input
          if result['name'].blank? || result['lng'].blank?
            raise "Error: Geonames value of #{val} is invalid for #{self.id}"
          end

          geojson_hash_base[:geometry][:coordinates] = [result['lng'],result['lat']]

          if result['fcl'] == 'P' and result['adminCode1'].present?
            #geojson_hash_base[:properties] = {placename: result['name'] + ', ' + result['adminCode1']}
            geojson_hash_base[:properties] = {placename: result['name']}
          else
            geojson_hash_base[:properties] = {placename: result['name']}
          end

          hierarchy_full = []
          hierarchy_full << result['name']
          hierarchy_full << result['adminName1'] if result['adminName1'].present?
          hierarchy_full << result['adminName2'] if result['adminName2'].present?
          hierarchy_full << result['adminName3'] if result['adminName3'].present?
          hierarchy_full << result['countryName'] if result['countryName'].present?
          hierarchy_full.uniq!

          hierarchy_display = []
          hierarchy_display << result['adminName1'] if result['adminName1'].present?
          hierarchy_display << result['adminName2'] if result['adminName2'].present?
          hierarchy_display << result['adminName3'] if result['adminName3'].present?
          hierarchy_display << result['name']
          hierarchy_display.uniq!

          # TODO: Get all Labels?
          ld = Geonames.create(uri: val, label: result['name'], lat: result['lat'], lng: result['lng'], hierarchy_full: hierarchy_full, hierarchy_display: hierarchy_display, geo_json_hash: geojson_hash_base)
        end
        raise "Could not find geonames for: #{val.to_s}" if ld.nil?
      elsif val.class == Geonames
        ld = value
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    value = ld
  end
end
