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
