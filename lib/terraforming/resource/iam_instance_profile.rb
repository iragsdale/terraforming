module Terraforming
  module Resource
    class IAMInstanceProfile
      include Terraforming::Util

      def self.tf(client: Aws::IAM::Client.new, matcher: nil)
        self.new(client, matcher:matcher).tf
      end

      def self.tfstate(client: Aws::IAM::Client.new, tfstate_base: nil, matcher: nil)
        self.new(client, matcher:matcher).tfstate(tfstate_base)
      end

      def initialize(client, matcher: nil)
        @client = client
        @matcher = matcher
      end

      def tf
        apply_template(@client, "tf/iam_instance_profile")
      end

      def tfstate(tfstate_base)
        resources = iam_instance_profiles.inject({}) do |result, profile|
          attributes = {
            "arn" => profile.arn,
            "id" => profile.instance_profile_name,
            "name" => profile.instance_profile_name,
            "path" => profile.path,
            "roles.#" => profile.roles.length.to_s,
          }
          result["aws_iam_instance_profile.#{profile.instance_profile_name}"] = {
            "type" => "aws_iam_instance_profile",
            "primary" => {
              "id" => profile.instance_profile_name,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def iam_instance_profiles
        @client.list_instance_profiles.instance_profiles
      end
    end
  end
end
