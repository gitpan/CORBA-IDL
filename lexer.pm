#
#	Interface Definition Language (OMG IDL CORBA v3.0)
#
# 	Lexer module
#

use strict;

use Math::BigInt;
use Math::BigFloat;

sub Error {
	my $parser = shift;
	my ($msg) = @_;

	$msg ||= "Syntax error.\n";

	if (exists $parser->YYData->{nb_error}) {
		$parser->YYData->{nb_error} ++;
	} else {
		$parser->YYData->{nb_error} = 1;
	}

	unless (exists $parser->YYData->{filename}) {
		print STDOUT "#No parsed input : ",$msg;
	} else {
		print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Error: ',$msg
				if (		exists $parser->YYData->{verbose_error}
						and $parser->YYData->{verbose_error});
	}
}

sub Warning {
	my $parser = shift;
	my ($msg) = @_;

	$msg ||= ".\n";

	if (exists $parser->YYData->{nb_warning}) {
		$parser->YYData->{nb_warning} ++;
	} else {
		$parser->YYData->{nb_warning} = 1;
	}

	print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Warning: ',$msg
			if (		exists $parser->YYData->{verbose_warning}
					and $parser->YYData->{verbose_warning});
}

sub Info {
	my $parser = shift;
	my ($msg) = @_;

	$msg ||= ".\n";

	if (exists $parser->YYData->{nb_info}) {
		$parser->YYData->{nb_info} ++;
	} else {
		$parser->YYData->{nb_info} = 1;
	}

	print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Info: ',$msg
			if (		exists $parser->YYData->{verbose_info}
					and $parser->YYData->{verbose_info});
}

sub Deprecated {
	my $parser = shift;
	my ($msg) = @_;

	$msg ||= ".\n";

	if (exists $parser->YYData->{nb_deprecated}) {
		$parser->YYData->{nb_deprecated} ++;
	} else {
		$parser->YYData->{nb_deprecated} = 1;
	}

	print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Deprecated: ',$msg
			if (		exists $parser->YYData->{verbose_deprecated}
					and $parser->YYData->{verbose_deprecated});
}

sub _StringLexer {
	my $parser = shift;
	my ($token) = @_;
	my $str = '';

	while ($parser->YYData->{line}) {

		for ($parser->YYData->{line}) {

			s/^\"//
				and return ($token, $str);

			s/^([^"\\]+)//
				and $str .= $1,		# any character except single quote or backslash
				    last;

			s/^\\a//
				and $str .= "\a",	# alert
				    last;
			s/^\\b//
				and $str .= "\b",	# backspace
				    last;
			s/^\\f//
				and $str .= "\f",	# form feed
				    last;
			s/^\\n//
				and $str .= "\n",	# new line
				    last;
			s/^\\r//
				and $str .= "\r",	# carriage return
				    last;
			s/^\\t//
				and $str .= "\t",	# horizontal tab
				    last;
			s/^\\v//
				and $str .= "\013",	# vertical tab
				    last;
			s/^\\([\?'"])//
				and $str .= $1,		# backslash, question mark, single quote, double quote
				    last;

			s/^\\([0-7]{1,3})//
				and $str .= chr oct $1,
				    (oct $1) ? 1 : $parser->Error("null character in a string.\n"),
				    last;
			s/^\\x([0-9A-Fa-f]{1,2})//
				and $str .= chr hex $1,
				    (hex $1) ? 1 : $parser->Error("null character in a string.\n"),
				    last;
			if ($token eq 'WIDE_STRING_LITERAL') {
				s/^\\u([0-9A-Fa-f]{1,4})//
					and $str .= chr hex $1,
					    (hex $1) ? 1 : $parser->Error("null character in a string.\n"),
					    last;
			}
			s/^\\//
				and $parser->Error("invalid escape sequence.\n"),
					last
		}
	}

	$parser->Error("untermined string.\n");
	$parser->YYData->{lineno} ++;
	return ($token, $str);
}

sub _CharLexer {
	my $parser = shift;
	my ($token) = @_;

	$_ = $parser->YYData->{line};
	s/^([^'\\])\'//
		and return ($token, $1);		# any character except single quote or backslash

	s/^\\n\'//
		and return ($token, "\n");	# new line
	s/^\\t\'//
		and return ($token, "\t");	# horizontal tab
	s/^\\v\'//
		and return ($token, "\013");	# vertical tab
	s/^\\b\'//
		and return ($token, "\b");	# backspace
	s/^\\r\'//
		and return ($token, "\r");	# carriage return
	s/^\\f\'//
		and return ($token, "\f");	# form feed
	s/^\\a\'//
		and return ($token, "\a");	# alert
	s/^\\([\?'"])\'//
		and return ($token, $1);		# backslash, question mark, single quote, double quote
	s/^\\([0-7]{1,3})\'//
		and return ($token, chr oct $1);
	s/^\\x([0-9A-Fa-f]{1,2})\'//
		and return ($token, chr hex $1);
	if ($token eq 'WIDE_STRING_LITERAL') {
		s/^\\u([0-9A-Fa-f]{1,4})\'//
			and return ($token, chr hex $1);
	}

	s/^\\([^\s\(\)\[\]\{\}<>,;:="]*)//
		and $parser->Error("invalid escape sequence $1.\n"),
		    return ($token, ' ');

	s/^([^\s\(\)\[\]\{\}<>,;:="]*)//
		and $parser->Error("invalid character $1.\n"),
		    return ($token, ' ');

	print "INTERNAL_ERROR:_CharLexer $_\n";
	return ($token, ' ');
}

sub _Identifier {
	my $parser = shift;
	my ($ident) = @_;

	my $key = uc $ident;
	if (exists $parser->YYData->{keyword}{$key}) {
		my $keywd = $parser->YYData->{keyword}{$key}[0];
		my $version = $parser->YYData->{keyword}{$key}[1];
		if ($Parser::IDL_version ge $version) {
			if ($ident eq $keywd) {
				return ($key, $ident);
			} else {
				$parser->Error("'$ident' collides with keyword '$keywd'.\n");
				return ('IDENTIFIER', $ident);
			}
		} else {
			if ($ident eq $keywd) {
				$parser->Info("'$ident' is a future keyword.\n");
			} else {
				$parser->Info("'$ident' collides with future keyword '$keywd'.\n");
			}
			return ('IDENTIFIER', $ident);
		}
	}
	return ('IDENTIFIER', $ident);
}

sub _EscIdentifier {
	my $parser = shift;
	my ($ident) = @_;

	if ($Parser::IDL_version ge '2.3') {
		my $key = uc $ident;
		unless (exists $parser->YYData->{keyword}{$key}) {
			Info("Unnecessary escaped identifier '$ident'.\n");
		}
	} else {
		$parser->Warning("Escaped identifier is not allowed.\n");
	}
	return ('IDENTIFIER', $ident);
}

sub _OctInteger {
	my $parser = shift;
	my ($str) = @_;

	my $val = new Math::BigInt(0);
	foreach (split //, $str) {
		$val = $val * new Math::BigInt(8) + new Math::BigInt(oct $_);
	}
	return ('INTEGER_LITERAL', $val);
}

sub _HexInteger {
	my $parser = shift;
	my ($str) = @_;

	my $val = new Math::BigInt(0);
	foreach (split //, $str) {
		$val = $val * new Math::BigInt(16) + new Math::BigInt(hex $_);
	}
	return ('INTEGER_LITERAL', $val);
}

sub _CommentLexer {
	my $parser = shift;

	while (1) {
		    $parser->YYData->{line}
		or  $parser->YYData->{line} = readline $parser->YYData->{fh}
		or  return;

		for ($parser->YYData->{line}) {
			s/^\n//
					and $parser->YYData->{lineno} ++,
					last;
			s/^\*\///
					and return;
			s/^.//
					and last;
		}
	}
}

sub _DocLexer {
	my $parser = shift;

	$parser->YYData->{doc} = '';
	my $flag = 1;
	while (1) {
		    $parser->YYData->{line}
		or  $parser->YYData->{line} = readline $parser->YYData->{fh}
		or  return;

		for ($parser->YYData->{line}) {
			s/^(\n)//
					and $parser->YYData->{lineno} ++,
						$parser->YYData->{doc} .= $1,
						$flag = 0,
						last;
			s/^\r//
					and last;
			s/^\*\///
					and return;
			unless ($flag) {
				s/^\*//
						and $flag = 1,
						last;
			}
			s/^([ \t\f\013]+)//
					and $parser->YYData->{doc} .= $1,
					last;
			s/^(.)//
					and $parser->YYData->{doc} .= $1,
					$flag = 1,
					last;
		}
	}
}

sub _CodeLexer {
	my $parser = shift;
	my $frag = "";

	while (1) {
		    $parser->YYData->{line}
		or  $parser->YYData->{line} = readline $parser->YYData->{fh}
		or  return;

		for ($parser->YYData->{line}) {
			s/^(\n)//
					and $parser->YYData->{lineno} ++,
						$frag .= $1,
						last;
			s/^%\}//
					and return ('CODE_FRAGMENT', $frag);
			s/^(.)//
					and $frag .= $1,
						last;
		}
	}
}

sub _PragmaLexer {						#	10.6.5	Pragma Directives for RepositoryId
	my $parser = shift;
	my($line) = @_;

	for ($line) {
		s/^ID[ \t]+([0-9A-Za-z_:]+)[ \t]+\"([^\s">]+)\"//
				and $parser->YYData->{symbtab}->PragmaID($1,$2),
				    return;
		s/^prefix[ \t]+\"([0-9A-Za-z_:\.\/\-]*)\"//
				and $parser->YYData->{symbtab}->PragmaPrefix($1),
				    return;
		s/^version[ \t]+([0-9A-Za-z_:]+)[ \t]+([0-9]+)\.([0-9]+)//
				and $parser->YYData->{symbtab}->PragmaVersion($1,$2,$3),
				    return;

		$parser->Info("Non standard pragma.\n");
		return;
	}
}

sub _AttachDoc {
	my $parser = shift;
	my($comment) = @_;

	if (defined $parser->YYData->{curr_node}) {
		if (exists $parser->YYData->{curr_node}->{doc}) {
			$parser->YYData->{curr_node}->{doc} .= $comment;
		} else {
			$parser->YYData->{curr_node}->{doc} = $comment;
		}
	}
}

sub _Lexer {
	my $parser = shift;

	while (1) {
		    $parser->YYData->{line}
		or  $parser->YYData->{line} = readline $parser->YYData->{fh}
		or  return('',undef);

		unless (exists $parser->YYData->{srcname}) {
			if ($parser->YYData->{line} =~ /^#\s*(line\s+)?\d+\s+["<]([^\s">]+)[">]\s*\n/ ) {
				$parser->YYData->{srcname} = $2;
			} else {
				print "INTERNAL_ERROR:_Lexer\n";
			}
			if (defined $parser->YYData->{srcname}) {
				my @st = stat($parser->YYData->{srcname});
				$parser->YYData->{srcname_size} = $st[7];
				$parser->YYData->{srcname_mtime} = $st[9];
			}
		}

		for ($parser->YYData->{line}) {
			s/^#\s+[\d]+\s+"<[^>]+>"\s*\n//							# cpp 3.2.3 ("<build-in>", "<command line>")
					and last;

			s/^#\s+([\d]+)\s+["<]([^\s">]+)[">]\s+([\d]+)\s*\n//	# cpp
					and $parser->YYData->{lineno} = $1,
					    $parser->YYData->{filename} = $2,
					    $parser->YYData->{doc} = '',
					    $parser->YYData->{curr_node} = undef,
					    last;

			s/^#\s+([\d]+)\s+["<]([^\s">]+)[">]\s*\n//				# cpp
					and $parser->YYData->{lineno} = $1,
					    $parser->YYData->{filename} = $2,
					    $parser->YYData->{doc} = '',
					    $parser->YYData->{curr_node} = undef,
					    last;
			s/^#\s*line\s+([\d]+)\s+["<]([^\s">]+)[">]\s*\n//		# CL.EXE Microsoft VC
					and $parser->YYData->{lineno} = $1,
					    $parser->YYData->{filename} = $2,
					    $parser->YYData->{doc} = '',
					    $parser->YYData->{curr_node} = undef,
					    last;

			s/^[ \r\t\f\013]+//;							# whitespaces
			s/^\n//
					and $parser->YYData->{lineno} ++,
					    $parser->YYData->{curr_node} = undef,
					    last;

			s/^#pragma\s+(.*)\n//
					and $parser->_PragmaLexer($1),
					    $parser->YYData->{lineno} ++,
					    $parser->YYData->{curr_node} = undef,
					    last;

			s/^\/\*\*//										# documentation
					and $parser->_DocLexer(),
					    last;
			s/^\/\/\/(.*)\n//								# single line documentation
					and $parser->_AttachDoc($1),
					and $parser->YYData->{lineno} ++,
					    last;

			s/^\/\*//										# multiple line comment
					and $parser->_CommentLexer(),
					    last;
			s/^\/\/.*\n//									# single line comment
					and $parser->YYData->{lineno} ++,
					    $parser->YYData->{curr_node} = undef,
					    last;

			s/^%\{//										# code fragment
					and return $parser->_CodeLexer();

			if ($parser->YYData->{prop}) {
				s/^([A-Za-z][0-9A-Za-z_]*)//
						and return ('PROP_KEY', $1);

				s/^\(([^\)]+)\)//
						and return ('PROP_VALUE', $1);
			}

			if ($parser->YYData->{native}) {
				s/^([^\)]+)\)//
						and return ('NATIVE_TYPE', $1);
			}

			s/^__declspec\s*\(\s*([A-Za-z]*)\s*\)//
					and return ('DECLSPEC', $1);

			s/^([0-9]+)([Dd])//
					and $parser->YYData->{lexeme} = $1 . $2,
					    return ('FIXED_PT_LITERAL', new Math::BigFloat($1));
			s/^([0-9]+\.)([Dd])//
					and $parser->YYData->{lexeme} = $1 . $2,
					    return ('FIXED_PT_LITERAL', new Math::BigFloat($1));
			s/^(\.[0-9]+)([Dd])//
					and $parser->YYData->{lexeme} = $1 . $2,
					    return ('FIXED_PT_LITERAL', new Math::BigFloat($1));
			s/^([0-9]+\.[0-9]+)([Dd])//
					and $parser->YYData->{lexeme} = $1 . $2,
					    return ('FIXED_PT_LITERAL', new Math::BigFloat($1));

			s/^([0-9]+\.[0-9]+[Ee][+\-]?[0-9]+)//
					and $parser->YYData->{lexeme} = $1,
					    return ('FLOATING_PT_LITERAL', new Math::BigFloat($1));
			s/^([0-9]+[Ee][+\-]?[0-9]+)//
					and $parser->YYData->{lexeme} = $1,
					    return ('FLOATING_PT_LITERAL', new Math::BigFloat($1));
			s/^(\.[0-9]+[Ee][+\-]?[0-9]+)//
					and $parser->YYData->{lexeme} = $1,
					    return ('FLOATING_PT_LITERAL', new Math::BigFloat($1));
			s/^([0-9]+\.[0-9]+)//
					and $parser->YYData->{lexeme} = $1,
					    return ('FLOATING_PT_LITERAL', new Math::BigFloat($1));
			s/^([0-9]+\.)//
					and $parser->YYData->{lexeme} = $1,
					    return ('FLOATING_PT_LITERAL', new Math::BigFloat($1));
			s/^(\.[0-9]+)//
					and $parser->YYData->{lexeme} = $1,
					    return ('FLOATING_PT_LITERAL', new Math::BigFloat($1));

			s/^0([0-7]+)//
					and $parser->YYData->{lexeme} = '0' . $1,
					    return $parser->_OctInteger($1);
			s/^(0[Xx])([A-Fa-f0-9]+)//
					and $parser->YYData->{lexeme} = $1 . $2,
					    return $parser->_HexInteger($2);
			s/^(0)//
					and $parser->YYData->{lexeme} = $1,
					    return ('INTEGER_LITERAL', new Math::BigInt($1));
			s/^([1-9][0-9]*)//
					and $parser->YYData->{lexeme} = $1,
					    return ('INTEGER_LITERAL', new Math::BigInt($1));

			s/^\"//
					and return $parser->_StringLexer('STRING_LITERAL');

			if ($Parser::IDL_version ge '2.3') {
				s/^L\"//
						and return $parser->_StringLexer('WIDE_STRING_LITERAL');
			} else {
				s/^L\"//
						and $parser->Warning("literal 'wstring' is not allowed.\n")
						and return $parser->_StringLexer('STRING_LITERAL');
			}

			s/^\'//
					and return $parser->_CharLexer('CHARACTER_LITERAL');

			if ($Parser::IDL_version ge '2.3') {
				s/^L\'//
						and return $parser->_CharLexer('WIDE_CHARACTER_LITERAL');
			} else {
				s/^L\'//
						and $parser->Warning("literal 'wchar' is not allowed.\n")
						and return $parser->_CharLexer('CHARACTER_LITERAL');
			}

			s/^([A-Za-z][0-9A-Za-z_]*)//
					and return $parser->_Identifier($1);
			s/^_([A-Za-z][0-9A-Za-z_]*)//
					and return $parser->_EscIdentifier($1);

			s/^(<<)//
					and return ($1, $1);
			s/^(>>)//
					and return ($1, $1);
			s/^(::)//
					and return ($1, $1);
			s/^(\.\.\.)//
					and return ($1, $1);

			s/^([\+&\/%\*~\|\-\^\(\)\[\]\{\}<>,;:=])//
					and return ($1, $1);					# punctuators

			s/^([\S]+)//
					and $parser->Error("lexer error $1.\n"),
					    last;
		}
	}
}

sub _InitLexico {
	my $parser = shift;

	# 3.2.4	Keywords
	my %keywords = (
		'ABSTRACT'		=> [ 'abstract',	'2.3' ],
		'ANY'			=> [ 'any',			'2.0' ],
		'ATTRIBUTE'		=> [ 'attribute',	'2.0' ],
		'BOOLEAN'		=> [ 'boolean',		'2.0' ],
		'CASE'			=> [ 'case',		'2.0' ],
		'CHAR'			=> [ 'char',		'2.0' ],
		'COMPONENT'		=> [ 'component',	'3.0' ],
		'CONST'			=> [ 'const',		'2.0' ],
		'CONSUMES'		=> [ 'consumes',	'3.0' ],
		'CONTEXT'		=> [ 'context',		'2.0' ],
		'CUSTOM'		=> [ 'custom',		'2.3' ],
		'DEFAULT'		=> [ 'default',		'2.0' ],
		'DOUBLE'		=> [ 'double',		'2.0' ],
		'EMITS'			=> [ 'emits',		'3.0' ],
		'ENUM'			=> [ 'enum',		'2.0' ],
		'EVENTTYPE'		=> [ 'eventtype',	'3.0' ],
		'EXCEPTION'		=> [ 'exception',	'2.0' ],
		'FACTORY'		=> [ 'factory',		'2.3' ],
		'FALSE'			=> [ 'FALSE',		'2.0' ],
		'FINDER'		=> [ 'finder',		'3.0' ],
		'FIXED'			=> [ 'fixed',		'2.1' ],
		'FLOAT'			=> [ 'float',		'2.0' ],
		'GETRAISES'		=> [ 'getraises',	'3.0' ],
		'HOME'			=> [ 'home',		'3.0' ],
		'IMPORT'		=> [ 'import',		'3.0' ],
		'IN'			=> [ 'in',			'2.0' ],
		'INOUT'			=> [ 'inout',		'2.0' ],
		'INTERFACE'		=> [ 'interface',	'2.0' ],
		'LOCAL'			=> [ 'local',		'2.4' ],
		'LONG'			=> [ 'long',		'2.0' ],
		'MODULE'		=> [ 'module',		'2.0' ],
		'MULTIPLE'		=> [ 'multiple',	'3.0' ],
		'NATIVE'		=> [ 'native',		'2.2' ],
		'OBJECT'		=> [ 'Object',		'2.0' ],
		'OCTET'			=> [ 'octet',		'2.0' ],
		'ONEWAY'		=> [ 'oneway',		'2.0' ],
		'OUT'			=> [ 'out',			'2.0' ],
		'PRIMARYKEY'	=> [ 'primarykey',	'3.0' ],
		'PRIVATE'		=> [ 'private',		'2.3' ],
		'PROVIDES'		=> [ 'provides',	'3.0' ],
		'PUBLIC'		=> [ 'public',		'2.3' ],
		'PUBLISHES'		=> [ 'publishes',	'3.0' ],
		'RAISES'		=> [ 'raises',		'2.0' ],
		'READONLY'		=> [ 'readonly',	'2.0' ],
		'SEQUENCE'		=> [ 'sequence',	'2.0' ],
		'SETRAISES'		=> [ 'setraises',	'3.0' ],
		'SHORT'			=> [ 'short',		'2.0' ],
		'STRING'		=> [ 'string',		'2.0' ],
		'STRUCT'		=> [ 'struct',		'2.0' ],
		'SUPPORTS'		=> [ 'supports',	'2.3' ],
		'SWITCH'		=> [ 'switch',		'2.0' ],
		'TRUE'			=> [ 'TRUE',		'2.0' ],
		'TRUNCATABLE'	=> [ 'truncatable',	'2.3' ],
		'TYPEDEF'		=> [ 'typedef',		'2.0' ],
		'TYPEID'		=> [ 'typeid',		'3.0' ],
		'TYPEPREFIX'	=> [ 'typeprefix',	'3.0' ],
		'UNION'			=> [ 'union',		'2.0' ],
		'UNSIGNED'		=> [ 'unsigned',	'2.0' ],
		'USES'			=> [ 'uses',		'3.0' ],
		'VALUEBASE'		=> [ 'ValueBase',	'2.3' ],
		'VALUETYPE'		=> [ 'valuetype',	'2.3' ],
		'VOID'			=> [ 'void',		'2.0' ],
		'WCHAR'			=> [ 'wchar',		'2.1' ],
		'WSTRING'		=> [ 'wstring',		'2.1' ]
	);

	$parser->YYData->{keyword} = \%keywords;
}

sub getopts {			# from Getopt::Std
	no strict;
	my $parser = shift;
	local($argumentative) = @_;
	local(@args, $_, $first, $rest);

	$parser->YYData->{args} = [];
	@args = split( / */, $argumentative );
	while (@ARGV && ($_ = $ARGV[0]) =~ /^-(.)(.*)/) {
		($first, $rest) = ($1, $2);
		if (/^--$/) {	# early exit if --
			shift(@ARGV);
			last;
		}
		$pos = index($argumentative,$first);
		if ($pos >= 0) {
			if (defined($args[$pos+1]) and ($args[$pos+1] eq ':')) {
				shift(@ARGV);
				if ($rest eq '') {
					$rest = shift(@ARGV);
				}
				$parser->YYData->{"opt_$first"} = $rest;
			} else {
				$parser->YYData->{"opt_$first"} = 1;
				if ($rest eq '') {
					shift(@ARGV);
				} else {
					$ARGV[0] = "-$rest";
				}
			}
		} else {
			push @{$parser->YYData->{args}}, shift(@ARGV);
		}
	}
}

sub Run {
	my $parser = shift;
	my $preprocessor = $parser->YYData->{preprocessor};

	if ($preprocessor) {
		my @args;
		@args = @{$parser->YYData->{args}}
				if (exists $parser->YYData->{args});
		push @args, @_;

		open $parser->YYData->{fh}, "$preprocessor @args|"
				or die "can't open @_ ($!).\n";
	} else {
		my $file = shift;
		if (ref $file) {
			$parser->YYData->{fh} = $file;
			$parser->YYData->{srcname} = shift;
		} else {
			open $parser->YYData->{fh}, $file
					or die "can't open $file ($!).\n";
			$parser->YYData->{srcname} = shift || $file;
		}
	}

	$parser->_InitLexico();
	$parser->YYData->{doc} = '';
	$parser->YYData->{curr_node} = undef;
	$parser->YYData->{curr_itf} = undef;
	$parser->YYData->{prop} = 0;
	$parser->YYData->{native} = 0;
	$parser->YYParse(
			yylex	=> \&_Lexer,
			yyerror	=> sub { return; },
#			yydebug	=> 0x17,
	);

#    Bit Value    Outputs
#    0x01         Token reading (useful for Lexer debugging)
#    0x02         States information
#    0x04         Driver actions (shifts, reduces, accept...)
#    0x08         Parse Stack dump
#    0x10         Error Recovery tracing

	close $parser->YYData->{fh};
	delete $parser->{RULES};
	delete $parser->{STATES};
	delete $parser->{STACK};
}

1;





