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
    @stack.shift
  end

  def pushOperand(item)
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

  def validateDatatype(name)
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

# Namespace for constraints network nodes to avoid conflicts
module Node
  class VariableDeclaration
    def initialize(datatype, variable, expression)
      @datatype = datatype
      @variable = variable
      @expression = expression
    end

    def parse(iter)
      e = @expression.parse(iter)
      if @datatype != e
        raise "Incompatable datatypes: #{@datatype} and #{e}"
      end

      if not iter.validateDatatype(@datatype)
        raise "Undefined datatype: #{@datatype}"
      end
      iter.bindTopToVariable(@variable)
      true
    end
  end

  class Plus
    def initialize(lh, rh)
      @lh = lh
      @rh = rh
    end

    def parse(iter)
      rhdatatype = @rh.parse(iter)
      lhdatatype = @lh.parse(iter)
      returndatatype = iter.findFunctionIdentifier("+", [rhdatatype, lhdatatype])
      if not returndatatype
        raise "Undefined function: +(#{rhdatatype}, #{lhdatatype})"
      end
      iter.popOperand
      iter.popOperand
      iter.pushOperand(Operand.new(returndatatype))
      returndatatype
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
      item.datatype
    end
  end

  class Integer
    def initialize(value)
      @value = value
    end

    def parse(iter)
      iter.pushOperand(Operand.new("integer"))
      "integer"
    end
  end
end

i = Iterator.new
i.newDatatype("integer")
i.newFunctionIdentifier("+",["integer", "integer"], "integer")
i.pushScope

sl = [
      Node::VariableDeclaration.new("integer", "a", Node::Integer.new(1)),
      Node::VariableDeclaration.new("integer", "c",
                                    Node::Plus.new(Node::Plus.new(Node::Integer.new(1),
                                                                  Node::Integer.new(2)),
                                                   Node::PushVariable.new("a")))
     ]


sl.map{|s| s.parse(i)}
i.stack

