require 'test_helper'

class ArchitectureTest < ActiveSupport::TestCase

  test "browser_architecture_with_default_not_nil" do
     ["i386","amd64"].each do |s|
       assert !Architecture.browser_architecture_with_default(s).nil?
     end
  end
  test "browser_architecture_with_default_i386" do
     assert Architecture.browser_architecture_with_default("686").name == "i386"
  end
  test "browser_architecture_with_default_amd64" do
     assert Architecture.browser_architecture_with_default("86_64").name == "amd64"
  end
end
