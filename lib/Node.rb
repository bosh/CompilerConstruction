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
      code << "  exit"
    elsif is_rule?("TypeDefinitions")
      @children.select{|c| c.is_rule?("TypeDefinition")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("VariableDeclarations")
      @children.select{|c| c.is_rule?("VariableDeclaration")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("SubprogramDeclarations")
      @children.select{|c| c.is_rule?("ProcedureDeclaration") || c.is_rule?("Functioneclaration")}.each{|r| code += r.create_three_addr_code}
    elsif is_rule?("TypeDefinition")
      #code << "TODOtypedef"
    elsif is_rule?("VariableDeclaration")
      #code << "TODOvardec"
    elsif is_rule?("ProcedureDeclaration")
      code << "#{@children[1].content.value}"
      code += @children[3].create_three_addr_code
      code += @children[6].create_three_addr_code
      code << "return"
    elsif is_rule?("FunctionDeclaration")
      code << "#{@children[1].content.value}"
      code += @children[3].create_three_addr_code
      code += @children[8].create_three_addr_code
      code << "funreturn #{type_analyze(@children[6], nil)}" #TODO incorrect
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
    elsif is_rule?("AssignmentStatement")
      t = new_temp
      @children.select{|c| c.is_rule?("Expression")}.each{|r| code += r.create_three_addr_code(t)}
      if @children.size == 4
        t1 = new_temp
        code += @children[1].create_three_addr_code(t1)
        code << "#{@children[0].content.value}[#{t1}]:= #{t}" #TODO Bork
        else
        code << "#{@children[0].content.value} := #{t}"
      end
    elsif is_rule?("ProcedureStatement")
      code += @children[2].create_three_addr_code
      code << "call #{@children[0].content.value}"
    elsif is_rule?("StructuredStatement")
      code += @children[0].create_three_addr_code
    elsif is_rule?("MatchedStatement")
      if @children.size == 6 #if then else
        statement = new_temp
        els = new_temp
        bottom = new_temp
        t = new_temp
        code += @children[1].create_three_addr_code(t) 
        code << "if #{t} goto #{statement}" #true
        code << "goto #{els}" #false
        code << "#{statement}"
        code += @children[3].create_three_addr_code
        code << "goto #{bottom}"
        code << "#{els}"
        code += @children[5].create_three_addr_code
        code << "#{bottom}"        
      elsif @children.size == 1 #compound
        code += @children[0].create_three_addr_code
      elsif @children.size == 4 #while
        top = new_temp
        loop = new_temp
        bottom = new_temp
        code << "#{top}"
        t = new_temp
        code += @children[1].create_three_addr_code(t) 
        code << "if #{t} goto #{loop}" #true
        code << "goto #{bottom}" #false
        code << "#{loop}"
        code += @children[3].create_three_addr_code
        code << "goto #{top}"
        code << "#{bottom}"
      else #if @children.size == 8
        code << "TODO for loop"
      end
    elsif is_rule?("OpenStatement")
      code << "TODOopens"
    elsif is_rule?("Type")
      if @children.size == 1
        code << "#{tempname} := #{@children[0].content.value}___"
      elsif @children.size == 3
        code << "record___"
      elsif @children.size > 3
        code << "array___"
      end
    elsif is_rule?("Constant")
      if tempname
        if @children.size == 2
          code << "#{tempname} := #{@children[0].content.value} #{@children[1].content.value}"
        else
          code << "#{tempname} := #{@children[0].content.value}"
        end
      end
    elsif is_rule?("Expression")
      if @children.size == 3
        t = new_temp
        t1 = new_temp
        code += @children[2].create_three_addr_code(t)
        code += @children[0].create_three_addr_code(t1)
        code << "#{tempname} := #{t} #{@children[1].children[0].content.value} #{t1}"
      else
        code += @children[0].create_three_addr_code(tempname)
      end
    elsif is_rule?("RelationalOp")
      #code << "TODOrelop"
    elsif is_rule?("SimpleExpression") #comes with a temp
      t = new_temp
      if @children[0].is_rule?("Sign")
        code += @children[1].create_three_addr_code(t)
        code << "#{t} := #{@children[0].content.value} #{t}"
      else
        code += @children[0].create_three_addr_code(t)
      end
      addops = @children.select{|c| c.is_rule?("AddOp")}
      terms = @children.select{|c| c.is_rule?("Term")}
      (0...addops.size).each do |i|
        tn = new_temp
        code += terms[i+1].create_three_addr_code(tn)
        code << "#{t} := #{t} #{addops[i].children[0].content.value} #{tn}"
      end
      code << "#{tempname} := #{t}"
    elsif is_rule?("AddOp")
      #code << "TODOaddop"
    elsif is_rule?("Term")
      t = new_temp
      code += @children[0].create_three_addr_code(t)
      mulops = @children.select{|c| c.is_rule?("MulOp")}
      factors = @children.select{|c| c.is_rule?("Factor")}
      (0...mulops.size).each do |i|
        tn = new_temp
        code += factors[i+1].create_three_addr_code(tn)
        code << "#{t} := #{t} #{mulops[i].children[0].content.value} #{tn}"
      end
      code << "#{tempname} := #{t}"
    elsif is_rule?("MulOp")
      #code << "TODOmulop"
    elsif is_rule?("Factor")
      if @children[0].is_rule?("FunctionReference")
        code += @children[0].create_three_addr_code
      elsif @children[1] && @children[1].is_rule?("ComponentSelection")
        #resolve like componentselection first case
      elsif @children[1] && @children[1].is_rule?("Factor")
        t = new_temp
        code += @children[1].create_three_addr_code(t)
        code << "#{tempname} := not #{t}"
      elsif @children[1] && @children[1].is_rule?("Expression")
        code += @children[1].create_three_addr_code(tempname)
      end
    elsif is_rule?("FunctionReference")
      code += @children[2].create_three_addr_code
      code << "call #{@children[0].content.value}"
    elsif is_rule?("ComponentSelection")
      if !@children.size == 0
        if @children[0].content.value == "."
          if @children.size == 3
            t = new_temp
            code += @children[2].create_three_addr_code(t)
            code << "#{tempname}.#{t}"
          else
            code << "#{tempname}.#{@children[1].content.value}"
          end
        else
          t1 = nil
          if @children.size == 4 #borkborkbork todo
            t1 = new_temp
            code += @children[3].create_three_addr_code(t1)
          end
          t = new_temp
          code += @children[1].create_three_addr_code(t)
          if t1
            code << "#{tempname} := #{t}[#{t1}]"
          else
            code << "#{tempname} := #{t}"
          end
        end
      end
    elsif is_rule?("ActualParameterList")
      @children.select{|c| c.is_rule?("Expression")}.each do |r|
        t = new_temp
        code += r.create_three_addr_code(t) #pass in a new temp to save expr into
        code << "param #{t}"
      end
    elsif is_rule?("IdentifierList")
      #code << "TODOidentlist"
    elsif is_rule?("Sign")
      #code << "TODOsign"
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
