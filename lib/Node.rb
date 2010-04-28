class Node
  attr_accessor :children, :parent, :content
  def initialize(content, parent = nil, children = [])
    @content = content
    @parent = parent
    @children = children
  end
  def tree_stringify(level = 0)
    str = ""
    level.times{str << "|\t"}
    str << to_s
    @children.each{|c| str << "\n#{c.tree_stringify(level+1)}"}
    str
  end
  def clean!
    #before_clean
    @children.each do |c|
      c.clean!
      #internal_clean
    end
    #after_clean
  end
  def create_symbol_table
    table = {}
    #before_recurse
    @children.each do |c|
      internal = c.create_symbol_table
      table[internal.name] = internal
    end
    #after_recurse
    table
  end
 
  def to_s;   "#{@content.to_s}"    end
  def rule?;  @content =~ /\ARule:/      end
  def anonymous_rule?;  @content =~ /\ARule: anonymous\z/      end
  def production?;  @content =~ /\AProduction\z/      end
  def empty?; @content =~ /\AEmpty match/ end
  def valid?; !(@content =~ /error/i)     end
  def parse_error?; @content =~ /fatal/i  end
end
