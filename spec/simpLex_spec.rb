require File.expand_path(File.join('.', 'spec_helper'), File.dirname(__FILE__))
require 'simpLex'

describe Lexer do
  before :each do
    @lex = Lexer.new
  end

  it "should load the selected file into a buffer" do
    @lex.load_buffer
    @lex.buffer.should == "simple buffer"
  end

  it "should initially load the file into the buffer" do
    @lex.buffer.should == "simple buffer"
  end
end