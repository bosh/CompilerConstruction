class Tree
  attr_accessor :root

  def initialize(node = nil); @root = node; clean! end

  def clean!;                 @root.clean!                 end
  def print;                  puts stringify               end
  def stringify;              @root.tree_stringify         end
  def create_symbol_table;    @root.create_symbol_table    end
  def create_three_addr_code; @root.create_three_addr_code end
end
