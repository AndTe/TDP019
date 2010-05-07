require 'InfixParser.rb'
require 'PostfixParser.rb'
require 'Stack.rb'

i = Iterator.new

i.newDatatype(:void)
i.newDatatype("int")
i.newDatatype("bool")
i.newFunctionIdentifier("+",["int", "int"], "int", ["+"], [])
i.newFunctionIdentifier("-",["int", "int"], "int", ["-"], [])
i.newFunctionIdentifier("*",["int", "int"], "int", ["*"], [])
i.newFunctionIdentifier("/",["int", "int"], "int", ["/"], [])

i.newFunctionIdentifier("putchar",["int"], "int",
                        [],
                        #[:retAddress, :fnAddress, "goto", :retLabel],
                        ["stacktop", 2, "-", "stacktop", 1, "-", "reference_value", "stacktop", "reference_value", "output", "assign_to_reference", 1, "pop","goto"])

#ret_val ret_add arg

#args ret_add

=begin
i.newFunctionIdentifier("and",["bool", "bool"], "bool")
i.newFunctionIdentifier("or",["bool", "bool"], "bool")
i.newFunctionIdentifier("xor",["bool", "bool"], "bool")
i.newFunctionIdentifier("not",["bool"], "bool")

i.newFunctionIdentifier("<",["int", "int"], "int")

i.newFunctionIdentifier("<=",["int", "int"], "int")

i.newFunctionIdentifier("==",["int", "int"], "int")
i.newFunctionIdentifier("==",["bool", "bool"], "bool")
#=begin
i.newFunctionIdentifier("hej2",["int"], "int")




sl =
Node::Block.new(
                Node::StatementList.new([
                                         Node::VariableDeclaration.new("int", "f", Node::Integer.new(1), true),
                                         #Node::VariableDeclaration.new("int", "a", Node::FunctionCall.new("hej2", [Node::Integer.new(9)])),
                                         Node::Return.new(Node::Integer.new(12))
                                         #Node::VariableDeclaration.new("int", "c",
                                         #                              Node::Arithmetic.new(Node::Arithmetic.new(Node::Integer.new(1),
                                         #                                                                        Node::Integer.new(2),
                                         #                                                                        "*"),
                                         #                                                   Node::PushVariable.new("a"),
                                         #                                                   "+"))
                                        ]))
fn = Node::FunctionDeclaration.new("hej", "int", [["int", "a"]], sl)


#program = [Label.new("hej2(int) int"), Address.new("hej(int) int"), "goto", 0] + fn.parse(i)
program =  fn.parse(i)
i.stack
labelAddressing(program)


=end

#z = InfixParseString("int main(){ int a = 222; a = a + a + 1; return a;}")
lala = "

int main(){
int g = 2;
int a = g*2;
return a;
}"

z = InfixParseString(lala)

pkod = z.parse(i)
pkod2 = labelAddressing(pkod.flatten)
p = PostfixParseString(pkod2)
s = Stack.new
ar = pkod2.split(" ")
ar.each_index{|e| puts "#{e}\t#{ar[e]}"}
p s.eat(p)



#ret_ad: arg1 arg2
#ret_val ret_ad: arg1 arg2
#          999 500 2 + stacktop 1 - stacktop 1 - reference_value stacktop 3 - reference_value + 2 + assign_to_reference

#28 3 goto 999 500 2 + stacktop 1 - stacktop 1 - reference_value stacktop 3 - reference_value + 2 + assign_to_reference 1 pop swap goto 3 pop exit"

