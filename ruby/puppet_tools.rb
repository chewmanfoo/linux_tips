module PuppetTools

$LOAD_PATH.unshift("/opt/provision/jobs/lib")
require 'yaml'
require 'config_tools'
require 'business_tools'
require 'jenkins_tools'

  GITURL = ConfigTools.lookup("system/git/url")
#  GITURL = "https://provisioning:trinity1\!@gitlab.sabrenow.com"

##############################################################################################
# validators
# for these jobs, _environment is (cit_certification, cit_production, cit_dr)
# for these jobs, _role is from system_role.yaml from particular environment
#                 -> note the environment is a folder and not a branch - this is master branch
# role_exists(_role, _environment)
# environment_exists(_environment)
# tier_exists(_tier, _environment)
# os_exists(_os)
# num_instances_valid(_num)
##############################################################################################

  def self.validate_file_version(_version)
    # file version is major.minor.micro ##.##.##
    /\d+\.\d+\.\d+/.match(_version)
  end

  def self.role_exists_in_puppet(_role, _environment)
    out = false
    Dir.mktmpdir do |dir|
      `git clone #{GITURL}/data/corpit-systemdata.git #{dir}`
      system_role = YAML.load_file("#{dir}/hieradata/systemconfiguration/#{_environment}/system_role.yaml")
      out = system_role["system_role::profiles"].keys.include? "#{_role}"
    end
    out
  end

  def self.role_exists_in_business()
    true
  end

  def self.role_exists(_role, _environment, _naming="puppet role")
    case _naming
    when "iamsabre name"
      PuppetTools.role_exists_in_business()
    when "puppet role"
      PuppetTools.role_exists_in_puppet(_role, _environment)
    end
  end

  def self.environment_exists(_environment)
    out = false
    Dir.mktmpdir do |dir|
      `git clone #{GITURL}/infrastructure/corpit-cloudformation-vm-provisioning.git #{dir}`
      @result = `ls #{dir}/environments`.strip
      @resulta=@result.split("\n")
      out = @resulta.include?("#{_environment}")
    end
    out
  end

  def self.tier_exists(_tier, _environment)
    out = false
  # ? use aws cli or sdk to list VPC's for this account
    Dir.mktmpdir do |dir|
      `git clone #{GITURL}/infrastructure/corpit-cloudformation-vm-provisioning.git #{dir}`
      @result = `ls #{dir}/environments/#{_environment}`.strip
      @resulta=@result.split("\n")
      out = @resulta.include?("#{_tier}")
    end
    out
  end

  def self.subtier_exists(_subtier, _environment)
    case _environment
      when "cit_certification"
        %w[app tmz mgt].include?(_subtier)
      when "cit_production"
        %w[app tmz mgt].include?(_subtier)
      when "cit_dr"
        %w[app tmz mgt].include?(_subtier)
    end
  end

  def self.module_exists(_module, _environment)
    Dir.mktmpdir do |dir|
# TODO: use Puppetfile, not system_role.yaml
#      `git clone #{GITURL}/data/corpit-systemdata.git #{dir}`
#      system_module = YAML.load_file("#{dir}/hieradata/systemconfiguration/#{_environment}/system_module.yaml")
#      system_module["system_module::profiles"].keys.include? "#{_module}"
    end
    false
  end

  def self.template_exists(_template, _environment, _tier)
    retval = false
    Dir.mktmpdir do |dir|
      `git clone #{GITURL}/infrastructure/corpit-cloudformation-vm-provisioning.git #{dir}`
      @result = `ls #{dir}/environments/#{_environment}/#{_tier}/`.strip
      @resulta=@result.split("\n")
      retval = @resulta.include?("#{_template}")
    end
    retval
  end

  def self.os_exists(_os)
    %w(windows linux).include?(_os)
  end
  
  def self.num_instances_valid(_num)
    Integer(_num)
  end

##############################################################################################
# getters
##############################################################################################

  def self.get_hosts_ip(_host, _num)
    #TODO this is only for smone - this needs to be fixed for all hosts!
    d = _host.split('-')[1]
    case d
      when "c"
        "10.6.36.37"
      when "q"
        case _num
          when "1"
            "10.6.36.82"
          when "2"
            "10.6.37.19"
          when "3"
            "10.6.38.159"
          when "4"
            "10.6.36.40"
          when "5"
            "10.6.37.60"
        end
      when "d"
        "10.6.36.166"
      when "p"
        case _num
          when "1"
            "10.6.16.234"
        end
    end
  end

  def self.get_host_from_role_env_subenv(_environment, _subenv, _role, _naming, _num=1)
    # presently ignoring naming
    case _subenv
      when "cert"
        dqa=""    
      when "dev"
        dqa="d"
      when "qa"
        dqa="q"
      else
        dqa=""
    end

    prefix = PuppetTools.get_prefix(_environment, dqa)

    "#{prefix}#{_role}#{_num.to_s.rjust(3, "0")}"
  end

  def self.get_other_env(_environment)
    case _environment
      when "cit_certification"
        "cit_production"
      when "cit_production"
        "cit_certification"
      when "cit_dr"
        ""
    end
  end

  def self.get_access_cidr_from_environment(_environment)
    case _environment
      when "cit_certification"
        "10.6.39.0/26,10.6.39.64/26"
      when "cit_production"
        "10.6.33.64/26,10.6.33.128/26,10.6.33.192/26"
      when "cit_dr"
        ""
    end
  end

  def self.get_sg_prefix(environment, dqa="")
    case environment
      when "cit_certification"
        case dqa
          when "" 
            "cit_c"
          when "d"
            "cit_d"
          when "q"
            "cit_q"
          when "i"
            "snaws"
        end
      when "cit_production"
        case dqa
          when ""
            "cit_p"
          when "i"
            "snaws"
        end
      when "cit_dr"
        case dqa
          when ""
            "cit_d"
          when "i"
            "snaws"
        end
    end
  end

  def self.get_prefix(environment, dqa="")
    case environment
      when "cit_certification"
        case dqa
          when ""
            "cit-c-"
          when "c"
            "cit-c-"
          when "d"
            "cit-d-"
          when "q"
            "cit-q-"
          when "i"
            "snaws"
        end    
      when "cit_production"
        case dqa
          when ""
            "cit-p-"
          when "i"
            "snaws"
        end
      when "cit_dr"
        case dqa
          when ""
            "cit-d-"
          when "i"
            "snaws"
        end
    end
  end

  def self.get_puppet_environment(_environment)
    case _environment
      when "cit_certification"
        "certification"
      when "cit_production"
        "production"
      when "cit_dr"
        "dr"
    end
  end

  def self.get_env_short(_environment, _naming)
    case _environment
      when "cit_certification"
        case _naming
          when "puppet role"
            "crt"
          when "iamsabre name"
            ""
        end
      when "cit_production"
        case _naming
          when "puppet role" 
            "prd"
          when "iamsabre name"
            ""
        end
      when "cit_dr"
        "dr"
    end
  end

  def self.get_environment_from_subnet(_subnet)
    part = _subnet.split("_")[1]
    case part
      when "prd"
        "cit_production"
       when "hub"
        "cit_production"
      when "dr"
        "cit_dr"
      when "cert"
        "cit_certification"
    end
  end

  def self.get_tier_from_subnet(_subnet)
    _subnet.split("_")[2]
  end

  def self.get_tags_from_business(_role, _created_by="")
    out = Hash.new

    if (_created_by == "")
      profile_hash = PuppetTools.get_tags_from_profile(_role)
      out["created_by"] = profile_hash["created_by"]
    else
      out["created_by"] = _created_by
    end 

    first_tier = BusinessTools.get_first_tier_from_role(_role)
    second_tier = BusinessTools.get_second_tier_from_role(_role)
    third_tier = BusinessTools.get_third_tier_from_role(_role)

    out["business_unit"] = first_tier
    out["business_service"] = second_tier
    out["technical_service"] = third_tier

    raise "could not find Business Unit, Business Service, Technical Service in role profile metadata.json" if (out["business_unit"].empty? || out["business_service"].empty? || out["technical_service"].empty?)
    
    out
  end

  def self.get_tags_from_profile(_role)
    out = Hash.new

    Dir.mktmpdir do |dir|
      p "trying to git clone [#{GITURL}/profiles/sabre-profile_#{_role}.git]"
      `git clone #{GITURL}/profiles/sabre-profile_#{_role}.git #{dir}`

      bfile = File.read("#{dir}/metadata.json")
      bdata = JSON.parse(bfile)
      out["business_unit"] = bdata["business_unit"]
      out["business_service"] = bdata["business_service"]
      out["technical_service"] = bdata["technical_service"]
      out["created_by"] = bdata["created_by"]

      raise "could not find Business Unit, Business Service, Technical Service in role profile metadata.json" if (out["business_unit"].empty? || out["business_service"].empty? || out["technical_service"].empty?)
    end

    out
  end

  def self.get_bu_bs_ts_from_profile(_role)
    out = Hash.new

    Dir.mktmpdir do |dir|
      `git clone #{GITURL}/profiles/sabre-profile_#{_role}.git #{dir}`

      bfile = File.read("#{dir}/metadata.json")
      bdata = JSON.parse(bfile)
      out["business_unit"] = bdata["business_unit"]
      out["business_service"] = bdata["business_service"]
      out["technical_service"] = bdata["technical_service"]

      raise "could not find Business Unit, Business Service, Technical Service in role profile metadata.json" if (out["business_unit"].empty? || out["business_service"].empty? || out["technical_service"].empty?)
    end

    out
  end

  def self.get_puppetmaster_fqdn_from_env(_env)
    case _env
      when "cit_certification"
        "cit-c-puppet001.crt.aws.cit.sabrenow.com"
      when "cit_production"
        "cit-p-puppet001.prd.aws.cit.sabrenow.com"
      when "cit_dr"
        "cit-d-puppet001.dr.aws.cit.sabrenow.com"
    end
  end

  def self.get_puppetmaster_ip_from_env(_env)
    case _env
      when "cit_certification"
        "10.6.39.7"
      when "cit_production"
        "10.6.33.111"
      when "cit_dr"
        "10.6.33.999"
    end
  end

  def self.get_domain_from_env(_env)
    case _env
      when "cit_certification"
        "crt.aws.cit.sabrenow.com"
      when "cit_production"
        "prd.aws.cit.sabrenow.com"
      when "cit_dr"
        "dr.aws.cit.sabrenow.com"
    end
  end

  def self.get_next_number(_dir, _role, _naming)
    last = `ls #{_dir}/|grep #{_role}|grep -v #{_role}_sg|tail -1`
  p "found #{last}"

    if last.empty?
      case _naming
        when "iamsabre name"
          '01'
        when "puppet role"
          '001'
      end
    else
      lastnum = last.strip.delete("a-zA-Z.\-").split(//).last(3).join("").to_s
      out = Integer(lastnum) + 1
      case _naming
        when "iamsabre name"
          out.to_s.rjust(2, "0")
        when "puppet role"
          out.to_s.rjust(3, "0")
      end
    end
  end

  def self.get_new_template_name(_template)
    # figure out naming
    naming = "puppet role"

    case naming
      when "puppet role" 
        digits = _template.scan(/\d+/).first.to_i
        digts = digits.to_s.rjust(3, "0")
        nondigits = _template.gsub(digts, '').gsub(".json","")
        newdigits = (digits + 1).to_s.rjust(3, "0")
        "#{nondigits}#{newdigits}.json"
      when "iamsabre"
    end
  end

  def self.get_role_from_instance(_instance)
#    _instance.gsub(/\d{3}\z/,"")
    pre = _instance[0..3]
    case pre
      when "snaw"
        _instance.gsub(/\d{2}$/,"").gsub("snaws","")
      when "cit-"
        _instance.gsub(/\d{3}$/,"").gsub("cit-c-","").gsub("cit-p-","").gsub("cit-q-","").gsub("cit-d-","")
    end
    # TODO iamsabre hostname is actually something like snawsdbodsw01
    #       role is bodsw - the 'd' befor eit means 'dev', it needs to be removed
  end

  def self.get_role_from_hostname(_hostname)
    _hostname.gsub(/\d{3}$/,"").split("-")[2]
  end

  def self.strip_off_number_from_hostname(_name)
    _name.gsub /\ \d+/, ''
  end

  def self.strip_off_prefix_from_hostname(_name)
    _name.split('-')[2] == nil ? _name : _name.split('-')[2]
  end

  def self.strip_off_prefix_from_template(_name)
    _name.split('-')[2] == nil ? _name.gsub(".json","") : _name.split('-')[2].gsub(".json","")
  end
##############################################################################################
# setters
##############################################################################################

  def self.add_new_profile_to_puppetfile(_role, _environment)
    env = get_puppet_environment(_environment)
    Dir.mktmpdir do |dir|
      git_dir="#{dir}"
# Puppetfile is branched
#      `git clone #{GITURL2}/control/corpit-env_control.git #{dir}`
      `git clone -b #{env} #{GITURL}/control/corpit-env_control.git #{dir}`
      open("#{dir}/Puppetfile", 'a') do |f|
        f.puts "\nmod 'profile_#{_role}',"
        f.puts "  :git    => 'https://gitlab.sabrenow.com/profiles/sabre-profile_#{_role}.git'"
      end

      raise "Could not commit to local git repo for Puppetfile" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} commit -a -m "provisioning add new profile repo for role=#{_role}"`
# Puppetfile is branched
#      raise "Could not push to origin master" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} push origin master`
      raise "Could not push to origin #{env}" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} push origin #{env}`
    end

   true
  end
  
#TODO fix this - Puppetfile is branched!
  def self.remove_profile_from_puppetfile(_role)
  # #{GITURL2}/control/corpit-env_control/Puppetfile
    Dir.mktmpdir do |dir|
      git_dir="#{dir}"
      `git clone #{GITURL}/control/corpit-env_control.git #{dir}`
  
      File.open("#{dir}/Puppetfile.temp", "w+") do |out_file|
        File.foreach("#{dir}/Puppetfile") do |line|
          out_file.puts line unless line.include?("profile_#{_role}")
        end
      end
  
      FileUtils.mv("#{dir}/Puppetfile.temp", "#{dir}/Puppetfile")
  
      raise "Could not commit to local git repo for Puppetfile" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} commit -a -m "provisioning remove profile repo for role=#{_role}"`
      raise "Could not push to origin master" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} push origin master`
    end
  
   true
  end

  def self.get_os_profile(_os)
    case _os
      when "windows"
        "profile_windows_standard"
      when "linux"
        "linux_standard"
    end
  end

  def self.store_metaparam(_metadata_repo, _metadata_dir, _key, _value)
    Dir.mktmpdir do |dir|
      # TODO git clone _metadata_repo, cd _metadata_dir
      file = FIle.read("#{dir}/#{_metadata_dir}/metadata.json")
      metadata = JSON.parse(file)
      metadata[_key] = _value
      File.open("#{dir}/#{_metadata_dir}/metadata.json", "w") do |h|
        h.write JSON.pretty_generate(metadata)
      end
    end
  end

  def self.add_new_module_to_puppet(_module, _environment, _bu, _bs, _ts, _creator)
    Dir.mktmpdir do |dir|
      `cd #{dir};puppet module generate --skip-interview sabre-#{_module}`
      file = File.read("#{dir}/sabre-#{_module}/metadata.json")
      metadata = JSON.parse(file)
      metadata["summary"] = "default summary created by provisioning.  CHANGEME!"
      metadata["license"] = "Sabre Proprietary"
      metadata["source"] = "#{GITURL}/modules/sabre-#{_module}"
      metadata["project_page"] = "#{GITURL}/modules/sabre-#{_module}"
      metadata["issues_url"] = "#{GITURL}/modules/sabre-#{_module}/issues"
      metadata["business_unit"] = _bu
      metadata["business_service"] = _bs
      metadata["technical_service"] = _ts
      metadata["created_by"] = _creator
      File.open("#{dir}/sabre-#{_module}/metadata.json", 'w') do |h|
        h.write JSON.pretty_generate(metadata)
      end
  
      p "creating module repo on gitlab"
  
      apitoken="_MnVsxXVgyAMsEsV7yCC"
      reponame="sabre-#{_module}"
  
      raise "Could not create new gitlab repo with curl" unless out=`. /var/lib/jenkins/bin/git_create_module \"#{reponame}\" \"#{apitoken}\"`
  
      p "checking in new puppet boilerplate"
  
      raise "Could not git init for new boilerplate repo" unless `cd #{dir}/sabre-#{_module}/;git init`
      raise "Could not git add in new boilerplate repo" unless `git --git-dir=#{dir}/sabre-#{_module}/.git/ --work-tree=#{dir}/sabre-#{_module} add .`
      raise "Could not commit to new boilerplate repo" unless `git --git-dir=#{dir}/sabre-#{_module}/.git/ --work-tree=#{dir}/sabre-#{_module} commit -m \"first commit\"`
      raise "Could not add origin to new boilerplate repo" unless  `git --git-dir=#{dir}/sabre-#{_module}/.git/ --work-tree=#{dir}/sabre-#{_module} remote add origin #{GITURL}/modules/sabre-#{_module}.git`
      raise "Could not push to master new boilerplate repo" unless `git --git-dir=#{dir}/sabre-#{_module}/.git/ --work-tree=#{dir}/sabre-#{_module} push origin master`
      true
    end
  end

  def self.add_new_module_to_puppetfile(_module, _env)
    env = get_puppet_environment(_environment)
    Dir.mktmpdir do |dir|
      git_dir="#{dir}"
      # Defect Pulletfile is branched
      #{}`git clone #{GITURL}/control/corpit-env_control.git #{dir}`
      `git clone -b #{env} #{GITURL}/control/corpit-env_control.git #{dir}`
      open("#{dir}/Puppetfile", 'a') do |f|
        f.puts "\nmod '#{_module}',"
        f.puts "  :git    => 'https://gitlab.sabrenow.com/modules/sabre-#{_module}.git'"
      end
  
      raise "Could not commit to local git repo for Puppetfile" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} commit -a -m "provisioning add new module repo for #{_module}"`
      raise "Could not push to origin #{env}" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} push origin #{env}`
    end
  
   true
  end
 
  def self.remove_profile_repo_from_puppet(_role, _environment)
    Dir.mktmpdir do |dir|
      JenkinsTools.plan_out("removing profile repo from gitlab")
  
      #TODO remove profile repo from gitlab
  
      apitoken="_MnVsxXVgyAMsEsV7yCC"
      reponame="sabre-profile_#{_role}"
  
      raise "Could not delete gitlab repo with curl" unless out=`. /var/lib/jenkins/bin/git_delete_remote \"#{reponame}\" \"#{apitoken}\"`
  
      true
    end
  end
 
 def self.add_key_value_in_hieradata_role_file(_key, _value, _role, _environment)
    Dir.mktmpdir do |dir|
      git_dir="#{dir}"
      `git clone #{GITURL}/data/corpit-systemdata.git #{dir}`
      hieradata = YAML.load_file("#{dir}/hieradata/systemconfiguration/#{_environment}/roles/#{_role}.yaml")
      hieradata[_key] = _value
      File.open("#{dir}/hieradata/systemconfiguration/#{_environment}/roles/#{_role}.yaml",'w') do |h|
        h.write hieradata.to_yaml
      end

      raise "Could not commit to local git repo for puppet" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} commit -a -m "provisioning add new key/value for role=#{_role}"`
      raise "Could not push to origin master" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} push origin master`
    end

    true
  end

  def self.add_new_role_to_puppet(_role, _os, _environment)
    roleh = Hash.new
    os_profile = get_os_profile(_os)
    role_profile = "profile_#{_role}"
    roleh[_role] = [os_profile, role_profile]

    Dir.mktmpdir do |dir|
      git_dir="#{dir}"
      `git clone #{GITURL}/data/corpit-systemdata.git #{dir}`
      system_role = YAML.load_file("#{dir}/hieradata/systemconfiguration/#{_environment}/system_role.yaml")
      system_role["system_role::profiles"].merge!(roleh)
      File.open("#{dir}/hieradata/systemconfiguration/#{_environment}/system_role.yaml",'w') do |h|
        h.write system_role.to_yaml
      end

      raise "Could not commit to local git repo for puppet" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} commit -a -m "provisioning add puppet role for role=#{_role}"`
      raise "Could not push to origin master" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} push origin master`
    end

    true
  end

  def self.remove_role_from_puppet(_role, _environment)
    Dir.mktmpdir do |dir|
      git_dir="#{dir}"
      `git clone #{GITURL}/data/corpit-systemdata.git #{dir}`
      system_role = YAML.load_file("#{dir}/hieradata/systemconfiguration/#{_environment}/system_role.yaml")
  # remove from
      system_role["system_role::profiles"].delete(_role)
      File.open("#{dir}/hieradata/systemconfiguration/#{_environment}/system_role.yaml",'w') do |h|
        h.write system_role.to_yaml
      end
  
      raise "Could not commit to local git repo for puppet" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} commit -a -m "provisioning remove puppet role for role=#{_role}"`
      raise "Could not push to origin master" unless `git --git-dir=#{git_dir}/.git/  --work-tree=#{git_dir} push origin master`
    end
  
    true
  end

  def self.add_new_profile_to_puppet(_role, _environment, _bu, _bs, _ts, _creator)
    Dir.mktmpdir do |dir|
      `cd #{dir};puppet module generate --skip-interview sabre-profile_#{_role}`
      file = File.read("#{dir}/sabre-profile_#{_role}/metadata.json")
      metadata = JSON.parse(file)
      metadata["summary"] = "default summary created by provisioning.  CHANGEME!"
      metadata["license"] = "Sabre Proprietary"
      metadata["source"] = "#{GITURL}/profiles/sabre-profile_#{_role}"
      metadata["project_page"] = "#{GITURL}/profiles/sabre-profile_#{_role}"
      metadata["issues_url"] = "#{GITURL}/profiles/sabre-profile_#{_role}/issues"
      metadata["business_unit"] = _bu
      metadata["business_service"] = _bs
      metadata["technical_service"] = _ts
      metadata["created_by"] = _creator
      File.open("#{dir}/sabre-profile_#{_role}/metadata.json", 'w') do |h|
        h.write JSON.pretty_generate(metadata)
      end

      p "creating profile repo on gitlab"

      apitoken="_MnVsxXVgyAMsEsV7yCC"
      reponame="sabre-profile_#{_role}"

      raise "Could not create new gitlab repo with curl" unless out=`. /var/lib/jenkins/bin/git_create_remote \"#{reponame}\" \"#{apitoken}\"`

      p "checking in new puppet boilerplate"

      raise "Could not git init for new boilerplate repo" unless `cd #{dir}/sabre-profile_#{_role}/;git init`
      raise "Could not git add in new boilerplate repo" unless `git --git-dir=#{dir}/sabre-profile_#{_role}/.git/ --work-tree=#{dir}/sabre-profile_#{_role} add .`
      raise "Could not commit to new boilerplate repo" unless `git --git-dir=#{dir}/sabre-profile_#{_role}/.git/ --work-tree=#{dir}/sabre-profile_#{_role} commit -m \"first commit\"`
      raise "Could not add origin to new boilerplate repo" unless  `git --git-dir=#{dir}/sabre-profile_#{_role}/.git/ --work-tree=#{dir}/sabre-profile_#{_role} remote add origin #{GITURL}/profiles/sabre-profile_#{_role}.git`
      raise "Could not push to master new boilerplate repo" unless `git --git-dir=#{dir}/sabre-profile_#{_role}/.git/ --work-tree=#{dir}/sabre-profile_#{_role} push origin master`
      true
    end
  end

#  def self.insert_default_parameters(_template_path, _environment, _tier, _os, _role, _hostname, _subnet, _ec2size, _pm_fqdn, _pm_ip, _dom, _bu, _bs, _ts, _subnet_id)
#    tfile = File.read(_template_path)
#    tdata = JSON.parse(tfile)
#
#  # default_linux_no_sg.json needs ("Parameters"):
#  # "KeyName", "InstanceType", "Role", "Puppetmasterfqdn", "Puppetmasterip", "Domain", "Environment", "Hostname", "ShortHostname", "BusinessUnit", "TechnicalService", "OS", "SubnetId", "SecurityGroupId"
#
#    shorthostname = _hostname.split('.')[0]
#    tdata["Description"] = "Sabre AWS CIT Infrastructure template for #{_os} in #{_environment}"
#    tdata["Parameters"]["InstanceType"]["Default"] = _ec2size
#    tdata["Parameters"]["Role"]["Default"] = _role
#    tdata["Parameters"]["Puppetmasterfqdn"]["Default"] = PUPPETMASTER_FQDN
#    tdata["Parameters"]["Puppetmasterip"]["Default"] = PUPPETMASTER_IP
#    tdata["Parameters"]["Domain"]["Default"] = DOMAIN
#    tdata["Parameters"]["Environment"]["Default"] = _environment
#    tdata["Parameters"]["Hostname"]["Default"] = _hostname
#    tdata["Parameters"]["ShortHostname"]["Default"] = shorthostname
#    tdata["Parameters"]["BusinessUnit"]["Default"] = BUSINESS_UNIT
#    tdata["Parameters"]["TechnicalService"]["Default"] = TECHNICAL_SERVICE
#    tdata["Parameters"]["BusinessService"]["Default"] = BUSINESS_SERVICE
#    tdata["Parameters"]["OS"]["Default"] = _os
#    tdata["Parameters"]["SubnetId"]["Default"] = _subnet_id
#  
#    File.open(_template_path, "w") do |t|
#      t.write JSON.pretty_generate(tdata)
#    end
#    true
#  end

  def self.insert_default_sg_parameters(_template_path, _role, _portsin, _vpcid, _sg_name, _custom, _bu, _bs, _ts, _default_cidr)
  
  #foo="/var/lib/jenkins/jobs/Create\ a\ Security\ Group/workspace/corpit-cloudformation-vm-provisioning/environments/cit_production/int/cit-p-wbap_sg.json"
  foo="#{_template_path}".gsub("\\","")
  
    tfile = File.read(foo)
    tdata = JSON.parse(tfile)
  
    tdata["Description"] = "Sabre AWS CIT Infrastructure template for security group"
    tdata["Parameters"]["SecurityGroupName"]["Default"] = _sg_name
    tdata["Parameters"]["Role"]["Default"] = _role
    tdata["Parameters"]["VPCID"]["Default"] = _vpcid
    tdata["Parameters"]["BusinessUnit"]["Default"] =  _bu
    tdata["Parameters"]["TechnicalService"]["Default"] = _ts
    tdata["Parameters"]["BusinessService"]["Default"] = _bs
    tdata["Parameters"]["SourceCidr"]["Default"] = _default_cidr
  
    # tcp:80:80:10.23.227.10/32
    if _custom == true
      _portsin.split(",").each do |c|
        carr = c.split(":")
        ipp = carr[0]
        fp = carr[1]
        tp = carr[2]
        cidr = carr[3]
        h = {}
        h["IpProtocol"] = ipp
        h["FromPort"] = fp
        h["ToPort"] = tp
        h["CidrIp"] = cidr
        tdata["Resources"]["SecurityGroup"]["Properties"]["SecurityGroupIngress"] << h
      end
    end
  
    File.open(foo, "w") do |t|
      t.write JSON.pretty_generate(tdata)
    end
    true
  end

  def self.refresh_r10khiera(_env)
    # tested 2/10 100% works!
    hostname = `hostname -a`
    if ( hostname =~ /\w{3}-\w-\w*\d{3}/ )
      # hostname is format of cit-p-mgmt001
      case hostname.split('-')[1]
        when 'c'
          case _env
            when "cit_certification"
              p "about to 'ssh cit-c-puppet001 bin/update_hiera.bash..."
              `ssh -q root@cit-c-mgmt001 "ssh cit-c-puppet001 bin/update_hiera.bash"`
            when "cit_production"
              p "about to 'ssh cit-p-puppet001 bin/update_hiera.bash..."
              `ssh -q root@cit-c-mgmt001 "ssh 10.6.33.111 bin/update_hiera.bash"`
          end
        when 'p'
          case _env
            when "cit_certification"
              p "about to 'ssh cit-c-puppet001 bin/update_hiera.bash..."
              `ssh -q root@cit-c-mgmt001 "ssh cit-c-puppet001 bin/update_hiera.bash"`
            when "cit_production"
              p "about to 'ssh cit-p-puppet001 bin/update_hiera.bash..."
              `ssh -q root@cit-p-mgmt001 "ssh 10.6.33.111 bin/update_hiera.bash"`
          end
      end      
    else
      p "ERROR hostname of jenkins server is not correct!  Cannot sync r10k now"
      # hostname is not of format cit-p-mgmt001
    end  
  end 

  def self.refresh_r10k(_env)
    # tested 2/10 100% works!
    hostname = `hostname -a`
    if ( hostname =~ /\w{3}-\w-\w*\d{3}/ )
      # hostname is format of cit-p-mgmt001
      case hostname.split('-')[1]
        when 'c'
          case _env
            when "cit_certification"
              `ssh -q root@cit-c-mgmt001 "ssh cit-c-puppet001 bin/r10k_run.bash"`
            when "cit_production"
              `ssh -q root@cit-c-mgmt001 "ssh 10.6.33.111 bin/r10k_run.bash"`
          end
        when 'p'
          case _env
            when "cit_certification"
              `ssh -q root@cit-c-mgmt001 "ssh cit-c-puppet001 bin/r10k_run.bash"`
            when "cit_production"
              `ssh -q root@cit-p-mgmt001 "ssh 10.6.33.111 bin/r10k_run.bash"`
          end
      end      
    else
      p "ERROR hostname of jenkins server is not correct!  Cannot sync r10k now"
      # hostname is not of format cit-p-mgmt001
    end  
  end  

  def self.refresh_puppet(_env, _host, _pre="", _post="")

    hostname = `hostname -a`
    if ( hostname =~ /\w{3}-\w-\w*\d{3}/ )
      # hostname is format of cit-p-mgmt001
      case hostname.split('-')[1]
        when 'c'
          case _env
            when "cit_certification"
              `ssh -q root@cit-c-mgmt001 \"/root/bin/refpuppet #{_host} '#{_pre}' '#{_post}'\"`
            when "cit_production"
              `echo not ready for prod yet`
          end
        when 'p'
          case _env
            when "cit_certification"
              `ssh -q root@cit-c-mgmt001 \"/root/bin/refpuppet #{_host} '#{_pre}' '#{_post}'\"`
            when "cit_production"
              `echo not ready for prod yet`
          end
      end      
    else
      p "ERROR hostname of jenkins server is not correct!  Cannot refresh puppet now"
      # hostname is not of format cit-p-mgmt001
    end  
  end  

  def self.clean_puppet_host_cert(_env, _role, _num)
    # _num is 3-digit right-justified with 0's
    hostname = `hostname -a`
    if ( hostname =~ /\w{3}-\w-\w*\d{3}/ )
      # hostname is format of cit-p-mgmt001
      case hostname.split('-')[1]
        when 'c'
          case _env
            when "cit_certification"
              `ssh -q root@cit-c-puppet001 "puppet cert clean cit-c-#{_role}#{_num}.crt.aws.cit.sabrenow.com"`
            when "cit_production"
              `ssh -q root@cit-p-puppet001 "puppet cert clean cit-p-#{_role}#{_num}.prd.aws.cit.sabrenow.com"`
          end
        when 'p'
          case _env
            when "cit_certification"
              `ssh -q root@cit-c-puppet001 "puppet cert clean cit-c-#{_role}#{_num}.crt.aws.cit.sabrenow.com"`
            when "cit_production"
              `ssh -q root@cit-p-puppet001 "puppet cert clean cit-c-#{_role}#{_num}.prd.aws.cit.sabrenow.com"`
          end
      end      
    else
      p "ERROR hostname of jenkins server is not correct!  Cannot work with puppet now"
      # hostname is not of format cit-p-mgmt001
    end 
    p out
  end
end
