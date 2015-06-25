module Terraforming
  module Resource
    class SecurityGroup
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
        apply_template(@client, "tf/security_group")
      end

      def tfstate(tfstate_base)
        resources = security_groups.inject({}) do |result, security_group|
          attributes = {
            "description" => security_group.description,
            "id" => security_group.group_id,
            "name" => security_group.group_name,
            "owner_id" => security_group.owner_id,
            "vpc_id" => security_group.vpc_id || "",
          }

          attributes.merge!(tags_attributes_of(security_group))
          attributes.merge!(egress_attributes_of(security_group))
          attributes.merge!(ingress_attributes_of(security_group))

          result["aws_security_group.#{module_name_of(security_group)}"] = {
            "type" => "aws_security_group",
            "primary" => {
              "id" => security_group.group_id,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def ingress_attributes_of(security_group)
        attributes = { "ingress.#" => security_group.ip_permissions.length.to_s }

        security_group.ip_permissions.each do |permission|
          attributes.merge!(permission_attributes_of(security_group, permission, "ingress"))
        end

        attributes
      end

      def egress_attributes_of(security_group)
        attributes = { "egress.#" => security_group.ip_permissions_egress.length.to_s }

        security_group.ip_permissions_egress.each do |permission|
          attributes.merge!(permission_attributes_of(security_group, permission, "egress"))
        end

        attributes
      end

      def group_hashcode_of(group)
        Zlib.crc32(group)
      end

      def module_name_of(security_group)
        normalize_module_name("#{security_group.group_id}-#{security_group.group_name}")
      end

      def permission_attributes_of(security_group, permission, type)
        hashcode = permission_hashcode_of(security_group, permission)
        security_groups = security_groups_in(permission).reject { |group_id| group_id == security_group.group_id }

        attributes = {
          "#{type}.#{hashcode}.from_port" => (permission.from_port || 0).to_s,
          "#{type}.#{hashcode}.to_port" => (permission.to_port || 0).to_s,
          "#{type}.#{hashcode}.protocol" => permission.ip_protocol,
          "#{type}.#{hashcode}.cidr_blocks.#" => permission.ip_ranges.length.to_s,
          "#{type}.#{hashcode}.security_groups.#" => security_groups.length.to_s,
          "#{type}.#{hashcode}.self" => self_referenced_permission?(security_group, permission).to_s,
        }

        permission.ip_ranges.each_with_index do |range, index|
          attributes["#{type}.#{hashcode}.cidr_blocks.#{index}"] = range.cidr_ip
        end

        security_groups.each do |group|
          attributes["#{type}.#{hashcode}.security_groups.#{group_hashcode_of(group)}"] = group
        end

        attributes
      end

      def permission_hashcode_of(security_group, permission)
        string =
          "#{permission.from_port || 0}-" <<
          "#{permission.to_port || 0}-" <<
          "#{permission.ip_protocol}-" <<
          "#{self_referenced_permission?(security_group, permission).to_s}-"

        permission.ip_ranges.each { |range| string << "#{range.cidr_ip}-" }
        security_groups_in(permission).each { |group| string << "#{group}-" }

        Zlib.crc32(string)
      end

      def self_referenced_permission?(security_group, permission)
        security_groups_in(permission).include?(security_group.group_id)
      end

      def security_groups
        @client.describe_security_groups.security_groups
      end

      def security_groups_in(permission)
        permission.user_id_group_pairs.map { |range| range.group_id }
      end

      def tags_attributes_of(security_group)
        tags = security_group.tags
        attributes = { "tags.#" => tags.length.to_s }
        tags.each { |tag| attributes["tags.#{tag.key}"] = tag.value }
        attributes
      end
    end
  end
end
