require_relative './base_instruction'

module Natalie
  class Compiler
    class InstanceVariableDefinedInstruction < BaseInstruction
      def initialize(name)
        @name = name.to_sym
      end

      attr_reader :name

      def to_s
        "instance_variable_defined #{@name}"
      end

      def generate(transform)
        transform.exec("if (!Object::ivar_defined(env, self, #{transform.intern(@name)})) throw new ExceptionObject")
      end

      def execute(vm)
        vm.push(vm.self.instance_variables.include?(@name))
      end
    end
  end
end
