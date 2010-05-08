require 'InfixParser.rb'
require 'PostfixParser.rb'
require 'Stack.rb'

i = Iterator.new

i.newDatatype(:void)
i.newDatatype("int")
i.newDatatype("bool")
i.newFunctionIdentifier("+",["int", "int"], "int", ["+"], true)
i.newFunctionIdentifier("-",["int", "int"], "int", ["-"], true)
i.newFunctionIdentifier("*",["int", "int"], "int", ["*"], true)
i.newFunctionIdentifier("/",["int", "int"], "int", ["/"], true)
i.newFunctionIdentifier("<",["int", "int"], "int", ["<"], true)
i.newFunctionIdentifier("<=",["int", "int"], "int", ["swap", "<", "not"], true)
i.newFunctionIdentifier("==",["int", "int"], "int", ["=="], true)
i.newFunctionIdentifier("!=",["int", "int"], "int", ["==", "not"], true)
i.newFunctionIdentifier("and",["bool", "bool"], "bool", ["and"], true)
i.newFunctionIdentifier("or",["bool", "bool"], "bool", ["or"], true)
i.newFunctionIdentifier("putchar",["int"], "int",
                        ["stacktop", "reference_value", "output"],
                        true)

cppProgram = "
int fib(int n) {
    if (n <= 1) {
        return n;
    } else {
        return (fib(n-1)+fib(n-2));
    }
}

int main() {
return fib(10);
}"

ips = InfixParseString(cppProgram)
postfixCode = labelAddressing(ips.parse(i))
pps = PostfixParseString(postfixCode)
wmStack = Stack.new
p wmStack.eat(pps)


