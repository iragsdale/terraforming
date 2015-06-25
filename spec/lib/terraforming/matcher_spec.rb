require "spec_helper"

module Terraforming
  module Matcher
    describe DefaultMatcher do
      it "should return true for nil objects" do
        expect(described_class.new.match(nil)).to eq true
      end

      it "should return true for any object" do
        expect(described_class.new.match(false)).to eq true
      end
    end

    describe PropertyMatcher do
      let (:anything) do
        OpenStruct.new( plain: "whatever", path: OpenStruct.new(path: OpenStruct.new(:path => "something") ) )
      end

      it "should resolve plain properties" do
        expect(PropertyMatcher.resolve(anything, "plain")).to eq "whatever"
      end

      it "should resolve property paths (path.path.path)" do
        expect(PropertyMatcher.resolve(anything, "path.path.path")).to eq "something"
      end

      it "should return false for nil objects" do
        expect(described_class.new("key=val").match(nil)).to eq false
      end

      it "should return true for simple equal objects" do
        expect(described_class.new("plain=whatever").match(anything)).to eq true
      end

      it "should return true for simple equal nested objects" do
        expect(described_class.new("path.path.path=something").match(anything)).to eq true
      end

      it "should return true for simple equal objects" do
        expect(described_class.new("plain=~what.*").match(anything)).to eq true
      end

      it "should return true for simple equal nested objects" do
        expect(described_class.new("path.path.path=~some.*").match(anything)).to eq true
      end
    end

    describe CompoundMatcher do
      let (:anything) do
        OpenStruct.new( plain: "whatever", path: OpenStruct.new(path: OpenStruct.new(:path => "something") ) )
      end

      it "should return pass if all matchers pass" do
        expect(described_class.new(["plain=~what.*", "plain=whatever","path.path.path=~some.*","path.path.path=something"]).match(anything)).to eq true
      end

      it "should fail if any matcher fails" do
        expect(described_class.new(["plain=~nope.*", "plain=whatever","path.path.path=~some.*","path.path.path=something"]).match(anything)).to eq false
      end
    end
  end
end
