require 'rdparse.rb'

class InfixParser

	def initialize
		@p = []
		@InfixParser = Parser.new("infix parser") do
		token(/\d+/) {|m| m.to_i}
		token(/\s+/) 
		token(/\<=/) {|m| m}
		token(/\=>/) {|m| m}
		token(/\==/) {|m| m}
		token(/\!=/) {|m| m}
		token(/</) {|m| m}
		token(/>/) {|m| m}
		token(/\w+/) {|m| m}
		token(/./) {|m| m}
		
=begin		
		start :program do
			match(:statement_list) {|m| m + " exit"}
		end
		
		rule :statement_list do
			match(:statement, :statement_list) {|a, b| a + " " + b}
			match(:statement) {|a| a}
		end
		
		rule :statement do
			match(:declaration) {|a| a}
			match(:plus_expr) {|a| a}
		end
		
		rule :declaration do
			match("integer", /\w+/ ,"=", :plus_expr) {|_,_,_,a| a}
		end
		

		start :comparison do
			match(:or_expr,"<=", :or_expr){|m, _, n| m<=n}
			match(:or_expr,"=>", :or_expr){|m, _, n| m=>n}
			match(:or_expr,"==", :or_expr){|m, _, n| m==n}
			match(:or_expr,"!=", :or_expr){|m, _, n| m!=n}
			match(:or_expr,"<", :or_expr){|m, _, n| m<n}
			match(:or_expr,">", :or_expr){|m, _, n| m>n}
			match(:or_expr) {|m| m}
		end
	
		rule :or_expr do
		
		end
=end

		start :plus_expr do
			match(:parenthesis){|m| m}
			match(:multiply_expr) {|m| m}
			match(:plus_expr, "+", :multiply_expr) {|a,_,b| a + " " + b +" +"}
			match(:plus_expr, "-", :multiply_expr) {|a,_,b| a + " " + b +" -"}
		end

		rule :multiply_expr do
			match(:expression_value) {|m|m}
			match(:multiply_expr, "*", :expression_value){|a,_,b| a + " " + b+ " *"}
			match(:multiply_expr, "/", :expression_value){|a,_,b| a + " " + b +" /"}
		end

		rule  :expression_value do
			match("(", :plus_expr, ")") {|_,m,_| m}
			match(Fixnum)  {|m| m.to_s}
		end
	end
end

  def parse_string(str)
    @InfixParser.parse str
  end

  #~ def log(state = false)
    #~ if state
      #~ @diceParser.logger.level = Logger::DEBUG
    #~ else
      #~ @diceParser.logger.level = Logger::WARN
    #~ end
  #~ end
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
