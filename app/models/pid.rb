require 'noid-rails'

class Pid
  extend ActiveSupport::Concern

  def self.tree(id)
    Noid::Rails.treeify(id)
  end

  def self.stump(path)
    @baseparts ||= 2 + [(Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
    return path.to_s.split('/', @baseparts).last
  end

  def self.mint
    raise 'I should not be here'
    conflicts = true
    while conflicts do
      pid = service.mint
      conflicts = false unless GenericObject.exists?(pid: pid) || Coll.exists?(pid: pid) || Inst.exists?(pid: pid)
    end
    return pid
  end

  def self.assign_id
    self.forge
  end

  private

  def self.service
    @service ||= Noid::Rails::Service.new
  end
end
