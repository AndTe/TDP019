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
  class VariableDeclaration
    def initialize(datatype, variable, expression)
      @datatype = datatype
      @variable = variable
      @expression = expression
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
      iter.pushOperand(e)
      iter.bindTopToVariable(@variable)
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
        #iter.bindTopToVariable(arg[1])
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

      programreturn + ["pop"] * popsize
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


  class Arithmetic
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
      if not item
        raise "Undefined variable: #{@name}"
      end
      iter.pushOperand(Operand.new(item.datatype))

      [index, "duplicate"]
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
