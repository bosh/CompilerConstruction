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
    @children.each do |c|
      c.clean!
      if c.empty? || (c.rule? && c.children.size == 0)
        @children.delete(c)
      end
    end
  end
 
  def to_s;   "Node: #{@content.to_s}"    end
  def rule?;  @content =~ /\ARule: /      end
  def empty?; @content =~ /\AEmpty match/ end
  def valid?; !(@content =~ /error/i)     end
  def parse_error?; @content =~ /fatal/i  end
end
