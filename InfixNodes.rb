
# Iterates over the constraints network, validates the node constructions
# and generates the postfix code
class Iterator
  attr_accessor :functions, :datatypes, :stack, :stacktop
  def initialize
    @functions = {}
    @datatypes = []
    @stack = []
    @stacktop = 0
  end

  def pushScope
    @stack.unshift({})
  end

  def popScope
    @stack.shift
  end

  def pushOperand
    @stacktop += 1
  end

  def popOperands(elements=1)
    @stacktop -= elements
  end

  def pushVariable(name, operand)
    @stack.first[name] = [operand, @stacktop]
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
    rl = @stack.select{|h| h.has_key?(name)}
    if rl.empty?
      return [nil, nil]
    end
    datatype, i = rl.first[name]
    [datatype, @stacktop - i]
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
      iter.pushVariable(@variable, e)
    end
  end

  class Plus
    def initialize(lh, rh)
      @lh = lh
      @rh = rh
    end

    def parse(iter)
      rhdatatype = @lh.parse(iter)
      lhdatatype = @rh.parse(iter)
      returndatatype = iter.findFunctionIdentifier("+", [rhdatatype, lhdatatype])
      if not returndatatype
        raise "Undefined function: +(#{rhdatatype}, #{lhdatatype})"
      end
      iter.popOperands(1)
      returndatatype
    end
  end

  class PushVariable
    def initialize(name)
      @name = name
    end

    def parse(iter)
      datatype, index = iter.getVariable(@name)

      if not datatype
        raise "Undefined variable: #{@name}"
      end
      iter.pushOperand
      datatype
    end
  end

  class Integer
    def initialize(value)
      @value = value
    end

    def parse(iter)
      iter.pushOperand
      "integer"
    end
  end
end

i = Iterator.new
i.newDatatype("integer")
i.newFunctionIdentifier("+",["integer", "integer"], "integer")
i.pushScope
i.pushVariable(:return, "integer")

sl = [
      Node::VariableDeclaration.new("integer", "a", Node::Integer.new(1)),
      Node::VariableDeclaration.new("integer", "c",
                                    Node::Plus.new(Node::Plus.new(Node::Integer.new(1),
                                                                  Node::Integer.new(2)),
                                                   Node::PushVariable.new("a")))
     ]


sl.map{|s| s.parse(i)}
i.stack
