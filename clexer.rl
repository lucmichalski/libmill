
%%{
	machine c;

	newline = '\n' @{curline += 1;};
	any_count_line = any | newline;

	# Consume a C comment.
	c_comment := any_count_line* :>> '*/' @{fgoto main;};

	main := |*

	# Alpha numberic characters or underscore.
	alnum_u = alnum | '_' | '$';

	# Alpha charactres or underscore.
	alpha_u = alpha | '_';

	# Symbols. Upon entering clear the buffer. On all transitions
	# buffer a character. Upon leaving dump the symbol.
	( punct - [_'"] ) {
		#puts "symbol(#{curline}): #{data[ts..te-1].pack("c*")}"
	};

	# Identifier. Upon entering clear the buffer. On all transitions
	# buffer a character. Upon leaving, dump the identifier.
	alpha_u alnum_u* {
        #puts "ident(#{curline}): #{data[ts..te-1].pack("c*")}"
        identifiers << [ts, te-1]
	};

	# Single Quote.
	sliteralChar = [^'\\] | newline | ( '\\' . any_count_line );
	'\'' . sliteralChar* . '\'' {
        #puts "single_lit(#{curline}): #{data[ts..te-1].pack("c*")}"
	};

	# Double Quote.
	dliteralChar = [^"\\] | newline | ( '\\' any_count_line );
	'"' . dliteralChar* . '"' {
		#puts "double_lit(#{curline}): #{data[ts..te-1].pack("c*")}"
	};

	# Whitespace is standard ws, newlines and control codes.
	any_count_line - 0x21..0x7e;

	# Describe both c style comments and c++ style comments. The
	# priority bump on tne terminator of the comments brings us
	# out of the extend* which matches everything.
	'//' [^\n]* newline;

	'/*' { fgoto c_comment; };

	# Match an integer. We don't bother clearing the buf or filling it.
	# The float machine overlaps with int and it will do it.
	digit+ {
		#puts "int(#{curline}): #{data[ts..te-1].pack("c*")}"
	};

	# Match a float. Upon entering the machine clear the buf, buffer
	# characters on every trans and dump the float upon leaving.
	digit+ '.' digit+ {
		#puts "float(#{curline}): #{data[ts..te-1].pack("c*")}"
	};

	# Match a hex. Upon entering the hex part, clear the buf, buffer characters
	# on every trans and dump the hex on leaving transitions.
	'0x' xdigit+ {
		#puts "hex(#{curline}): #{data[ts..te-1].pack("c*")}"
	};

	*|;
}%%

%% write data nofinal;

def scan(data)

    curline = 1
    data = data.unpack("c*")
    eof = data.length
    identifiers = [] 

	%% write init;
    %% write exec;

    return identifiers

end
