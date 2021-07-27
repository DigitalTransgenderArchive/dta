if Settings.dta_config["proxy_host"].present?
  RestClient.proxy = "http://#{Settings.dta_config['proxy_host']}:#{Settings.dta_config['proxy_port']}"
end