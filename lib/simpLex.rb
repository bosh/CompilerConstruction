class Lexer
  attr_accessor :buffer, :options
  def initialize(file, options = {})
    @options = options
    @buffer = Buffer.new(File.open(file).read, @options[:dirty])
    if options[:full] : full_analysis() end
  end
  def full_analysis
    prepare_outfile
    until complete?
      emit next_token
    end
  end
  def complete?
    @buffer.finished?
  end
  def next_token
    @buffer.get_next_token.tokenized
  end
  def emit(str)
    if @options[:stdout]
      print str
    elsif @options[:target]
      File.open(@options[:target], 'a') {|f| f.write(str) }
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
  @@ids = []
  attr_accessor :contents, :current, :current_head, :style
  def initialize(str, dirty = false, style = :default)
    @contents = str.strip
    @current = @current_head = 0
    @style = style
    clean! unless dirty #Heh heh heh
  end
  def clean!
    @contents.gsub!(/\{.*?(\}|\z)/m, "") #Strip {} comments, including nonclosing terminal ones
  end
  def finished?
    @current_head >= @contents.length #Meaning current is beyond referenceable characters
  end
  def lookahead #Returns the character one ahead of the lookahead
    if @current+1 < @contents.size
      Token.new(@contents[@current+1,1]) #token so that it can call the _? methods
    else
      nil
    end
  end
  def advance
    @current += 1
  end
  def back_up
    @current -= 1
  end
  def update_head
    @current_head = @current
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
      puts "Token: #{} was not recognized as valid. Terminating run."
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
  def initialize(text, type = "", value = "")
    @text = text
    @type = type
    @value = value
    #confirm_type!
  end
  def << (str)
    @text << str
  end
  def identifier_head?
    @text.match( /\A[a-zA-Z]\z/ )
  end
  def identifier_tail?
    @text.match( /\A[a-zA-Z0-9_]*\z/ )
  end
  def digit?
    @text.match( /\A[0-9]+\z/ )
  end
  def quote?
    @text.match( /\A"\z/ )
  end
  def keyword?
    @@keywords.index @text #return value. gives nil if not present
  end
  def symbol?
    @@symbols.index @text #return value. gives nil if not present
  end
  def whitespace?
    @text.match(/\A[\n\t\ ]*\z/) #return value. gives nil if not == ws
  end
  def tokenized(style = :default)
    if style == :default : "#{@type} #{@value}\n"
      elsif style == :brackets : "[#{@type}: #{@value}]\n"
      elsif style == :indent : "\t#{@type}: #{@value}\n"
      elsif style == :angle : "<#{@type}, #{@value}>\n"
    end
  end
end
#Following should only run when not being used as a require from somewhere else
instructions = "\nWelcome to simpLex,\n
\ta simple Ruby lexical analyzer for a basic Pascal grammar.
Usage:\n\t$ruby simpLex filename [opts]\nOptions:
\t-f\"_filename_\" - (OPT) Specifies a file to save output to.
\t\tThe defaut file is \"input_file\"_tokens.txt
\t-d - Dirty: Comments will not be automatically stripped from the file
\t-a - All: Forces a full lexical analysis of the file
\t-s - StdOut: Prints output to the command line (no save to a file)
\t-o - Overwrite: Will overwrite the output file
\tNOTE: -a, -s, and -f all force a full run of the analyzer
\t\t Also, -s has precedence in determining output type\n"
if $0 == __FILE__
  if ARGV.size == 0
    puts instructions
  else
    opts = {}
    opts[:source] = "#{ARGV[0]}"
    ARGV[0].match(/\A(.*)\..*\z/)
    opts[:target] = "#{$1}_lex.txt"
    args = ARGV.delete_at 0 #remove the program file from the arguments
    ARGV.each do |arg|
      case arg
      when "-d" : opts[:dirty] = true
      when "-a" : opts[:full] = true
      when "-o" : opts[:overwrite] = true
      when "-s"
        opts[:stdout] = true
        opts[:full] = true
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
