class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory
  helper BlacklightMaps::RenderConstraintsOverride

  helper BlacklightRangeLimit::ViewHelperOverride
  helper RangeLimitHelper
end
