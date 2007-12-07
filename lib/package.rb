# package.rb
#
# LEGAL NOTICE
# -------------
# 
# OSS Discovery is a tool that finds installed open source software.
#    Copyright (C) 2007 OpenLogic, Inc.
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


# --------------------------------------------------------------------------------------------------
#
=begin rdoc
  This class essentially represents a simple, flattened rendition of what packages were discovered 
  by the tool.  In addition to package names, versions and locations where they were found are 
  encapsulated here.  The class doesn't come into play until the scan itself is complete, and the
  process is on the stage of rolling up and analyzing results.

  There are also a few class methods that are used by the RuleAnalyzer to help roll up the results 
  of MatchRule states.  Namely, create_instances and make_packages_with_bad_unknowns_removed.
=end 

require 'set'

require File.join(File.dirname(__FILE__), 'conf', 'config')

class Package
  VERSION_UNKNOWN = "unknown"
  attr_accessor :name, :version, :found_at
  
=begin rdoc
  I don't know why they call this the 'spaceship' operator.  It looks more like 
  a mouth to me, so I'm calling it the 'mouth' operator.
=end  
  def <=>(other)
    val = 0
    if (self.name == other.name) then
      if (self.version == other.version) then
        if (self.found_at == other.found_at) then
          val = 0
        else
          val = self.found_at <=> other.found_at
        end
      else
        val = self.version <=> other.version
      end
    else
      val = self.name <=> other.name
    end
    
    return val
  end
  
  def eql?(other)
    if ((self.==(other)) && (self.class == other.class)) then
      return true
    else
      return false
    end
  end
  
  def ==(other)
    val = false
    if ((other.name == @name) && 
        (other.version == @version) &&
        (other.found_at == @found_at)) then
      val = true
    end
    return val
  end
  
  def hash
    val = 0
    val += @name.size
    val += @version.size
    val += @found_at.size
    
    return val
  end
  
  def Package.make_packages_with_bad_unknowns_removed(packages, project)
    no_unknowns = Set.new
    only_unknowns = Set.new
    packages.each do |pkg|
      if (pkg.name == project.name) then
        if (pkg.version != VERSION_UNKNOWN) then
          no_unknowns << pkg
        else
          only_unknowns << pkg
        end
      end
    end # of packages.each
    
    valid_packages = Set.new
    valid_packages.merge(no_unknowns)
    
    only_unknowns.each do |upkg|
      valid_unknown = true
      no_unknowns.each do |vpkg|
        if (vpkg.found_at == upkg.found_at) then
          valid_unknown = false
          break
        end
      end # of no_unknowns.each
      if (valid_unknown) then
        valid_packages << upkg
      end
    end # of only_unknowns.each
    
    return valid_packages
  end
  
  def Package.create_instances(locations, project_rule)
    
    instances = Array.new
    
    locations.each do |location|

      version_set = Set.new
      project_rule.rulesets.each do |ruleset|
        ruleset.match_rules.each do |match_rule|
          found_versions = match_rule.get_found_versions(location)
          found_versions.each do |version|
            if (version == nil || version == "") then
              version = VERSION_UNKNOWN
            end
            version_set << version
          end # of found_versions.each
        end
        
        # Essentially, here's what we're saying.
        # - If "unknown" was the only hit for a given location, report that.
        # - If we hit on "unknown" and some actual version, the "unknown" probably 
        #   only exists as kruft left around from an AND of two match rules (One that 
        #   could get us part of the way there, telling us the package existed, but not 
        #   knowing which version, and won that finished the job by telling us the version as well.)
        if (version_set.size > 1) then
          version_set.delete_if() {|version| version == VERSION_UNKNOWN}
        end
      end # of project_rule.rulesets.each
      version_set.each do |version|
          package = Package.new
          package.name = project_rule.name
          package.found_at = location
          # Doing this gsub because we ran into a scenario when using a hex binary match where the version looked like this: 2^@.^@3
          package.version = version.gsub("\0", "")
          
          instances << package
      end # of version_set.each
    end # of locations.each
    
    return instances
    
  end
  
end