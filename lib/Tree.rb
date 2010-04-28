class Tree
  attr_accessor :root
  def initialize(node = nil); @root = node; clean!  end
  def print;                  puts stringify        end
  def stringify;              @root.tree_stringify  end
  def clean!; @root.clean!                          end
end
