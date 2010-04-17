require 'rdparse.rb'

class InfixParser
  def initialize
    @InfixParser = Parser.new("infix parser") do
      token(/\d+/) {|m| m.to_i}
      token(/[ \t]+/)
      token(/[\r\n]+/) {:newline}
      token(/\<=/) {|m| m}
      token(/\=>/) {|m| m}
      token(/\==/) {|m| m}
      token(/\!=/) {|m| m}
      token(/</) {|m| m}
      token(/>/) {|m| m}
      token(/\w+/) {|m| m}
      token(/./) {|m| m}

      start :program do
        match(:statement_list) {|m| "{statement_list \n#{m}\n}"}
      end

      rule :statement_list do
        match(:statement, :statement_list) {|a, b| "#{a}\n#{b}"}
        match(:statement) {|m| "#{m}"}
      end

      rule :statement do
        match(:variable_declaration, :newline) {|a, b| a}
      end

      rule :variable_declaration do
        match(:datatypes, :identifier, "=", :expression) {|a, b, _, c| "[#{a}:#{b} = #{c}]"}
      end

      rule :datatypes do
        match(:identifier) {|a| a}
      end

      rule :expression do
        match(:or_expr) {|m| m}
      end

      rule :or_expr do
        match(:or_expr, "or", :and_expr) {|l, op, r| wrap(l, op, r)}
        match(:and_expr) {|m| m}
      end

      rule :and_expr do
        match(:and_expr, "and", :not_expr) {|l, op, r| wrap(l, op, r)}
        match(:not_expr) {|m| m}

      end

      rule :not_expr do
        match("not", :not_expr) {|op, a| "(#{op} #{a})"}
        match(:comparison_expr) {|m| m}
      end

      rule :comparison_expr do
        match(:comparison_expr,"<=", :plus_expr) {|l, op, r| wrap(l, op, r)}
        match(:comparison_expr,"=>", :plus_expr) {|l, op, r| wrap(l, op, r)}
        match(:comparison_expr,"==", :plus_expr) {|l, op, r| wrap(l, op, r)}
        match(:comparison_expr,"!=", :plus_expr) {|l, op, r| wrap(l, op, r)}
        match(:comparison_expr,"<", :plus_expr) {|l, op, r| wrap(l, op, r)}
        match(:comparison_expr,">", :plus_expr) {|l, op, r| wrap(l, op, r)}
        match(:plus_expr) {|m| m}
      end

      rule :plus_expr do
        match(:plus_expr, "+", :multiply_expr) {|l, op, r| wrap(l, op, r)}
        match(:plus_expr, "-", :multiply_expr) {|l, op, r| wrap(l, op, r)}
        match(:multiply_expr) {|m| m}
      end

      rule :multiply_expr do
        match(:multiply_expr, "*", :expression_value){|l, op, r| wrap(l, op, r)}
        match(:multiply_expr, "/", :expression_value){|l, op, r| wrap(l, op, r)}
        match(:expression_value) {|m| m}
      end

      rule  :expression_value do
        match("(", :expression, ")") {|_, m, _| "#{m}"}
        match(Fixnum)  {|m| m.to_s}
        match(:identifier) {|m| m}
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

def wrap(a, op, b)
  "(#{a} #{op} #{b})"
end
