module BlacklightMapsHelper
  include Blacklight::BlacklightMapsHelperBehavior

  # OVERRIDE: allow controller.action name to be passed, allow @controller
  # pass the document or facet values to BlacklightMaps::GeojsonExport
  def serialize_geojson(documents, action_name=nil, options={})
    action = action_name || controller.action_name
    cntrllr = @controller || controller
    export = BlacklightMaps::GeojsonExport.new(cntrllr, action, documents, options)
    export.to_geojson
  end
end
