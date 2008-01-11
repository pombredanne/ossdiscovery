require 'erb'
require 'openssl'
require 'digest/md5'

module CensusUtils
        
  # get the openlogic rules file checksum once as it won't
  # change during a run (after any rule updates)
  def openlogic_rules_file_checksum  
    @@openlogic_rules_file_checksum ||= add_check_digits(Digest::MD5.hexdigest(
        File.new(File.join(File.dirname(__FILE__), "..", "..", 
                 "rules", "openlogic", "project-rules.xml")).read))
  end


=begin rdoc
  Implement ISO 7064 mod(97,10) check digits to prevent accidental and some
  malicious tampering with the machine uuid that will be sent to the OSS Census
  collection site.
=end
  def add_check_digits(hex_str)
    hex_str_as_base_10_number = hex_str.hex
    check_number = (98 - ((hex_str_as_base_10_number * 100) % 97)) % 97
    result = hex_str_as_base_10_number.to_s + ("%02d" % check_number)

    # make sure we did it right
    raise "add check digits failed" unless result.to_i % 97 == 1

    # convert the big long decimal string into a shorter hexadecimal string
    result.to_i.to_s(16)
  end

=begin rdoc
  Output the report we'll submit to the census.
=end
  def machine_report(destination, packages, client_version, machine_id,
                     directory_count, file_count, sym_link_count,
                     permission_denied_count, files_of_interest_count,
                     start_time, end_time, distro, os_family, os,
		     os_version, machine_architecture, kernel, 
		     production_scan, include_paths, preview_results, group_code )
    io = nil
    if (destination == STDOUT) then
      io = STDOUT
    else 
      io = File.new(destination, "w")
    end

    production_scan = false unless production_scan == true

    template = %{
      report_type:             census
      census_plugin_version:   <%= CENSUS_PLUGIN_VERSION %>
      client_version:          <%= client_version %>
      rules_file_checksum:     <%= CensusUtils.openlogic_rules_file_checksum %>
      machine_id:              <%= machine_id %>
      directory_count:         <%= directory_count %>
      file_count:              <%= file_count %>
      sym_link_count:          <%= sym_link_count %>
      permission_denied_count: <%= permission_denied_count %>
      files_of_interest:       <%= files_of_interest_count %>
      start_time:              <%= start_time.to_i %>
      end_time:                <%= end_time.to_i %>
      elapsed_time:            <%= end_time - start_time %>
      packages_found_count:    <%= packages.length %>
      distro:                  <%= distro %>
      os_family:               <%= os_family %>
      os:                      <%= os %>
      os_version:              <%= os_version %>
      machine_architecture:    <%= machine_architecture %>
      kernel:                  <%= kernel %>
      ruby_platform:           <%= RUBY_PLATFORM %>
      production_scan:         <%= production_scan %>
      group_code:              <%= group_code %>
      package,version
      % if packages.length > 0
      %   packages.sort.each do |package|
      %     package.version.split(",").sort.each do |version|
      %       version.gsub!(" ", "")
      %       version.tr!("\0", "")
              <%= package.name %>,<%= version %>
      %     end
      %   end
      % end
    }

    # strip off leading whitespace and compress all other spaces in 
    # the rendered template so it's more efficient for sending
    template = template.gsub(/^\s+/, "").squeeze(" ")
    text = ERB.new(template, 0, "%").result(binding)

    # now create a secure checksum of the results to use as an integrity check
    # on the server side.  Do this by combining the current OpenLogic rules
    # file checksum with a constant to create a secret key.  This secret key
    # is then blended into the results of an SHA256 hash of the file contents
    # to produce a cryptographically strong hash that we can use on the server
    # to make sure the file contents have not been tampered with.  
    # Note that this mechanism can provide only minor defense against a
    # motivated attacker seeking to skew the results of the census.
    checksum = CensusUtils.openlogic_rules_file_checksum
    hmac = OpenSSL::HMAC.new(checksum + CENSUS_PLUGIN_VERSION_KEY, OpenSSL::Digest::SHA256.new)
    hmac.update(text)

    printf(io, "integrity_check: #{add_check_digits(hmac.to_s)}\n")
    printf(io, text + "\n")
    
    io.close unless io == STDOUT
  
    if preview_results && io != STDOUT
      printf("\nThese are the actual machine scan results from the file, %s, that would be delivered by --deliver-results option\n", destination)
      puts File.new(destination).read
    end
  end

  module_function :add_check_digits
  module_function :machine_report
  module_function :openlogic_rules_file_checksum

end

# We have to open class Object here because the method we
# want to alias is defined outside of any class or module and
# is therefore automatically defined on class Object.
class Object
  # change the make_machine_id method to return a machine id
  # with check digits added to prevent accidental and some
  # malicious tampering.
  alias_method :orig_make_machine_id, :make_machine_id
  def make_machine_id(*args)
    CensusUtils.add_check_digits(orig_make_machine_id(*args))
  end
    
  # change the make_machine_id method to return a machine id
  # with check digits added to prevent accidental and some
  # malicious tampering.
  alias_method :orig_machine_report, :machine_report
  def machine_report(*args)
    CensusUtils.machine_report(*args)
  end
    
end
