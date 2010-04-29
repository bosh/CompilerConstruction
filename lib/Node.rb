class Node
  attr_accessor :children, :parent, :content
  def initialize(content, parent = nil, children = [])
    @content = content
    @parent = parent
    @children = children
  end
  def tree_stringify(level = 0)
    str = ""
    level.times{str << "|\t"}
    str << to_s
    @children.each{|c| str << "\n#{c.tree_stringify(level+1)}"}
    str
  end
  def clean!
    replacements = []
    @children.each do |c| #kills empties and anons/productions
      if c.empty?
        next
      elsif c.production? || c.anonymous_rule? || c.repeater_node?
        c.clean!
        replacements += c.children
      else
        c.clean!
        replacements << c
      end
    end
    @children = replacements
  end
  
  def create_symbol_table(table = nil)
    if is_rule?($parser.grammar.start_symbol) #TODO dont like the global here
      table = SymbolTable.new("Global")
      table.add_variable(@children[1].content.value, "PROGRAMNAME")
      @children.each{|c| c.create_symbol_table(table)}
    elsif is_rule?("ProcedureDeclaration")
      subtable = SymbolTable.new(@children[1].content.value) #@children.select{|n| n.content.class == Token && n.content.value} #returns the value, which is the name
      @children[3].create_symbol_table(subtable) #@c.select{FormalParamList}
      @children[6].create_symbol_table(subtable) #@c.select{Block}
      table.add_subtable(subtable)
      table.add_variable(@children[1].content.value, "PROC")
    elsif is_rule?("FunctionDeclaration")
      subtable = SymbolTable.new(@children[1].content.value)
      @children[3].create_symbol_table(subtable) #see above
      @children[8].create_symbol_table(subtable) #see above
      table.add_subtable(subtable)
      table.add_variable(@children[1].content.value, type_analyze(@children[6], table))
      #may also want to add to the super table "funcname"=>"@children[6]" ie :name=>:type
    elsif is_rule?("TypeDefinition")
      table.add_type(@children[0].content.value, type_analyze(@children[2], table))
    elsif is_rule?("VariableDeclaration")
      type = type_analyze(@children[2], table)
      idents = @children[0].children.select{|c| c.content.type == "ID"}
      idents.each{|i| table.add_variable(i.content.value, type)} #TODO inline with prev
    elsif @children.size == 0 && @content.type == "ID" && !table.contains?(@content.value)
      puts "ERROR: undeclared variable: #{@content.value}"
    else
      @children.each{|c| c.create_symbol_table(table)}
    end
    table
  end  
  def type_analyze(typenode, table)
    first_child = typenode.children[0].content
    if first_child.type == "ID"
      first_child.value
    elsif first_child.value == "array"
      "array of #{type_analyze(typenode.children[7], table)}"
    elsif first_child.value == "record"
      "record"# with members:" #TODO oh god this can recurse
    else
      puts "ERROR: Type detector borked"
    end
  end
  def create_three_addr_code
    if is_rule?("Program")
      #
    elsif is_rule?("TypeDefinitions")
      #
    elsif is_rule?("VariableDeclarations")
      #
    elsif is_rule?("SubprogramDeclarations")
      #
    elsif is_rule?("TypeDefinition")
      #
    elsif is_rule?("VariableDeclaration")
      #
    elsif is_rule?("ProcedureDeclaration")
      #
    elsif is_rule?("FunctionDeclaration")
      #
    elsif is_rule?("FormalParameterList")
      #
    elsif is_rule?("Block")
      #
    elsif is_rule?("CompoundStatement")
      #
    elsif is_rule?("StatementSequence")
      #
    elsif is_rule?("Statement")
      #
    elsif is_rule?("SimpleStatement")
      #
    elsif is_rule?("AssignmentStatement")
      #
    elsif is_rule?("ProcedureStatement")
      #
    elsif is_rule?("StructuredStatement")
      #
    elsif is_rule?("MatchedStatement")
      #
    elsif is_rule?("OpenStatement")
      #
    elsif is_rule?("Type")
      #
    elsif is_rule?("Constant")
      #
    elsif is_rule?("Expression")
      #
    elsif is_rule?("RelationalOp")
      #
    elsif is_rule?("SimpleExpression")
      #
    elsif is_rule?("AddOp")
      #
    elsif is_rule?("Term")
      #
    elsif is_rule?("MulOp")
      #
    elsif is_rule?("Factor")
      #
    elsif is_rule?("FunctionReference")
      #
    elsif is_rule?("ComponentSelection")
      #
    elsif is_rule?("ActualParameterList")
      #
    elsif is_rule?("IdentifierList")
      #
    elsif is_rule?("Sign")
      #
    end
  end

  def to_s;   "#{@content.to_s}"    end
  def rule?;  @content =~ /\ARule:/      end
  def is_rule?(name);  @content =~ /\ARule: (.*)/; rule? && $1.strip == name  end
  def anonymous_rule?;  @content =~ /\ARule: anonymous\z/      end
  def repeater_node?;  @content =~ /\ARepeater node\z/      end
  def production?;  @content =~ /\AProduction\z/      end
  def empty?; @content =~ /\AEmpty match/ end
  def valid?; !(@content =~ /error/i)     end
  def parse_error?; @content =~ /fatal/i  end
end
