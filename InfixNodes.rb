class Operand
  attr_accessor :datatype, :variableName
  def initialize(datatype, variableName=nil)
    @datatype = datatype
    @variableName = variableName
  end
end

# Iterates over the constraints network, validates the node constructions
# and generates the postfix code
class Iterator
  attr_accessor :functions, :datatypes, :stack
  def initialize
    @functions = {}
    @datatypes = []
    @stack = []
    @globalvariables = []
    @uniqueid = 0
    @continues = []
    @breaks = []
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
      raise "Datatype #{item} not defined"
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

  def newFunctionIdentifier(name, args, outdatatype)
    @functions[[name, args]] = outdatatype
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

  def pushContinueAdress(adress)
    @continues << [getStackDepth, adress]
  end

  def pushBreakAdress(adress)
    @breaks << [getStackDepth, adress]
  end

  def popStackedAdresses
    @continues.pop
    @breaks.pop
  end

  def topContinueAdress
    @continues.last
  end

  def topBreakAdress
    @breaks.last
  end

  def getUniqueId
    @uniqueid += 1
  end

  def getGotoIds
    id = getUniqueId
    [Label.new(id), Adress.new(id)]
  end
end



def labelAdressing(preprogram)
  preprogram.flatten!
  labels = {}
  adresses = {}

  i = 0
  while(i < preprogram.size)
    if preprogram[i].class == Label
      labels[preprogram.delete_at(i).id] = i
      next
    elsif preprogram[i].class == Adress
      if adresses.has_key?(preprogram[i].id)
        adresses[preprogram[i].id] << i
      else
        adresses[preprogram[i].id] = [i]
      end
    end
    i += 1
  end

  adresses.each_pair{|key, value|
    value.each{|i|
      preprogram[i]= labels[key]
    }
  }

  preprogram.join(" ")
end

class Label
  attr_accessor :id
  def initialize(id)
    @id = id
  end
end

class Adress
  attr_accessor :id
  def initialize(id)
    @id = id
  end
end

# Namespace for constraints network nodes to avoid conflicts
module Node
  class Program
    def initialize(globals)
      @globals = globals
    end

    def parse(iter)
      [Adress(:main), "goto", @globals.map{|s| s.parse(iter)}]
    end
  end

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
      if @datatype != e.datatype
        raise "Incompatable datatypes: #{@datatype} and #{e.datatype}"
      end

      if not iter.validDatatype(@datatype)
        raise "Undefined datatype: #{@datatype}"
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

  class FunctionDeclaration
    def initialize(id, returntype, argumentlist, block)
      @id = id
      @returntype = returntype
      @argumentlist = argumentlist
      @block = block
    end

    def parse(iter)
      typelist = @argumentlist.map{|arg| arg[0]}
      typeliststring = typelist.join(" ")

      if @if != "main"
        label = Label.new("#{@id}(#{typeliststring}) #{@returntype}")
      else
        label = Label.new(:main)
      end
      iter.pushScope
      iter.pushOperand Operand.new("integer", :return)

      @argumentlist.map{|arg|
        iter.pushOperand Operand.new(arg[0], arg[1])
      }
      programreturn = @block.parse(iter)

      iter.popScope
      iter.newFunctionIdentifier(@id, typelist, @returntype)
      [label, programreturn]
    end
  end

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

  class IfStatment
    def initialize(expression, truebranch, falsebranch=nil)
      @expression = expression
      @truebranch = truebranch
      @falsebranch = falsebranch
    end

    def parse(iter)
      falseLabel, falseAdress = iter.getGotoIds
      endLabel, endAdress = iter.getGotoIds

      programreturn = [falseAdress]
      programreturn << @expression.parse(iter)
      programreturn << "if"
      programreturn << @truebranch.parse(iter)
      programreturn << endAdress
      programreturn << "goto"
      programreturn << falseLabel
      if @falsebranch
        programreturn << @falsebranch.parse(iter)
      end
      programreturn << endLabel
      programreturn
    end
  end

  class WhileStatement
    def initialize(expression, statement)
      @expression = expression
      @statement = statement
    end

    def parse(iter)
      startLabel, startAdress = iter.getGotoIds
      endLabel, endAdress = iter.getGotoIds

      iter.addContinueAdress(startAdress)
      iter.addBreakAdress(endAdress)

      programreturn = [startLabel]
      programreturn << endAdress
      programreturn << @expression.parse(iter)
      programreturn << "if"
      programreturn << @startLabel
      programreturn << @statement.parse(iter)
      programreturn << startAdress
      programreturn << "goto"
      programreturn << endLabel
      programreturn
      iter.popStackedAdresses
    end
  end

  class ForStatement
    def initialize(declaration=nil, continueexpr=nil, iterationexpr=nil, statement)
      @declaration = declaration
      @continueexpr = continueexpr
      @iterationexpr = iterationexpr
      @statement = statement
    end

    def parse(iter)
      startLabel, startAdress = iter.getGotoIds
      endLabel, endAdress = iter.getGotoIds
      continueLabel, continueAdress = iter.getGotoIds
      breakLabel, breakAdress = iter.getGotoIds

      iter.addBreakAdress(breakAdress)

      programreturn = []
      iter.pushScope
      if @declaration
        programreturn << @declaration.parse(iter)
      end

      iter.addContinueAdress(continueAdress)

      programreturn << startLabel
      programreturn << endAdress
      if @continueexpr
        programreturn << @continueexpr.parse(iter)
      else
        programreturn << "true"
      end
      programreturn << "if"
      programreturn << @statement.parse(iter)

      programreturn << continueLabel
      if @iterationexpr
        programreturn << @iterationexpr.parse(iter)
      end
      programreturn << startAdress
      programreturn << "goto"
      popdepth = iter.popScope

      programreturn << popdepth
      programreturn << "pop"
      programreturn << breakLabel
      iter.popStackedAdresses
    end
  end

  class Return
    def initialize(expression)
      @expression = expression
    end

    def parse(iter)
      depth = iter.getStackDepth
      if depth < 2
        programreturn = @expression.parse(iter)
        programreturn << "swap" << "goto"
      else
        operand, rindex = iter.getVariable(:return)
        rindex -= 1
        programreturn = ["stacktop", rindex, "-"]
        programreturn << @expression.parse(iter)
        programreturn << "assign_to_reference"
        programreturn << (depth - 2)
        programreturn << "pop"
        programreturn << "swap"
        programreturn << "goto"
      end

      programreturn
    end
  end

  class Continue
    def initialize()
    end

    def parse(iter)
      previousDepth, adress = iter.topContinueAdress
      [iter.getStackDepth - previousDepth, adress, "goto"]
    end
  end

  class Break
    def initialize()
    end

    def parse(iter)
      previousDepth, adress = iter.topBreakAdress
      [iter.getStackDepth - previousDepth, adress, "goto"]
    end
  end

  class SimpleExpression
    def initialize(lh, rh, operator)
      @lh = lh
      @rh = rh
      @operator = operator
    end

    def parse(iter)
      lh = @lh.parse(iter)
      rh = @rh.parse(iter)

      rhdatatype = iter.popOperand.datatype
      lhdatatype = iter.popOperand.datatype

      returndatatype = iter.findFunctionIdentifier(@operator, [rhdatatype, lhdatatype])
      if not returndatatype
        raise "Undefined function: #{@operator}(#{rhdatatype}, #{lhdatatype})"
      end
      iter.pushOperand(Operand.new(returndatatype))
      [lh, rh, @operator]
    end
  end

  class LessEquals
    def initialize(lh, rh, operator)
      @lh = lh
      @rh = rh
      @operator = operator
    end

    def parse(iter)
      rh = @rh.parse(iter)
      lh = @lh.parse(iter)

      rhdatatype = iter.popOperand.datatype
      lhdatatype = iter.popOperand.datatype

      returndatatype = iter.findFunctionIdentifier(@operator, [rhdatatype, lhdatatype])
      if not returndatatype
        raise "Undefined function: #{@operator}(#{rhdatatype}, #{lhdatatype})"
      end
      iter.pushOperand(Operand.new(returndatatype))
      [rh, lh, "<", "not"]
    end
  end

  class LogicalNot
    def initialize(expression)
      @expression = expression
    end

    def parse(iter)
      programreturn = @expression.parse(iter)

      returndatatype = iter.findFunctionIdentifier("not", ["bool"])
      if not returndatatype
        raise "Undefined function: not(#{returndatatype})"
      end

      iter.pushOperand(Operand.new(returndatatype))
      [programreturn, "not"]
    end
  end

  class LogicalXor
    def initialize(lh, rh, operator)
      @lh = lh
      @rh = rh
      @operator = operator
    end

    def parse(iter)
      lh = @lh.parse(iter)
      rh = @rh.parse(iter)

      rhdatatype = iter.popOperand.datatype
      lhdatatype = iter.popOperand.datatype

      returndatatype = iter.findFunctionIdentifier(@operator, [rhdatatype, lhdatatype])
      if not returndatatype
        raise "Undefined function: #{@operator}(#{rhdatatype}, #{lhdatatype})"
      end
      iter.pushOperand(Operand.new(returndatatype))

      [0, lh, rh, "topstack", 2, "-",
       "topstack", 2, "-", "reference_value",
       "topstack", 2, "-", "reference_value", "or",
       "assign_reference_value", "and", "not", "and"]
    end
  end

  class FunctionCall
    def initialize(id, nodelist)
      @id = id
      @nodelist = nodelist
    end

    def parse(iter)
      programlist = @nodelist.map{|n|
        n.parse(iter)
      }

      numargs = programlist.size
      operandlist = []
      1.upto(numargs) {
        operandlist << iter.popOperand
      }
      datatypelist = operandlist.reverse.map{|o|
        o.datatype
      }

      returntype = iter.findFunctionIdentifier(@id, datatypelist)

      datatypeliststring = datatypelist.join(" ")

      adress = Adress.new("#{@id}(#{datatypeliststring}) #{returntype}")

      returnlabel = Label.new(adress)


      returnadress = Adress.new(adress)
      iter.pushOperand Operand.new(returntype)
      [returnadress, programlist, adress, "goto", returnlabel]
    end
  end

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

  class Integer
    def initialize(value)
      @value = value
    end

    def parse(iter)
      iter.pushOperand(Operand.new("integer"))
      @value
    end
  end
end
