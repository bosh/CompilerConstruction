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
