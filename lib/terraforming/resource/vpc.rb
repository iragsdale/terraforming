module Terraforming
  module Resource
    class VPC
      include Terraforming::Util

      def self.tf(client: Aws::EC2::Client.new, matcher: nil)
        self.new(client, matcher:matcher).tf
      end

      def self.tfstate(client: Aws::EC2::Client.new, tfstate_base: nil, matcher: nil)
        self.new(client, matcher:matcher).tfstate(tfstate_base)
      end

      def initialize(client, matcher: nil)
        @client = client
        @matcher = matcher
      end

      def tf
        apply_template(@client, "tf/vpc")
      end

      def tfstate(tfstate_base)
        resources = vpcs.inject({}) do |result, vpc|
          attributes = {
            "cidr_block" => vpc.cidr_block,
            "enable_dns_hostnames" => enable_dns_hostnames?(vpc).to_s,
            "enable_dns_support" => enable_dns_support?(vpc).to_s,
            "id" => vpc.vpc_id,
            "instance_tenancy" => vpc.instance_tenancy,
            "tags.#" => vpc.tags.length.to_s,
          }
          result["aws_vpc.#{module_name_of(vpc)}"] = {
            "type" => "aws_vpc",
            "primary" => {
              "id" => vpc.vpc_id,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def enable_dns_hostnames?(vpc)
        vpc_attribute(vpc, :enableDnsHostnames).enable_dns_hostnames.value
      end

      def enable_dns_support?(vpc)
        vpc_attribute(vpc, :enableDnsSupport).enable_dns_support.value
      end

      def module_name_of(vpc)
        normalize_module_name(name_from_tag(vpc, vpc.vpc_id))
      end

      def vpcs
        @client.describe_vpcs.vpcs
      end

      def vpc_attribute(vpc, attribute)
        @client.describe_vpc_attribute(vpc_id: vpc.vpc_id, attribute: attribute)
      end
    end
  end
end
