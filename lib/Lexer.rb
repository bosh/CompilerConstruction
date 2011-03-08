class Lexer
  attr_accessor :buffer, :options, :token_list

  #call with options[:internal] = true if you want the lex'd stream available
  def initialize( file, options = {} )
    if File.exists?(file)
      @options  = options
      @buffer   = Buffer.new(   File.open(file).read, @options[:dirty] )
      if @options[:internal ] : @token_list = [] end
      if @options[:full     ] : full_analysis()  end
    else
      puts "Cannot find the input file: #{file}\nType Use --help for more options."
      exit(0)
    end
  end
  
  def complete?;  @buffer.finished? end
  def next_token; @buffer.get_next_token end
  
  def full_analysis
    prepare_outfile
    until  complete?
      emit next_token
    end
  end

  def emit( token )
    if    @options[:stdout  ] : print token.tokenized
    elsif @options[:internal] : @token_list << token
    elsif @options[:target  ]
      File.open(@options[:target], 'a') { |f| f.write(token.tokenized) }
    end
  end

  def prepare_outfile
    if !@options[:stdout] && !@options[:internal]
      target = @options[:target] || "simpLex_out.txt"
      if !File.exists?(target) || @options[:overwrite]
        File.new(target, "w") 
      else
        puts "simpLex: The target file already exists.
        Run with -f or -o if you want to overwrite it."
        exit(0)
      end
    end
  end
end
