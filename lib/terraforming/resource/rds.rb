module Terraforming
  module Resource
    class RDS
      include Terraforming::Util

      def self.tf(client: Aws::RDS::Client.new, matcher: nil)
        self.new(client, matcher:matcher).tf
      end

      def self.tfstate(client: Aws::RDS::Client.new, tfstate_base: nil, matcher: nil)
        self.new(client, matcher:matcher).tfstate(tfstate_base)
      end

      def initialize(client, matcher: nil)
        @client = client
        @matcher = matcher
      end

      def tf
        apply_template(@client, "tf/rds")
      end

      def tfstate(tfstate_base)
        resources = db_instances.inject({}) do |result, instance|
          attributes = {
            "address" => instance.endpoint.address,
            "allocated_storage" => instance.allocated_storage.to_s,
            "availability_zone" => instance.availability_zone,
            "backup_retention_period" => instance.backup_retention_period.to_s,
            "backup_window" => instance.preferred_backup_window,
            "db_subnet_group_name" => instance.db_subnet_group ? instance.db_subnet_group.db_subnet_group_name : "",
            "endpoint" => instance.endpoint.address,
            "engine" => instance.engine,
            "engine_version" => instance.engine_version,
            "final_snapshot_identifier" => "#{instance.db_instance_identifier}-final",
            "id" => instance.db_instance_identifier,
            "identifier" => instance.db_instance_identifier,
            "instance_class" => instance.db_instance_class,
            "maintenance_window" => instance.preferred_maintenance_window,
            "multi_az" => instance.multi_az.to_s,
            "name" => instance.db_name,
            "parameter_group_name" => instance.db_parameter_groups[0].db_parameter_group_name,
            "password" => "xxxxxxxx",
            "port" => instance.endpoint.port.to_s,
            "publicly_accessible" => instance.publicly_accessible.to_s,
            "security_group_names.#" => instance.db_security_groups.length.to_s,
            "status" => instance.db_instance_status,
            "storage_type" => instance.storage_type,
            "username" => instance.master_username,
            "vpc_security_group_ids.#" => instance.vpc_security_groups.length.to_s,
          }
          result["aws_db_instance.#{module_name_of(instance)}"] = {
            "type" => "aws_db_instance",
            "primary" => {
              "id" => instance.db_instance_identifier,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def db_instances
        @client.describe_db_instances.db_instances
      end

      def module_name_of(instance)
        normalize_module_name(instance.db_instance_identifier)
      end
    end
  end
end
