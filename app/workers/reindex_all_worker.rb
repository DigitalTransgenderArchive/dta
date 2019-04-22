class ReindexAllWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing

  def perform
    DSolr.reindex('HomosaurusSubject')
    DSolr.reindex('Inst')
    DSolr.reindex('Coll')
    DSolr.reindex('GenericObject')
  end
end
