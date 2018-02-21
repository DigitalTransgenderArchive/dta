class ProcessFileWorker
    include Sidekiq::Worker
    sidekiq_options unique: :until_and_while_executing

    def perform(obj_id, force=true)
      file = BaseFile.find(obj_id)
      file.create_derivatives
      file.reload
      file.base_object.send_solr
    end
end
