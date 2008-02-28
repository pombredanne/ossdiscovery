# scan_rules_updater.rb
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

require 'find'
require 'fileutils'
require 'open-uri'
require 'set'
require 'net/http'
require File.join(File.dirname(__FILE__), 'conf', 'config')

begin
  # not all ruby installs and builds contain openssl, so degrade
  # gracefully if https can't be pulled in.
  require 'net/https'
  @@no_ssl = false
rescue LoadError => e
  # bail on using any HTTPS delivery mechanisms since the client machine
  # doesn't have the prerequisite software
  @@no_ssl = true
end


require 'rexml/document'

=begin rdoc
  ScanRulesUpdater, believe it or not, is responsible for updating scan rules.
  This is done by going out to a server and downloading the latest and greates scan rules.
=end    
class ScanRulesUpdater
  
@@log = Config.log
  
  attr_accessor :base_url, :proxy_host, :proxy_port, :proxy_username, :proxy_password
  
=begin rdoc
  Construct a ScanRulesUpdater.  The 'base_url' argument is intended to be the base_url of the site 
  that contains the list of rules files that tells what to download, and the actual downloadable 
  files themselves.

  EG...
  
  The following url is to the xml that will show all possible rules files.

    http://localhost:3000/rules_files.xml

  The 'base_url' in this case would be http://localhost:3000/

  -----

  The following url's are to the downloadable scan rules files themselves (the list of these will 
  have come from the aforementioned rules_files.xml).

    http://localhost:3000/rules/scan-rules.xml
    http://localhost:3000/rules/scan-rules-mvngen.xml

  Again, the 'base_url' is http://localhost:3000/

  -----
  
  This class assumes that the 'rules_file.xml' file and the downloadable files themselves with have
  the same 'base_url'
=end    
  def initialize(service_base_url, rules_file_base_url )

    if (service_base_url == nil)
      @base_url = "http://localhost:3000/"
    else
      if (service_base_url[service_base_url.size - 1 ..service_base_url.size - 1] == "/")
        @base_url = service_base_url
      else
        @base_url = service_base_url << "/"
      end
    end
    
    @proxy_host = nil
    @proxy_port = nil
    @proxy_username = nil
    @proxy_password = nil

    if ( rules_file_base_url == nil )
       @rules_file_base_url = "http://localhost:3000/"
    else
      @rules_file_base_url = rules_file_base_url
      if (@rules_file_base_url[ @rules_file_base_url.size - 1 ..@rules_file_base_url.size - 1] == "/")
        @rules_file_base_url = rules_file_base_url
      else
        @rules_file_base_url = rules_file_base_url << "/"
      end
    end
   
  end

=begin rdoc
  The most important method of this class.  The one intended to be used by outsiders.
  params:
    * local_scan_rules_dir - The path of the local scan rules directory housing all updateable scan rules.
      'updateable scan rules' are those that live in the 'rules/openlogic' directory of this client.  
      A distinction is being made because the user may create their own scan rules in the 'rules/drop_ins' directory.  
      The latter will not be updated, as the server does not have them.  This argument can be safely passed as nil, 
      and the ':rules_openlogic' property will be used from the client's config.yml.
    * rules_files_url_path - 

       There is no default for this value.  A valid value must be passed in for this operation to work.
 
=end  
  def update_scanrules(local_scan_rules_dir, rules_files_url_path)
    @@log.info("ScanRulesUpdater") {"Updating scan rules: local_scan_rules_dir: '#{local_scan_rules_dir}'; rules_files_url_path = '#{rules_files_url_path}'"}
    rules_files_url_path = ScanRulesUpdater.scrub_url_path(rules_files_url_path)
    
    # get the list of files that need to be downloaded
    begin
      rules_files_to_download = http_get_rules_files_to_download(rules_files_url_path)
    rescue Exception => ge
      raise ge, "Can't get the list of rules files to download (original message: #{ge.message}", ge.backtrace
      # either the server failed to respond or there was an issue on the client side or internet connection to the server
    end
    
    # back the scan rules dir up
    rules_dir = ""
    if (local_scan_rules_dir == nil) then
      rules_dir = ScanRulesUpdater.get_default_scan_rules_dir()
    else 
      rules_dir = File.expand_path(local_scan_rules_dir)
    end
    # after this, 'rules_dir' will no longer exist because it will have been mv'd to a new name
    backup_dir = ScanRulesUpdater.backup_scanrules_dir(rules_dir, nil) 
    
    # download the files
    FileUtils.mkdir(rules_dir) # making the directory for the rules to be downloaded into
      
    begin
      rules_files_to_download.each do |file_to_download|
        download_file(file_to_download.path, rules_dir)
      end
    rescue Exception => e
      ScanRulesUpdater.rollback_update(backup_dir)
      raise e, "Scan rules update failed, rollback performed.\nThe rules that were in effect before the update attempt occurred are still in effect.\n(original message: #{e.message})", e.backtrace
    end
    
  end

=begin rdoc
  Method is intended only as a helper internal to this class.  It is only accessible so it can be tested.

  Downloads a file (by streaming it down from the server).

  params:
    * file_to_download_path - As per the example given in the documentation for initialize, this refers to
      the actual downloadable scan rules file that is available on the server. Assuming you can 
      navigate to this file in a browser by going to 'http://localhost:3000/rules/scan-rules.xml', this value would be:
      
        /rules/scan-rules.xml
          or
        rules/scan-rules.xml
    * dest_dir - Where you want the file to be saved/downloaded to.

=end 
  def download_file(file_to_download_path, dest_dir="") 
    file_to_download_path = ScanRulesUpdater.scrub_url_path(file_to_download_path)
    
    File.open(File.join(dest_dir, File.basename(file_to_download_path)), "w") do |downloaded_file|
    
      if ( response_body = http_get_file( @rules_file_base_url + file_to_download_path ) )
        downloaded_file.write( response_body )
      end
    
    end # of File.open
    
  end

=begin rdoc
  requests a file of rules files to download.
  
  returns the contents as a set of rules files to download
=end

  def http_get_rules_files_to_download(rules_files_url_path)
    rules_files_url_path = ScanRulesUpdater.scrub_url_path(rules_files_url_path)
    response_body = http_get_file(@base_url + rules_files_url_path )

    xml_str = response_body
    
    xml = REXML::Document.new(xml_str)
    root = xml.root
    rules_files = Set.new
     
    root.elements.each do |xrules_file| 
      rf = RulesFile.new(xrules_file.attributes["path"])
      rules_files << rf
    end
    
    return rules_files
  end
  
=begin rdoc
  encapsulates all the support we need to do an http request - including https or proxy support
  several places needed the same functionality, so put it here. 
  
  returns a response object

  raises an Exception if the HTTP response was errant (aka... was not in the 2xx range).  
  Uses the Net::HTTPResponse.value method to do so.
  
  TODO - we may want to pull this out and extend Net::HTTP with this helper
=end  
  def http_get_file( a_url )
    @@log.debug("ScanRulesUpdater") {"Doing an HTTP Get on '#{a_url}'"}
    
    # Net::HTTP.Proxy will use a normal HTTP if proxy host and port are nil, so this code will work whether or not
    # proxy support is enabled, but if it's not enabled, proxy host and port need to be nil

    if !JAVA_HTTPS_AVAILABLE && RUBY_HTTPS_AVAILABLE

      begin
        parts = URI.split(a_url)
        protocol = parts[0]
        host = parts[2]
        port = parts[3]
        path = parts[5]


        if ( a_url.match("^https") && (port == nil || port == '') )
          port = 443
          http = Net::HTTP.new( host, port )
          http.use_ssl = true
        else
          http = Net::HTTP.new( host, 80 )
        end

        response = http.get( path )
		
        return response.body

      rescue Exception => e # most likely will be a Timeout::Error because a download failed midstream (the network cable yank scenario)
        raise e, "Failure trying to get '#{a_url}' (original message: #{e.message})", e.backtrace
      end
	    
      begin
        # Raises HTTP error if the response is not 2xx (aka... is not successful).
        response.value
      rescue => e
        raise e, "Trying to get '#{a_url}' produced an errant HTTP response. (original message: #{e.message})", e.backtrace
      end

    else
	# do it the Java way because for HTTPS through a proxy this will work in addition to the standard HTTPS post
        client = org.apache.commons.httpclient.HttpClient.new
        get = org.apache.commons.httpclient.methods.GetMethod.new( a_url )
        get.set_do_authentication( true )

        if ( @proxy_host != nil )
           # setting up proxy
           client.get_host_configuration().set_proxy(@proxy_host, @proxy_port)
           scope = Java::OrgApacheCommonsHttpclientAuth::AuthScope::ANY
           credentials = org.apache.commons.httpclient.UsernamePasswordCredentials.new( @proxy_user, @proxy_password )
           client.get_state().set_proxy_credentials( scope, credentials ) 
           # proxy credentials created
        end

        client.executeMethod( get )

        response = get.getResponseBodyAsString()
        return response
    end
   
    return nil 
  end
  
  
=begin rdoc
  Method is intended only as a helper internal to this class.  It is only accessible so it can be tested.

  Backs up the default scan rules directory.  '.svn' directories are deleted.

  Returns the expanded path to the backup directory.
=end    
  def ScanRulesUpdater.backup_scanrules_dir(local_scan_rules_dir=nil, bak_extension=nil) 
    
    if (bak_extension.nil? or bak_extension == "") then bak_extension = "_" + ScanRulesUpdater.get_YYYYMMDD_HHMM_str + ".bak" end    
    @@log.info("ScanRulesUpdater") {"Backing up the local scan rules dir (#{local_scan_rules_dir}) with extension '#{bak_extension}'"}
    
    path = ""
    if (local_scan_rules_dir == nil) then
      path = ScanRulesUpdater.get_default_scan_rules_dir()
    else 
      path = File.expand_path(local_scan_rules_dir)
    end    
    
    backup = path + bak_extension
    FileUtils.mv(path, backup)
    
    Find.find(backup) do |the_path|
      if (File.directory?(the_path) && File.basename(the_path) == ".svn") then
        FileUtils.remove_dir(the_path, true)
      end
    end
    return backup
  end
  
  def ScanRulesUpdater.get_default_scan_rules_dir()
    return File.expand_path(Config.prop(:rules_openlogic))
  end
  
=begin rdoc
  Method is intended only as a helper internal to this class.  It is only accessible so it can be tested.

  if 'url-path' is equal to "/rules_files.xml" then this method returns "rules_files.xml"

  if 'url-path' is equal to "rules_files.xml" then this method returns "rules_files.xml" (does nothing)
=end      
  def ScanRulesUpdater.scrub_url_path(url_path)
    if (url_path[0..0] == "/") then
      return url_path[1..url_path.size]
    else
      return url_path
    end
  end
  
  def ScanRulesUpdater.get_YYYYMMDD_HHMM_str(time=Time.new)
    # TODO findme: move this method to a utils class
    str = "#{time.year}"
    
    month = "#{time.month}"
    if (month.size == 1) then month = "0" + month end
    str << month
    
    day = "#{time.day}"
    if (day.size == 1) then day = "0" + day end
    str << day
    
    hour = "#{time.hour}"
    if (hour.size == 1) then hour = "0" + hour end
    str << "_" << hour
    
    minute = "#{time.min}"
    if (minute.size == 1) then minute = "0" + minute end
    str << minute
    
    return str
  end
  
=begin rdoc
  Method is intended only as a helper internal to this class.  It is only accessible so it can be tested.

  This is the method that gets called in case something went wrong with the process of downloading 
  updated scan rules.  It's job is to get the state of the client's scan rules back to what it was
  before the update process ever began.

  Params:
    * dir_with_rollback_content - This is the dir that holds the original scan rules (the last valid set 
      of scan rules we had before trying to update to the new ones).  It will be named something like:
      '.../rules/openlogic_20071106_0950.bak'
    * rules_dir - This argument is only available for testing, because by default, in a real 
      client-in-production scenario, this will always be '.../rules/openlogic'.
=end     
  def ScanRulesUpdater.rollback_update(dir_with_rollback_content, rules_dir=nil)
    @@log.info("ScanRulesUpdater") {"Rolling back the scan rules update. Rolling back to the rules in '#{dir_with_rollback_content}'"}
    
    unfinished_update_dir = ""
    if (rules_dir == nil) then # the production case
      unfinished_update_dir = File.join(File.dirname(dir_with_rollback_content), "openlogic")
    else # the test case
      unfinished_update_dir = rules_dir
    end
    
    unfinished_update_dir_new_name = File.join(File.dirname(dir_with_rollback_content), File.basename(dir_with_rollback_content) + ".failed-update")
    FileUtils.mv(unfinished_update_dir, unfinished_update_dir_new_name)
    FileUtils.mv(dir_with_rollback_content, unfinished_update_dir)
    return unfinished_update_dir # not currently used for anything, but more explicit than returning whatever FileUtils.mv returns
  end
  
end

class RulesFile
  attr_accessor :path
  
  def initialize(path)
    @path = path
  end
end
