module Terraforming
  module Resource
    class ELB
      include Terraforming::Util

      def self.tf(client: Aws::ElasticLoadBalancing::Client.new, matcher: nil)
        self.new(client, matcher:matcher).tf
      end

      def self.tfstate(client: Aws::ElasticLoadBalancing::Client.new, tfstate_base: nil, matcher: nil)
        self.new(client, matcher:matcher).tfstate(tfstate_base)
      end

      def initialize(client, matcher: nil)
        @client = client
        @matcher = matcher
      end

      def tf
        apply_template(@client, "tf/elb")
      end

      def tfstate(tfstate_base)
        resources = load_balancers.inject({}) do |result, load_balancer|
          load_balancer_attributes = load_balancer_attributes_of(load_balancer)
          attributes = {
            "availability_zones.#" => load_balancer.availability_zones.length.to_s,
            "connection_draining" => load_balancer_attributes.connection_draining.enabled.to_s,
            "connection_draining_timeout" => load_balancer_attributes.connection_draining.timeout.to_s,
            "cross_zone_load_balancing" => load_balancer_attributes.cross_zone_load_balancing.enabled.to_s,
            "dns_name" => load_balancer.dns_name,
            "health_check.#" => "1",
            "id" => load_balancer.load_balancer_name,
            "idle_timeout" => load_balancer_attributes.connection_settings.idle_timeout.to_s,
            "instances.#" => load_balancer.instances.length.to_s,
            "listener.#" => load_balancer.listener_descriptions.length.to_s,
            "name" => load_balancer.load_balancer_name,
            "security_groups.#" => load_balancer.security_groups.length.to_s,
            "source_security_group" => load_balancer.source_security_group.group_name,
            "subnets.#" => load_balancer.subnets.length.to_s,
          }
          result["aws_elb.#{module_name_of(load_balancer)}"] = {
            "type" => "aws_elb",
            "primary" => {
              "id" => load_balancer.load_balancer_name,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      def load_balancers
        @client.describe_load_balancers.load_balancer_descriptions
      end

      def load_balancer_attributes_of(load_balancer)
        @client.describe_load_balancer_attributes(load_balancer_name: load_balancer.load_balancer_name).load_balancer_attributes
      end

      def module_name_of(load_balancer)
        normalize_module_name(load_balancer.load_balancer_name)
      end

      def vpc_elb?(load_balancer)
        load_balancer.vpc_id != ""
      end
    end
  end
end
