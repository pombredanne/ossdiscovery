# filename_version_match_rule.rb
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
# If not, see http://www.gnu.org/licenses
#  
# You can learn more about OSSDiscovery, report bugs and get the latest versions at www.ossdiscovery.org.
# You can contact the OSS Discovery team at info@ossdiscovery.org.
# You can contact OpenLogic at info@openlogic.com.


# --------------------------------------------------------------------------------------------------
#

$:.unshift File.join(File.dirname(__FILE__), '..')
require 'matchrules/filename_match_rule'
require File.join(File.dirname(__FILE__), '..', 'conf', 'config')

require 'set'

class FilenameVersionMatchRule < FilenameMatchRule
  
  @@log = Config.log
  
  def initialize(name, defined_filename)
    super(name, defined_filename)
    @type = MatchRule::TYPE_FILENAME_VERSION
    
    # This is a Hash (location (a fully qualified directory) -> set of versions found in that directory)
    @matched_against = Hash.new
  end
  
  def match?(actual_filepath, archive_parents)
    @match_attempts = @match_attempts + 1
    val = false    
    match_val = FilenameVersionMatchRule.match?(@defined_filename, actual_filepath)
    if match_val
      val = true
      match_set = Set.new
      dir = File.dirname(actual_filepath)
      if @matched_against.has_key?(dir)
        match_set = @matched_against[dir]
        @@log.debug('FilenameVersionMatchRule') {"Multiple versions of the same project likely exist in the same directory. MatchRule name: '#{@name}', version: '#{@version}', defined filename: '#{@defined_filename}', defined_regexp: '#{@defined_regexp}'"}
      end
      mv = match_val[1]
      unless mv
        @@log.info('FilenameVersionMatchRule') {"Got a nil match value when matching #{@defined_filename} against #{actual_filepath}.  Probably a filenameVersion rule with a regex to capture the version." }
        mv = "unknown"
      end
      match_set << [mv.strip, archive_parents, File.basename(actual_filepath)]
      @latest_match_val = mv
      @matched_against[dir] = match_set
    end
    
    val
  end

  
=begin rdoc
  Returns a Set of versions (strings) that were found as the result of 
  previously running matches over a set of files with this MatchRule.
=end   
  def get_found_versions(location)
    @matched_against[location] || []
  end
  
  def FilenameVersionMatchRule.match?(defined_filename, actual_filepath)
    val = nil    
    basename = File.basename(actual_filepath)

    match_val = basename.match(defined_filename)
    if (match_val != nil) then
      val = match_val
    end
    return val
  end

  def FilenameVersionMatchRule.create(attributes)
    fmr = FilenameVersionMatchRule.new(attributes['name'], attributes['filename'])
    return fmr
  end
end
