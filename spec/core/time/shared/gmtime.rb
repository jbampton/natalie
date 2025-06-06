describe :time_gmtime, shared: true do
  it "converts self to UTC, modifying the receiver" do
    # Testing with America/Regina here because it doesn't have DST.
    with_timezone("CST", -6) do
      t = Time.local(2007, 1, 9, 6, 0, 0)
      NATFIXME "Implement Time##{@method}", condition: @method == :utc, exception: NoMethodError, message: "undefined method '#{@method}' for an instance of Time" do
        t.send(@method)
        # Time#== compensates for time zones, so check all parts separately
        t.year.should == 2007
        t.month.should == 1
        t.mday.should == 9
        t.hour.should == 12
        t.min.should == 0
        t.sec.should == 0
        t.zone.should == "UTC"
      end
    end
  end

  it "returns self" do
    with_timezone("CST", -6) do
      t = Time.local(2007, 1, 9, 12, 0, 0)
      NATFIXME "Implement Time##{@method}", condition: @method == :utc, exception: NoMethodError, message: "undefined method '#{@method}' for an instance of Time" do
        t.send(@method).should equal(t)
      end
    end
  end

  describe "on a frozen time" do
    it "does not raise an error if already in UTC" do
      time = Time.gm(2007, 1, 9, 12, 0, 0)
      time.freeze
      NATFIXME "Implement Time##{@method}", condition: @method == :utc, exception: NoMethodError, message: "undefined method '#{@method}' for an instance of Time" do
        time.send(@method).should equal(time)
      end
    end

    it "raises a FrozenError if the time is not UTC" do
      with_timezone("CST", -6) do
        time = Time.now
        time.freeze
        NATFIXME "Implement Time##{@method}", condition: @method == :utc, exception: SpecFailedException, message: /undefined method '#{Regexp.quote(@method)}' for an instance of Time/ do
          -> { time.send(@method) }.should raise_error(FrozenError)
        end
      end
    end
  end
end
