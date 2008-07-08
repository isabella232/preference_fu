class Person < ActiveRecord::Base

  has_preferences :send_email, :change_theme, :delete_user, :create_user,
                  :column => 'preferences',
                  :accessor => :prefs,
                  :default => { :send_email => true }
                  
  has_preferences :birthday, :holiday,
                  :accessor => :reminders
  
end

class Task < ActiveRecord::Base
  has_preferences :birthday, :holiday,
                  :accessor => :reminders,
                  :default => { :birthday => true, :holiday => true}
end