require 'InfixParser.rb'
require 'PostfixParser.rb'
require 'Stack.rb'

i = Iterator.new

i.newDatatype("void")
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
void putdigit(int digit) {
  putchar('0' + digit);
  return;
}

void put_re(int number) {
  if (number == 0) {
    return;
  }
  int mult = number / 10;
  int rest = number - mult * 10;
  put_re(mult);
  putdigit(rest);
  return;
}

void put(int number) {
  if(number == 0) {
    putdigit(0);
    return;
  }
  put_re(number);
  return;
}

void put(bool b) {
  if(b)
    putchar('T');
  else
    putchar('F');
  return;
}

int main() {
  put(0);
  putchar('\\n');
  put(100);
  putchar('\\n');
  put(false);
  putchar('\\n');
  put(true);
  return 0;
}"

ips = InfixParseString(cppProgram)
postfixCode = labelAddressing(ips.parse(i))
pps = PostfixParseString(postfixCode)
wmStack = Stack.new
p wmStack.eat(pps)
