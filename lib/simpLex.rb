require 'Core'
if $0 == __FILE__
  if ARGV.size == 0 || ARGV.include?("-h") || ARGV.include?("--help")
    puts "Welcome to simpLex,
\ta simple Ruby lexical analyzer for a basic Pascal grammar.
Usage:\n\t$ruby simpLex filename [opts]\nOptions:
\t\tThe defaut file is \"input_file\"_tokens.txt
\t-d - Dirty: Comments will not be automatically stripped from the file
\t-a - All: Forces a full lexical analysis of the file
\t-s - StdOut: Prints output to the command line (no save to a file)
\t-o - Overwrite: Will overwrite the output file\n
\tNOTE: -a and -s both force a full run of the analyzer
\t      -s has precedence in determining output type\n"
  else
    opts = {}
    ARGV[0].match(/\A(.*)\..*\z/)
    opts[:target] = "#{$1}_lex.txt"
    opts[:source] = ARGV.delete_at 0
    ARGV.each do |arg|
      case arg
        when "-a" : opts[:full]       = true
        when "-d" : opts[:dirty]      = true
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
