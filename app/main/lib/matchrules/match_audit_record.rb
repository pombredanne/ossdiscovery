# match_audi_record.rb
#
# LEGAL NOTICE
# -------------
# 
# OSS Discovery is a tool that finds installed open source software.
#    Copyright (C) 2007-2009 OpenLogic, Inc.
#  
# OSS Discovery is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License version 3 as 
# published by the Free Software Foundation.  
#  
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License version 3 (discovery2-client/license/OSSDiscoveryLicense.txt) 
# for more details.
#  
# You should have received a copy of the GNU Affero General Public License along with this program.  
# If not, see http://www.gnu.org/licenses/
#  
# You can learn more about OSSDiscovery, report bugs and get the latest versions at www.ossdiscovery.org.
# You can contact the OSS Discovery team at info@ossdiscovery.org.
# You can contact OpenLogic at info@openlogic.com.
#
#
# --------------------------------------------------------------------------------------------------
#

class MatchAuditRecord
  attr_accessor :project_rule_name, :match_rule_set_name, :match_rule_name, :foi_that_matched, :version
  
  def initialize(project_rule_name, match_rule_set_name, match_rule_name, foi_that_matched, version)
    @project_rule_name = project_rule_name
    @match_rule_set_name = match_rule_set_name
    @match_rule_name = match_rule_name
    @foi_that_matched = foi_that_matched
    @version = version
  end
  
  def to_s
    return "ProjectRule:#{@project_rule_name},MatchRuleSet:#{@match_rule_set_name},MatchRule:#{@match_rule_name},Version:#{@version},matched on:#{@foi_that_matched}"
  end
  
end