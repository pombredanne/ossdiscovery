# binary_match_rule.rb
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

$:.unshift File.join(File.dirname(__FILE__), '..')
require 'matchrules/filename_match_rule'
require File.join(File.dirname(__FILE__), '..', 'conf', 'config')

class BinaryMatchRule < FilenameMatchRule
  
  @@log = Config.log
  
  attr_accessor :defined_regexp
  
  def initialize(name, defined_filename, defined_regexp)
    super(name, defined_filename)
    @type = MatchRule::TYPE_BINARY
    @defined_regexp = defined_regexp
    
    # This is a Hash (location (a fully qualified directory) -> set of versions found in that directory)
    @matched_against = Hash.new
  end
  
  def match?(actual_filepath, actual_filepath_binary_content=nil)
    @match_attempts = @match_attempts + 1
    val = false
    match_value = BinaryMatchRule.get_match_value(@defined_filename, @defined_regexp, actual_filepath, actual_filepath_binary_content)
    if (match_value != nil) then
      val = true
      match_set = Set.new
      if (@matched_against.has_key?(File.dirname(actual_filepath))) then
        match_set = @matched_against[File.dirname(actual_filepath)]
        @@log.debug('BinaryMatchRule') {"Multiple versions of the same project likely exist in the same directory. MatchRule name: '#{@name}', version: '#{@version}', defined filename: '#{@defined_filename}', defined_regexp: '#{@defined_regexp}'"}
      end
      
      start, finish = match_value.offset(1)
      s = match_value.string
      mv = (start...finish).inject("") { |all, character| all << s[character] }
      match_set << mv
      @latest_match_val = mv
      
      @matched_against[File.dirname(actual_filepath)] = match_set
    end
    
    return val;    
  end
  
=begin rdoc
  Returns a Set of versions (strings) that were found as the result of 
  previously running matches over a set of files with this MatchRule.
=end   
  def get_found_versions(location)
    versions = Set.new
    match_set = @matched_against[location]
    if (match_set != nil) then
      match_set.each { |match_val|
        versions << match_val
      }
    end
    return versions
  end
  
  def BinaryMatchRule.get_match_value(defined_filename, defined_regexp, actual_filepath, actual_filepath_binary_content=nil)
    match_value = nil
    binary_content = nil
    if (FilenameMatchRule.match?(defined_filename, actual_filepath))
      if (actual_filepath_binary_content == nil) then
        binary_content = get_binary_content_for(actual_filepath)
      else
        binary_content = actual_filepath_binary_content
      end
      
      begin
        match_value = binary_content.match(defined_regexp)
      rescue
        $stderr.printf("\nregular expression match error:\n%s in match rule: %s\n", $!, name )
        $stderr.printf("defined_filename: %s, defined_regexp: %s, actual_filepath: %s\n", defined_filename, defined_regexp, actual_filepath )
        raise
      end
    end
    return match_value
  end
  
  def BinaryMatchRule.get_binary_content_for(actual_filepath) 
    binary_file = File.new(actual_filepath)
    binary_file.binmode
    binary_content = binary_file.read
    binary_file.close
    return binary_content
  end
  
  def BinaryMatchRule.create(attributes)
    bmr = BinaryMatchRule.new(attributes['name'], attributes['filename'], attributes['regexp'])  
    return bmr
  end
end
