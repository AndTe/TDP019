class Operand
  attr_accessor :datatype, :variableName
  def initialize(datatype, variableName=nil)
    @datatype = datatype
    @variableName = variableName
  end
end

class FunctionIdentifier
  attr_accessor :id, :argumentTypes, :returnType, :functionBlock, :inline
  attr_accessor :address
  def initialize(id, argumentTypes, returnType, functionBlock, inline)
    @id = id
    @argumentTypes = argumentTypes
    @returnType = returnType
    @functionBlock = functionBlock
    @inline = inline
    args = argumentTypes.join(",")
    @address = Address.new("#{id}(#{args})")
  end
end

# Iterates over the nodes, validates the node constructions and
# generates the postfix code
class Iterator
  attr_accessor :functions, :datatypes, :stack, :returnType
  def initialize
    @functions = {}
    @datatypes = []
    @stack = []
    @globalvariables = []
    @uniqueid = 0
    @continues = []
    @breaks = []
    @returnType = nil
  end

  def pushScope
    @stack.unshift([])
  end

  def popScope
    @stack.shift.size
  end

  def pushOperand(item)
    if item.class != Operand
      raise "Can't push #{item.class}, must be an Operand"
    end

    if not validDatatype(item.datatype)
      raise "Datatype #{item.datatype} not defined"
    end
    @stack.first.unshift(item)
  end

  def popOperand
    @stack.first.shift
  end

  def bindTopToVariable(name)
    @stack.first.each {|i|
      if i.variableName == name
        raise "Variable #{name} already defined in current scope"
      end
    }
    @stack.first.first.variableName = name
  end

  def pushGlobal(item)
    @globalvariables << item
  end

  def newFunctionIdentifier(id, argumentTypes, returnType, functionBlock,
                            inline)
    at = argumentTypes.join(",")

    if @functions[[id, argumentTypes]] and
        @functions[[id, argumentTypes]].functionBlock != []
      raise "Function already defined: #{id}(#{at})"
    end

    fnLabel, fnAddress = getGotoIds("#{id}(#{at})")
    if not inline and functionBlock != []
      functionBlock.unshift(fnLabel)
    end
    @functions[[id, argumentTypes]] = FunctionIdentifier.new(id,
                                                             argumentTypes,
                                                             returnType,
                                                             functionBlock,
                                                             inline)
  end

  def newDatatype(name)
    if @datatypes.include?(name)
      raise "Datatype #{name} already defined"
    end
    @datatypes << name
  end

  def validDatatype(name)
    @datatypes.include?(name)
  end

  def findFunctionIdentifier(name, args)
    @functions[[name, args]]
  end

  def getVariable(name)
    index = nil
    flat = stack.flatten
    flat.each_index {|i|
      if flat[i].variableName == name
        index = i
      end
    }
    if not index
      nil
    else
      [flat[index], index]
    end
  end

  def getGlobalVariable(name)
    index = nil
    @globalvariables.each_index {|i|
      if @globalvariables[i].variableName == name
        index = i
      end
    }
    if not index
      nil
    else
      [@globalvariables[index], index]
    end
  end

  def getStackDepth
    @stack.flatten.size
  end

  def pushContinueAddress(address)
    @continues << [getStackDepth, address]
  end

  def pushBreakAddress(address)
    @breaks << [getStackDepth, address]
  end

  def popStackedAddresses
    @continues.pop
    @breaks.pop
  end

  def topContinueAddress
    @continues.last
  end

  def topBreakAddress
    @breaks.last
  end

  def getUniqueId
    @uniqueid += 1
  end

  def getGotoIds(id=getUniqueId)
    [Label.new(id), Address.new(id)]
  end

end

# Registers all Label locations and replaces all Address instances with
# a correct absolute address.
def labelAddressing(preprogram)
  preprogram.flatten!
  labels = {}
  addresses = {}

  i = 0
  while(i < preprogram.size)
    if preprogram[i].class == Label
      labels[preprogram.delete_at(i).id] = i
      next
    elsif preprogram[i].class == Address
      if addresses.has_key?(preprogram[i].id)
        addresses[preprogram[i].id] << i
      else
        addresses[preprogram[i].id] = [i]
      end
    end
    i += 1
  end

  addresses.each_pair{|key, value|
    value.each{|i|
      if preprogram[i]
        preprogram[i] = labels[key]
      else
        raise "Label #{i} is missing"
      end
    }
  }
  preprogram.join(" ")
end

# Label is a marker placed within a postfix code, used inconjunction
# with Address.
class Label
  attr_accessor :id
  def initialize(id)
    @id = id
  end
end

# Address is a place holder for addresses, used inconjunction with
# Label.
class Address
  attr_accessor :id
  def initialize(id)
    @id = id
  end
end

# Namespace for nodes to avoid conflicts
module Node
  # Program is the root node, it's make sure the program jumps to the
  # main function.
  class Program
    def initialize(globals)
      @globals = globals
    end

    def parse(iter)
      programreturn = [0, Address.new(:endprogram), Address.new("main()"),
                       "goto", @globals.map{|s| s.parse(iter)},
                       Label.new(:endprogram), "exit"]
      iter.functions.each_value{|fid|
        if not fid.inline
          programreturn << fid.functionBlock
        end
      }
      programreturn
    end
  end

  # VariableDeclaration generates code that places the expression
  # result on the stack and associate it with a variable name.
  class VariableDeclaration
    def initialize(datatype, variable, expression, local)
      @datatype = datatype
      @variable = variable
      @expression = expression
      @local = local
    end

    def parse(iter)
      ep = @expression.parse(iter)
      e = iter.popOperand

      if not iter.validDatatype(@datatype)
        raise "Undefined datatype: #{@datatype}"
      end

      if @datatype != e.datatype
        raise "Incompatable datatypes: #{@datatype} and #{e.datatype}"
      end

      if @local
        iter.pushOperand(e)
        iter.bindTopToVariable(@variable)
      else
        iter.pushGlobal(e)
      end
      ep
    end
  end

  # FunctionDeclaration associate the function code with the function
  # identifier. The generated function code expects that the arguments
  # is located on the top of the stack, with a reserved slot for
  # return value and a return address.
  class FunctionDeclaration
    def initialize(id, returntype, argumentlist, block)
      @id = id
      @returntype = returntype
      @argumentlist = argumentlist
      @block = block
    end

    def parse(iter)
      iter.returnType = @returntype
      typelist = @argumentlist.map{|arg| arg[0]}
      typeliststring = typelist.join(" ")

      if @id != "main"
        label = Label.new("#{@id}(#{typeliststring})")
      else
        if @argumentlist.size != 0
          raise "Main function argument list should be empty"
        end
        label = Label.new(:main)
      end

      iter.newFunctionIdentifier(@id, typelist, @returntype, [], false) #

      iter.pushScope
      @argumentlist.map{|arg|
        iter.pushOperand Operand.new(arg[0], arg[1])
      }

      iter.pushOperand Operand.new(@returntype, :returnValue)
      iter.pushOperand Operand.new("int", :returnAddress)

      programreturn = @block.parse(iter)

      iter.popScope

      iter.newFunctionIdentifier(@id, typelist, @returntype, programreturn,
                                 false) #
      iter.returnType = nil
      []
    end
  end

  # Block creates a new local scope in the stack, making it possible
  # to override a variable. At the end of the scope it removes the
  # variables declared in the scope.
  class Block
    def initialize(statementlist)
      @statementlist = statementlist
    end

    def parse(iter)
      iter.pushScope
      programreturn = @statementlist.parse(iter)

      popsize = iter.popScope

      programreturn + [popsize, "pop"]
    end

  end

  class StatementList
    def initialize(list)
      @list = list
    end

    def parse(iter)
      @list.map{|s| s.parse(iter)}
    end
  end

  # IfStatement generates code jumping to truebrach or falsebranch.
  class IfStatement
    def initialize(expression, truebranch, falsebranch=nil)
      @expression = expression
      @truebranch = truebranch
      @falsebranch = falsebranch
    end

    def parse(iter)
      falseLabel, falseAddress = iter.getGotoIds
      endLabel, endAddress = iter.getGotoIds

      iter.pushOperand(Operand.new("int")) # push false address to stack
      programreturn = [falseAddress]       #
      programreturn << @expression.parse(iter)
      programreturn << "if"
      iter.popOperand
      iter.popOperand
      programreturn << @truebranch.parse(iter)
      iter.pushOperand(Operand.new("int")) # push end address to stack
      programreturn << endAddress          #
      programreturn << "goto"
      iter.popOperand
      programreturn << falseLabel
      if @falsebranch
        programreturn << @falsebranch.parse(iter)
      end
      programreturn << endLabel
      programreturn
    end
  end

  # WhileStatement generates code that corresponds to a while-loop.
  class WhileStatement
    def initialize(expression, statement)
      @expression = expression
      @statement = statement
    end

    def parse(iter)
      startLabel, startAddress = iter.getGotoIds
      endLabel, endAddress = iter.getGotoIds

      iter.pushContinueAddress(startAddress)
      iter.pushBreakAddress(endAddress)

      programreturn = [startLabel]
      iter.pushOperand(Operand.new("int")) # push end address to stack
      programreturn << endAddress          #
      programreturn << @expression.parse(iter)
      programreturn << "if"
      iter.popOperand
      iter.popOperand
      programreturn << @statement.parse(iter)
      iter.pushOperand(Operand.new("int")) # push start address to stack
      programreturn << startAddress        #
      programreturn << "goto"
      iter.popOperand
      programreturn << endLabel
      iter.popStackedAddresses
      programreturn
    end
  end

  # WhileStatement generates code that corresponds to a for-loop.
  class ForStatement
    def initialize(declaration, continueexpr, iterationexpr, statement)
      @declaration = declaration
      @continueexpr = continueexpr
      @iterationexpr = iterationexpr
      @statement = statement
    end

    def parse(iter)
      startLabel, startAddress = iter.getGotoIds
      endLabel, endAddress = iter.getGotoIds
      continueLabel, continueAddress = iter.getGotoIds
      breakLabel, breakAddress = iter.getGotoIds

      programreturn = []
      iter.pushScope
      iter.pushBreakAddress(breakAddress)
      if @declaration
        programreturn << @declaration.parse(iter)
      end

      iter.pushContinueAddress(continueAddress)

      programreturn << startLabel
      iter.pushOperand(Operand.new("int")) # push end address to stack
      programreturn << endAddress          #
      if @continueexpr
        programreturn << @continueexpr.parse(iter)
      else
        programreturn << "true"
      end
      programreturn << "if"
      iter.popOperand
      iter.popOperand
      programreturn << @statement.parse(iter)

      programreturn << continueLabel
      if @iterationexpr
        programreturn << @iterationexpr.parse(iter)
      end
      iter.pushOperand(Operand.new("int")) # push start address to stack
      programreturn << startAddress        #
      programreturn << "goto"
      iter.popOperand
      popdepth = iter.popScope
      programreturn << endLabel
      programreturn << popdepth
      programreturn << "pop"
      programreturn << breakLabel
      iter.popStackedAddresses
      programreturn
    end
  end

  # Generates code that stores expression result to the reserved
  # return value slot, removes all variables in the function scope and
  # consume the return address on the stack.
  class Return
    def initialize(expression)
      @expression = expression
    end

    def parse(iter)
      # args, ret_val, ret_addr
      depth = iter.getStackDepth - 2
      operand, rindex = iter.getVariable(:returnValue)

      iter.pushOperand Operand.new("int")
      e = @expression.parse(iter)
      item = iter.popOperand
      if item.datatype != iter.returnType
        raise "Missmatched return type expected \"#{iter.returnType}\", " +
          "was \"#{item.datatype}\""
      end

      ["stacktop", rindex, "-", e, "assign_to_reference", rindex - 1, "pop",
       "goto"]
      # args, ret_val
    end
  end

  # Removes all declared variables sinse the loopstart, then jumps to
  # the end of the loop.
  class Continue
    def initialize()
    end

    def parse(iter)
      previousDepth, address = iter.topContinueAddress
      [iter.getStackDepth - previousDepth, "pop", address, "goto"]
    end
  end

  # Generates code that removes all declared variables sinse the
  # loopstart, then exiting the loop.
  class Break
    def initialize()
    end

    def parse(iter)
      previousDepth, address = iter.topBreakAddress
      [iter.getStackDepth - previousDepth, "pop", address, "goto"]
    end
  end

  # Generates code that removes the value that an expression leaves on
  # the stack.
  class ExpressionStatement
    def initialize(ae)
      @ae = ae
    end

    def parse(iter)
      programreturn = [@ae.parse(iter)]
      iter.popOperand
      programreturn << 1 << "pop"
      programreturn
    end
  end

  # Generates code for assigning a value to a variable and leaves a
  # copy of the value on the stack.
  class AssignExpression
    def initialize(variableId, rh)
      @variableId = variableId
      @rh = rh
    end

    def parse(iter)

      rh = @rh.parse(iter)
      programreturn = [rh]

      item, index = iter.getVariable(@variableId)
      if not item
        raise "Undefined variable: #{@variableId}"
      end

      programreturn << "stacktop" << index << "-"
      programreturn << "stacktop" << 1 << "-" << "reference_value"
      programreturn << "assign_to_reference"
      programreturn

    end
  end

  # FunctionCall generate code that places the arguments results on the stack.
  # If the function is a non-inline function its also reserves a slot for the
  # return value and the return address, then jumps to the function code. When
  # returning from the function, FunctionCall expects the return address is
  # consumed and that the return value is stored in reserved slot, removes
  # arguments results and places the return value on top.
  # If the function is a inline it paste the function code after the arguments
  # code and expects that the function code removes the arguments results and
  # leaves a result on the stack.
  class FunctionCall
    def initialize(id, argumentNodes)
      @id = id
      @argumentNodes = argumentNodes
    end

    def parse(iter)
      programlist = @argumentNodes.map{|n|
        n.parse(iter)
      }
      #[args1..argsN]

      #get the operand types from the iterator stack
      operands = []
      1.upto(@argumentNodes.size) {
        operands << iter.popOperand
      }

      datatypes = operands.reverse.map{|o|
        o.datatype
      }

      functionId = iter.findFunctionIdentifier(@id, datatypes)

      typeList = datatypes.join(",")

      if not functionId
        raise "FunctionId not declared: #{@id}(#{typeList})"
      end
      #[args1..argsN]
      if functionId.inline
        programlist << [functionId.functionBlock]
        #[ret_val]
      else
        returnValue = Operand.new("void") #reserve return value slot

        iter.pushOperand(returnValue)
        iter.pushOperand(Operand.new("int"))  #return address

        fnAddress = functionId.address
        returnLabel, returnAddress = iter.getGotoIds


        if @argumentNodes.size == 0
          #[ret_val, ret_add fn_add]
          programlist << [0, returnAddress, fnAddress, "goto", returnLabel]
        else

          programlist << [0, returnAddress, fnAddress, "goto"]
          #[args,  ret_val, ret_add]

          #[arg1, arg2, ret_val] =>           #[ret_val, arg2]
          programlist << [returnLabel,
                          "stacktop", @argumentNodes.size, "-", "swap",
                          "assign_to_reference", @argumentNodes.size - 1, "pop"]
        end
        iter.popOperand
        iter.popOperand
      end


      iter.pushOperand(Operand.new(functionId.returnType))
      programlist
    end
  end

  # Generates code that copyes variable value to the top of the stack.
  class PushVariable
    def initialize(name)
      @name = name
    end

    def parse(iter)
      item, index = iter.getVariable(@name)
      if item
        iter.pushOperand(Operand.new(item.datatype))
        ["stacktop", index, "-", "reference_value"]
      else
        item, index = iter.getGlobalVariable(@name)

        if item
          iter.pushOperand(Operand.new(item.datatype))
          [index, "reference_value"]
        else
          raise "Undefined variable: #{@name}"
        end
      end
    end
  end

  # Integer generates code that leaves an integer value on the stack.
  class Integer
    def initialize(value)
      @value = value
    end

    def parse(iter)
      iter.pushOperand(Operand.new("int"))
      @value
    end
  end

  # Boolean generates code that leaves a boolean value on the stack.
  class Boolean
    def initialize(value)
      @value = value
    end

    def parse(iter)
      iter.pushOperand(Operand.new("bool"))
      if(@value)
        "true"
      else
        "false"
      end
    end
  end

  # Void generates code that leaves a value on the stack. (It only
  # used when a function returns a void, to solve a special case of
  # "return;")
  class Void
    def parse(iter)
      iter.pushOperand(Operand.new("void"))
      0
    end
  end
end
