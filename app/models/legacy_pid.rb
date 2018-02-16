require 'noid-rails'

module LegacyPid
  extend ActiveSupport::Concern

  ## This overrides the default behavior, which is to ask Fedora for an id
  # @see ActiveFedora::Persistence.assign_id
  def assign_id
    service.mint
  end

  def to_param
    id
  end

  private

  def service
    @service ||= Noid::Rails::Service.new
  end
end
