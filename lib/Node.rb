class Node
  @@tempcount = 0
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
  def create_three_addr_code(tempname = nil)
    code = []
    if is_rule?("Program")
      code << "goto #{@children[1].content.value}"
      (3..(@children.size - 3)).each{|i| code += @children[i].create_three_addr_code}
      code << "#{@children[1].content.value}"
      code += @children[@children.size-2].create_three_addr_code
    elsif is_rule?("TypeDefinitions")
      @children.select{|c| c.is_rule?("TypeDefinition")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("VariableDeclarations")
      @children.select{|c| c.is_rule?("VariableDeclaration")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("SubprogramDeclarations")
      @children.select{|c| c.is_rule?("ProcedureDeclaration") || c.is_rule?("Functioneclaration")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("TypeDefinition")
      #
    elsif is_rule?("VariableDeclaration")
      #
    elsif is_rule?("ProcedureDeclaration")
      code << "#{@children[1].content.value}"
      code += @children[3].create_three_addr_code
      code += @children[6].create_three_addr_code
      code << "return"
    elsif is_rule?("FunctionDeclaration")
      code << "#{@children[1].content.value}"
      code += @children[3].create_three_addr_code
      code += @children[8].create_three_addr_code
      code << "funreturn _something_" #TODO Where?
    elsif is_rule?("FormalParameterList")
      @children.select{|c| c.is_rule?("VariableDeclaration")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("Block")
      @children.select{|c| c.is_rule?("VariableDeclaration")}.each{|r| code += r.create_three_addr_code}
      @children.select{|c| c.is_rule?("CompoundStatement")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("CompoundStatement")
      code += @children[1].create_three_addr_code
    elsif is_rule?("StatementSequence")
      @children.select{|c| c.is_rule?("Statement")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("Statement")
      code += @children[0].create_three_addr_code
    elsif is_rule?("SimpleStatement")
      code += @children[0].create_three_addr_code unless @children.size == 0
    elsif is_rule?("AssignmentStatement") #needs work
      @children.select{|c| c.is_rule?("Expression")}.each{|r| code += r.create_three_addr_code}
      code << "_tempvar_ := above"
      code << "work compselection in somehow"
      code << "#{@children[0]} := _tempvar_"
    elsif is_rule?("ProcedureStatement")
      code += @children[2].create_three_addr_code
      code << "call #{@children[0].content.value}"
    elsif is_rule?("StructuredStatement")
      code += @children[0].create_three_addr_code
    elsif is_rule?("MatchedStatement")
      #OHGOD
    elsif is_rule?("OpenStatement")
      #OHGOD
    elsif is_rule?("Type")
      #do nothing
    elsif is_rule?("Constant")
      #usually do nothing, maybe save into a var
    elsif is_rule?("Expression")
      code += @children[0].create_three_addr_code
      if @children.size == 3
        code << "_newtemp_ := _resultofabove_"
        code += @children[2].create_three_addr_code
        code << "_newtemp2_ := _resultofabove_"
        code << "_passedintemp_ := _newtemp_ #{@children[1].children[0].content.value} _newtemp2_"
      else
        code << "_passedintemp_ := _resultofabove_"
      end
    elsif is_rule?("RelationalOp")
      #do nothing
    elsif is_rule?("SimpleExpression")
      rep = 1
      if @children[0].is_rule?("Sign")
        code += @children[1].create_three_addr_code
        code << "_fromprev_ #{@children[0].content.value} _fromprev_"
        rep = 2
      end
      (rep..@children.size-2).each do |i| #May wish to make this run from the reverse backwards towards head
        if rep == 1 && i%2 == 0; next end #TODO verify that 1 and 0 (even/odd) arent swapped 
        if rep == 2 && i%2 == 1; next end
        code += @children[i+1].create_three_addr_code
        code += @children[i].create_three_addr_code
        code << "_temp_:= running 'sum'"
      end
    elsif is_rule?("AddOp")
      #do nothing
    elsif is_rule?("Term")
      #similar to SimpleExpr
    elsif is_rule?("MulOp")
      #do nothing
    elsif is_rule?("Factor")
      #usually do nothing
    elsif is_rule?("FunctionReference")
      code += @children[2].create_three_addr_code
      code << "call #{@children[0].content.value}"
    elsif is_rule?("ComponentSelection")
      if !@children.size == 0
        if @children[0].content.value == "." #its opt1
          
        else #its opt2
          
        end
      end
    elsif is_rule?("ActualParameterList")
      @children.select{|c| c.is_rule?("Expression")}.each do |r|
        code += r.create_three_addr_code #pass in a new temp to save expr into
        code << "param _thetempfromprevline_"
      end
    elsif is_rule?("IdentifierList")
      #dont do anything
    elsif is_rule?("Sign")
      #dont do anything
    end
    code
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
  def new_temp; @@tempcount += 1; "t#{@@tempcount}" end
end
