# frozen_string_literal: true
class BookmarksController < CatalogController
  include Blacklight::Bookmarks
  blacklight_config.view.delete(:gallery)
end