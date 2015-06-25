module Terraforming
  module Resource
    class IAMPolicy
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
        apply_template(@client, "tf/iam_policy")
      end

      def tfstate(tfstate_base)
        resources = iam_policies.inject({}) do |result, policy|
          version = iam_policy_version_of(policy)
          attributes = {
            "id" => policy.arn,
            "name" => policy.policy_name,
            "path" => policy.path,
            "policy" => prettify_policy(version.document, true),
          }
          result["aws_iam_policy.#{policy.policy_name}"] = {
            "type" => "aws_iam_policy",
            "primary" => {
              "id" => policy.arn,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def iam_policies
        @client.list_policies(scope: "Local").policies
      end

      def iam_policy_version_of(policy)
        @client.get_policy_version(policy_arn: policy.arn, version_id: policy.default_version_id).policy_version
      end
    end
  end
end
