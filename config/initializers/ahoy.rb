class Ahoy::Store < Ahoy::Stores::ActiveRecordTokenStore
  # customize here
  def track_visit(options)
    super do |visit|
    end
  end

  def track_event(name, properties, options)
    super do |event|
      event.param1 = options[:param1] if options[:param1].present?
      event.param1_type = options[:param1_type] if options[:param1_type].present?
      event.param2 = options[:param2] if options[:param2].present?
      event.param2_type = options[:param2_type] if options[:param2_type].present?
      event.pid = options[:pid] if options[:pid].present?
      event.institution_pid = options[:institution_pid] if options[:institution_pid].present?
      event.collection_pid = options[:collection_pid] if options[:collection_pid].present?
      event.model = options[:model] if options[:model].present?
      event.search_term = options[:search_term] if options[:search_term].present?
    end
  end
end

Ahoy.geocode = :async
