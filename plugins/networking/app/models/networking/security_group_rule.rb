module Networking
  class SecurityGroupRule < Core::ServiceLayer::Model
    RULE_TYPES = HashWithIndifferentAccess.new(YAML.load(File.open("#{::Core::PluginsManager.plugin('networking').path}/config/security_group_rule_types.yml", 'r')))

    DESCRIPTIONS = RULE_TYPES[:descriptions]
    PREDEFINED_RULE_TYPES = RULE_TYPES[:predefined_types]
    PROTOCOLS = RULE_TYPES[:protocols]
    
    PROTOCOL_LABELS = PROTOCOLS.inject({}){|hash,(protocol_name,label)| hash[label]=protocol_name; hash}
    TYPE_LABELS = PREDEFINED_RULE_TYPES.inject({}){|hash,(rule_name,rule)| hash[rule['label']]=rule_name; hash}
    
    PORT_RANGE_RULE = PREDEFINED_RULE_TYPES.inject({}){|hash,(rule_name,rule)| hash[rule['port_range'].to_s]= rule; hash }
    
    def port_range
      if port_range_min.blank? && port_range_max.blank?
        nil
      elsif port_range_min.blank? 
        port_range_max
      elsif port_range_max.blank?
        port_range_min
      else          
        "#{port_range_min}-#{port_range_max}"
      end          
    end
    
    def display_port
      port = if self.port_range_min.blank? and self.port_range_max.blank? 
        nil
      elsif self.port_range_min.blank? and !self.port_range_max.blank?
        self.port_range_max
      elsif !self.port_range_min.blank? and self.port_range_max.blank?
        self.port_range_min
      elsif self.port_range_min==self.port_range_max
        self.port_range_min
      else
        "#{self.port_range_min}-#{self.port_range_max}"
      end
      
      if port 
        rule = PORT_RANGE_RULE[port.to_s] 
        port = port.to_s
        port += " (#{rule['label']})" if rule 
      else
        "Any"
      end
    end
  end
end
