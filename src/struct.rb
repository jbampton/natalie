class Struct
  include Enumerable

  class << self
    alias [] new
  end

  def self.new(*attrs)
    if respond_to?(:members)
      BasicObject.method(:new).unbind.bind(self).(*attrs)
    else
      if attrs.last.is_a?(Hash)
        options = attrs.pop
      else
        options = {}
      end
      Class.new(Struct) do
        include Enumerable

        define_singleton_method :members do
          attrs
        end

        define_method :length do
          attrs.length
        end
        alias_method :size, :length

        attrs.each { |attr| attr_accessor attr }

        if options[:keyword_init]
          define_method :initialize do |args|
            args.each { |attr, value| send("#{attr}=", value) }
          end
        else
          define_method :initialize do |*vals|
            attrs.each_with_index { |attr, index| send("#{attr}=", vals[index]) }
          end
        end

        define_method :each do
          if block_given?
            attrs.each { |attr| yield send(attr) }
          else
            enum_for(:each)
          end
        end

        define_method :each_pair do
          if block_given?
            attrs.each { |attr| yield attr, send(attr) }
          else
            enum_for(:each_pair)
          end
        end

        define_method :inspect do
          inspected_attrs = attrs.map { |attr| "#{attr}=#{send(attr).inspect}" }
          "#<struct #{inspected_attrs.join(', ')}>"
        end

        define_method(:deconstruct) do
          attrs.map { |attr| send(attr) }
        end

        define_method :[] do |arg|
          case arg
          when Integer
            attribute = attrs.fetch(arg)
            send(attribute)
          else
            send(arg)
          end
        end
      end
    end
  end
end
