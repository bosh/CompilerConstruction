#(1..100).each{|i| puts((i%3==0) ? ((i%5==0)? "fizzbuzz" : "fizz" ) : ((i%5==0)? "buzz" : i) )} # But first, a short: Lolbuzz
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
    emit @buffer.id_table
  end
  def complete?
    @buffer.finished?
  end
  def next_token
    emit @buffer.get_next_token
  end
  def emit(str)
    if @options[:stdout]
      print str
    elsif options[:target]
      File.open(@options[:target], 'w') {|f| f.write(str) }
    end
  end
  def prepare_outfile
    if !@options[:stdout]
      target = @options[:target]
      if !File.exists?(target) || @options[:overwrite]
        File.new(target, "w") 
      else
        puts "The target file already exists.\nRun with -f or -o if you want to overwrite it."
        exit(0)
      end
    end
  end
end

class Buffer
  @@ids = []
  attr_accessor :contents, :current, :current_head, :style
  def initialize(str, dirty, style = :default)
    @contents = str
    @current = @current_head = 0
    @style = style
    clean! unless dirty? #Heh heh heh
  end
  def clean!
    #@contents.gsub!(/#[^\n]*\n/, "")  #Strip ruby style comments # to \n
    #@contents.gsub!(/\/\*.*?(\*\/|\z)/m, "") #Strip java style comments /* to */
    @contents.gsub!(/\{.*?(\}|\z)/m, "") #Strip {} comments, including nonclosing terminal ones
  end
  def dirty?
    @dirty
  end
  def finished?
    @current_head == @contents.length #Meaning current is beyond referenceable characters
  end
  def lookahead #Returns the character one ahead of the lookahead
    if @current+1 < @contents.size
      @contents[@current+1,0]
    else
      nil
    end
  end
  def get_next_token
    token = ''
    @current = @current_head-1 #start at -1 such that it can increase to be ==
    while true #requires a break when you find good stuff
      @current += 1 #increase it
      token = Token.new(@contents[@current_head..@current])
      nextchar = lookahead
      if token.whitespace? : #handle it
        elsif token.keyword? : #handle it } THESE ALL MEAN SET TYPE AND VALUE AND BREAK
        elsif token.symbol? : #handle it
      end
      if token == "\"" : end #run until you get another "
      if token.match(/\A\d+\z/) : end #run until you get a nondigit
      if token.match(/\A[a-zA-Z][a-zA-Z0-9_]*\z/) : end #run until you get an invalid
    end
    if token.identifier? : end #@@ids[@@ids.length] = value; value = @@ids.length-1; 
    token.tokenized #return
  end
  def id_table
    str = ""
    @@ids.each_with_index do |id|
      str << id.tokenized(@style)
    end
    str
  end
end
class Token
  attr_accessor :text, :type, :value
  @@symbols = %w(+ * -  = < <= > >= <> . , : ; := .. ( ) [ ])
  @@keywords = %w(and begin forward div do else end
    for function if array mod not of or procedure program
    record then to type var while)
  def initialize(text)
    @text = text
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
    if style == :default : "<#{@type}, #{@value}>\n"
      elsif style == :brackets : "[#{@type}: #{@value}]\n"
      elsif style == :indent : "\t#{@type}: #{@value}\n"
      elsif style == :plain : "#{@type}, #{@value}\n"
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
if ARGV.size == 0
  puts instructions
else
  opts = {}
  opts[:source] = "#{ARGV[0]}"
  ARGV[0].match()
  opts[:target] = "#{}_lex.txt"
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
      puts "this should not be seen(L150)"
    else
      puts "Unrecognized option: '#{arg}'. Attempting run anyway."
    end
  end
  Lexer.new(ARGV[0], opts)
end