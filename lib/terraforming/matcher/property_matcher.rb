module Terraforming
  module Matcher
    # matches a particular property
    class PropertyMatcher
      # string in the form of key=value or key=~value
      # if the latter, uses a regular expression match instead of a string equals
      def initialize(definition)
        @key, @condition = definition.split("=", 2)
        if @condition =~ /^~/
          @condition = Regexp.new(@condition[1..@condition.length])
        end
      end

      # returns true if the property's value for key matches the given value, false otherwise
      def match(anything)
        return false unless anything
        case @condition
        when String
          return resolve(anything).to_s == @condition
        when Regexp
          return nil != (resolve(anything).to_s =~ @condition)
        else
          return false
        end
      end

      def resolve(anything)
        PropertyMatcher.resolve(anything, @key)
      end

      def self.resolve(anything, key)
        first, rest = key.split(".", 2)
        val = anything.method(first.to_sym).call rescue nil
        if rest
          return resolve(val, rest)
        else
          return val.to_s
        end
      end
    end
  end
end
