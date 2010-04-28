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

def labelAdressing(preprogram)
  labels = {}
  adresses = {}
  preprogram.each_index{|i|
    if preprogram[i].class == Label
      labels[preprogram.delete_at(i).id] = i
    elsif preprogram[i].class == Adress
      if adresses.has_key?(preprogram[i].id)
        adresses[preprogram[i].id] << i
      else
        adresses[preprogram[i].id] = [i]
      end
    end
  }

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

      if not iter.validateDatatype(@datatype)
        raise "Undefined datatype: #{@datatype}"
      end
      iter.pushOperand(e)
      iter.bindTopToVariable(@variable)
      ep
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

i = Iterator.new
i.newDatatype("integer")
i.newFunctionIdentifier("+",["integer", "integer"], "integer")
i.newFunctionIdentifier("-",["integer", "integer"], "integer")
i.newFunctionIdentifier("*",["integer", "integer"], "integer")
i.newFunctionIdentifier("/",["integer", "integer"], "integer")

i.pushScope
#i.pushOperand(Operand.new("integer", :return))

sl = [
      Node::VariableDeclaration.new("integer", "f", Node::Integer.new(1)),
      Node::VariableDeclaration.new("integer", "a", Node::Integer.new(1)),
      Node::VariableDeclaration.new("integer", "c",
                                    Node::Arithmetic.new(Node::Arithmetic.new(Node::Integer.new(1),
                                                                              Node::Integer.new(2),
                                                                              "*"),
                                                         Node::PushVariable.new("a"),
                                                         "+"))
     ]


program = sl.map{|s| s.parse(i)}
i.stack
program.flatten



a= [0,1,2,3, Label.new("hej"),4,5,Label.new("hej2"),6,8,Adress.new("hej"), :goto, Adress.new("hej2")]
labelAdressing(a)
