class Lexer
  attr_accessor :buffer, :options, :token_list
  def initialize( file, options = {} ) #call with options[:internal] = true if you want the lex'd stream available
    if File.exists?(file)
      @options  = options
      @buffer   = Buffer.new( File.open(file).read, @options[:dirty] )
      if @options[:internal] : @token_list = [] end
      if options[:full] : full_analysis() end
    else
      puts "Cannot find the input file: #{file}\nType Use --help for more options."
      exit(0)
    end
  end
  
  def complete?;  @buffer.finished? end
  def next_token; @buffer.get_next_token end
  
  def full_analysis
    prepare_outfile
    until complete?
      emit next_token
    end
  end
  def emit( token )
    if @options[:stdout] : print token.tokenized
    elsif @options[:internal] : @token_list << token
    elsif @options[:target]
      File.open(@options[:target], 'a') {|f| f.write(token.tokenized) }
    end
  end
  def prepare_outfile
    if !@options[:stdout]
      target = @options[:target] || "simpLex_out.txt"
      if !File.exists?(target) || @options[:overwrite]
        File.new(target, "w") 
      else
        puts "The target file already exists.
        Run with -f or -o if you want to overwrite it."
        exit(0)
      end
    end
  end
end

class Buffer
  attr_accessor :contents, :current, :current_head, :style
  def initialize(str, dirty = false, style = :default)
    @contents = str.strip
    @current  = @current_head = 0
    @style    = style
    clean! unless dirty #Heh heh heh
  end
  
  def clean!;       @contents.gsub!(/\{.*?(\}|\z)/m, "") end #Strip {} comments
  def finished?;    @current_head >= @contents.length end
  def advance;      @current += 1             end
  def back_up;      @current -= 1             end
  def update_head;  @current_head = @current  end
  
  def lookahead #Returns the character one ahead of the lookahead
    if @current+1 < @contents.size
      Token.new(@contents[@current+1,1]) #token so that it can call the _? methods
    else
      nil
    end
  end
  def get_next_token
    if finished? : return nil end #Returns a nil if past end and still being called
    token = Token.new("")
    @current = @current_head #make certain that current == head to start with
    token << @contents[@current, 1]
    if token.quote?
      advance until (lookahead == nil || lookahead.quote?)
      advance
      text = @contents[@current_head..@current]
      token = Token.new(text, "LITERAL", text)
      advance #should be right
      update_head
    elsif token.digit?
      advance while lookahead && lookahead.digit?
      if lookahead && lookahead.identifier_tail? #if it's a nonterminal that is also a nondigit
        text = @contents[@current_head..@current]
        update_head
        puts "INT Token: #{text} is followed by nondigits (#{lookahead.text}). Terminating run."
        exit(0)
      end
      text = @contents[@current_head..@current]
      token = Token.new(text, "INT", text)
      advance #should be right
      update_head
    elsif token.identifier_head?
      advance while lookahead && lookahead.identifier_tail?
      text = @contents[@current_head..@current]
      token = Token.new(text, "ID", text)
      advance #this bit might be factorable too.. what about token.assemble or something
      update_head
    elsif token.symbol?
      if lookahead && Token.new(token << lookahead.text).symbol? : advance end
      text = @contents[@current_head..@current]
      token = Token.new(text, "SYMBOL", text)
      advance
      update_head
    elsif token.whitespace?
      advance while lookahead && lookahead.whitespace?
      advance
      update_head
      token = get_next_token #recursion, not great, but should be impossible to get more than one level deep
    else
      puts "Token: #{token.text} was not recognized as valid. Terminating run."
      exit(0) #can't use emit here
    end
    token
  end
end

class Token
  attr_accessor :text, :type, :value
  @@symbols = %w(+ * -  = < <= > >= <> . , : ; := .. ( ) [ ])
  @@keywords = %w(and begin forward div do else end
    for function if array mod not of or procedure program
    record then to type var while)
  @@relops = %w(= < <= >= > <>)
  @@ariths = %w(+ * -)
  @@groups = %w( ( ) [ ] )
  
  def initialize(text, type = "", value = "")
    @text = text
    @type = type
    @value = value
    specify_type!
  end
  def specify_type!
    if keyword?               : @type = "KEYWORD"
      elsif string_literal?   : @type = "STR"
      elsif relational_op?    : @type = "RELOP"
      elsif arithmetic_op?    : @type = "ARITHOP"
      elsif grouping_symbol?  : @type = "GROUP"
    end
  end
  
  def << (str);           @text << str  end
  def to_terminal;        @value        end
  def grouping_symbol?;   @@groups.index(@text)   end
  def relational_op?;     @@relops.index(@text)   end
  def arithmetic_op?;     @@ariths.index(@text)   end
  def keyword?;           @@keywords.index @text  end
  def symbol?;            @@symbols.index @text   end
  def string_literal?;    @text.match( /\A\".*\"\z/m )        end
  def identifier_head?;   @text.match( /\A[a-zA-Z]\z/ )       end
  def identifier_tail?;   @text.match( /\A[a-zA-Z0-9_]*\z/ )  end
  def digit?;             @text.match( /\A[0-9]+\z/ )         end
  def quote?;             @text.match( /\A"\z/ )              end
  def whitespace?;        @text.match( /\A[\n\t\ ]*\z/ )      end
  
  def tokenized(style = :default)
    if      style == :default   : "#{@type} #{@value}\n"
      elsif style == :brackets  : "[#{@type}: #{@value}]\n"
      elsif style == :indent    : "\t#{@type}: #{@value}\n"
      elsif style == :angle     : "<#{@type}, #{@value}>\n"
    end
  end
end

#Following bit run only when not being used as a require from somewhere else
instructions = "\nWelcome to simpLex,
\ta simple Ruby lexical analyzer for a basic Pascal grammar.
Usage:\n\t$ruby simpLex filename [opts]\nOptions:
\t\tThe defaut file is \"input_file\"_tokens.txt
\t-d - Dirty: Comments will not be automatically stripped from the file
\t-a - All: Forces a full lexical analysis of the file
\t-s - StdOut: Prints output to the command line (no save to a file)
\t-o - Overwrite: Will overwrite the output file\n
\tNOTE: -a and -s both force a full run of the analyzer
\t      -s has precedence in determining output type\n"
if $0 == __FILE__
  if ARGV.size == 0 || ARGV[0] == "-h" || ARGV[0] == "--help"
    puts instructions
  else
    opts = {}
    ARGV[0].match(/\A(.*)\..*\z/)
    opts[:target] = "#{$1}_lex.txt"
    opts[:source] = ARGV[0]
    args = ARGV.delete_at 0 #remove the program file from the arguments
    ARGV.each do |arg|
      case arg
        when "-d" : opts[:dirty]      = true
        when "-a" : opts[:full]       = true
        when "-o" : opts[:overwrite]  = true
        when "-s" : opts[:stdout]     = opts[:full] = true
        when arg[0..1]=="-f" : #broken
          opts[:overwrite] = true
          opts[:target] = arg[2..-1]
      else
        puts "Unrecognized option: '#{arg}'. Attempting run anyway."
      end
    end
    Lexer.new(opts[:source], opts)
  end
end
