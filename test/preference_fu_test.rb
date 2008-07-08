require 'test/unit'
require File.join(File.dirname(__FILE__), 'abstract_unit')
require File.join(File.dirname(__FILE__), 'person')


class PreferenceFuTest < Test::Unit::TestCase
  
  def setup
    setup_db
    @person = Person.new
    @task = Task.new
  end

  def teardown
    teardown_db
  end
  
  def test_that_all_default_to_true_except_send_email
    assert_equal [true, false, false, false], @person.prefs.map { |k, v| v }
  end
  
  def test_new_user_for_default_preference_int
    assert_equal 1, @person.read_attribute(:preferences)
  end
  
  def test_changing_of_preference
    assert_equal false, @person.prefs[:delete_user]
    @person.prefs[:delete_user] = true
    assert_equal true, @person.prefs[:delete_user]
  end
  
  def test_mass_assignment
    @person.prefs = {:send_email => true, :change_theme => true, :delete_user => true, :create_user => true}
    assert_equal [true, true, true, true], @person.prefs.map { |k, v| v }
  end
  
  def test_setting_an_unknown_option
    @person.prefs[:unknown] = true
    assert_equal 4, @person.prefs.size
  end
  
  def test_saving_and_loading
    @person.prefs[:change_theme] = true
    @person.save
    
    @new_person = Person.find(:first)
    assert_equal [true, true, false, false], @new_person.prefs.map { |k, v| v }
  end
  
  def test_various_ways_of_stating_truth
    [true, 1, '1', 'y', 'yes', 'Y', 'YES'].each do |val|
      @person.prefs[:change_theme] = val
      assert_equal true, @person.prefs[:change_theme]
    end
  end
  
  def test_lookup_index_of_key
    assert_equal 4, @person.prefs.index(:delete_user)
  end
  
  def test_second_preference
    @person.reminders[:birthday] = true
    @person.save
    @new_person = Person.find(:first)
    assert_equal [true, false], @new_person.reminders.map { |k, v| v }
  end
  
  def test_interference
    @person.reminders = {:birthday => true,:holiday => true}
    @person.prefs = {:send_email => false, :change_theme => false, :delete_user => false, :create_user => false}
    @person.save
    @new_person = Person.find(:first)
    assert_equal [true, true], @new_person.reminders.map { |k, v| v }
    assert_equal [false, false, false, false], @new_person.prefs.map { |k, v| v }
    
  end
  
  
  def test_access_by_method_missing
    @person.reminders[:birthday] = true
    assert_equal @person.reminders[:birthday], @person.reminders.birthday?
  end
  
  def test_preferences_on_different_models
    @person.reminders[:birthday] = true
    @task.reminders[:birthday] = false
    assert_equal @person.reminders[:birthday], true
    assert_equal @task.reminders[:birthday], false
    @task.save
    @person.save
    @new_person = Person.find(:first)
    assert_equal [true, false], @new_person.reminders.map { |k, v| v }
    @new_task = Task.find(:first)
    assert_equal [false, true], @new_task.reminders.map { |k, v| v }
  end
  
end
