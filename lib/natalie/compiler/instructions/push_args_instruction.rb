require_relative './base_instruction'

module Natalie
  class Compiler
    class PushArgsInstruction < BaseInstruction
      def initialize(for_block:, min_count:, max_count:, spread: false, to_array: true)
        @for_block = for_block
        @min_count = min_count
        @max_count = max_count
        @spread = spread
        @to_array = to_array
      end

      def to_s
        s = "push_args #{@min_count}..#{@max_count}"
        s << ' (for_block)' if @for_block
        s << ' (spread)' if @spread
        s
      end

      def generate(transform)
        args = transform.temp('args')
        if @for_block
          transform.exec_and_push(:args, "args.to_array_for_block(env, #{@min_count}, #{@max_count || -1}, #{@spread ? 'true' : 'false'})")
        elsif @to_array
          transform.exec_and_push(:args, 'args.to_array()')
        else
          transform.exec_and_push(:args, 'args')
        end
      end

      def execute(vm)
        if @for_block && @max_count > 1 && vm.args.size == 1
          if vm.args.first.is_a?(Array)
            vm.push(vm.args.first.dup)
          elsif vm.args.first.respond_to?(:to_ary)
            vm.push(vm.args.first.to_ary)
          else
            vm.push(vm.args)
          end
        else
          vm.push(vm.args)
        end
      end

      def serialize
        raise NotImplementedError, 'Support special ... syntax' if @min_count.nil? || @max_count.nil?

        flags = 0
        [@for_block, @spread, @to_array].each_with_index do |flag, index|
          flags |= (1 << index) if flag
        end
        [
          instruction_number,
          flags,
          @min_count,
          @max_count,
        ].pack('CCww')
      end

      def self.deserialize(io)
        flags = io.getbyte
        min_count = io.read_ber_integer
        max_count = io.read_ber_integer
        for_block = flags[0] == 1
        spread = flags[1] == 1
        to_array = flags[2] == 1
        new(for_block:, min_count:, max_count:, spread:, to_array:)
      end
    end
  end
end
