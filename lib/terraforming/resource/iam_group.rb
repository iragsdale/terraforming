module Terraforming
  module Resource
    class IAMGroup
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
        apply_template(@client, "tf/iam_group")
      end

      def tfstate(tfstate_base)
        resources = iam_groups.inject({}) do |result, group|
          attributes = {
            "arn"=> group.arn,
            "id" => group.group_name,
            "name" => group.group_name,
            "path" => group.path,
            "unique_id" => group.group_id,
          }
          result["aws_iam_group.#{group.group_name}"] = {
            "type" => "aws_iam_group",
            "primary" => {
              "id" => group.group_name,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def iam_groups
        @client.list_groups.groups
      end
    end
  end
end
