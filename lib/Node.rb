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
    replacements = []
    @children.each do |c| #kills empties and anons/productions
      if c.class == Array; puts c; exit(0) end
      if c.empty?
        next
      elsif c.production? || c.anonymous_rule?
        c.clean!
        replacements += c.children
      else
        c.clean!
        replacements << c
      end
    end
    @children = replacements
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
