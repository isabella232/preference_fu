module PreferenceFu

  def self.included(receiver)
    receiver.extend ClassMethods
  end

  module ClassMethods


    def has_preferences(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      preference_accessor = options.delete(:accessor) || 'preferences'
      column_name = options.delete(:column) || preference_accessor
      defaults = options.delete(:default) || {}

      metaclass.instance_exec(preference_accessor) { |preference_accessor|
        attr_accessor "#{preference_accessor}_options"

        define_method("#{preference_accessor}_bitmask") do |pref_name|
          idx,hsh = self.send("#{preference_accessor}_options").find { |idx, hsh| hsh[:key] == pref_name }
          idx
        end

        # define_method("instantiate_with_#{preference_accessor}") do |*args|
        #   record = send("instantiate_without_#{preference_accessor}",*args)
        #   record.instance_variable_set("@#{preference_accessor}_object",nil)
        #   record.send preference_accessor
        #   record
        # end
        #
        # alias_method_chain :instantiate, preference_accessor

      }

      self.send("#{preference_accessor}_options=", preference_options =  {})

      args.each_with_index do |pref,idx|
        preference_options[2**idx] = { :key => pref.to_sym, :default => defaults[pref.to_sym] || false }
      end

      instance_code = <<-end_src
        def initialize_with_#{preference_accessor}(*args)
          initialize_without_#{preference_accessor}(*args)
          #{preference_accessor}
          yield self if block_given?
        end

        def reload_with_#{preference_accessor}(*args)
          res = reload_without_#{preference_accessor}(*args)
          @#{preference_accessor}_object = nil
          #{preference_accessor}
          res
        end


        def #{preference_accessor}
          @#{preference_accessor}_object ||= Preferences.new(read_attribute('#{column_name}'.to_sym),
            self.class.#{preference_accessor}_options, '#{column_name}', self)
        end

        def #{preference_accessor}=(hsh)
          #{preference_accessor}.store(hsh)
        end

      end_src
      class_eval(instance_code)
      alias_method_chain :initialize, preference_accessor
      alias_method_chain :reload, preference_accessor
    end

  end

  class Preferences

    include Enumerable

    attr_accessor :options

    def initialize(prefs, options,column,instance)
      return if options.nil? or column.nil? or instance.nil?
      @options = options
      @column = column
      @instance = instance

      # setup defaults if prefs is nil
      if prefs.nil?
        @options.each do |idx, hsh|
          instance_variable_set("@#{hsh[:key]}", hsh[:default])
        end
      elsif prefs.is_a?(Numeric)
        @options.each do |idx, hsh|
          instance_variable_set("@#{hsh[:key]}", (prefs & idx) != 0 ? true : false)
        end
      else
        raise(ArgumentError, "Input must be numeric")
      end

      update_preference_attribute

    end

    def method_missing(name,*args)
      name = name.to_s
      instance_variable_name = "@" + name[0..-2]
      if name[-1] == ?? and instance_variable_defined?(instance_variable_name)
        return instance_variable_get(instance_variable_name)
      else
        super
      end
    end

    def each
      @options.each_value do |hsh|
        yield hsh[:key], self[hsh[:key]]
      end
    end

    def size
      @options.size
    end

    def [](key)
      instance_variable_get("@#{key}")
    end

    def []=(key, value)
      idx, hsh = lookup(key)
      instance_variable_set("@#{key}", is_true(value))
      update_preference_attribute
    end

    def index(key)
      idx, hsh = lookup(key)
      idx
    end

    # used for mass assignment of preferences, such as a hash from params
    def store(prefs)
      prefs.each do |key, value|
        self[key] = value
      end if prefs.respond_to?(:each)
    end

    def to_i
      @options.inject(0) do |bv, (idx, hsh)|
        bv |= instance_variable_get("@#{hsh[:key]}") ? idx : 0
      end
    end

    private

      def update_preference_attribute
        @instance.write_attribute(@column, self.to_i)
      end

      def is_true(value)
        case value
        when true, 1, /1|y|yes/i then true
        else false
        end
      end

      def lookup(key)
        @options.find { |idx, hsh| hsh[:key] == key.to_sym }
      end

  end

end
ActiveRecord::Base.class_eval { include PreferenceFu }