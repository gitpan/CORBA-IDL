####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.05';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'' => -2,
			'TYPEDEF' => 12,
			'MODULE' => 15,
			'IDENTIFIER' => 14,
			'NATIVE' => 2,
			'UNION' => 17,
			'STRUCT' => 6,
			'error' => 20,
			'CONST' => 23,
			'EXCEPTION' => 24,
			'ENUM' => 29,
			'INTERFACE' => 30
		},
		GOTOS => {
			'const_dcl' => 1,
			'except_dcl' => 4,
			'interface_header' => 3,
			'specification' => 5,
			'module_header' => 7,
			'interface' => 8,
			'struct_type' => 9,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'interface_dcl' => 16,
			'enum_type' => 18,
			'forward_dcl' => 19,
			'module' => 22,
			'enum_header' => 21,
			'union_header' => 25,
			'type_dcl' => 26,
			'definitions' => 27,
			'definition' => 28
		}
	},
	{#State 1
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 31
		}
	},
	{#State 2
		ACTIONS => {
			'error' => 36,
			'IDENTIFIER' => 35
		},
		GOTOS => {
			'simple_declarator' => 34
		}
	},
	{#State 3
		ACTIONS => {
			"{" => 37
		}
	},
	{#State 4
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 38
		}
	},
	{#State 5
		ACTIONS => {
			'' => 39
		}
	},
	{#State 6
		ACTIONS => {
			'error' => 41,
			'IDENTIFIER' => 40
		}
	},
	{#State 7
		ACTIONS => {
			"{" => 43,
			'error' => 42
		}
	},
	{#State 8
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 44
		}
	},
	{#State 9
		DEFAULT => -104
	},
	{#State 10
		ACTIONS => {
			"{" => 46,
			'error' => 45
		}
	},
	{#State 11
		DEFAULT => -105
	},
	{#State 12
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 76,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'UNION' => 17,
			'WCHAR' => 63,
			'error' => 68,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'type_spec' => 58,
			'signed_long_int' => 57,
			'type_declarator' => 59,
			'string_type' => 61,
			'struct_header' => 13,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 77,
			'integer_type' => 78,
			'boolean_type' => 79,
			'signed_short_int' => 84,
			'struct_type' => 86,
			'union_type' => 88,
			'sequence_type' => 90,
			'unsigned_long_int' => 91,
			'template_type_spec' => 92,
			'constr_type_spec' => 93,
			'simple_type_spec' => 94,
			'fixed_pt_type' => 95
		}
	},
	{#State 13
		ACTIONS => {
			"{" => 96
		}
	},
	{#State 14
		ACTIONS => {
			'error' => 97
		}
	},
	{#State 15
		ACTIONS => {
			'error' => 98,
			'IDENTIFIER' => 99
		}
	},
	{#State 16
		DEFAULT => -20
	},
	{#State 17
		ACTIONS => {
			'error' => 100,
			'IDENTIFIER' => 101
		}
	},
	{#State 18
		DEFAULT => -106
	},
	{#State 19
		DEFAULT => -21
	},
	{#State 20
		DEFAULT => -3
	},
	{#State 21
		ACTIONS => {
			"{" => 103,
			'error' => 102
		}
	},
	{#State 22
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 104
		}
	},
	{#State 23
		ACTIONS => {
			'CHAR' => 74,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'FIXED' => 106,
			'WCHAR' => 63,
			'DOUBLE' => 80,
			'error' => 111,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'FLOAT' => 71,
			'WSTRING' => 85,
			'UNSIGNED' => 60
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 105,
			'signed_int' => 50,
			'wide_string_type' => 112,
			'integer_type' => 114,
			'boolean_type' => 113,
			'char_type' => 107,
			'scoped_name' => 108,
			'fixed_pt_const_type' => 115,
			'wide_char_type' => 109,
			'signed_long_int' => 57,
			'signed_short_int' => 84,
			'const_type' => 116,
			'string_type' => 110,
			'unsigned_longlong_int' => 64,
			'unsigned_long_int' => 91,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72
		}
	},
	{#State 24
		ACTIONS => {
			'error' => 117,
			'IDENTIFIER' => 118
		}
	},
	{#State 25
		ACTIONS => {
			'SWITCH' => 119
		}
	},
	{#State 26
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 120
		}
	},
	{#State 27
		DEFAULT => -1
	},
	{#State 28
		ACTIONS => {
			'TYPEDEF' => 12,
			'IDENTIFIER' => 14,
			'NATIVE' => 2,
			'MODULE' => 15,
			'UNION' => 17,
			'STRUCT' => 6,
			'CONST' => 23,
			'EXCEPTION' => 24,
			'ENUM' => 29,
			'INTERFACE' => 30
		},
		DEFAULT => -4,
		GOTOS => {
			'const_dcl' => 1,
			'interface_header' => 3,
			'except_dcl' => 4,
			'module_header' => 7,
			'interface' => 8,
			'struct_type' => 9,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'interface_dcl' => 16,
			'enum_type' => 18,
			'forward_dcl' => 19,
			'enum_header' => 21,
			'module' => 22,
			'union_header' => 25,
			'definitions' => 121,
			'type_dcl' => 26,
			'definition' => 28
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 122,
			'IDENTIFIER' => 123
		}
	},
	{#State 30
		ACTIONS => {
			'error' => 124,
			'IDENTIFIER' => 125
		}
	},
	{#State 31
		DEFAULT => -7
	},
	{#State 32
		DEFAULT => -12
	},
	{#State 33
		DEFAULT => -13
	},
	{#State 34
		DEFAULT => -107
	},
	{#State 35
		DEFAULT => -135
	},
	{#State 36
		ACTIONS => {
			";" => 126,
			"," => 127
		}
	},
	{#State 37
		ACTIONS => {
			'CHAR' => -235,
			'OBJECT' => -235,
			'ONEWAY' => 128,
			'FIXED' => -235,
			'NATIVE' => 2,
			'VOID' => -235,
			'SEQUENCE' => -235,
			'STRUCT' => 6,
			'DOUBLE' => -235,
			'LONG' => -235,
			'STRING' => -235,
			"::" => -235,
			'WSTRING' => -235,
			'UNSIGNED' => -235,
			'SHORT' => -235,
			'TYPEDEF' => 12,
			'BOOLEAN' => -235,
			'IDENTIFIER' => -235,
			'UNION' => 17,
			'READONLY' => 139,
			'WCHAR' => -235,
			'ATTRIBUTE' => -221,
			'error' => 133,
			'CONST' => 23,
			"}" => 134,
			'EXCEPTION' => 24,
			'OCTET' => -235,
			'FLOAT' => -235,
			'ENUM' => 29,
			'ANY' => -235
		},
		GOTOS => {
			'const_dcl' => 135,
			'op_mod' => 129,
			'except_dcl' => 130,
			'op_attribute' => 131,
			'attr_mod' => 132,
			'exports' => 136,
			'export' => 137,
			'struct_type' => 9,
			'op_header' => 138,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'enum_type' => 18,
			'op_dcl' => 140,
			'enum_header' => 21,
			'attr_dcl' => 141,
			'type_dcl' => 142,
			'union_header' => 25,
			'interface_body' => 143
		}
	},
	{#State 38
		DEFAULT => -8
	},
	{#State 39
		DEFAULT => 0
	},
	{#State 40
		DEFAULT => -164
	},
	{#State 41
		DEFAULT => -165
	},
	{#State 42
		ACTIONS => {
			"}" => 144
		}
	},
	{#State 43
		ACTIONS => {
			'TYPEDEF' => 12,
			'IDENTIFIER' => 14,
			'NATIVE' => 2,
			'MODULE' => 15,
			'UNION' => 17,
			'STRUCT' => 6,
			'error' => 145,
			'CONST' => 23,
			'EXCEPTION' => 24,
			"}" => 146,
			'ENUM' => 29,
			'INTERFACE' => 30
		},
		GOTOS => {
			'const_dcl' => 1,
			'interface_header' => 3,
			'except_dcl' => 4,
			'module_header' => 7,
			'interface' => 8,
			'struct_type' => 9,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'interface_dcl' => 16,
			'enum_type' => 18,
			'forward_dcl' => 19,
			'enum_header' => 21,
			'module' => 22,
			'union_header' => 25,
			'definitions' => 147,
			'type_dcl' => 26,
			'definition' => 28
		}
	},
	{#State 44
		DEFAULT => -9
	},
	{#State 45
		DEFAULT => -227
	},
	{#State 46
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 76,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'UNION' => 17,
			'WCHAR' => 63,
			'error' => 149,
			"}" => 151,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'type_spec' => 148,
			'string_type' => 61,
			'struct_header' => 13,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'member_list' => 150,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 77,
			'boolean_type' => 79,
			'integer_type' => 78,
			'signed_short_int' => 84,
			'member' => 152,
			'struct_type' => 86,
			'union_type' => 88,
			'sequence_type' => 90,
			'unsigned_long_int' => 91,
			'template_type_spec' => 92,
			'constr_type_spec' => 93,
			'simple_type_spec' => 94,
			'fixed_pt_type' => 95
		}
	},
	{#State 47
		DEFAULT => -143
	},
	{#State 48
		DEFAULT => -116
	},
	{#State 49
		ACTIONS => {
			"<" => 154,
			'error' => 153
		}
	},
	{#State 50
		DEFAULT => -142
	},
	{#State 51
		ACTIONS => {
			"<" => 156,
			'error' => 155
		}
	},
	{#State 52
		DEFAULT => -118
	},
	{#State 53
		DEFAULT => -123
	},
	{#State 54
		DEFAULT => -121
	},
	{#State 55
		ACTIONS => {
			"::" => 157
		},
		DEFAULT => -114
	},
	{#State 56
		DEFAULT => -119
	},
	{#State 57
		DEFAULT => -145
	},
	{#State 58
		ACTIONS => {
			'error' => 36,
			'IDENTIFIER' => 163
		},
		GOTOS => {
			'declarators' => 158,
			'declarator' => 159,
			'simple_declarator' => 161,
			'array_declarator' => 162,
			'complex_declarator' => 160
		}
	},
	{#State 59
		DEFAULT => -103
	},
	{#State 60
		ACTIONS => {
			'SHORT' => 164,
			'LONG' => 165
		}
	},
	{#State 61
		DEFAULT => -125
	},
	{#State 62
		DEFAULT => -147
	},
	{#State 63
		DEFAULT => -157
	},
	{#State 64
		DEFAULT => -152
	},
	{#State 65
		DEFAULT => -122
	},
	{#State 66
		DEFAULT => -112
	},
	{#State 67
		DEFAULT => -130
	},
	{#State 68
		DEFAULT => -108
	},
	{#State 69
		DEFAULT => -159
	},
	{#State 70
		DEFAULT => -150
	},
	{#State 71
		DEFAULT => -139
	},
	{#State 72
		DEFAULT => -146
	},
	{#State 73
		DEFAULT => -160
	},
	{#State 74
		DEFAULT => -156
	},
	{#State 75
		DEFAULT => -161
	},
	{#State 76
		DEFAULT => -115
	},
	{#State 77
		DEFAULT => -126
	},
	{#State 78
		DEFAULT => -117
	},
	{#State 79
		DEFAULT => -120
	},
	{#State 80
		DEFAULT => -140
	},
	{#State 81
		ACTIONS => {
			'LONG' => 167,
			'DOUBLE' => 166
		},
		DEFAULT => -148
	},
	{#State 82
		ACTIONS => {
			"<" => 168
		},
		DEFAULT => -208
	},
	{#State 83
		ACTIONS => {
			'error' => 169,
			'IDENTIFIER' => 170
		}
	},
	{#State 84
		DEFAULT => -144
	},
	{#State 85
		ACTIONS => {
			"<" => 171
		},
		DEFAULT => -211
	},
	{#State 86
		DEFAULT => -128
	},
	{#State 87
		DEFAULT => -158
	},
	{#State 88
		DEFAULT => -129
	},
	{#State 89
		DEFAULT => -43
	},
	{#State 90
		DEFAULT => -124
	},
	{#State 91
		DEFAULT => -151
	},
	{#State 92
		DEFAULT => -113
	},
	{#State 93
		DEFAULT => -111
	},
	{#State 94
		DEFAULT => -110
	},
	{#State 95
		DEFAULT => -127
	},
	{#State 96
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 76,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'UNION' => 17,
			'WCHAR' => 63,
			'error' => 172,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'type_spec' => 148,
			'string_type' => 61,
			'struct_header' => 13,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'member_list' => 173,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 77,
			'boolean_type' => 79,
			'integer_type' => 78,
			'signed_short_int' => 84,
			'member' => 152,
			'struct_type' => 86,
			'union_type' => 88,
			'sequence_type' => 90,
			'unsigned_long_int' => 91,
			'template_type_spec' => 92,
			'constr_type_spec' => 93,
			'simple_type_spec' => 94,
			'fixed_pt_type' => 95
		}
	},
	{#State 97
		ACTIONS => {
			";" => 174
		}
	},
	{#State 98
		DEFAULT => -19
	},
	{#State 99
		DEFAULT => -18
	},
	{#State 100
		DEFAULT => -175
	},
	{#State 101
		DEFAULT => -174
	},
	{#State 102
		DEFAULT => -194
	},
	{#State 103
		ACTIONS => {
			'error' => 175,
			'IDENTIFIER' => 177
		},
		GOTOS => {
			'enumerators' => 178,
			'enumerator' => 176
		}
	},
	{#State 104
		DEFAULT => -10
	},
	{#State 105
		DEFAULT => -57
	},
	{#State 106
		DEFAULT => -280
	},
	{#State 107
		DEFAULT => -54
	},
	{#State 108
		ACTIONS => {
			"::" => 157
		},
		DEFAULT => -61
	},
	{#State 109
		DEFAULT => -55
	},
	{#State 110
		DEFAULT => -58
	},
	{#State 111
		DEFAULT => -52
	},
	{#State 112
		DEFAULT => -59
	},
	{#State 113
		DEFAULT => -56
	},
	{#State 114
		DEFAULT => -53
	},
	{#State 115
		DEFAULT => -60
	},
	{#State 116
		ACTIONS => {
			'error' => 179,
			'IDENTIFIER' => 180
		}
	},
	{#State 117
		DEFAULT => -229
	},
	{#State 118
		DEFAULT => -228
	},
	{#State 119
		ACTIONS => {
			'error' => 182,
			"(" => 181
		}
	},
	{#State 120
		DEFAULT => -6
	},
	{#State 121
		DEFAULT => -5
	},
	{#State 122
		DEFAULT => -196
	},
	{#State 123
		DEFAULT => -195
	},
	{#State 124
		ACTIONS => {
			"{" => -28
		},
		DEFAULT => -26
	},
	{#State 125
		ACTIONS => {
			"{" => -39,
			":" => 183
		},
		DEFAULT => -25,
		GOTOS => {
			'interface_inheritance_spec' => 184
		}
	},
	{#State 126
		DEFAULT => -137
	},
	{#State 127
		DEFAULT => -136
	},
	{#State 128
		DEFAULT => -236
	},
	{#State 129
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 189,
			'SEQUENCE' => 51,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'WCHAR' => 63,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'wide_string_type' => 188,
			'integer_type' => 78,
			'boolean_type' => 79,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 185,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'signed_short_int' => 84,
			'string_type' => 186,
			'op_type_spec' => 191,
			'op_param_type_spec' => 190,
			'sequence_type' => 192,
			'base_type_spec' => 187,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'unsigned_long_int' => 91,
			'unsigned_short_int' => 70,
			'fixed_pt_type' => 193,
			'signed_longlong_int' => 72
		}
	},
	{#State 130
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 194
		}
	},
	{#State 131
		DEFAULT => -234
	},
	{#State 132
		ACTIONS => {
			'ATTRIBUTE' => 195
		}
	},
	{#State 133
		ACTIONS => {
			"}" => 196
		}
	},
	{#State 134
		DEFAULT => -22
	},
	{#State 135
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 197
		}
	},
	{#State 136
		DEFAULT => -29
	},
	{#State 137
		ACTIONS => {
			'ONEWAY' => 128,
			'NATIVE' => 2,
			'STRUCT' => 6,
			'TYPEDEF' => 12,
			'UNION' => 17,
			'READONLY' => 139,
			'ATTRIBUTE' => -221,
			'CONST' => 23,
			"}" => -30,
			'EXCEPTION' => 24,
			'ENUM' => 29
		},
		DEFAULT => -235,
		GOTOS => {
			'const_dcl' => 135,
			'op_mod' => 129,
			'except_dcl' => 130,
			'op_attribute' => 131,
			'attr_mod' => 132,
			'exports' => 198,
			'export' => 137,
			'struct_type' => 9,
			'op_header' => 138,
			'exception_header' => 10,
			'union_type' => 11,
			'struct_header' => 13,
			'enum_type' => 18,
			'op_dcl' => 140,
			'enum_header' => 21,
			'attr_dcl' => 141,
			'type_dcl' => 142,
			'union_header' => 25
		}
	},
	{#State 138
		ACTIONS => {
			'error' => 200,
			"(" => 199
		},
		GOTOS => {
			'parameter_dcls' => 201
		}
	},
	{#State 139
		DEFAULT => -220
	},
	{#State 140
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 202
		}
	},
	{#State 141
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 203
		}
	},
	{#State 142
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 204
		}
	},
	{#State 143
		ACTIONS => {
			"}" => 205
		}
	},
	{#State 144
		DEFAULT => -17
	},
	{#State 145
		ACTIONS => {
			"}" => 206
		}
	},
	{#State 146
		DEFAULT => -16
	},
	{#State 147
		ACTIONS => {
			"}" => 207
		}
	},
	{#State 148
		ACTIONS => {
			'error' => 36,
			'IDENTIFIER' => 163
		},
		GOTOS => {
			'declarators' => 208,
			'declarator' => 159,
			'simple_declarator' => 161,
			'array_declarator' => 162,
			'complex_declarator' => 160
		}
	},
	{#State 149
		ACTIONS => {
			"}" => 209
		}
	},
	{#State 150
		ACTIONS => {
			"}" => 210
		}
	},
	{#State 151
		DEFAULT => -224
	},
	{#State 152
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 76,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'UNION' => 17,
			'WCHAR' => 63,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		DEFAULT => -166,
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'type_spec' => 148,
			'string_type' => 61,
			'struct_header' => 13,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'member_list' => 211,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 77,
			'boolean_type' => 79,
			'integer_type' => 78,
			'signed_short_int' => 84,
			'member' => 152,
			'struct_type' => 86,
			'union_type' => 88,
			'sequence_type' => 90,
			'unsigned_long_int' => 91,
			'template_type_spec' => 92,
			'constr_type_spec' => 93,
			'simple_type_spec' => 94,
			'fixed_pt_type' => 95
		}
	},
	{#State 153
		DEFAULT => -279
	},
	{#State 154
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 221,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'primary_expr' => 231,
			'and_expr' => 232,
			'scoped_name' => 214,
			'positive_int_const' => 215,
			'wide_string_literal' => 216,
			'boolean_literal' => 218,
			'mult_expr' => 234,
			'const_exp' => 219,
			'or_expr' => 220,
			'unary_expr' => 238,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 155
		DEFAULT => -206
	},
	{#State 156
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 76,
			'SEQUENCE' => 51,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'WCHAR' => 63,
			'error' => 242,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'wide_string_type' => 77,
			'integer_type' => 78,
			'boolean_type' => 79,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'signed_short_int' => 84,
			'string_type' => 61,
			'sequence_type' => 90,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'unsigned_long_int' => 91,
			'template_type_spec' => 92,
			'unsigned_short_int' => 70,
			'simple_type_spec' => 243,
			'fixed_pt_type' => 95,
			'signed_longlong_int' => 72
		}
	},
	{#State 157
		ACTIONS => {
			'error' => 244,
			'IDENTIFIER' => 245
		}
	},
	{#State 158
		DEFAULT => -109
	},
	{#State 159
		ACTIONS => {
			"," => 246
		},
		DEFAULT => -131
	},
	{#State 160
		DEFAULT => -134
	},
	{#State 161
		DEFAULT => -133
	},
	{#State 162
		DEFAULT => -138
	},
	{#State 163
		ACTIONS => {
			"[" => 249
		},
		DEFAULT => -135,
		GOTOS => {
			'fixed_array_sizes' => 247,
			'fixed_array_size' => 248
		}
	},
	{#State 164
		DEFAULT => -153
	},
	{#State 165
		ACTIONS => {
			'LONG' => 250
		},
		DEFAULT => -154
	},
	{#State 166
		DEFAULT => -141
	},
	{#State 167
		DEFAULT => -149
	},
	{#State 168
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 252,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'primary_expr' => 231,
			'and_expr' => 232,
			'scoped_name' => 214,
			'positive_int_const' => 251,
			'wide_string_literal' => 216,
			'boolean_literal' => 218,
			'mult_expr' => 234,
			'const_exp' => 219,
			'or_expr' => 220,
			'unary_expr' => 238,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 169
		DEFAULT => -45
	},
	{#State 170
		DEFAULT => -44
	},
	{#State 171
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 254,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'primary_expr' => 231,
			'and_expr' => 232,
			'scoped_name' => 214,
			'positive_int_const' => 253,
			'wide_string_literal' => 216,
			'boolean_literal' => 218,
			'mult_expr' => 234,
			'const_exp' => 219,
			'or_expr' => 220,
			'unary_expr' => 238,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 172
		ACTIONS => {
			"}" => 255
		}
	},
	{#State 173
		ACTIONS => {
			"}" => 256
		}
	},
	{#State 174
		DEFAULT => -11
	},
	{#State 175
		ACTIONS => {
			"}" => 257
		}
	},
	{#State 176
		ACTIONS => {
			";" => 258,
			"," => 259
		},
		DEFAULT => -197
	},
	{#State 177
		DEFAULT => -201
	},
	{#State 178
		ACTIONS => {
			"}" => 260
		}
	},
	{#State 179
		DEFAULT => -51
	},
	{#State 180
		ACTIONS => {
			'error' => 261,
			"=" => 262
		}
	},
	{#State 181
		ACTIONS => {
			'CHAR' => 74,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'error' => 266,
			'LONG' => 270,
			"::" => 83,
			'ENUM' => 29,
			'UNSIGNED' => 60
		},
		GOTOS => {
			'switch_type_spec' => 267,
			'unsigned_int' => 47,
			'signed_int' => 50,
			'integer_type' => 269,
			'boolean_type' => 268,
			'unsigned_longlong_int' => 64,
			'char_type' => 263,
			'enum_type' => 265,
			'unsigned_long_int' => 91,
			'scoped_name' => 264,
			'enum_header' => 21,
			'signed_long_int' => 57,
			'unsigned_short_int' => 70,
			'signed_short_int' => 84,
			'signed_longlong_int' => 72
		}
	},
	{#State 182
		DEFAULT => -173
	},
	{#State 183
		ACTIONS => {
			'error' => 272,
			'IDENTIFIER' => 89,
			"::" => 83
		},
		GOTOS => {
			'scoped_name' => 271,
			'interface_names' => 274,
			'interface_name' => 273
		}
	},
	{#State 184
		DEFAULT => -27
	},
	{#State 185
		ACTIONS => {
			"::" => 157
		},
		DEFAULT => -275
	},
	{#State 186
		DEFAULT => -272
	},
	{#State 187
		DEFAULT => -271
	},
	{#State 188
		DEFAULT => -273
	},
	{#State 189
		DEFAULT => -238
	},
	{#State 190
		DEFAULT => -237
	},
	{#State 191
		ACTIONS => {
			'error' => 275,
			'IDENTIFIER' => 276
		}
	},
	{#State 192
		DEFAULT => -239
	},
	{#State 193
		DEFAULT => -274
	},
	{#State 194
		DEFAULT => -34
	},
	{#State 195
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 279,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'UNION' => 17,
			'WCHAR' => 63,
			'error' => 277,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'wide_string_type' => 188,
			'integer_type' => 78,
			'boolean_type' => 79,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 185,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'signed_short_int' => 84,
			'string_type' => 186,
			'op_param_type_spec' => 280,
			'struct_type' => 86,
			'union_type' => 88,
			'struct_header' => 13,
			'sequence_type' => 281,
			'base_type_spec' => 187,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'enum_type' => 67,
			'unsigned_long_int' => 91,
			'param_type_spec' => 278,
			'enum_header' => 21,
			'constr_type_spec' => 282,
			'unsigned_short_int' => 70,
			'union_header' => 25,
			'fixed_pt_type' => 193,
			'signed_longlong_int' => 72
		}
	},
	{#State 196
		DEFAULT => -24
	},
	{#State 197
		DEFAULT => -33
	},
	{#State 198
		DEFAULT => -31
	},
	{#State 199
		ACTIONS => {
			'CHAR' => -253,
			'OBJECT' => -253,
			'FIXED' => -253,
			'VOID' => -253,
			'IN' => 283,
			'SEQUENCE' => -253,
			'STRUCT' => -253,
			'DOUBLE' => -253,
			'LONG' => -253,
			'STRING' => -253,
			"::" => -253,
			'WSTRING' => -253,
			"..." => 284,
			'UNSIGNED' => -253,
			'SHORT' => -253,
			")" => 289,
			'OUT' => 290,
			'BOOLEAN' => -253,
			'IDENTIFIER' => -253,
			'UNION' => -253,
			'WCHAR' => -253,
			'error' => 285,
			'INOUT' => 286,
			'OCTET' => -253,
			'FLOAT' => -253,
			'ENUM' => -253,
			'ANY' => -253
		},
		GOTOS => {
			'param_dcl' => 291,
			'param_dcls' => 288,
			'param_attribute' => 287
		}
	},
	{#State 200
		DEFAULT => -231
	},
	{#State 201
		ACTIONS => {
			'RAISES' => 293
		},
		DEFAULT => -257,
		GOTOS => {
			'raises_expr' => 292
		}
	},
	{#State 202
		DEFAULT => -36
	},
	{#State 203
		DEFAULT => -35
	},
	{#State 204
		DEFAULT => -32
	},
	{#State 205
		DEFAULT => -23
	},
	{#State 206
		DEFAULT => -15
	},
	{#State 207
		DEFAULT => -14
	},
	{#State 208
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 294
		}
	},
	{#State 209
		DEFAULT => -226
	},
	{#State 210
		DEFAULT => -225
	},
	{#State 211
		DEFAULT => -167
	},
	{#State 212
		DEFAULT => -91
	},
	{#State 213
		DEFAULT => -92
	},
	{#State 214
		ACTIONS => {
			"::" => 157
		},
		DEFAULT => -84
	},
	{#State 215
		ACTIONS => {
			"," => 295
		}
	},
	{#State 216
		DEFAULT => -90
	},
	{#State 217
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 297,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 234,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'const_exp' => 296,
			'and_expr' => 232,
			'or_expr' => 220,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 218
		DEFAULT => -95
	},
	{#State 219
		DEFAULT => -102
	},
	{#State 220
		ACTIONS => {
			"|" => 298
		},
		DEFAULT => -62
	},
	{#State 221
		ACTIONS => {
			">" => 299
		}
	},
	{#State 222
		ACTIONS => {
			"^" => 300
		},
		DEFAULT => -63
	},
	{#State 223
		ACTIONS => {
			"<<" => 301,
			">>" => 302
		},
		DEFAULT => -67
	},
	{#State 224
		DEFAULT => -101
	},
	{#State 225
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 225
		},
		DEFAULT => -98,
		GOTOS => {
			'wide_string_literal' => 303
		}
	},
	{#State 226
		DEFAULT => -85
	},
	{#State 227
		DEFAULT => -100
	},
	{#State 228
		ACTIONS => {
			"+" => 304,
			"-" => 305
		},
		DEFAULT => -69
	},
	{#State 229
		DEFAULT => -89
	},
	{#State 230
		DEFAULT => -94
	},
	{#State 231
		DEFAULT => -80
	},
	{#State 232
		ACTIONS => {
			"&" => 306
		},
		DEFAULT => -65
	},
	{#State 233
		DEFAULT => -88
	},
	{#State 234
		ACTIONS => {
			"%" => 308,
			"*" => 307,
			"/" => 309
		},
		DEFAULT => -72
	},
	{#State 235
		ACTIONS => {
			'STRING_LITERAL' => 235
		},
		DEFAULT => -96,
		GOTOS => {
			'string_literal' => 310
		}
	},
	{#State 236
		DEFAULT => -93
	},
	{#State 237
		DEFAULT => -82
	},
	{#State 238
		DEFAULT => -75
	},
	{#State 239
		DEFAULT => -81
	},
	{#State 240
		DEFAULT => -83
	},
	{#State 241
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'boolean_literal' => 218,
			'scoped_name' => 214,
			'primary_expr' => 311,
			'literal' => 226,
			'wide_string_literal' => 216
		}
	},
	{#State 242
		ACTIONS => {
			">" => 312
		}
	},
	{#State 243
		ACTIONS => {
			">" => 314,
			"," => 313
		}
	},
	{#State 244
		DEFAULT => -47
	},
	{#State 245
		DEFAULT => -46
	},
	{#State 246
		ACTIONS => {
			'error' => 36,
			'IDENTIFIER' => 163
		},
		GOTOS => {
			'declarators' => 315,
			'declarator' => 159,
			'simple_declarator' => 161,
			'array_declarator' => 162,
			'complex_declarator' => 160
		}
	},
	{#State 247
		DEFAULT => -213
	},
	{#State 248
		ACTIONS => {
			"[" => 249
		},
		DEFAULT => -214,
		GOTOS => {
			'fixed_array_sizes' => 316,
			'fixed_array_size' => 248
		}
	},
	{#State 249
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 318,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'primary_expr' => 231,
			'and_expr' => 232,
			'scoped_name' => 214,
			'positive_int_const' => 317,
			'wide_string_literal' => 216,
			'boolean_literal' => 218,
			'mult_expr' => 234,
			'const_exp' => 219,
			'or_expr' => 220,
			'unary_expr' => 238,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 250
		DEFAULT => -155
	},
	{#State 251
		ACTIONS => {
			">" => 319
		}
	},
	{#State 252
		ACTIONS => {
			">" => 320
		}
	},
	{#State 253
		ACTIONS => {
			">" => 321
		}
	},
	{#State 254
		ACTIONS => {
			">" => 322
		}
	},
	{#State 255
		DEFAULT => -163
	},
	{#State 256
		DEFAULT => -162
	},
	{#State 257
		DEFAULT => -193
	},
	{#State 258
		DEFAULT => -200
	},
	{#State 259
		ACTIONS => {
			'IDENTIFIER' => 177
		},
		DEFAULT => -199,
		GOTOS => {
			'enumerators' => 323,
			'enumerator' => 176
		}
	},
	{#State 260
		DEFAULT => -192
	},
	{#State 261
		DEFAULT => -50
	},
	{#State 262
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 325,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 234,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'const_exp' => 324,
			'and_expr' => 232,
			'or_expr' => 220,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 263
		DEFAULT => -177
	},
	{#State 264
		ACTIONS => {
			"::" => 157
		},
		DEFAULT => -180
	},
	{#State 265
		DEFAULT => -179
	},
	{#State 266
		ACTIONS => {
			")" => 326
		}
	},
	{#State 267
		ACTIONS => {
			")" => 327
		}
	},
	{#State 268
		DEFAULT => -178
	},
	{#State 269
		DEFAULT => -176
	},
	{#State 270
		ACTIONS => {
			'LONG' => 167
		},
		DEFAULT => -148
	},
	{#State 271
		ACTIONS => {
			"::" => 157
		},
		DEFAULT => -42
	},
	{#State 272
		DEFAULT => -38
	},
	{#State 273
		ACTIONS => {
			"," => 328
		},
		DEFAULT => -40
	},
	{#State 274
		DEFAULT => -37
	},
	{#State 275
		DEFAULT => -233
	},
	{#State 276
		DEFAULT => -232
	},
	{#State 277
		DEFAULT => -219
	},
	{#State 278
		ACTIONS => {
			'error' => 36,
			'IDENTIFIER' => 35
		},
		GOTOS => {
			'simple_declarators' => 330,
			'simple_declarator' => 329
		}
	},
	{#State 279
		DEFAULT => -268
	},
	{#State 280
		DEFAULT => -267
	},
	{#State 281
		DEFAULT => -269
	},
	{#State 282
		DEFAULT => -270
	},
	{#State 283
		DEFAULT => -250
	},
	{#State 284
		ACTIONS => {
			")" => 331
		}
	},
	{#State 285
		ACTIONS => {
			")" => 332
		}
	},
	{#State 286
		DEFAULT => -252
	},
	{#State 287
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 279,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'UNION' => 17,
			'WCHAR' => 63,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'wide_string_type' => 188,
			'integer_type' => 78,
			'boolean_type' => 79,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 185,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'signed_short_int' => 84,
			'string_type' => 186,
			'op_param_type_spec' => 280,
			'struct_type' => 86,
			'union_type' => 88,
			'struct_header' => 13,
			'sequence_type' => 281,
			'base_type_spec' => 187,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'enum_type' => 67,
			'unsigned_long_int' => 91,
			'param_type_spec' => 333,
			'enum_header' => 21,
			'constr_type_spec' => 282,
			'unsigned_short_int' => 70,
			'union_header' => 25,
			'fixed_pt_type' => 193,
			'signed_longlong_int' => 72
		}
	},
	{#State 288
		ACTIONS => {
			")" => 335,
			"," => 334
		}
	},
	{#State 289
		DEFAULT => -243
	},
	{#State 290
		DEFAULT => -251
	},
	{#State 291
		ACTIONS => {
			";" => 336
		},
		DEFAULT => -246
	},
	{#State 292
		ACTIONS => {
			'CONTEXT' => 337
		},
		DEFAULT => -264,
		GOTOS => {
			'context_expr' => 338
		}
	},
	{#State 293
		ACTIONS => {
			'error' => 340,
			"(" => 339
		}
	},
	{#State 294
		DEFAULT => -168
	},
	{#State 295
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 342,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'primary_expr' => 231,
			'and_expr' => 232,
			'scoped_name' => 214,
			'positive_int_const' => 341,
			'wide_string_literal' => 216,
			'boolean_literal' => 218,
			'mult_expr' => 234,
			'const_exp' => 219,
			'or_expr' => 220,
			'unary_expr' => 238,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 296
		ACTIONS => {
			")" => 343
		}
	},
	{#State 297
		ACTIONS => {
			")" => 344
		}
	},
	{#State 298
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 234,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'and_expr' => 232,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'xor_expr' => 345,
			'shift_expr' => 223,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 299
		DEFAULT => -278
	},
	{#State 300
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 234,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'and_expr' => 346,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'shift_expr' => 223,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 301
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 234,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 347
		}
	},
	{#State 302
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 234,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 348
		}
	},
	{#State 303
		DEFAULT => -99
	},
	{#State 304
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 349,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241
		}
	},
	{#State 305
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 350,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241
		}
	},
	{#State 306
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 234,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'shift_expr' => 351,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 307
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'unary_expr' => 352,
			'scoped_name' => 214,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241
		}
	},
	{#State 308
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'unary_expr' => 353,
			'scoped_name' => 214,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241
		}
	},
	{#State 309
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'CHARACTER_LITERAL' => 212,
			"+" => 237,
			'FIXED_PT_LITERAL' => 236,
			'WIDE_CHARACTER_LITERAL' => 213,
			"-" => 239,
			"::" => 83,
			'FALSE' => 224,
			'WIDE_STRING_LITERAL' => 225,
			'INTEGER_LITERAL' => 233,
			"~" => 240,
			"(" => 217,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'unary_expr' => 354,
			'scoped_name' => 214,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241
		}
	},
	{#State 310
		DEFAULT => -97
	},
	{#State 311
		DEFAULT => -79
	},
	{#State 312
		DEFAULT => -205
	},
	{#State 313
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 356,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'string_literal' => 229,
			'primary_expr' => 231,
			'and_expr' => 232,
			'scoped_name' => 214,
			'positive_int_const' => 355,
			'wide_string_literal' => 216,
			'boolean_literal' => 218,
			'mult_expr' => 234,
			'const_exp' => 219,
			'or_expr' => 220,
			'unary_expr' => 238,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 314
		DEFAULT => -204
	},
	{#State 315
		DEFAULT => -132
	},
	{#State 316
		DEFAULT => -215
	},
	{#State 317
		ACTIONS => {
			"]" => 357
		}
	},
	{#State 318
		ACTIONS => {
			"]" => 358
		}
	},
	{#State 319
		DEFAULT => -207
	},
	{#State 320
		DEFAULT => -209
	},
	{#State 321
		DEFAULT => -210
	},
	{#State 322
		DEFAULT => -212
	},
	{#State 323
		DEFAULT => -198
	},
	{#State 324
		DEFAULT => -48
	},
	{#State 325
		DEFAULT => -49
	},
	{#State 326
		DEFAULT => -172
	},
	{#State 327
		ACTIONS => {
			"{" => 360,
			'error' => 359
		}
	},
	{#State 328
		ACTIONS => {
			'IDENTIFIER' => 89,
			"::" => 83
		},
		GOTOS => {
			'scoped_name' => 271,
			'interface_names' => 361,
			'interface_name' => 273
		}
	},
	{#State 329
		ACTIONS => {
			"," => 362
		},
		DEFAULT => -222
	},
	{#State 330
		DEFAULT => -218
	},
	{#State 331
		DEFAULT => -244
	},
	{#State 332
		DEFAULT => -245
	},
	{#State 333
		ACTIONS => {
			'error' => 36,
			'IDENTIFIER' => 35
		},
		GOTOS => {
			'simple_declarator' => 363
		}
	},
	{#State 334
		ACTIONS => {
			'IN' => 283,
			"..." => 364,
			")" => 365,
			'OUT' => 290,
			'INOUT' => 286
		},
		DEFAULT => -253,
		GOTOS => {
			'param_dcl' => 366,
			'param_attribute' => 287
		}
	},
	{#State 335
		DEFAULT => -240
	},
	{#State 336
		DEFAULT => -248
	},
	{#State 337
		ACTIONS => {
			'error' => 368,
			"(" => 367
		}
	},
	{#State 338
		DEFAULT => -230
	},
	{#State 339
		ACTIONS => {
			'error' => 370,
			'IDENTIFIER' => 89,
			"::" => 83
		},
		GOTOS => {
			'scoped_name' => 369,
			'exception_names' => 371,
			'exception_name' => 372
		}
	},
	{#State 340
		DEFAULT => -256
	},
	{#State 341
		ACTIONS => {
			">" => 373
		}
	},
	{#State 342
		ACTIONS => {
			">" => 374
		}
	},
	{#State 343
		DEFAULT => -86
	},
	{#State 344
		DEFAULT => -87
	},
	{#State 345
		ACTIONS => {
			"^" => 300
		},
		DEFAULT => -64
	},
	{#State 346
		ACTIONS => {
			"&" => 306
		},
		DEFAULT => -66
	},
	{#State 347
		ACTIONS => {
			"+" => 304,
			"-" => 305
		},
		DEFAULT => -71
	},
	{#State 348
		ACTIONS => {
			"+" => 304,
			"-" => 305
		},
		DEFAULT => -70
	},
	{#State 349
		ACTIONS => {
			"%" => 308,
			"*" => 307,
			"/" => 309
		},
		DEFAULT => -73
	},
	{#State 350
		ACTIONS => {
			"%" => 308,
			"*" => 307,
			"/" => 309
		},
		DEFAULT => -74
	},
	{#State 351
		ACTIONS => {
			"<<" => 301,
			">>" => 302
		},
		DEFAULT => -68
	},
	{#State 352
		DEFAULT => -76
	},
	{#State 353
		DEFAULT => -78
	},
	{#State 354
		DEFAULT => -77
	},
	{#State 355
		ACTIONS => {
			">" => 375
		}
	},
	{#State 356
		ACTIONS => {
			">" => 376
		}
	},
	{#State 357
		DEFAULT => -216
	},
	{#State 358
		DEFAULT => -217
	},
	{#State 359
		DEFAULT => -171
	},
	{#State 360
		ACTIONS => {
			'error' => 380,
			'CASE' => 377,
			'DEFAULT' => 379
		},
		GOTOS => {
			'case_labels' => 382,
			'switch_body' => 381,
			'case' => 378,
			'case_label' => 383
		}
	},
	{#State 361
		DEFAULT => -41
	},
	{#State 362
		ACTIONS => {
			'error' => 36,
			'IDENTIFIER' => 35
		},
		GOTOS => {
			'simple_declarators' => 384,
			'simple_declarator' => 329
		}
	},
	{#State 363
		DEFAULT => -249
	},
	{#State 364
		ACTIONS => {
			")" => 385
		}
	},
	{#State 365
		DEFAULT => -242
	},
	{#State 366
		DEFAULT => -247
	},
	{#State 367
		ACTIONS => {
			'error' => 386,
			'STRING_LITERAL' => 235
		},
		GOTOS => {
			'string_literal' => 387,
			'string_literals' => 388
		}
	},
	{#State 368
		DEFAULT => -263
	},
	{#State 369
		ACTIONS => {
			"::" => 157
		},
		DEFAULT => -260
	},
	{#State 370
		ACTIONS => {
			")" => 389
		}
	},
	{#State 371
		ACTIONS => {
			")" => 390
		}
	},
	{#State 372
		ACTIONS => {
			"," => 391
		},
		DEFAULT => -258
	},
	{#State 373
		DEFAULT => -276
	},
	{#State 374
		DEFAULT => -277
	},
	{#State 375
		DEFAULT => -202
	},
	{#State 376
		DEFAULT => -203
	},
	{#State 377
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 230,
			'CHARACTER_LITERAL' => 212,
			'WIDE_CHARACTER_LITERAL' => 213,
			"::" => 83,
			'INTEGER_LITERAL' => 233,
			"(" => 217,
			'IDENTIFIER' => 89,
			'STRING_LITERAL' => 235,
			'FIXED_PT_LITERAL' => 236,
			"+" => 237,
			'error' => 393,
			"-" => 239,
			'WIDE_STRING_LITERAL' => 225,
			'FALSE' => 224,
			"~" => 240,
			'TRUE' => 227
		},
		GOTOS => {
			'mult_expr' => 234,
			'string_literal' => 229,
			'boolean_literal' => 218,
			'primary_expr' => 231,
			'const_exp' => 392,
			'and_expr' => 232,
			'or_expr' => 220,
			'unary_expr' => 238,
			'scoped_name' => 214,
			'xor_expr' => 222,
			'shift_expr' => 223,
			'wide_string_literal' => 216,
			'literal' => 226,
			'unary_operator' => 241,
			'add_expr' => 228
		}
	},
	{#State 378
		ACTIONS => {
			'CASE' => 377,
			'DEFAULT' => 379
		},
		DEFAULT => -181,
		GOTOS => {
			'case_labels' => 382,
			'switch_body' => 394,
			'case' => 378,
			'case_label' => 383
		}
	},
	{#State 379
		ACTIONS => {
			'error' => 395,
			":" => 396
		}
	},
	{#State 380
		ACTIONS => {
			"}" => 397
		}
	},
	{#State 381
		ACTIONS => {
			"}" => 398
		}
	},
	{#State 382
		ACTIONS => {
			'CHAR' => 74,
			'OBJECT' => 75,
			'FIXED' => 49,
			'VOID' => 76,
			'SEQUENCE' => 51,
			'STRUCT' => 6,
			'DOUBLE' => 80,
			'LONG' => 81,
			'STRING' => 82,
			"::" => 83,
			'WSTRING' => 85,
			'UNSIGNED' => 60,
			'SHORT' => 62,
			'BOOLEAN' => 87,
			'IDENTIFIER' => 89,
			'UNION' => 17,
			'WCHAR' => 63,
			'FLOAT' => 71,
			'OCTET' => 69,
			'ENUM' => 29,
			'ANY' => 73
		},
		GOTOS => {
			'unsigned_int' => 47,
			'floating_pt_type' => 48,
			'signed_int' => 50,
			'char_type' => 52,
			'object_type' => 53,
			'octet_type' => 54,
			'scoped_name' => 55,
			'wide_char_type' => 56,
			'signed_long_int' => 57,
			'type_spec' => 399,
			'string_type' => 61,
			'struct_header' => 13,
			'element_spec' => 400,
			'unsigned_longlong_int' => 64,
			'any_type' => 65,
			'base_type_spec' => 66,
			'enum_type' => 67,
			'enum_header' => 21,
			'union_header' => 25,
			'unsigned_short_int' => 70,
			'signed_longlong_int' => 72,
			'wide_string_type' => 77,
			'boolean_type' => 79,
			'integer_type' => 78,
			'signed_short_int' => 84,
			'struct_type' => 86,
			'union_type' => 88,
			'sequence_type' => 90,
			'unsigned_long_int' => 91,
			'template_type_spec' => 92,
			'constr_type_spec' => 93,
			'simple_type_spec' => 94,
			'fixed_pt_type' => 95
		}
	},
	{#State 383
		ACTIONS => {
			'CASE' => 377,
			'DEFAULT' => 379
		},
		DEFAULT => -184,
		GOTOS => {
			'case_labels' => 401,
			'case_label' => 383
		}
	},
	{#State 384
		DEFAULT => -223
	},
	{#State 385
		DEFAULT => -241
	},
	{#State 386
		ACTIONS => {
			")" => 402
		}
	},
	{#State 387
		ACTIONS => {
			"," => 403
		},
		DEFAULT => -265
	},
	{#State 388
		ACTIONS => {
			")" => 404
		}
	},
	{#State 389
		DEFAULT => -255
	},
	{#State 390
		DEFAULT => -254
	},
	{#State 391
		ACTIONS => {
			'IDENTIFIER' => 89,
			"::" => 83
		},
		GOTOS => {
			'scoped_name' => 369,
			'exception_names' => 405,
			'exception_name' => 372
		}
	},
	{#State 392
		ACTIONS => {
			'error' => 406,
			":" => 407
		}
	},
	{#State 393
		DEFAULT => -188
	},
	{#State 394
		DEFAULT => -182
	},
	{#State 395
		DEFAULT => -190
	},
	{#State 396
		DEFAULT => -189
	},
	{#State 397
		DEFAULT => -170
	},
	{#State 398
		DEFAULT => -169
	},
	{#State 399
		ACTIONS => {
			'error' => 36,
			'IDENTIFIER' => 163
		},
		GOTOS => {
			'declarator' => 408,
			'simple_declarator' => 161,
			'array_declarator' => 162,
			'complex_declarator' => 160
		}
	},
	{#State 400
		ACTIONS => {
			'error' => 33,
			";" => 32
		},
		GOTOS => {
			'check_semicolon' => 409
		}
	},
	{#State 401
		DEFAULT => -185
	},
	{#State 402
		DEFAULT => -262
	},
	{#State 403
		ACTIONS => {
			'STRING_LITERAL' => 235
		},
		GOTOS => {
			'string_literal' => 387,
			'string_literals' => 410
		}
	},
	{#State 404
		DEFAULT => -261
	},
	{#State 405
		DEFAULT => -259
	},
	{#State 406
		DEFAULT => -187
	},
	{#State 407
		DEFAULT => -186
	},
	{#State 408
		DEFAULT => -191
	},
	{#State 409
		DEFAULT => -183
	},
	{#State 410
		DEFAULT => -266
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'specification', 1,
sub
#line 60 "parser22.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 0,
sub
#line 66 "parser22.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 70 "parser22.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 77 "parser22.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 81 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 6
		 'definition', 2, undef
	],
	[#Rule 7
		 'definition', 2, undef
	],
	[#Rule 8
		 'definition', 2, undef
	],
	[#Rule 9
		 'definition', 2, undef
	],
	[#Rule 10
		 'definition', 2, undef
	],
	[#Rule 11
		 'definition', 3,
sub
#line 100 "parser22.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 12
		 'check_semicolon', 1, undef
	],
	[#Rule 13
		 'check_semicolon', 1,
sub
#line 114 "parser22.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 14
		 'module', 4,
sub
#line 123 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 15
		 'module', 4,
sub
#line 130 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 16
		 'module', 3,
sub
#line 136 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 17
		 'module', 3,
sub
#line 142 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module_header', 2,
sub
#line 151 "parser22.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 157 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'interface', 1, undef
	],
	[#Rule 21
		 'interface', 1, undef
	],
	[#Rule 22
		 'interface_dcl', 3,
sub
#line 174 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 23
		 'interface_dcl', 4,
sub
#line 182 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 190 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 25
		 'forward_dcl', 2,
sub
#line 201 "parser22.yp"
{
			new ForwardRegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 207 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 27
		 'interface_header', 3,
sub
#line 216 "parser22.yp"
{
			new RegularInterface($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3]
			);
		}
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 223 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 29
		 'interface_body', 1, undef
	],
	[#Rule 30
		 'exports', 1,
sub
#line 237 "parser22.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 31
		 'exports', 2,
sub
#line 241 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 32
		 'export', 2, undef
	],
	[#Rule 33
		 'export', 2, undef
	],
	[#Rule 34
		 'export', 2, undef
	],
	[#Rule 35
		 'export', 2, undef
	],
	[#Rule 36
		 'export', 2, undef
	],
	[#Rule 37
		 'interface_inheritance_spec', 2,
sub
#line 264 "parser22.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 38
		 'interface_inheritance_spec', 2,
sub
#line 270 "parser22.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 39
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 40
		 'interface_names', 1,
sub
#line 280 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 41
		 'interface_names', 3,
sub
#line 284 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 42
		 'interface_name', 1,
sub
#line 292 "parser22.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 43
		 'scoped_name', 1, undef
	],
	[#Rule 44
		 'scoped_name', 2,
sub
#line 302 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 45
		 'scoped_name', 2,
sub
#line 306 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 46
		 'scoped_name', 3,
sub
#line 312 "parser22.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 47
		 'scoped_name', 3,
sub
#line 316 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 48
		 'const_dcl', 5,
sub
#line 326 "parser22.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 49
		 'const_dcl', 5,
sub
#line 334 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 50
		 'const_dcl', 4,
sub
#line 339 "parser22.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 51
		 'const_dcl', 3,
sub
#line 344 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 52
		 'const_dcl', 2,
sub
#line 349 "parser22.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 53
		 'const_type', 1, undef
	],
	[#Rule 54
		 'const_type', 1, undef
	],
	[#Rule 55
		 'const_type', 1, undef
	],
	[#Rule 56
		 'const_type', 1, undef
	],
	[#Rule 57
		 'const_type', 1, undef
	],
	[#Rule 58
		 'const_type', 1, undef
	],
	[#Rule 59
		 'const_type', 1, undef
	],
	[#Rule 60
		 'const_type', 1, undef
	],
	[#Rule 61
		 'const_type', 1,
sub
#line 374 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 62
		 'const_exp', 1, undef
	],
	[#Rule 63
		 'or_expr', 1, undef
	],
	[#Rule 64
		 'or_expr', 3,
sub
#line 390 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 65
		 'xor_expr', 1, undef
	],
	[#Rule 66
		 'xor_expr', 3,
sub
#line 400 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 67
		 'and_expr', 1, undef
	],
	[#Rule 68
		 'and_expr', 3,
sub
#line 410 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 69
		 'shift_expr', 1, undef
	],
	[#Rule 70
		 'shift_expr', 3,
sub
#line 420 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 71
		 'shift_expr', 3,
sub
#line 424 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 72
		 'add_expr', 1, undef
	],
	[#Rule 73
		 'add_expr', 3,
sub
#line 434 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 74
		 'add_expr', 3,
sub
#line 438 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 75
		 'mult_expr', 1, undef
	],
	[#Rule 76
		 'mult_expr', 3,
sub
#line 448 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 77
		 'mult_expr', 3,
sub
#line 452 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 78
		 'mult_expr', 3,
sub
#line 456 "parser22.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 79
		 'unary_expr', 2,
sub
#line 464 "parser22.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 80
		 'unary_expr', 1, undef
	],
	[#Rule 81
		 'unary_operator', 1, undef
	],
	[#Rule 82
		 'unary_operator', 1, undef
	],
	[#Rule 83
		 'unary_operator', 1, undef
	],
	[#Rule 84
		 'primary_expr', 1,
sub
#line 484 "parser22.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 85
		 'primary_expr', 1,
sub
#line 490 "parser22.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 86
		 'primary_expr', 3,
sub
#line 494 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 87
		 'primary_expr', 3,
sub
#line 498 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 88
		 'literal', 1,
sub
#line 507 "parser22.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 89
		 'literal', 1,
sub
#line 514 "parser22.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 90
		 'literal', 1,
sub
#line 520 "parser22.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 91
		 'literal', 1,
sub
#line 526 "parser22.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 92
		 'literal', 1,
sub
#line 532 "parser22.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 93
		 'literal', 1,
sub
#line 538 "parser22.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 94
		 'literal', 1,
sub
#line 545 "parser22.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 95
		 'literal', 1, undef
	],
	[#Rule 96
		 'string_literal', 1, undef
	],
	[#Rule 97
		 'string_literal', 2,
sub
#line 559 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 98
		 'wide_string_literal', 1, undef
	],
	[#Rule 99
		 'wide_string_literal', 2,
sub
#line 568 "parser22.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 100
		 'boolean_literal', 1,
sub
#line 576 "parser22.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 101
		 'boolean_literal', 1,
sub
#line 582 "parser22.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 102
		 'positive_int_const', 1,
sub
#line 592 "parser22.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 103
		 'type_dcl', 2,
sub
#line 602 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 104
		 'type_dcl', 1, undef
	],
	[#Rule 105
		 'type_dcl', 1, undef
	],
	[#Rule 106
		 'type_dcl', 1, undef
	],
	[#Rule 107
		 'type_dcl', 2,
sub
#line 612 "parser22.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 108
		 'type_dcl', 2,
sub
#line 619 "parser22.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 109
		 'type_declarator', 2,
sub
#line 628 "parser22.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 110
		 'type_spec', 1, undef
	],
	[#Rule 111
		 'type_spec', 1, undef
	],
	[#Rule 112
		 'simple_type_spec', 1, undef
	],
	[#Rule 113
		 'simple_type_spec', 1, undef
	],
	[#Rule 114
		 'simple_type_spec', 1,
sub
#line 651 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 115
		 'simple_type_spec', 1,
sub
#line 655 "parser22.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 116
		 'base_type_spec', 1, undef
	],
	[#Rule 117
		 'base_type_spec', 1, undef
	],
	[#Rule 118
		 'base_type_spec', 1, undef
	],
	[#Rule 119
		 'base_type_spec', 1, undef
	],
	[#Rule 120
		 'base_type_spec', 1, undef
	],
	[#Rule 121
		 'base_type_spec', 1, undef
	],
	[#Rule 122
		 'base_type_spec', 1, undef
	],
	[#Rule 123
		 'base_type_spec', 1, undef
	],
	[#Rule 124
		 'template_type_spec', 1, undef
	],
	[#Rule 125
		 'template_type_spec', 1, undef
	],
	[#Rule 126
		 'template_type_spec', 1, undef
	],
	[#Rule 127
		 'template_type_spec', 1, undef
	],
	[#Rule 128
		 'constr_type_spec', 1, undef
	],
	[#Rule 129
		 'constr_type_spec', 1, undef
	],
	[#Rule 130
		 'constr_type_spec', 1, undef
	],
	[#Rule 131
		 'declarators', 1,
sub
#line 708 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 132
		 'declarators', 3,
sub
#line 712 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 133
		 'declarator', 1,
sub
#line 721 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 134
		 'declarator', 1, undef
	],
	[#Rule 135
		 'simple_declarator', 1, undef
	],
	[#Rule 136
		 'simple_declarator', 2,
sub
#line 733 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 137
		 'simple_declarator', 2,
sub
#line 738 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 138
		 'complex_declarator', 1, undef
	],
	[#Rule 139
		 'floating_pt_type', 1,
sub
#line 753 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 140
		 'floating_pt_type', 1,
sub
#line 759 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 141
		 'floating_pt_type', 2,
sub
#line 765 "parser22.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 142
		 'integer_type', 1, undef
	],
	[#Rule 143
		 'integer_type', 1, undef
	],
	[#Rule 144
		 'signed_int', 1, undef
	],
	[#Rule 145
		 'signed_int', 1, undef
	],
	[#Rule 146
		 'signed_int', 1, undef
	],
	[#Rule 147
		 'signed_short_int', 1,
sub
#line 793 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 148
		 'signed_long_int', 1,
sub
#line 803 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 149
		 'signed_longlong_int', 2,
sub
#line 813 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 150
		 'unsigned_int', 1, undef
	],
	[#Rule 151
		 'unsigned_int', 1, undef
	],
	[#Rule 152
		 'unsigned_int', 1, undef
	],
	[#Rule 153
		 'unsigned_short_int', 2,
sub
#line 833 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 154
		 'unsigned_long_int', 2,
sub
#line 843 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 155
		 'unsigned_longlong_int', 3,
sub
#line 853 "parser22.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 156
		 'char_type', 1,
sub
#line 863 "parser22.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 157
		 'wide_char_type', 1,
sub
#line 873 "parser22.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 158
		 'boolean_type', 1,
sub
#line 883 "parser22.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 159
		 'octet_type', 1,
sub
#line 893 "parser22.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'any_type', 1,
sub
#line 903 "parser22.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'object_type', 1,
sub
#line 913 "parser22.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'struct_type', 4,
sub
#line 923 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 163
		 'struct_type', 4,
sub
#line 930 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 164
		 'struct_header', 2,
sub
#line 939 "parser22.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 165
		 'struct_header', 2,
sub
#line 945 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 166
		 'member_list', 1,
sub
#line 954 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 167
		 'member_list', 2,
sub
#line 958 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 168
		 'member', 3,
sub
#line 967 "parser22.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 169
		 'union_type', 8,
sub
#line 978 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 170
		 'union_type', 8,
sub
#line 986 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 171
		 'union_type', 6,
sub
#line 992 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 172
		 'union_type', 5,
sub
#line 998 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 173
		 'union_type', 3,
sub
#line 1004 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 174
		 'union_header', 2,
sub
#line 1013 "parser22.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 175
		 'union_header', 2,
sub
#line 1019 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 176
		 'switch_type_spec', 1, undef
	],
	[#Rule 177
		 'switch_type_spec', 1, undef
	],
	[#Rule 178
		 'switch_type_spec', 1, undef
	],
	[#Rule 179
		 'switch_type_spec', 1, undef
	],
	[#Rule 180
		 'switch_type_spec', 1,
sub
#line 1036 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 181
		 'switch_body', 1,
sub
#line 1044 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 182
		 'switch_body', 2,
sub
#line 1048 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 183
		 'case', 3,
sub
#line 1057 "parser22.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 184
		 'case_labels', 1,
sub
#line 1067 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 185
		 'case_labels', 2,
sub
#line 1071 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 186
		 'case_label', 3,
sub
#line 1080 "parser22.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 187
		 'case_label', 3,
sub
#line 1084 "parser22.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 188
		 'case_label', 2,
sub
#line 1090 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 189
		 'case_label', 2,
sub
#line 1095 "parser22.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 190
		 'case_label', 2,
sub
#line 1099 "parser22.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 191
		 'element_spec', 2,
sub
#line 1109 "parser22.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 192
		 'enum_type', 4,
sub
#line 1120 "parser22.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 193
		 'enum_type', 4,
sub
#line 1126 "parser22.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 194
		 'enum_type', 2,
sub
#line 1131 "parser22.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 195
		 'enum_header', 2,
sub
#line 1139 "parser22.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 196
		 'enum_header', 2,
sub
#line 1145 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 197
		 'enumerators', 1,
sub
#line 1153 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 198
		 'enumerators', 3,
sub
#line 1157 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 199
		 'enumerators', 2,
sub
#line 1162 "parser22.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 200
		 'enumerators', 2,
sub
#line 1167 "parser22.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 201
		 'enumerator', 1,
sub
#line 1176 "parser22.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 202
		 'sequence_type', 6,
sub
#line 1186 "parser22.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 203
		 'sequence_type', 6,
sub
#line 1194 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 204
		 'sequence_type', 4,
sub
#line 1199 "parser22.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 205
		 'sequence_type', 4,
sub
#line 1206 "parser22.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 206
		 'sequence_type', 2,
sub
#line 1211 "parser22.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 207
		 'string_type', 4,
sub
#line 1220 "parser22.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 208
		 'string_type', 1,
sub
#line 1227 "parser22.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 209
		 'string_type', 4,
sub
#line 1233 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 210
		 'wide_string_type', 4,
sub
#line 1242 "parser22.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 211
		 'wide_string_type', 1,
sub
#line 1249 "parser22.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 212
		 'wide_string_type', 4,
sub
#line 1255 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 213
		 'array_declarator', 2,
sub
#line 1264 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 214
		 'fixed_array_sizes', 1,
sub
#line 1272 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 215
		 'fixed_array_sizes', 2,
sub
#line 1276 "parser22.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 216
		 'fixed_array_size', 3,
sub
#line 1285 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 217
		 'fixed_array_size', 3,
sub
#line 1289 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 218
		 'attr_dcl', 4,
sub
#line 1298 "parser22.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 219
		 'attr_dcl', 3,
sub
#line 1306 "parser22.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 220
		 'attr_mod', 1, undef
	],
	[#Rule 221
		 'attr_mod', 0, undef
	],
	[#Rule 222
		 'simple_declarators', 1,
sub
#line 1321 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 223
		 'simple_declarators', 3,
sub
#line 1325 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 224
		 'except_dcl', 3,
sub
#line 1334 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 225
		 'except_dcl', 4,
sub
#line 1339 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 226
		 'except_dcl', 4,
sub
#line 1346 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 227
		 'except_dcl', 2,
sub
#line 1352 "parser22.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 228
		 'exception_header', 2,
sub
#line 1361 "parser22.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 229
		 'exception_header', 2,
sub
#line 1367 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 230
		 'op_dcl', 4,
sub
#line 1376 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3],
					'list_context'	=>	$_[4]
			) if (defined $_[1]);
		}
	],
	[#Rule 231
		 'op_dcl', 2,
sub
#line 1386 "parser22.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 232
		 'op_header', 3,
sub
#line 1396 "parser22.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 233
		 'op_header', 3,
sub
#line 1404 "parser22.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 234
		 'op_mod', 1, undef
	],
	[#Rule 235
		 'op_mod', 0, undef
	],
	[#Rule 236
		 'op_attribute', 1, undef
	],
	[#Rule 237
		 'op_type_spec', 1, undef
	],
	[#Rule 238
		 'op_type_spec', 1,
sub
#line 1428 "parser22.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 239
		 'op_type_spec', 1,
sub
#line 1434 "parser22.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 240
		 'parameter_dcls', 3,
sub
#line 1443 "parser22.yp"
{
			$_[2];
		}
	],
	[#Rule 241
		 'parameter_dcls', 5,
sub
#line 1447 "parser22.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 242
		 'parameter_dcls', 4,
sub
#line 1452 "parser22.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 243
		 'parameter_dcls', 2,
sub
#line 1457 "parser22.yp"
{
			undef;
		}
	],
	[#Rule 244
		 'parameter_dcls', 3,
sub
#line 1461 "parser22.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 245
		 'parameter_dcls', 3,
sub
#line 1466 "parser22.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 246
		 'param_dcls', 1,
sub
#line 1474 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 247
		 'param_dcls', 3,
sub
#line 1478 "parser22.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 248
		 'param_dcls', 2,
sub
#line 1483 "parser22.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 249
		 'param_dcl', 3,
sub
#line 1492 "parser22.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 250
		 'param_attribute', 1, undef
	],
	[#Rule 251
		 'param_attribute', 1, undef
	],
	[#Rule 252
		 'param_attribute', 1, undef
	],
	[#Rule 253
		 'param_attribute', 0,
sub
#line 1510 "parser22.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 254
		 'raises_expr', 4,
sub
#line 1519 "parser22.yp"
{
			$_[3];
		}
	],
	[#Rule 255
		 'raises_expr', 4,
sub
#line 1523 "parser22.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 256
		 'raises_expr', 2,
sub
#line 1528 "parser22.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 257
		 'raises_expr', 0, undef
	],
	[#Rule 258
		 'exception_names', 1,
sub
#line 1538 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 259
		 'exception_names', 3,
sub
#line 1542 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 260
		 'exception_name', 1,
sub
#line 1550 "parser22.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 261
		 'context_expr', 4,
sub
#line 1558 "parser22.yp"
{
			$_[3];
		}
	],
	[#Rule 262
		 'context_expr', 4,
sub
#line 1562 "parser22.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 263
		 'context_expr', 2,
sub
#line 1567 "parser22.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 264
		 'context_expr', 0, undef
	],
	[#Rule 265
		 'string_literals', 1,
sub
#line 1577 "parser22.yp"
{
			[$_[1]];
		}
	],
	[#Rule 266
		 'string_literals', 3,
sub
#line 1581 "parser22.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 267
		 'param_type_spec', 1, undef
	],
	[#Rule 268
		 'param_type_spec', 1,
sub
#line 1592 "parser22.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 269
		 'param_type_spec', 1,
sub
#line 1597 "parser22.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 270
		 'param_type_spec', 1,
sub
#line 1602 "parser22.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 271
		 'op_param_type_spec', 1, undef
	],
	[#Rule 272
		 'op_param_type_spec', 1, undef
	],
	[#Rule 273
		 'op_param_type_spec', 1, undef
	],
	[#Rule 274
		 'op_param_type_spec', 1, undef
	],
	[#Rule 275
		 'op_param_type_spec', 1,
sub
#line 1618 "parser22.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 276
		 'fixed_pt_type', 6,
sub
#line 1626 "parser22.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 277
		 'fixed_pt_type', 6,
sub
#line 1634 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'fixed_pt_type', 4,
sub
#line 1639 "parser22.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'fixed_pt_type', 2,
sub
#line 1644 "parser22.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 280
		 'fixed_pt_const_type', 1,
sub
#line 1653 "parser22.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1660 "parser22.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '2.2';

use CORBA::IDL::symbtab;
use CORBA::IDL::node;

require CORBA::IDL::lexer;

sub BuildUnop
{
	my($op,$expr) = @_;

	my $node = new UnaryOp($_[0],	'op'	=>	$op);
	push(@$expr,$node);
	return $expr;
}

sub BuildBinop
{
	my($left,$op,$right) = @_;

	my $node = new BinaryOp($_[0],	'op'	=>	$op);
	push(@$left,@$right);
	push(@$left,$node);
	return $left;
}


1;
