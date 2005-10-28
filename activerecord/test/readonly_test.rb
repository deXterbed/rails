require 'abstract_unit'
require 'fixtures/post'
require 'fixtures/comment'
require 'fixtures/developer'
require 'fixtures/project'

# Dummy class methods to test implicit association constraints.
def Comment.foo() find :first end
def Project.foo() find :first end


class ReadOnlyTest < Test::Unit::TestCase
  fixtures :posts, :comments, :developers, :projects, :developers_projects

  def test_cant_save_readonly_record
    dev = Developer.find(1)
    assert !dev.readonly?

    dev.readonly!
    assert dev.readonly?

    assert_nothing_raised do
      dev.name = 'Luscious forbidden fruit.'
      assert !dev.save
      dev.name = 'Forbidden.'
    end
    assert_raise(ActiveRecord::ReadOnlyRecord) { dev.save  }
    assert_raise(ActiveRecord::ReadOnlyRecord) { dev.save! }
  end


  def test_find_with_readonly_option
    Developer.find(:all).each { |d| assert !d.readonly? }
    Developer.find(:all, :readonly => false).each { |d| assert !d.readonly? }
    Developer.find(:all, :readonly => true).each { |d| assert d.readonly? }
  end


  def test_find_with_joins_option_implies_readonly
    # Blank joins don't count.
    Developer.find(:all, :joins => '  ').each { |d| assert !d.readonly? }
    Developer.find(:all, :joins => '  ', :readonly => false).each { |d| assert !d.readonly? }

    # Others do.
    Developer.find(:all, :joins => ', projects').each { |d| assert d.readonly? }
    Developer.find(:all, :joins => ', projects', :readonly => false).each { |d| assert !d.readonly? }
  end


  def test_habtm_find_readonly
    dev = Developer.find(1)
    assert !dev.projects.empty?
    dev.projects.each { |p| assert !p.readonly? }
    dev.projects.find(:all) { |p| assert !p.readonly? }
    dev.projects.find(:all, :readonly => true) { |p| assert p.readonly? }
  end

  def test_has_many_find_readonly
    post = Post.find(1)
    assert !post.comments.empty?
    post.comments.each { |r| assert !r.readonly? }
    post.comments.find(:all) { |r| assert !r.readonly? }
    post.comments.find(:all, :readonly => true) { |r| assert r.readonly? }
  end


  def test_readonly_constraint
    Post.constrain(:conditions => '1=1') do 
      assert !Post.find(1).readonly?
      assert Post.find(1, :readonly => true).readonly?
      assert !Post.find(1, :readonly => false).readonly?
    end

    Post.constrain(:joins => '   ') do 
      assert !Post.find(1).readonly?
      assert Post.find(1, :readonly => true).readonly?
      assert !Post.find(1, :readonly => false).readonly?
    end

    Post.constrain(:joins => ', developers') do 
      assert Post.find(1).readonly?
      assert Post.find(1, :readonly => true).readonly?
      assert !Post.find(1, :readonly => false).readonly?
    end

    Post.constrain(:readonly => true) do
      assert Post.find(1).readonly?
      assert Post.find(1, :readonly => true).readonly?
      assert !Post.find(1, :readonly => false).readonly?
    end
  end

  def test_association_collection_method_missing_constraint_not_readonly
    assert !Developer.find(1).projects.foo.readonly?
    assert !Post.find(1).comments.foo.readonly?
  end
end
