#(1..100).each{|i| puts((i%3==0) ? ((i%5==0)? "fizzbuzz" : "fizz" ) : ((i%5==0)? "buzz" : i) )} # But first, a short: Lolbuzz
class Lexer
  attr_accessor :buffer, :options
  def initialize(file, options = {})
    @options = options
    @buffer = Buffer.new(File.open(file).read, @options[:dirty])
    if options[:full] : full_analysis() end
  end
  def full_analysis
    #if target to write to doesnt exist, create it
    until complete?
      emit next_token
    end
  end
  def complete?
    @buffer.finished?
  end
  def next_token
    #if target to write to doesnt exist, create it
    emit @buffer.get_next_token
  end
  def emit(str)
    if @options[:stdout]
      puts str
      #elsif options[:outfile] write to it
    else
      #write to the default file File.write(str)
    end
  end
end

class Buffer
  attr_accessor :contents, :current, :current_head
  def initialize(str, dirty)
    @contents = str
    @current = @current_head = 0
    clean! unless dirty? #Heh heh heh
  end
  def clean!
    #@contents.gsub!(/#[^\n]*\n/, "")  #Strip ruby style comments # to \n
    #@contents.gsub!(/\/\*.*?(\*\/|\z)/m, "") #Strip java style comments /* to */
    @contents.gsub!(/\{.*?\}/m, "")
  end
  def dirty?
    @dirty
  end
  def finished?
    @current_head == @contents.length #Meaning current is beyond referenceable characters
  end
  def get_next_token
    token = ''
    @current = @current_head-1 #start at -1 such that it can increase to be ==
    while true #requires a break when you find good stuff
      @current += 1 #increase it
      token = Token.new(@contents[@current_head..@current])
      if token.whitespace? : #handle it
      elsif token.keyword? : #handle it } THESE ALL MEAN SET TYPE AND VALUE AND BREAK
      elsif token.symbol? : #handle it
      end
      if token = "\"" : end #run until you get another "
      if token.match(/\A\d+\z/) : end #run until you get a nondigit
      if token.match(/\A[a-zA-Z][a-zA-Z0-9_]*\z/) : end #run until you get an invalid
    end
    if token.identifier? : end #@@ids[@@id] = value, value = @@id, @@id += 1; 
    token.tokenized #return
  end
end
class Token
  attr_accessor :text, :type, :value
  @@symbols = %w(+ * -  = < <= > >= <> . , : ; := .. ( ) [ ])
  @@keywords = %w(and begin forward div do else end
    for function if array mod not of or procedure program
    record then to type var while)
  @@whitespace = ("\t", "\n", " ")
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
    @@whitespace.index @text #return value. gives nil if not == ws
  end
  def tokenized
    "<#{@type},#{@value}>\n"
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
\tNOTE: -a, -s, and -f all force a full run of the analyzer\n"
if ARGV.size == 0
  puts instructions
else
  opts = {}
  ARGV.each do |arg|
    case arg
    when "-d" : opts[:dirty] = true
    when "-a" : opts[:full] = true
    when "-s"
      opts[:stdout] = true
      opts[:full] = true
    #when "-f" : #broken
    else
      #puts "Unrecognized option: '#{arg}'. Attempting run anyway."
    end
  end
  Lexer.new(ARGV[0], opts)
end