# init.rb
#
# LEGAL NOTICE
# -------------
# 
# OSS Discovery is a tool that finds installed open source software.
#    Copyright (C) 2007-2008 OpenLogic, Inc.
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
# You can learn more about OSSDiscovery or contact the team at www.ossdiscovery.com.
# You can contact OpenLogic at info@openlogic.com.
#
#--------------------------------------------------------------------------------------------------


$:.unshift File.dirname(__FILE__)
require 'conf/inventory_config'

if ( InventoryConfig.inventory_enabled )
   require 'inventory_plugin'

   INVENTORY_PLUGIN_VERSION = "1.0"
   INVENTORY_PLUGIN_VERSION_KEY =  "29the23special46secret31".to_i(36).to_s(16)

   # create the plugin and register it with the ossdiscovery plugin framework
   inventory_plugin = InventoryPlugin.new
   @plugins_list["Inventory"] = inventory_plugin  # registers the plugin
end