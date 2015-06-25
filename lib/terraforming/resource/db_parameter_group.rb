module Terraforming
  module Resource
    class DBParameterGroup
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
        apply_template(@client, "tf/db_parameter_group")
      end

      def tfstate(tfstate_base)
        resources = db_parameter_groups.inject({}) do |result, parameter_group|
          attributes = {
            "description" => parameter_group.description,
            "family" => parameter_group.db_parameter_group_family,
            "id" => parameter_group.db_parameter_group_name,
            "name" => parameter_group.db_parameter_group_name,
            "parameter.#" => db_parameters_in(parameter_group).length.to_s
          }
          result["aws_db_parameter_group.#{module_name_of(parameter_group)}"] = {
            "type" => "aws_db_parameter_group",
            "primary" => {
              "id" => parameter_group.db_parameter_group_name,
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources, tfstate_base)
      end

      private

      def db_parameter_groups
        @client.describe_db_parameter_groups.db_parameter_groups
      end

      def db_parameters_in(parameter_group)
        @client.describe_db_parameters(db_parameter_group_name: parameter_group.db_parameter_group_name).parameters
      end

      def module_name_of(parameter_group)
        normalize_module_name(parameter_group.db_parameter_group_name)
      end
    end
  end
end
