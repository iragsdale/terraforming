module Terraforming
  module Matcher
    # matches a set of properties
    class CompoundMatcher
      def initialize(patterns)
        @matchers = patterns.map{|p| Matcher::PropertyMatcher.new(p)}
      end

      def match(anything)
        return false unless @matchers
        return @matchers.inject(true){|result, matcher| result && matcher.match(anything) }
      end
    end
  end
end
