module Terraforming
  module Matcher
    # matches anything by default
    class DefaultMatcher
      def match(anything)
        true
      end
    end
  end
end