require 'rdparse.rb'
require 'InfixNodes.rb'

class InfixParser
  def initialize
    @InfixParser = Parser.new("infix parser") do
      token(/\d+/) {|m| m.to_i}
      token(/\s+/)
      token(/;/) {:stmt_end}
      token(/<=/) {|m| m}
      token(/>=/) {|m| m}
      token(/\=\=/) {|m| m}
      token(/!\=/) {|m| m}
      token(/[\(\)\{\}]/) {|m| m}
      token(/\=/) {|m| m}
      token(/[\+\-\*\/]/){|m| m}

      token(/</) {|m| m}
      token(/>/) {|m| m}
      token(/\w+/) {|m| puts m; m}


      start :program do
        match(:global_declaration_list) {|m| Node::Program.new(m)}
      end

      rule :global_declaration_list do
        match(:global_declaration, :global_declaration_list) {|a, b| [a] + b}
        match(:global_declaration) {|m| [m]}
      end

      rule :global_declaration do
        match(:global_variable_declaration) {|m| m}
        match(:function_declaration) {|m| m}
      end

      rule :function_declaration do
        match(:datatype, :function_identifier, "(", :argument_list, ")", :block) {|ret, id, _, arg , _, block| Node::FunctionDeclaration.new(id, ret, arg, block)}
      end

      rule :argument_list do
        match(:argument, ",", :argument_list) {|a, _, b| [a] + b}
        match(:argument) {|m| [m]}
        match() {[]}
      end

      rule :argument do
        match(:datatype, :variable) {|d, v| [d,v]}
      end

      rule :block do
        match("{", :statement_list, "}" ) {|_, sl, _| Node::Block.new(Node::StatementList.new(sl))}
      end

      rule :statement_list do
        match(:statement, :statement_list) {|a, b| [a] + b}
        match(:statement) {|m| [m]}
      end

      rule :statement do
        match(:variable_declaration, :stmt_end) {|a, b| a}
        match(:assignment_statement, :stmt_end) {|a, b| a}
        match(:return, :stmt_end) {|r, _| r}
        match(:block) {|m| m}
      end

      rule :return do
        match("return", :expression) {|_, e| Node::Return.new(e)}
        #match("return")
      end


      rule :variable_declaration do
        match(:datatype, :variable, "=", :expression) {|t, v, _, e| Node::VariableDeclaration.new(t,v,e, true)}
      end

      rule :assignment_statement do
        match(:assignment_expr) {|a| "[assignment #{a}]"}
      end

      rule :assignment_expr do
        match(:variable, "=", :expression){|lh, _, rh| raise "ops"}
      end

      rule :function_identifier do
        match(:identifier) {|m| m}
      end

      rule :datatype do
        match(:identifier) {|m| m}
      end

      rule :variable do
        match(:identifier) {|m| m}
      end

      rule :expression do
        match(:or_expr) {|m| m}
      end

      rule :or_expr do
        match(:or_expr, "or", :and_expr) {|lh, _, rh| Node::SimpleExpression.new(lh, rh, "or")}
        match(:and_expr) {|m| m}
      end

      rule :and_expr do
        match(:and_expr, "and", :not_expr) {|lh, _, rh| Node::SimpleExpression.new(lh, rh, "and")}
        match(:not_expr) {|m| m}
      end

      rule :not_expr do
        match("not", :not_expr) {|_, a| Node::LogicalNot.new(a)}
        match(:comparison_expr) {|m| m}
      end

      rule :comparison_expr do
        match(:comparison_expr,"<=", :plus_expr) {|lh, _, rh| Node::LessEquals.new(lh, rh)}
        match(:comparison_expr,">=", :plus_expr) {|lh, _, rh| Node::LessEquals.new(rh, lh)}
        match(:comparison_expr,"==", :plus_expr) {|lh, _, rh| Node::SimpleExpression.new(lh, rh, "==")}
        match(:comparison_expr,"!=", :plus_expr) {|lh, _, rh| Node::LogicalNot.new(Node::SimpleExpression.new(lh, rh, "=="))}
        match(:comparison_expr,"<", :plus_expr) {|lh, _, rh| Node::SimpleExpression.new(lh, rh, "<")}
        match(:comparison_expr,">", :plus_expr) {|lh, _, rh| Node::SimpleExpression.new(rh, lh, ">")}
        match(:plus_expr) {|m| m}
      end

      rule :plus_expr do
        match(:plus_expr, "+", :multiply_expr) {|lh, _, rh| Node::SimpleExpression.new(lh, rh, "+")}
        match(:plus_expr, "-", :multiply_expr) {|lh, _, rh| Node::SimpleExpression.new(lh, rh, "-")}
        match(:multiply_expr) {|m| m}
      end

      rule :multiply_expr do
        match(:multiply_expr, "*", :expression_value){|lh, _, rh| Node::SimpleExpression.new(lh, rh, "*")}
        match(:multiply_expr, "/", :expression_value){|lh, _, rh| Node::SimpleExpression(lh, rh, "/")}
        match(:expression_value) {|m| m}
      end

      rule :expression_value do
        #match(:assignment_expr) {|m| m}
        match("(", :expression, ")") {|_, m, _| m}
        match(Fixnum)  {|m| Node::Integer.new(m)}
        match(:variable) {|m| Node::PushVariable.new(m)}
      end




      rule :identifier do
        match(/\w+/) {|m| m}
      end
    end
  end

  def parse_string(str)
    @InfixParser.parse str
  end
end

def InfixParseString(infix)
  p = InfixParser.new
  p.parse_string infix
end

def InfixParseFile(sourcefile)
  source = open(sourcefile)
  p = InfixParser.new
  p.parse_string source.read
end
