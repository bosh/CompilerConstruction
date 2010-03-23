require "simpLex.rb"

class Tree
  attr_accessor :root
  def initialize(node)
    @root = node #would be great to make this non-destructive via full copying of data, but that doesn't matter for a one-shot
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
  def initialize(filename, opts = {})
    @filename = filename
    @current_token = @token_head = 0
    @tokens = []
    if opts[:from_tokens]
      import_token_stream(@filename)
    else
      lexer_token_stream(@filename)
    end
  end
  def import_token_stream(filename)
    stream = []
    File.open(filename) do |f|
      lines = f.readlines
      i = 0
      until i > lines.size-1 do #last line is blank
        line = lines[i]
        type = ( /\A(\w+)/ =~ line) ? $1 : line
        value = line[type.length..-1] #skip the delimiting space
        if value[1, 1] == '"' #second in string is "
          while value[value.length-2, 1] != '"' #value isn't terminated by a "
            i += 1
            value += lines[i] #append the next line
          end
          value = value[1...-1] #get rid of starting quote and last char (\n, the " will be handled below)
        end
        value = value[1...-1] #get rid of first and last char (" " and then \n normally, " if went through the if/while)
        stream << Token.new("",type, value) #oh look, token needs a factoring
        i += 1
      end
    end
  end
  def lexer_token_stream(filename)
    lex = Lexer.new(filename, {:internal => true, :full => true})
  end
end

if $0 == __FILE__
  parser = Parser.new("C:/Users/Bosh/Desktop/txt.txt")
  #then run the file and use command line args
  #options should be: (Stdout|Fileout[Overwrite?]|Internal) and (Full|No-run)
  #defaults being same as simpLex's
end
