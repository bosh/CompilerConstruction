require 'Core'
$current_index = 0
$matchno = 0
$debug = false
def debug?; $debug end 

if $0 == __FILE__
  if ARGV.size == 0 || ARGV.include?("-h") || ARGV.include?("help")
    puts "Welcome to simParse,
\ta simple parser for a pascal-variant grammar
\nsimParse works together with simpLex to analyze and parse your programs.
\nTo use:\n\truby simParse _filename_ [options]
\nOptions:
\t[-s|-f]\t- Stdout OR fileout. File out will be _filename_parsed.txt
\t-o\t- If mode -f, will overwrite any file with the same target name
\t[-a|-n]\t- Full run OR no run. No run is default\n"
  else
    opts = {}
    filename = ARGV.delete_at(0)
    ARGV.each do |arg|
      case arg
        when "-a" : opts[:full]         = true
        when "-d" : opts[:debug]        = $debug = true
        when "-f" : opts[:file]         = opts[:full] = true
        #when "-g" : opts[:grammar_file] = filename#.drop_extension.add__grammar.grm #BROKEN
        when "-n" : opts[:full]         = false
        when "-o" : opts[:overwrite]    = true
        when "-s" : opts[:stdout]       = opts[:full] = true
        when "-p"  : opts[:post_actions] = true
      else
        puts "Unrecognized option: '#{arg}'. Attempting run anyway."
      end
    end
    opts[:grammar_file] ||= "default_grammar.grm"
    $parser = Parser.new(filename, opts)
    $parser.after_create
  end
end
