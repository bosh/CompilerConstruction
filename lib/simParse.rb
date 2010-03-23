require "simpLex.rb"

class Tree
  attr_accessor :root
  def initialize(node)
    @root = node
    @root.orphan!
  end
  def full_print
    @root.tree_print
  end
end

class Node
  attr_accessor :contents, :parent, :text
  def initialize(parent, text)
    @contents = []
    @parent = parent
    @text = text
  end
  def tree_print(level = 0)
    level.times{print "\t"}
    puts @text
    @contents.each{|c| c.tree_print(level+1)}
  end
  def orphan!
    @parent = nil
  end
end

class Parser
  attr_accessor :filename, :tokens, :current_token, :token_head
  def initialize(filename)
    @filename = filename
    @current_token = @token_head = 0
    @tokens = []
    load_token_stream
  end
  def load_token_stream
    #open file
    #each line do
    #create a token and put into @tokens
    #close file
  end
end

