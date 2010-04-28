class Parser
  attr_accessor :filename, :options, :grammar, :tree, :tokens, :three_addr_code, :symbol_table
  def initialize(filename, opts = {})
    @options = opts
    @filename = filename
    load_grammar_rules
    load_token_steam
  end
  def after_create
    print_grammar if debug?
    parse if parse_after_create?
    emit_tree if emit_after_create?
    post_actions if post_actions?
  end
  def load_grammar_rules
    @grammar = GrammarGenerator.new(@options[:grammar_file])
  end
  def load_token_steam
    (premade_token_stream?)? load_textfile_tokens : load_simplex_tokens
  end
  def load_textfile_tokens
    @tokens = []
    lines = []
    File.open(@filename){|f| lines = f.readlines}
    while lines && lines.size > 0 #lines to make sure it isn't nil
      lines.shift =~ /\A(\w+)\s+(.*)\z/
      type = $1
      value = $2.strip
      if value[0,1] == '"'
        until value[-1,1] == '"' #or could do until value.quoted?
          value << "\n#{lines.shift.strip}"
        end
        value.dequote!
      end
      @tokens << Token.new("", type, value) #TODO still needs a cleanup
    end
  end
  def load_simplex_tokens
    lex = Lexer.new(@filename, {:internal => true, :full => true})
    @tokens = lex.token_list
  end
  def parse
    result = match?(@grammar.start_symbol)
    if result.parse_error?
      puts "Parse error: #{result}"
      exit(0) #TODO find a proper, in-module way to do this
    else
      @tree = Tree.new(result)
      @tree.clean!
    end
  end
  def match?(start)
    $current_index = 0
    @grammar.start_rule.match?(@tokens)
  end
  def emit_tree
    @tree.print if cmd_line_output?
    if file_output?
      @filename =~ /\A(.*)\.\w+\z/
      outfile = "#{$1}_parsed.txt"
      if overwrite_output? || !File.exists?(outfile)
        puts "Parse successful! Writing to file #{outfile}."
        File.new(outfile, 'w')
        File.open(outfile, 'a'){|f| f.write(@tree.stringify)}
      end
    end
  end
  def print_grammar
    puts "Grammar: #{@grammar.name}"
    grammar_rules.each{|g| puts g[1].to_extended}
    puts "Start Symbol: #{@grammar.start_symbol}"
  end
  def post_actions
    generate_symbol_table
    generate_3ac
    emit_symbol_table
    emit_3ac
  end
  def generate_symbol_table; @symbol_table = @tree.create_symbol_table end
  def generate_3ac
    #TODO
  end
  def emit_symbol_table; puts @symbol_table end
  def emit_3ac; puts @three_addr_code end
  
  def post_actions?;    @options[:post_actions] end
  def parse_after_create?;    @options[:full]         end
  def file_output?;           @options[:file]         end
  def grammar_rules;          @grammar.grammar        end
  def cmd_line_output?;       @options[:stdout]       end
  def overwrite_output?;      options[:overwrite]     end
  def premade_token_stream?;  @options[:from_tokens]  end
  def emit_after_create?;     @options[:full] || @options[:stdout]  end
end
