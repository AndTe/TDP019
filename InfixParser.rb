require 'rdparse.rb'
require 'InfixNodes.rb'

class InfixParser
  def initialize
    @InfixParser = Parser.new("infix parser") do
      token(/\d+/) {|m| m.to_i}
      token(/\s+/)
      token(/;/) {|m| m}
      token(/<=/) {|m| m}
      token(/>=/) {|m| m}
      token(/\=\=/) {|m| m}
      token(/!\=/) {|m| m}
      token(/[\(\)\{\}]/) {|m| m}
      token(/\=/) {|m| m}
      token(/[\+\-\*\/]/){|m| m}
      token(/".*?[^\\]"/) {|m| m} # matches strings
      token(/' '/) {|m| m} # matches spacecharacter
      token(/'/) {|m| m}
      token(/</) {|m| m}
      token(/>/) {|m| m}
      token(/\w+/) {|m| m}
      token(/\S{1,2}/) {|m| m}


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
        match(:datatype, :function_identifier, "(", :argument_list, ")", :block) {|ret, id, _, arg , _, block|
          Node::FunctionDeclaration.new(id, ret, arg, block)}
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
        match("break", :stmt_end) {Node::Break.new()}
        match("continue", :stmt_end) {Node::Continue.new()}
        match(:while) {|m| m}
        match(:for) {|m| m}
        match(:block) {|m| m}
        match(:if) {|m| m}
      end

      rule :stmt_end do
        match(";")
      end

      rule :return do
        match("return", :expression) {|_, e| Node::Return.new(e)}
        #match("return")
      end

      rule :while do
        match("while", "(", :expression, ")", :statement) {|_, _, e, _, s| Node::WhileStatement.new(e, s)}
      end

      rule :for do
        match("for", "(", :for_declaration, ";", :for_expression, ";", :for_assignment, ")", :statement) {|_, _, vd, _, ce, _, ie, _, s|
          Node::ForStatement.new(vd, ce, ie, s)}
      end

      rule :for_declaration do
        match(:variable_declaration) {|m| m}
        match() {false}
      end

      rule :for_expression do
        match(:expression) {|m| m}
        match() {false}
      end

      rule :for_assignment do
        match(:assignment_statement) {|m| m}
        match() {false}
      end

      rule :if do
        match("if", "(", :expression, ")", :statement, "else", :statement) {|_, _, e, _, trues, _, falses| Node::IfStatement.new(e, trues, falses)}
        match("if", "(", :expression, ")", :statement) {|_, _, e, _, s| Node::IfStatement.new(e, s, false)}
      end

      rule :variable_declaration do
        match(:datatype, :variable, "=", :expression) {|t, v, _, e| Node::VariableDeclaration.new(t,v,e, true)}
      end

      rule :assignment_statement do
        match(:assignment_expr) {|m| Node::AssignStatement.new(m)}
      end

      rule :assignment_expr do
        match(:variable, "=", :expression){|v, _, rh| Node::AssignExpression.new(v, rh)}
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
        match(:comparison_expr,">", :plus_expr) {|lh, _, rh| Node::SimpleExpression.new(rh, lh, "<")}
        match(:plus_expr) {|m| m}
      end

      rule :plus_expr do
        match(:plus_expr, "+", :multiply_expr) {|lh, _, rh| Node::SimpleExpression.new(lh, rh, "+")}
        match(:plus_expr, "-", :multiply_expr) {|lh, _, rh| Node::SimpleExpression.new(lh, rh, "-")}
        match(:multiply_expr) {|m| m}
      end

      rule :multiply_expr do
        match(:multiply_expr, "*", :expression_value){|lh, _, rh| Node::SimpleExpression.new(lh, rh, "*")}
        match(:multiply_expr, "/", :expression_value){|lh, _, rh| Node::SimpleExpression.new(lh, rh, "/")}
        match(:expression_value) {|m| m}
      end

      rule :expression_value do
        #match(:assignment_expr) {|m| m}
        match("(", :expression, ")") {|_, m, _| m}
        match("true") {Node::Boolean.new(true)}
        match("false") {Node::Boolean.new(false)}
        match(Fixnum)  {|m| Node::Integer.new(m)}
        match(:char) {|m| m}
        match(:variable) {|m| Node::PushVariable.new(m)}
      end

      rule :char do
        match("'", /\S/, "'") {|_,c ,_| Node::Integer.new(eval("?#{c}"))}
        match("' '") {Node::Integer.new(?\s)}
        match("'\\n'") {Node::Integer.new(?\n)}
        match("'\\r'") {Node::Integer.new(?\r)}
        match("'\\t'") {Node::Integer.new(?\t)}
        match("'\\0'") {Node::Integer.new(?\0)}
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
