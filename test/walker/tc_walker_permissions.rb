# ruby requires
require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'main', 'lib')
require 'conf/config'

class TcWalkerPermissions < Test::Unit::TestCase

  @@log = Config.log

  DISCOVERY_RB = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'main', 'lib', 'discovery.rb')) unless defined? DISCOVERY_RB
  PERMISSIONS_DIR_TO_DISCOVER = File.expand_path(File.join(File.dirname(__FILE__), '..', 'resources', 'permission-tests')) unless defined? PERMISSIONS_DIR_TO_DISCOVER
  
  def setup
  end
  
  def teardown
  end
  
  def test_permission_count
    if (RUBY_PLATFORM =~ /mswin/) then
      assert true
      @@log.warn('TcWalkerPermissions'){'TODO: Not testing permissions on windows systems.'}
    else
      whoami_result = `whoami`
      if (whoami_result.include?('root')) then
        assert true
        @@log.warn('TcWalkerPermissions'){'Unable to test the permissions functionality because this process is being run by the root user, which has permissions to everything.'}
      else
        cmd = "ruby #{DISCOVERY_RB} --path #{PERMISSIONS_DIR_TO_DISCOVER}"
        output = `#{cmd}`
        pd_val = output.match(/^permission denied\s+:\s+(.*).*$/)[1]
        if (RUBY_PLATFORM.to_s.include?('java')) then
          assert(pd_val.to_i > 0, "Expected to be denied permission to more than zero items in the '#{PERMISSIONS_DIR_TO_DISCOVER}' directory when the RUBY_PLATFORM is java.")
        else
          assert_equal(2, pd_val.to_i, "Expected to be denied permission to two items (one directory and one file) in the '#{PERMISSIONS_DIR_TO_DISCOVER}' directory when the RUBY_PLATFORM is not java.")
        end
      end # of if (whoami_result.include?('root')) then
    end # of if (RUBY_PLATFORM =~ /mswin/)
  end

end
