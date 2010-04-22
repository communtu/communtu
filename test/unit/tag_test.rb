require 'test_helper'

class TagTest < ActiveSupport::TestCase
  # this really is a Rails function, if save doesn't work it's not our fault..
  # inserted tag in db has correct name from insertion
  test "new tag" do
    test_tag = { :name => "works-with-format::mp3" }

    tag = Tag.new(test_tag)
    tag.save

    db_tag = Tag.find(tag)

    assert db_tag[:name] <=> test_tag[:name]
  end

  test "duplicate tag" do
    assert !Tag.create(:name => "works-with-format::mp3") # validates uniqueness of name (OPTIMIZE this is kind of a bug actually, see tag model)
  end

  # this really is a Rails function, if save doesn't work it's not our fault..
  # tag cannot be empty
  test "new empty tag" do
    tag = Tag.new()

    assert !tag.save # validates presence of name
  end

  # this really is a rails function, if create doesn't work it's beyond our responsibilities
  # after insertion, there is one more tag in the db
  test "tag count" do
    i = Tag.count
    i += 1

    tag = Tag.create( { :name => "does-not-matter" } )

    assert_equal Tag.count, i
  end
end
