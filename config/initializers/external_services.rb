ext_services_cfg_file = "#{::Rails.root.to_s}/config/external.services.yml"
bugzilla_cfg_file     = "#{::Rails.root.to_s}/config/bugzilla.yml"

# Using the new configuration file
if not File.exists?(bugzilla_cfg_file)
  SERVICES = YAML.load_file(ext_services_cfg_file)
# Using Bugzilla configuration file
else
  puts "\033[34mNOTICE: Using config/bugzilla.yml is deprecated. Using it anyway, but"
  puts"        see https://github.com/leonidas/qa-reports/wiki/External-Services\033[0m"
  bugzilla_cfg = YAML.load_file(bugzilla_cfg_file)
  # Reformat the configuration a bit so it looks the same as loading a single
  # service from the new configuration file format.
  bugzilla_cfg['name']    = 'Bugzilla'
  bugzilla_cfg['type']    = 'bugzilla'
  bugzilla_cfg['default'] = true
  bugzilla_cfg['prefix']  = 'BZ'

  # Add sprintf formatting
  bugzilla_cfg['uri']      = bugzilla_cfg['uri'].gsub("%", "%%") + "%s"
  bugzilla_cfg['link_uri'] = bugzilla_cfg['link_uri'].gsub("%", "%%") + "%s"

  SERVICES = [bugzilla_cfg]
end

# Store additional default service for faster access
default = SERVICES.detect {|s| s['default']}
if default.nil?
  puts "\033[31mWARNING: Using the first external service as default since no default defined\033[0m"
  DEFAULT_SERVICE = SERVICES[0]
else
  DEFAULT_SERVICE = default
end

errors = false
# Check for prefixes if we have more than one service defined
if SERVICES.length > 1
  SERVICES.each do |s|
    if s['prefix'].blank?
      puts "\033[31mERROR: No prefix defined for #{s['name']}\033[0m"
      errors = true
    end

    if s['default'] and s != DEFAULT_SERVICE
      s['default'] = false
    end
  end
end

# Check the sprintf formatting of string
SERVICES.each do |s|
  if s['type'] == 'bugzilla' || s['type'] == 'gerrit'
    begin
      s['uri'] % 'test'
      s['link_uri'] % 'test'
    rescue ArgumentError
      puts "\033[31mERROR: Incorrect uri or link_uri for #{s['name']} - remember to escape % signs\033[0m"
      errors = true
    end

    unless s['uri'].include?("%s")
        puts "\033[31mERROR: uri for #{s['name']} missing ID placeholder (%s)\033[0m"
        errors = true
    end
  end

  unless s['link_uri'].include?("%s")
      puts "\033[31mERROR: link_uri for #{s['name']} missing ID placeholder (%s)\033[0m"
      errors = true
  end
end

abort("#{ext_services_cfg_file} is invalid") if errors
