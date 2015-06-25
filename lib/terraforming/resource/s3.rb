module Terraforming
  module Resource
    class S3
      include Terraforming::Util

      def self.tf(client: Aws::S3::Client.new, matcher: nil)
        self.new(client, matcher:matcher).tf
      end

      def self.tfstate(client: Aws::S3::Client.new, tfstate_base: nil, matcher: nil)
        self.new(client, matcher:matcher).tfstate(tfstate_base)
      end

      def initialize(client, matcher: nil)
        @client = client
        @matcher = matcher
      end

      def tf
        apply_template(@client, "tf/s3")
      end

      def tfstate(tfstate_base)
        resources = buckets.inject({}) do |result, bucket|
          result["aws_s3_bucket.#{module_name_of(bucket)}"] = {
            "type" => "aws_s3_bucket",
            "primary" => {
              "id" => bucket.name,
              "attributes" => {
                "acl" => "private",
                "bucket" => bucket.name,
                "id" => bucket.name
              }
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def buckets
        @client.list_buckets.buckets
      end

      def module_name_of(bucket)
        normalize_module_name(bucket.name)
      end
    end
  end
end
