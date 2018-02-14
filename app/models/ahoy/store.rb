class Ahoy::Store < Ahoy::Stores::ActiveRecordTokenStore
  def track_visit(options)
    super do |visit|
      visit.gclid = visit_properties.landing_params["gclid"]
    end
  end

  def track_event(name, properties, options)
    super do |event|
      event.param1 = properties[:param1] if properties[:param1].present?
      event.pid = properties[:pid] if properties[:pid].present?
    end
  end
end
