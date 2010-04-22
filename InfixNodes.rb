class StackItem
  attr_accessor :datatype, :variableName
  def initialize(datatype, variableName=nil)
    @datatype = datatype
    @variableName = variableName
  end
end

class FunctionIdentifier
  attr_accessor :name, :args, :return
  def initialize(name, args, ret)
    @name = name
    @args = args
    @return = ret
  end
end

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

  def pushStackItem(item)
    @stack.first.unshift(item)
  end

  def popStackItem
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

  def newFunction(name, args, outdatatype)
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

  def findFunction(name, args)
    @functions[[name, args]]
  end

  def findVariable(name)
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
      returndatatype = iter.findFunction("+", [rhdatatype, lhdatatype])
      if not returndatatype
        raise "Undefined function: +(#{rhdatatype}, #{lhdatatype})"
      end
      iter.popStackItem
      iter.popStackItem
      iter.pushStackItem(StackItem.new(returndatatype))
      returndatatype
    end
  end

  class PushVariable
    def initialize(name)
      @name = name
    end

    def parse(iter)
      item, index = iter.findVariable(@name)

      if not item
        raise "Undefined variable: #{@name}"
      end
      iter.pushStackItem(StackItem.new(item.datatype))
      item.datatype
    end
  end

  class Integer
    def initialize(value)
      @value = value
    end

    def parse(iter)
      iter.pushStackItem(StackItem.new("integer"))
      "integer"
    end
  end
end

i = Iterator.new
i.newDatatype("integer")
i.newFunction("+",["integer", "integer"], "integer")
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
