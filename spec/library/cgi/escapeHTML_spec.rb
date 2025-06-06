require_relative '../../spec_helper'
begin
  require 'cgi/escape'
rescue LoadError
  require 'cgi'
end

describe "CGI.escapeHTML" do
  it "escapes special HTML characters (&\"<>') in the passed argument" do
    CGI.escapeHTML(%[& < > " ']).should == '&amp; &lt; &gt; &quot; &#39;'
  end

  it "escapes invalid encoding" do
    CGI.escapeHTML(%[<\xA4??>]).should == "&lt;\xA4??&gt;"
  end

  it "does not escape any other characters" do
    chars = " !\#$%()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
    CGI.escapeHTML(chars).should == chars
  end
end
