require_relative '../../spec_helper'
require_relative 'fixtures/classes'

describe "Module#module_function" do
  it "is a private method" do
    Module.should have_private_instance_method(:module_function)
  end

  describe "on Class" do
    it "is undefined" do
      Class.should_not have_private_instance_method(:module_function, true)
    end

    it "raises a TypeError if calling after rebinded to Class" do
      -> {
        Module.instance_method(:module_function).bind(Class.new).call
      }.should raise_error(TypeError)

      -> {
        Module.instance_method(:module_function).bind(Class.new).call :foo
      }.should raise_error(TypeError)
    end
  end
end

describe "Module#module_function with specific method names" do
  it "creates duplicates of the given instance methods on the Module object" do
    m = Module.new do
      def test()  end
      def test2() end
      def test3() end

      module_function :test, :test2
    end

    m.respond_to?(:test).should == true
    m.respond_to?(:test2).should == true
    m.respond_to?(:test3).should == false
  end

  it "returns argument or arguments if given" do
    Module.new do
      def foo; end
      NATFIXME 'Support Ruby 3.1.0', exception: SpecFailedException do
        module_function(:foo).should equal(:foo)
        module_function(:foo, :foo).should == [:foo, :foo]
      end
    end
  end

  it "creates an independent copy of the method, not a redirect" do
    module Mixin
      def test
        "hello"
      end
      module_function :test
    end

    class BaseClass
      include Mixin
      def call_test
        test
      end
    end

    Mixin.test.should == "hello"
    c = BaseClass.new
    c.call_test.should == "hello"

    module Mixin
      def test
        "goodbye"
      end
    end

    Mixin.test.should == "hello"
    c.call_test.should == "goodbye"
  end

  it "makes the instance methods private" do
    m = Module.new do
      def test() "hello" end
      module_function :test
    end

    (o = mock('x')).extend(m)
    o.respond_to?(:test).should == false
    m.should have_private_instance_method(:test)
    o.send(:test).should == "hello"
    -> { o.test }.should raise_error(NoMethodError)
  end

  it "makes the new Module methods public" do
    m = Module.new do
      def test() "hello" end
      module_function :test
    end

    m.public_methods.map {|me| me.to_s }.include?('test').should == true
  end

  it "tries to convert the given names to strings using to_str" do
    (o = mock('test')).should_receive(:to_str).any_number_of_times.and_return("test")
    (o2 = mock('test2')).should_receive(:to_str).any_number_of_times.and_return("test2")

    m = Module.new do
      def test() end
      def test2() end
      module_function o, o2
    end

    m.respond_to?(:test).should == true
    m.respond_to?(:test2).should == true
  end

  it "raises a TypeError when the given names can't be converted to string using to_str" do
    o = mock('123')

    -> { Module.new { module_function(o) } }.should raise_error(TypeError)

    o.should_receive(:to_str).and_return(123)
    -> { Module.new { module_function(o) } }.should raise_error(TypeError)
  end

  it "can make accessible private methods" do # JRUBY-4214
    NATFIXME 'module_function + require', exception: NameError, message: "undefined method `require'" do
      m = Module.new do
        module_function :require
      end
      m.respond_to?(:require).should be_true
    end
  end

  it "creates Module methods that super up the singleton class of the module" do
    super_m = Module.new do
      def foo
        "super_m"
      end
    end

    m = Module.new do
      extend super_m
      module_function
      def foo
        ["m", super]
      end
    end

    m.foo.should == ["m", "super_m"]
  end

  context "methods created with define_method" do
    context "passed a block" do
      it "creates duplicates of the given instance methods" do
        m = Module.new do
          define_method :test1 do; end
          module_function :test1
        end

        m.respond_to?(:test1).should == true
      end
    end

    context "passed a method" do
      it "creates duplicates of the given instance methods" do
        module_with_method = Module.new do
          def test1; end
        end

        c = Class.new do
          extend module_with_method
        end

        m = Module.new do
          define_method :test2, c.method(:test1)
          module_function :test2
        end

        m.respond_to?(:test2).should == true
      end
    end

    context "passed an unbound method" do
      it "creates duplicates of the given instance methods" do
        module_with_method = Module.new do
          def test1; end
        end

        m = Module.new do
          define_method :test2, module_with_method.instance_method(:test1)
          module_function :test2
        end

        m.respond_to?(:test2).should == true
      end
    end
  end
end

describe "Module#module_function as a toggle (no arguments) in a Module body" do
  it "makes any subsequently defined methods module functions with the normal semantics" do
    m = Module.new do
      module_function
      def test1() end
      def test2() end
    end

    m.respond_to?(:test1).should == true
    m.respond_to?(:test2).should == true
  end

  it "returns nil" do
    Module.new do
      NATFIXME 'Support Ruby 3.1.0', exception: SpecFailedException do
        module_function.should equal(nil)
      end
    end
  end

  it "stops creating module functions if the body encounters another toggle " \
     "like public/protected/private without arguments" do
    m = Module.new do
      module_function
      def test1() end
      def test2() end
      public
      def test3() end
    end

    m.respond_to?(:test1).should == true
    m.respond_to?(:test2).should == true
    m.respond_to?(:test3).should == false
  end

  it "does not stop creating module functions if the body encounters " \
     "public/protected/private WITH arguments" do
    m = Module.new do
      def foo() end
      module_function
      def test1() end
      def test2() end
      public :foo
      def test3() end
    end

    m.respond_to?(:test1).should == true
    m.respond_to?(:test2).should == true
    m.respond_to?(:test3).should == true
  end

  it "does not affect module_evaled method definitions also if outside the eval itself" do
    m = Module.new do
      module_function
      module_eval { def test1() end }
      module_eval " def test2() end "
    end

    NATFIXME 'Make Module#module_eval spec-compliant', exception: SpecFailedException do
      m.respond_to?(:test1).should == false
      m.respond_to?(:test2).should == false
    end
  end

  it "has no effect if inside a module_eval if the definitions are outside of it" do
    m = Module.new do
      module_eval { module_function }
      def test1() end
      def test2() end
    end

    m.respond_to?(:test1).should == false
    m.respond_to?(:test2).should == false
  end

  it "functions normally if both toggle and definitions inside a module_eval" do
    m = Module.new do
      module_eval do
        module_function
        def test1() end
        def test2() end
      end
    end

    m.respond_to?(:test1).should == true
    m.respond_to?(:test2).should == true
  end

  it "affects eval'ed method definitions also even when outside the eval itself" do
    m = Module.new do
      module_function
      eval "def test1() end"
    end

    m.respond_to?(:test1).should == true
  end

  it "doesn't affect definitions when inside an eval even if the definitions are outside of it" do
    m = Module.new do
      eval "module_function"
      def test1() end
    end

    NATFIXME "module_function shouldn't affect definitions when inside an eval", exception: SpecFailedException do
      m.respond_to?(:test1).should == false
    end
  end

  it "functions normally if both toggle and definitions inside a eval" do
    m = Module.new do
      eval <<-CODE
        module_function

        def test1() end
        def test2() end
      CODE
    end

    m.respond_to?(:test1).should == true
    m.respond_to?(:test2).should == true
  end

  context "methods are defined with define_method" do
    context "passed a block" do
      it "makes any subsequently defined methods module functions with the normal semantics" do
        m = Module.new do
          module_function
          define_method :test1 do; end
        end

        m.respond_to?(:test1).should == true
      end
    end

    context "passed a method" do
      it "makes any subsequently defined methods module functions with the normal semantics" do
        module_with_method = Module.new do
          def test1; end
        end

        c = Class.new do
          extend module_with_method
        end

        m = Module.new do
          module_function
          define_method :test2, c.method(:test1)
        end

        m.respond_to?(:test2).should == true
      end
    end

    context "passed an unbound method" do
      it "makes any subsequently defined methods module functions with the normal semantics" do
        module_with_method = Module.new do
          def test1; end
        end

        m = Module.new do
          module_function
          define_method :test2, module_with_method.instance_method(:test1)
        end

        m.respond_to?(:test2).should == true
      end
    end
  end
end
