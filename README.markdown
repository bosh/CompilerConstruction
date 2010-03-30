simpLex
=====
    A ruby lexer for a pseudopascal language

###
    Usage:
    -----
    $ruby simpLex filename [opts]
###
    Options:
    -----
    The defaut file is "input_file"_tokens.txt
    -d - Dirty: Comments will not be automatically stripped from the file
    -a - All: Forces a full lexical analysis of the file
    -s - StdOut: Prints output to the command line (no save to a file)
    -o - Overwrite: Will overwrite the output file

###
    NOTE:
    -----
    -a and -s both force a full run of the analyzer
    -s has precedence in determining output type

simParse
=====
    A ruby grammar constructor and evaluator built around a pascal language variant, tokenized by simpLex.rb

###
Usage:
-----
    $ruby simParse _filename_ [options]
###
    Options:
    -----
    [-s|-f]	- Stdout OR fileout. File out will be _filename_parsed.txt
    -o		- If mode -f, will overwrite any file with the same target name
    [-a|-n]	- Full run OR no run. No run is default
