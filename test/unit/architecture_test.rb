require 'test_helper'

class ArchitectureTest < ActiveSupport::TestCase

  test "browser_architecture_with_default_not_nil" do
     ["xxxi386xxx","xxxamd64xxx","xxxyyy"].each do |s|
       assert !Architecture.browser_architecture_with_default(s).nil?
     end
  end
  test "browser_architecture_with_default_i386" do
     assert Architecture.browser_architecture_with_default("xxx686yyy").name == "i386"
  end
  test "browser_architecture_with_default_amd64" do
     assert Architecture.browser_architecture_with_default("xxx86_64yyy").name == "amd64"
  end
end
