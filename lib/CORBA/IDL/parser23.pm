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
			'INTERFACE' => -29,
			'ENUM' => 30,
			'VALUETYPE' => -76,
			'CUSTOM' => 3,
			'UNION' => 34,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'error' => 36,
			'EXCEPTION' => 15,
			'IDENTIFIER' => 22,
			'MODULE' => 38,
			'STRUCT' => 24,
			'CONST' => 39,
			'ABSTRACT' => 26
		},
		GOTOS => {
			'union_type' => 1,
			'value_dcl' => 2,
			'value_box_dcl' => 4,
			'enum_header' => 5,
			'definitions' => 31,
			'module_header' => 33,
			'definition' => 32,
			'struct_type' => 6,
			'union_header' => 7,
			'value_box_header' => 8,
			'specification' => 35,
			'except_dcl' => 9,
			'value_header' => 11,
			'interface_mod' => 14,
			'struct_header' => 12,
			'interface' => 16,
			'type_dcl' => 17,
			'module' => 37,
			'interface_header' => 19,
			'value_forward_dcl' => 18,
			'value_mod' => 20,
			'enum_type' => 21,
			'value' => 23,
			'value_abs_dcl' => 40,
			'value_abs_header' => 25,
			'forward_dcl' => 41,
			'exception_header' => 27,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 1
		DEFAULT => -166
	},
	{#State 2
		DEFAULT => -54
	},
	{#State 3
		DEFAULT => -75
	},
	{#State 4
		DEFAULT => -56
	},
	{#State 5
		ACTIONS => {
			"{" => 43,
			'error' => 42
		}
	},
	{#State 6
		DEFAULT => -165
	},
	{#State 7
		ACTIONS => {
			'SWITCH' => 44
		}
	},
	{#State 8
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 61,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'template_type_spec' => 55,
			'unsigned_long_int' => 57,
			'scoped_name' => 58,
			'string_type' => 59,
			'char_type' => 60,
			'fixed_pt_type' => 64,
			'signed_long_int' => 62,
			'signed_short_int' => 63,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 68,
			'object_type' => 71,
			'type_spec' => 72,
			'integer_type' => 73,
			'unsigned_int' => 75,
			'sequence_type' => 76,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 80,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 87,
			'signed_int' => 89,
			'simple_type_spec' => 90,
			'boolean_type' => 92
		}
	},
	{#State 9
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 94
		}
	},
	{#State 10
		ACTIONS => {
			'IDENTIFIER' => 98,
			'error' => 99
		},
		GOTOS => {
			'simple_declarator' => 97
		}
	},
	{#State 11
		ACTIONS => {
			"{" => 100
		}
	},
	{#State 12
		ACTIONS => {
			"{" => 101
		}
	},
	{#State 13
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'error' => 104,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 61,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'type_declarator' => 102,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'template_type_spec' => 55,
			'unsigned_long_int' => 57,
			'scoped_name' => 58,
			'string_type' => 59,
			'char_type' => 60,
			'fixed_pt_type' => 64,
			'signed_short_int' => 63,
			'signed_long_int' => 62,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 68,
			'object_type' => 71,
			'type_spec' => 103,
			'integer_type' => 73,
			'unsigned_int' => 75,
			'sequence_type' => 76,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 80,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 87,
			'signed_int' => 89,
			'simple_type_spec' => 90,
			'boolean_type' => 92
		}
	},
	{#State 14
		ACTIONS => {
			'INTERFACE' => 105
		}
	},
	{#State 15
		ACTIONS => {
			'IDENTIFIER' => 106,
			'error' => 107
		}
	},
	{#State 16
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 108
		}
	},
	{#State 17
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 109
		}
	},
	{#State 18
		DEFAULT => -57
	},
	{#State 19
		ACTIONS => {
			"{" => 110
		}
	},
	{#State 20
		ACTIONS => {
			'VALUETYPE' => 111
		}
	},
	{#State 21
		DEFAULT => -167
	},
	{#State 22
		ACTIONS => {
			'error' => 112
		}
	},
	{#State 23
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 113
		}
	},
	{#State 24
		ACTIONS => {
			'IDENTIFIER' => 114,
			'error' => 115
		}
	},
	{#State 25
		ACTIONS => {
			"{" => 116
		}
	},
	{#State 26
		ACTIONS => {
			'INTERFACE' => -28,
			'VALUETYPE' => 117,
			'error' => 118
		}
	},
	{#State 27
		ACTIONS => {
			"{" => 120,
			'error' => 119
		}
	},
	{#State 28
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 121
		}
	},
	{#State 29
		DEFAULT => -21
	},
	{#State 30
		ACTIONS => {
			'IDENTIFIER' => 122,
			'error' => 123
		}
	},
	{#State 31
		DEFAULT => -1
	},
	{#State 32
		ACTIONS => {
			'INTERFACE' => -29,
			'ENUM' => 30,
			'VALUETYPE' => -76,
			'CUSTOM' => 3,
			'UNION' => 34,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'IDENTIFIER' => 22,
			'MODULE' => 38,
			'STRUCT' => 24,
			'CONST' => 39,
			'ABSTRACT' => 26
		},
		DEFAULT => -4,
		GOTOS => {
			'union_type' => 1,
			'value_dcl' => 2,
			'value_box_dcl' => 4,
			'enum_header' => 5,
			'definitions' => 124,
			'definition' => 32,
			'module_header' => 33,
			'struct_type' => 6,
			'union_header' => 7,
			'value_box_header' => 8,
			'except_dcl' => 9,
			'value_header' => 11,
			'interface_mod' => 14,
			'struct_header' => 12,
			'interface' => 16,
			'type_dcl' => 17,
			'module' => 37,
			'interface_header' => 19,
			'value_forward_dcl' => 18,
			'value_mod' => 20,
			'enum_type' => 21,
			'value' => 23,
			'value_abs_dcl' => 40,
			'value_abs_header' => 25,
			'forward_dcl' => 41,
			'exception_header' => 27,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 33
		ACTIONS => {
			"{" => 126,
			'error' => 125
		}
	},
	{#State 34
		ACTIONS => {
			'IDENTIFIER' => 127,
			'error' => 128
		}
	},
	{#State 35
		ACTIONS => {
			'' => 129
		}
	},
	{#State 36
		DEFAULT => -3
	},
	{#State 37
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 130
		}
	},
	{#State 38
		ACTIONS => {
			'IDENTIFIER' => 131,
			'error' => 132
		}
	},
	{#State 39
		ACTIONS => {
			'DOUBLE' => 85,
			"::" => 69,
			'IDENTIFIER' => 56,
			'SHORT' => 86,
			'CHAR' => 70,
			'BOOLEAN' => 88,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNSIGNED' => 49,
			'FIXED' => 144,
			'error' => 141,
			'FLOAT' => 82,
			'LONG' => 51,
			'WCHAR' => 66
		},
		GOTOS => {
			'wide_string_type' => 138,
			'integer_type' => 139,
			'unsigned_int' => 75,
			'unsigned_short_int' => 46,
			'unsigned_longlong_int' => 78,
			'floating_pt_type' => 140,
			'const_type' => 142,
			'signed_longlong_int' => 52,
			'unsigned_long_int' => 57,
			'scoped_name' => 133,
			'string_type' => 134,
			'signed_int' => 89,
			'fixed_pt_const_type' => 143,
			'char_type' => 135,
			'signed_short_int' => 63,
			'signed_long_int' => 62,
			'boolean_type' => 145,
			'wide_char_type' => 136,
			'octet_type' => 137
		}
	},
	{#State 40
		DEFAULT => -55
	},
	{#State 41
		DEFAULT => -22
	},
	{#State 42
		DEFAULT => -256
	},
	{#State 43
		ACTIONS => {
			'IDENTIFIER' => 146,
			'error' => 148
		},
		GOTOS => {
			'enumerators' => 149,
			'enumerator' => 147
		}
	},
	{#State 44
		ACTIONS => {
			"(" => 150,
			'error' => 151
		}
	},
	{#State 45
		DEFAULT => -191
	},
	{#State 46
		DEFAULT => -212
	},
	{#State 47
		DEFAULT => -221
	},
	{#State 48
		DEFAULT => -190
	},
	{#State 49
		ACTIONS => {
			'SHORT' => 153,
			'LONG' => 152
		}
	},
	{#State 50
		DEFAULT => -222
	},
	{#State 51
		ACTIONS => {
			'DOUBLE' => 155,
			'LONG' => 154
		},
		DEFAULT => -210
	},
	{#State 52
		DEFAULT => -208
	},
	{#State 53
		DEFAULT => -192
	},
	{#State 54
		DEFAULT => -183
	},
	{#State 55
		DEFAULT => -174
	},
	{#State 56
		DEFAULT => -49
	},
	{#State 57
		DEFAULT => -213
	},
	{#State 58
		ACTIONS => {
			"::" => 156
		},
		DEFAULT => -175
	},
	{#State 59
		DEFAULT => -187
	},
	{#State 60
		DEFAULT => -179
	},
	{#State 61
		DEFAULT => -176
	},
	{#State 62
		DEFAULT => -207
	},
	{#State 63
		DEFAULT => -206
	},
	{#State 64
		DEFAULT => -189
	},
	{#State 65
		DEFAULT => -180
	},
	{#State 66
		DEFAULT => -219
	},
	{#State 67
		DEFAULT => -182
	},
	{#State 68
		DEFAULT => -188
	},
	{#State 69
		ACTIONS => {
			'IDENTIFIER' => 157,
			'error' => 158
		}
	},
	{#State 70
		DEFAULT => -218
	},
	{#State 71
		DEFAULT => -184
	},
	{#State 72
		DEFAULT => -60
	},
	{#State 73
		DEFAULT => -178
	},
	{#State 74
		DEFAULT => -223
	},
	{#State 75
		DEFAULT => -205
	},
	{#State 76
		DEFAULT => -186
	},
	{#State 77
		ACTIONS => {
			"<" => 159
		},
		DEFAULT => -270
	},
	{#State 78
		DEFAULT => -214
	},
	{#State 79
		ACTIONS => {
			"<" => 160
		},
		DEFAULT => -273
	},
	{#State 80
		DEFAULT => -172
	},
	{#State 81
		DEFAULT => -177
	},
	{#State 82
		DEFAULT => -201
	},
	{#State 83
		DEFAULT => -185
	},
	{#State 84
		ACTIONS => {
			"<" => 161,
			'error' => 162
		}
	},
	{#State 85
		DEFAULT => -202
	},
	{#State 86
		DEFAULT => -209
	},
	{#State 87
		DEFAULT => -173
	},
	{#State 88
		DEFAULT => -220
	},
	{#State 89
		DEFAULT => -204
	},
	{#State 90
		DEFAULT => -171
	},
	{#State 91
		ACTIONS => {
			"<" => 163,
			'error' => 164
		}
	},
	{#State 92
		DEFAULT => -181
	},
	{#State 93
		DEFAULT => -344
	},
	{#State 94
		DEFAULT => -8
	},
	{#State 95
		DEFAULT => -13
	},
	{#State 96
		DEFAULT => -14
	},
	{#State 97
		DEFAULT => -168
	},
	{#State 98
		DEFAULT => -197
	},
	{#State 99
		ACTIONS => {
			";" => 165,
			"," => 166
		}
	},
	{#State 100
		ACTIONS => {
			"}" => 167,
			'OCTET' => -297,
			'NATIVE' => 10,
			'UNSIGNED' => -297,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'ANY' => -297,
			'LONG' => -297,
			'IDENTIFIER' => -297,
			'STRUCT' => 24,
			'VOID' => -297,
			'WCHAR' => -297,
			'ENUM' => 30,
			'FACTORY' => 177,
			"::" => -297,
			'PRIVATE' => 179,
			'CHAR' => -297,
			'OBJECT' => -297,
			'ONEWAY' => 182,
			'STRING' => -297,
			'WSTRING' => -297,
			'UNION' => 34,
			'error' => 184,
			'FLOAT' => -297,
			'ATTRIBUTE' => -283,
			'PUBLIC' => 187,
			'SEQUENCE' => -297,
			'DOUBLE' => -297,
			'SHORT' => -297,
			'BOOLEAN' => -297,
			'CONST' => 39,
			'READONLY' => 188,
			'FIXED' => -297,
			'VALUEBASE' => -297
		},
		GOTOS => {
			'op_header' => 176,
			'union_type' => 1,
			'attr_mod' => 168,
			'init_header_param' => 178,
			'init_header' => 180,
			'enum_header' => 5,
			'op_dcl' => 181,
			'attr_dcl' => 183,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 169,
			'struct_header' => 12,
			'state_member' => 185,
			'type_dcl' => 171,
			'export' => 170,
			'state_mod' => 186,
			'enum_type' => 21,
			'op_attribute' => 172,
			'op_mod' => 173,
			'value_elements' => 189,
			'value_element' => 174,
			'exception_header' => 27,
			'const_dcl' => 175,
			'init_dcl' => 190
		}
	},
	{#State 101
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'error' => 194,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 61,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'member_list' => 191,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'template_type_spec' => 55,
			'member' => 192,
			'unsigned_long_int' => 57,
			'scoped_name' => 58,
			'string_type' => 59,
			'char_type' => 60,
			'fixed_pt_type' => 64,
			'signed_short_int' => 63,
			'signed_long_int' => 62,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 68,
			'object_type' => 71,
			'type_spec' => 193,
			'integer_type' => 73,
			'unsigned_int' => 75,
			'sequence_type' => 76,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 80,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 87,
			'signed_int' => 89,
			'simple_type_spec' => 90,
			'boolean_type' => 92
		}
	},
	{#State 102
		DEFAULT => -164
	},
	{#State 103
		ACTIONS => {
			'IDENTIFIER' => 196,
			'error' => 99
		},
		GOTOS => {
			'declarators' => 198,
			'array_declarator' => 199,
			'simple_declarator' => 195,
			'declarator' => 197,
			'complex_declarator' => 200
		}
	},
	{#State 104
		DEFAULT => -169
	},
	{#State 105
		ACTIONS => {
			'IDENTIFIER' => 201,
			'error' => 202
		}
	},
	{#State 106
		DEFAULT => -290
	},
	{#State 107
		DEFAULT => -291
	},
	{#State 108
		DEFAULT => -9
	},
	{#State 109
		DEFAULT => -6
	},
	{#State 110
		ACTIONS => {
			"}" => 203,
			'OCTET' => -297,
			'NATIVE' => 10,
			'UNSIGNED' => -297,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'ANY' => -297,
			'LONG' => -297,
			'IDENTIFIER' => -297,
			'STRUCT' => 24,
			'VOID' => -297,
			'WCHAR' => -297,
			'ENUM' => 30,
			'FACTORY' => 177,
			"::" => -297,
			'PRIVATE' => 179,
			'CHAR' => -297,
			'OBJECT' => -297,
			'ONEWAY' => 182,
			'STRING' => -297,
			'WSTRING' => -297,
			'UNION' => 34,
			'error' => 208,
			'FLOAT' => -297,
			'ATTRIBUTE' => -283,
			'PUBLIC' => 187,
			'SEQUENCE' => -297,
			'DOUBLE' => -297,
			'SHORT' => -297,
			'BOOLEAN' => -297,
			'CONST' => 39,
			'READONLY' => 188,
			'FIXED' => -297,
			'VALUEBASE' => -297
		},
		GOTOS => {
			'op_header' => 176,
			'union_type' => 1,
			'interface_body' => 206,
			'attr_mod' => 168,
			'init_header_param' => 178,
			'init_header' => 180,
			'enum_header' => 5,
			'op_dcl' => 181,
			'exports' => 207,
			'attr_dcl' => 183,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 169,
			'struct_header' => 12,
			'state_member' => 209,
			'export' => 204,
			'type_dcl' => 171,
			'state_mod' => 186,
			'enum_type' => 21,
			'op_attribute' => 172,
			'op_mod' => 173,
			'_export' => 205,
			'exception_header' => 27,
			'const_dcl' => 175,
			'init_dcl' => 210
		}
	},
	{#State 111
		ACTIONS => {
			'IDENTIFIER' => 211,
			'error' => 212
		}
	},
	{#State 112
		ACTIONS => {
			";" => 213
		}
	},
	{#State 113
		DEFAULT => -11
	},
	{#State 114
		DEFAULT => -226
	},
	{#State 115
		DEFAULT => -227
	},
	{#State 116
		ACTIONS => {
			"}" => 214,
			'OCTET' => -297,
			'NATIVE' => 10,
			'UNSIGNED' => -297,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'ANY' => -297,
			'LONG' => -297,
			'IDENTIFIER' => -297,
			'STRUCT' => 24,
			'VOID' => -297,
			'WCHAR' => -297,
			'ENUM' => 30,
			'FACTORY' => 177,
			"::" => -297,
			'PRIVATE' => 179,
			'CHAR' => -297,
			'OBJECT' => -297,
			'ONEWAY' => 182,
			'STRING' => -297,
			'WSTRING' => -297,
			'UNION' => 34,
			'error' => 216,
			'FLOAT' => -297,
			'ATTRIBUTE' => -283,
			'PUBLIC' => 187,
			'SEQUENCE' => -297,
			'DOUBLE' => -297,
			'SHORT' => -297,
			'BOOLEAN' => -297,
			'CONST' => 39,
			'READONLY' => 188,
			'FIXED' => -297,
			'VALUEBASE' => -297
		},
		GOTOS => {
			'op_header' => 176,
			'union_type' => 1,
			'attr_mod' => 168,
			'init_header_param' => 178,
			'init_header' => 180,
			'enum_header' => 5,
			'op_dcl' => 181,
			'exports' => 215,
			'attr_dcl' => 183,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 169,
			'struct_header' => 12,
			'state_member' => 209,
			'export' => 204,
			'type_dcl' => 171,
			'state_mod' => 186,
			'enum_type' => 21,
			'op_attribute' => 172,
			'op_mod' => 173,
			'_export' => 205,
			'exception_header' => 27,
			'const_dcl' => 175,
			'init_dcl' => 210
		}
	},
	{#State 117
		ACTIONS => {
			'IDENTIFIER' => 217,
			'error' => 218
		}
	},
	{#State 118
		DEFAULT => -67
	},
	{#State 119
		DEFAULT => -289
	},
	{#State 120
		ACTIONS => {
			"}" => 219,
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'error' => 221,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'DOUBLE' => 85,
			'IDENTIFIER' => 56,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 61,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'member_list' => 220,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'template_type_spec' => 55,
			'member' => 192,
			'unsigned_long_int' => 57,
			'scoped_name' => 58,
			'string_type' => 59,
			'char_type' => 60,
			'fixed_pt_type' => 64,
			'signed_short_int' => 63,
			'signed_long_int' => 62,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 68,
			'object_type' => 71,
			'type_spec' => 193,
			'integer_type' => 73,
			'unsigned_int' => 75,
			'sequence_type' => 76,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 80,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 87,
			'signed_int' => 89,
			'simple_type_spec' => 90,
			'boolean_type' => 92
		}
	},
	{#State 121
		DEFAULT => -7
	},
	{#State 122
		DEFAULT => -257
	},
	{#State 123
		DEFAULT => -258
	},
	{#State 124
		DEFAULT => -5
	},
	{#State 125
		ACTIONS => {
			"}" => 222
		}
	},
	{#State 126
		ACTIONS => {
			"}" => 223,
			'INTERFACE' => -29,
			'ENUM' => 30,
			'VALUETYPE' => -76,
			'CUSTOM' => 3,
			'UNION' => 34,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'error' => 225,
			'EXCEPTION' => 15,
			'IDENTIFIER' => 22,
			'MODULE' => 38,
			'STRUCT' => 24,
			'CONST' => 39,
			'ABSTRACT' => 26
		},
		GOTOS => {
			'union_type' => 1,
			'value_dcl' => 2,
			'value_box_dcl' => 4,
			'enum_header' => 5,
			'definitions' => 224,
			'definition' => 32,
			'module_header' => 33,
			'struct_type' => 6,
			'union_header' => 7,
			'value_box_header' => 8,
			'except_dcl' => 9,
			'value_header' => 11,
			'interface_mod' => 14,
			'struct_header' => 12,
			'interface' => 16,
			'type_dcl' => 17,
			'module' => 37,
			'interface_header' => 19,
			'value_forward_dcl' => 18,
			'value_mod' => 20,
			'enum_type' => 21,
			'value' => 23,
			'value_abs_dcl' => 40,
			'value_abs_header' => 25,
			'forward_dcl' => 41,
			'exception_header' => 27,
			'const_dcl' => 28,
			'interface_dcl' => 29
		}
	},
	{#State 127
		DEFAULT => -236
	},
	{#State 128
		DEFAULT => -237
	},
	{#State 129
		DEFAULT => 0
	},
	{#State 130
		DEFAULT => -10
	},
	{#State 131
		DEFAULT => -19
	},
	{#State 132
		DEFAULT => -20
	},
	{#State 133
		ACTIONS => {
			"::" => 156
		},
		DEFAULT => -121
	},
	{#State 134
		DEFAULT => -118
	},
	{#State 135
		DEFAULT => -114
	},
	{#State 136
		DEFAULT => -115
	},
	{#State 137
		DEFAULT => -122
	},
	{#State 138
		DEFAULT => -119
	},
	{#State 139
		DEFAULT => -113
	},
	{#State 140
		DEFAULT => -117
	},
	{#State 141
		DEFAULT => -112
	},
	{#State 142
		ACTIONS => {
			'IDENTIFIER' => 226,
			'error' => 227
		}
	},
	{#State 143
		DEFAULT => -120
	},
	{#State 144
		DEFAULT => -343
	},
	{#State 145
		DEFAULT => -116
	},
	{#State 146
		DEFAULT => -263
	},
	{#State 147
		ACTIONS => {
			";" => 228,
			"," => 229
		},
		DEFAULT => -259
	},
	{#State 148
		ACTIONS => {
			"}" => 230
		}
	},
	{#State 149
		ACTIONS => {
			"}" => 231
		}
	},
	{#State 150
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'IDENTIFIER' => 56,
			'SHORT' => 86,
			'CHAR' => 70,
			'BOOLEAN' => 88,
			'UNSIGNED' => 49,
			'error' => 237,
			'LONG' => 232
		},
		GOTOS => {
			'signed_longlong_int' => 52,
			'enum_type' => 233,
			'integer_type' => 236,
			'unsigned_long_int' => 57,
			'unsigned_int' => 75,
			'scoped_name' => 234,
			'enum_header' => 5,
			'signed_int' => 89,
			'unsigned_short_int' => 46,
			'unsigned_longlong_int' => 78,
			'char_type' => 235,
			'signed_long_int' => 62,
			'signed_short_int' => 63,
			'boolean_type' => 239,
			'switch_type_spec' => 238
		}
	},
	{#State 151
		DEFAULT => -235
	},
	{#State 152
		ACTIONS => {
			'LONG' => 240
		},
		DEFAULT => -216
	},
	{#State 153
		DEFAULT => -215
	},
	{#State 154
		DEFAULT => -211
	},
	{#State 155
		DEFAULT => -203
	},
	{#State 156
		ACTIONS => {
			'IDENTIFIER' => 241,
			'error' => 242
		}
	},
	{#State 157
		DEFAULT => -50
	},
	{#State 158
		DEFAULT => -51
	},
	{#State 159
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 261,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'shift_expr' => 259,
			'literal' => 245,
			'const_exp' => 247,
			'unary_operator' => 248,
			'string_literal' => 249,
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'positive_int_const' => 268,
			'unary_expr' => 254,
			'primary_expr' => 269,
			'wide_string_literal' => 271,
			'xor_expr' => 272
		}
	},
	{#State 160
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 273,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'shift_expr' => 259,
			'literal' => 245,
			'const_exp' => 247,
			'unary_operator' => 248,
			'string_literal' => 249,
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'positive_int_const' => 274,
			'unary_expr' => 254,
			'primary_expr' => 269,
			'wide_string_literal' => 271,
			'xor_expr' => 272
		}
	},
	{#State 161
		ACTIONS => {
			"::" => 69,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNSIGNED' => 49,
			'error' => 275,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'VOID' => 61,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'wide_string_type' => 68,
			'object_type' => 71,
			'integer_type' => 73,
			'sequence_type' => 76,
			'unsigned_int' => 75,
			'unsigned_short_int' => 46,
			'unsigned_longlong_int' => 78,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'signed_longlong_int' => 52,
			'any_type' => 54,
			'template_type_spec' => 55,
			'base_type_spec' => 87,
			'unsigned_long_int' => 57,
			'scoped_name' => 58,
			'signed_int' => 89,
			'string_type' => 59,
			'simple_type_spec' => 276,
			'char_type' => 60,
			'signed_short_int' => 63,
			'signed_long_int' => 62,
			'fixed_pt_type' => 64,
			'boolean_type' => 92,
			'wide_char_type' => 65,
			'octet_type' => 67
		}
	},
	{#State 162
		DEFAULT => -268
	},
	{#State 163
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 277,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'shift_expr' => 259,
			'literal' => 245,
			'const_exp' => 247,
			'unary_operator' => 248,
			'string_literal' => 249,
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'positive_int_const' => 278,
			'unary_expr' => 254,
			'primary_expr' => 269,
			'wide_string_literal' => 271,
			'xor_expr' => 272
		}
	},
	{#State 164
		DEFAULT => -342
	},
	{#State 165
		DEFAULT => -199
	},
	{#State 166
		DEFAULT => -198
	},
	{#State 167
		DEFAULT => -68
	},
	{#State 168
		ACTIONS => {
			'ATTRIBUTE' => 279
		}
	},
	{#State 169
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 280
		}
	},
	{#State 170
		DEFAULT => -88
	},
	{#State 171
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 281
		}
	},
	{#State 172
		DEFAULT => -296
	},
	{#State 173
		ACTIONS => {
			"::" => 69,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNSIGNED' => 49,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'VOID' => 284,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'wide_string_type' => 286,
			'object_type' => 71,
			'integer_type' => 73,
			'unsigned_int' => 75,
			'sequence_type' => 287,
			'op_param_type_spec' => 288,
			'unsigned_short_int' => 46,
			'unsigned_longlong_int' => 78,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'signed_longlong_int' => 52,
			'any_type' => 54,
			'base_type_spec' => 289,
			'unsigned_long_int' => 57,
			'scoped_name' => 282,
			'signed_int' => 89,
			'string_type' => 283,
			'char_type' => 60,
			'signed_long_int' => 62,
			'fixed_pt_type' => 285,
			'signed_short_int' => 63,
			'op_type_spec' => 290,
			'boolean_type' => 92,
			'wide_char_type' => 65,
			'octet_type' => 67
		}
	},
	{#State 174
		ACTIONS => {
			"}" => -71,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'STRUCT' => 24,
			'ENUM' => 30,
			'FACTORY' => 177,
			'PRIVATE' => 179,
			'ONEWAY' => 182,
			'UNION' => 34,
			'ATTRIBUTE' => -283,
			'PUBLIC' => 187,
			'CONST' => 39,
			'READONLY' => 188
		},
		DEFAULT => -297,
		GOTOS => {
			'op_header' => 176,
			'union_type' => 1,
			'attr_mod' => 168,
			'init_header_param' => 178,
			'init_header' => 180,
			'enum_header' => 5,
			'op_dcl' => 181,
			'attr_dcl' => 183,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 169,
			'struct_header' => 12,
			'state_member' => 185,
			'type_dcl' => 171,
			'export' => 170,
			'state_mod' => 186,
			'enum_type' => 21,
			'op_attribute' => 172,
			'op_mod' => 173,
			'value_elements' => 291,
			'value_element' => 174,
			'exception_header' => 27,
			'const_dcl' => 175,
			'init_dcl' => 190
		}
	},
	{#State 175
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 292
		}
	},
	{#State 176
		ACTIONS => {
			"(" => 293,
			'error' => 294
		},
		GOTOS => {
			'parameter_dcls' => 295
		}
	},
	{#State 177
		ACTIONS => {
			'IDENTIFIER' => 296,
			'error' => 297
		}
	},
	{#State 178
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 298
		}
	},
	{#State 179
		DEFAULT => -95
	},
	{#State 180
		ACTIONS => {
			"(" => 299,
			'error' => 300
		}
	},
	{#State 181
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 301
		}
	},
	{#State 182
		DEFAULT => -298
	},
	{#State 183
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 302
		}
	},
	{#State 184
		ACTIONS => {
			"}" => 303
		}
	},
	{#State 185
		DEFAULT => -89
	},
	{#State 186
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'error' => 305,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 61,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'template_type_spec' => 55,
			'unsigned_long_int' => 57,
			'scoped_name' => 58,
			'string_type' => 59,
			'char_type' => 60,
			'fixed_pt_type' => 64,
			'signed_long_int' => 62,
			'signed_short_int' => 63,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 68,
			'object_type' => 71,
			'type_spec' => 304,
			'integer_type' => 73,
			'unsigned_int' => 75,
			'sequence_type' => 76,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 80,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 87,
			'signed_int' => 89,
			'simple_type_spec' => 90,
			'boolean_type' => 92
		}
	},
	{#State 187
		DEFAULT => -94
	},
	{#State 188
		DEFAULT => -282
	},
	{#State 189
		ACTIONS => {
			"}" => 306
		}
	},
	{#State 190
		DEFAULT => -90
	},
	{#State 191
		ACTIONS => {
			"}" => 307
		}
	},
	{#State 192
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'DOUBLE' => 85,
			'IDENTIFIER' => 56,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 61,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		DEFAULT => -228,
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'member_list' => 308,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'template_type_spec' => 55,
			'member' => 192,
			'unsigned_long_int' => 57,
			'scoped_name' => 58,
			'string_type' => 59,
			'char_type' => 60,
			'fixed_pt_type' => 64,
			'signed_short_int' => 63,
			'signed_long_int' => 62,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 68,
			'object_type' => 71,
			'type_spec' => 193,
			'integer_type' => 73,
			'unsigned_int' => 75,
			'sequence_type' => 76,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 80,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 87,
			'signed_int' => 89,
			'simple_type_spec' => 90,
			'boolean_type' => 92
		}
	},
	{#State 193
		ACTIONS => {
			'IDENTIFIER' => 196,
			'error' => 99
		},
		GOTOS => {
			'declarators' => 309,
			'array_declarator' => 199,
			'simple_declarator' => 195,
			'declarator' => 197,
			'complex_declarator' => 200
		}
	},
	{#State 194
		ACTIONS => {
			"}" => 310
		}
	},
	{#State 195
		DEFAULT => -195
	},
	{#State 196
		ACTIONS => {
			"[" => 312
		},
		DEFAULT => -197,
		GOTOS => {
			'fixed_array_sizes' => 311,
			'fixed_array_size' => 313
		}
	},
	{#State 197
		ACTIONS => {
			"," => 314
		},
		DEFAULT => -193
	},
	{#State 198
		DEFAULT => -170
	},
	{#State 199
		DEFAULT => -200
	},
	{#State 200
		DEFAULT => -196
	},
	{#State 201
		ACTIONS => {
			":" => 315,
			"{" => -45
		},
		DEFAULT => -26,
		GOTOS => {
			'interface_inheritance_spec' => 316
		}
	},
	{#State 202
		ACTIONS => {
			"{" => -31
		},
		DEFAULT => -27
	},
	{#State 203
		DEFAULT => -23
	},
	{#State 204
		DEFAULT => -35
	},
	{#State 205
		ACTIONS => {
			"}" => -33,
			'NATIVE' => 10,
			'TYPEDEF' => 13,
			'EXCEPTION' => 15,
			'STRUCT' => 24,
			'ENUM' => 30,
			'FACTORY' => 177,
			'PRIVATE' => 179,
			'ONEWAY' => 182,
			'UNION' => 34,
			'ATTRIBUTE' => -283,
			'PUBLIC' => 187,
			'CONST' => 39,
			'READONLY' => 188
		},
		DEFAULT => -297,
		GOTOS => {
			'op_header' => 176,
			'union_type' => 1,
			'attr_mod' => 168,
			'init_header_param' => 178,
			'init_header' => 180,
			'enum_header' => 5,
			'op_dcl' => 181,
			'exports' => 317,
			'attr_dcl' => 183,
			'struct_type' => 6,
			'union_header' => 7,
			'except_dcl' => 169,
			'struct_header' => 12,
			'state_member' => 209,
			'export' => 204,
			'type_dcl' => 171,
			'state_mod' => 186,
			'enum_type' => 21,
			'op_attribute' => 172,
			'op_mod' => 173,
			'_export' => 205,
			'exception_header' => 27,
			'const_dcl' => 175,
			'init_dcl' => 210
		}
	},
	{#State 206
		ACTIONS => {
			"}" => 318
		}
	},
	{#State 207
		DEFAULT => -32
	},
	{#State 208
		ACTIONS => {
			"}" => 319
		}
	},
	{#State 209
		DEFAULT => -36
	},
	{#State 210
		DEFAULT => -37
	},
	{#State 211
		ACTIONS => {
			":" => 320,
			'SUPPORTS' => 321,
			";" => -58,
			'error' => -58,
			"{" => -86
		},
		DEFAULT => -61,
		GOTOS => {
			'supported_interface_spec' => 323,
			'value_inheritance_spec' => 322
		}
	},
	{#State 212
		DEFAULT => -74
	},
	{#State 213
		DEFAULT => -12
	},
	{#State 214
		DEFAULT => -62
	},
	{#State 215
		ACTIONS => {
			"}" => 324
		}
	},
	{#State 216
		ACTIONS => {
			"}" => 325
		}
	},
	{#State 217
		ACTIONS => {
			":" => 320,
			'SUPPORTS' => 321,
			"{" => -86
		},
		DEFAULT => -59,
		GOTOS => {
			'supported_interface_spec' => 323,
			'value_inheritance_spec' => 326
		}
	},
	{#State 218
		DEFAULT => -66
	},
	{#State 219
		DEFAULT => -286
	},
	{#State 220
		ACTIONS => {
			"}" => 327
		}
	},
	{#State 221
		ACTIONS => {
			"}" => 328
		}
	},
	{#State 222
		DEFAULT => -18
	},
	{#State 223
		DEFAULT => -17
	},
	{#State 224
		ACTIONS => {
			"}" => 329
		}
	},
	{#State 225
		ACTIONS => {
			"}" => 330
		}
	},
	{#State 226
		ACTIONS => {
			'error' => 331,
			"=" => 332
		}
	},
	{#State 227
		DEFAULT => -111
	},
	{#State 228
		DEFAULT => -262
	},
	{#State 229
		ACTIONS => {
			'IDENTIFIER' => 146
		},
		DEFAULT => -261,
		GOTOS => {
			'enumerators' => 333,
			'enumerator' => 147
		}
	},
	{#State 230
		DEFAULT => -255
	},
	{#State 231
		DEFAULT => -254
	},
	{#State 232
		ACTIONS => {
			'LONG' => 154
		},
		DEFAULT => -210
	},
	{#State 233
		DEFAULT => -241
	},
	{#State 234
		ACTIONS => {
			"::" => 156
		},
		DEFAULT => -242
	},
	{#State 235
		DEFAULT => -239
	},
	{#State 236
		DEFAULT => -238
	},
	{#State 237
		ACTIONS => {
			")" => 334
		}
	},
	{#State 238
		ACTIONS => {
			")" => 335
		}
	},
	{#State 239
		DEFAULT => -240
	},
	{#State 240
		DEFAULT => -217
	},
	{#State 241
		DEFAULT => -52
	},
	{#State 242
		DEFAULT => -53
	},
	{#State 243
		DEFAULT => -142
	},
	{#State 244
		DEFAULT => -144
	},
	{#State 245
		DEFAULT => -146
	},
	{#State 246
		DEFAULT => -162
	},
	{#State 247
		DEFAULT => -163
	},
	{#State 248
		ACTIONS => {
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'literal' => 245,
			'primary_expr' => 336,
			'scoped_name' => 252,
			'wide_string_literal' => 271,
			'boolean_literal' => 265,
			'string_literal' => 249
		}
	},
	{#State 249
		DEFAULT => -150
	},
	{#State 250
		ACTIONS => {
			"&" => 337
		},
		DEFAULT => -126
	},
	{#State 251
		ACTIONS => {
			"|" => 338
		},
		DEFAULT => -123
	},
	{#State 252
		ACTIONS => {
			"::" => 156
		},
		DEFAULT => -145
	},
	{#State 253
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 340,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'shift_expr' => 259,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 254,
			'unary_operator' => 248,
			'const_exp' => 339,
			'xor_expr' => 272,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 254
		DEFAULT => -136
	},
	{#State 255
		DEFAULT => -153
	},
	{#State 256
		DEFAULT => -161
	},
	{#State 257
		DEFAULT => -143
	},
	{#State 258
		DEFAULT => -149
	},
	{#State 259
		ACTIONS => {
			"<<" => 342,
			">>" => 341
		},
		DEFAULT => -128
	},
	{#State 260
		DEFAULT => -155
	},
	{#State 261
		ACTIONS => {
			">" => 343
		}
	},
	{#State 262
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 262
		},
		DEFAULT => -159,
		GOTOS => {
			'wide_string_literal' => 344
		}
	},
	{#State 263
		DEFAULT => -152
	},
	{#State 264
		ACTIONS => {
			"%" => 345,
			"*" => 346,
			"/" => 347
		},
		DEFAULT => -133
	},
	{#State 265
		DEFAULT => -156
	},
	{#State 266
		ACTIONS => {
			"-" => 348,
			"+" => 349
		},
		DEFAULT => -130
	},
	{#State 267
		DEFAULT => -154
	},
	{#State 268
		ACTIONS => {
			">" => 350
		}
	},
	{#State 269
		DEFAULT => -141
	},
	{#State 270
		ACTIONS => {
			'STRING_LITERAL' => 270
		},
		DEFAULT => -157,
		GOTOS => {
			'string_literal' => 351
		}
	},
	{#State 271
		DEFAULT => -151
	},
	{#State 272
		ACTIONS => {
			"^" => 352
		},
		DEFAULT => -124
	},
	{#State 273
		ACTIONS => {
			">" => 353
		}
	},
	{#State 274
		ACTIONS => {
			">" => 354
		}
	},
	{#State 275
		ACTIONS => {
			">" => 355
		}
	},
	{#State 276
		ACTIONS => {
			"," => 357,
			">" => 356
		}
	},
	{#State 277
		ACTIONS => {
			">" => 358
		}
	},
	{#State 278
		ACTIONS => {
			"," => 359
		}
	},
	{#State 279
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'error' => 366,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 360,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'unsigned_long_int' => 57,
			'scoped_name' => 282,
			'string_type' => 283,
			'char_type' => 60,
			'param_type_spec' => 362,
			'fixed_pt_type' => 361,
			'signed_long_int' => 62,
			'signed_short_int' => 63,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 286,
			'object_type' => 71,
			'integer_type' => 73,
			'sequence_type' => 363,
			'unsigned_int' => 75,
			'op_param_type_spec' => 364,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 365,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 289,
			'signed_int' => 89,
			'boolean_type' => 92
		}
	},
	{#State 280
		DEFAULT => -40
	},
	{#State 281
		DEFAULT => -38
	},
	{#State 282
		ACTIONS => {
			"::" => 156
		},
		DEFAULT => -338
	},
	{#State 283
		DEFAULT => -336
	},
	{#State 284
		DEFAULT => -300
	},
	{#State 285
		DEFAULT => -302
	},
	{#State 286
		DEFAULT => -337
	},
	{#State 287
		DEFAULT => -301
	},
	{#State 288
		DEFAULT => -299
	},
	{#State 289
		DEFAULT => -335
	},
	{#State 290
		ACTIONS => {
			'IDENTIFIER' => 367,
			'error' => 368
		}
	},
	{#State 291
		DEFAULT => -72
	},
	{#State 292
		DEFAULT => -39
	},
	{#State 293
		ACTIONS => {
			'ENUM' => -316,
			"::" => -316,
			'CHAR' => -316,
			'OBJECT' => -316,
			'STRING' => -316,
			'OCTET' => -316,
			'WSTRING' => -316,
			'UNION' => -316,
			'UNSIGNED' => -316,
			'error' => 374,
			'ANY' => -316,
			'FLOAT' => -316,
			")" => 375,
			'LONG' => -316,
			'SEQUENCE' => -316,
			'IDENTIFIER' => -316,
			'DOUBLE' => -316,
			'SHORT' => -316,
			'BOOLEAN' => -316,
			'INOUT' => 370,
			"..." => 376,
			'STRUCT' => -316,
			'OUT' => 371,
			'IN' => 377,
			'VOID' => -316,
			'FIXED' => -316,
			'VALUEBASE' => -316,
			'WCHAR' => -316
		},
		GOTOS => {
			'param_attribute' => 369,
			'param_dcl' => 372,
			'param_dcls' => 373
		}
	},
	{#State 294
		DEFAULT => -293
	},
	{#State 295
		ACTIONS => {
			'RAISES' => 378
		},
		DEFAULT => -320,
		GOTOS => {
			'raises_expr' => 379
		}
	},
	{#State 296
		DEFAULT => -101
	},
	{#State 297
		DEFAULT => -102
	},
	{#State 298
		DEFAULT => -96
	},
	{#State 299
		ACTIONS => {
			'error' => 382,
			")" => 383,
			'IN' => 385
		},
		GOTOS => {
			'init_param_decl' => 381,
			'init_param_decls' => 384,
			'init_param_attribute' => 380
		}
	},
	{#State 300
		DEFAULT => -100
	},
	{#State 301
		DEFAULT => -42
	},
	{#State 302
		DEFAULT => -41
	},
	{#State 303
		DEFAULT => -70
	},
	{#State 304
		ACTIONS => {
			'IDENTIFIER' => 196,
			'error' => 386
		},
		GOTOS => {
			'declarators' => 387,
			'array_declarator' => 199,
			'simple_declarator' => 195,
			'declarator' => 197,
			'complex_declarator' => 200
		}
	},
	{#State 305
		ACTIONS => {
			";" => 388
		}
	},
	{#State 306
		DEFAULT => -69
	},
	{#State 307
		DEFAULT => -224
	},
	{#State 308
		DEFAULT => -229
	},
	{#State 309
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 389
		}
	},
	{#State 310
		DEFAULT => -225
	},
	{#State 311
		DEFAULT => -275
	},
	{#State 312
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 390,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'shift_expr' => 259,
			'literal' => 245,
			'const_exp' => 247,
			'unary_operator' => 248,
			'string_literal' => 249,
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'positive_int_const' => 391,
			'unary_expr' => 254,
			'primary_expr' => 269,
			'wide_string_literal' => 271,
			'xor_expr' => 272
		}
	},
	{#State 313
		ACTIONS => {
			"[" => 312
		},
		DEFAULT => -276,
		GOTOS => {
			'fixed_array_sizes' => 392,
			'fixed_array_size' => 313
		}
	},
	{#State 314
		ACTIONS => {
			'IDENTIFIER' => 196,
			'error' => 99
		},
		GOTOS => {
			'declarators' => 393,
			'array_declarator' => 199,
			'simple_declarator' => 195,
			'declarator' => 197,
			'complex_declarator' => 200
		}
	},
	{#State 315
		ACTIONS => {
			"::" => 69,
			'IDENTIFIER' => 56,
			'error' => 395
		},
		GOTOS => {
			'interface_name' => 397,
			'interface_names' => 396,
			'scoped_name' => 394
		}
	},
	{#State 316
		DEFAULT => -30
	},
	{#State 317
		DEFAULT => -34
	},
	{#State 318
		DEFAULT => -24
	},
	{#State 319
		DEFAULT => -25
	},
	{#State 320
		ACTIONS => {
			'TRUNCATABLE' => 399
		},
		DEFAULT => -81,
		GOTOS => {
			'inheritance_mod' => 398
		}
	},
	{#State 321
		ACTIONS => {
			"::" => 69,
			'IDENTIFIER' => 56,
			'error' => 400
		},
		GOTOS => {
			'interface_name' => 397,
			'interface_names' => 401,
			'scoped_name' => 394
		}
	},
	{#State 322
		DEFAULT => -73
	},
	{#State 323
		DEFAULT => -79
	},
	{#State 324
		DEFAULT => -63
	},
	{#State 325
		DEFAULT => -64
	},
	{#State 326
		DEFAULT => -65
	},
	{#State 327
		DEFAULT => -287
	},
	{#State 328
		DEFAULT => -288
	},
	{#State 329
		DEFAULT => -15
	},
	{#State 330
		DEFAULT => -16
	},
	{#State 331
		DEFAULT => -110
	},
	{#State 332
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 403,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'shift_expr' => 259,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 254,
			'unary_operator' => 248,
			'const_exp' => 402,
			'xor_expr' => 272,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 333
		DEFAULT => -260
	},
	{#State 334
		DEFAULT => -234
	},
	{#State 335
		ACTIONS => {
			"{" => 405,
			'error' => 404
		}
	},
	{#State 336
		DEFAULT => -140
	},
	{#State 337
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'mult_expr' => 264,
			'shift_expr' => 406,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 254,
			'unary_operator' => 248,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 338
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'and_expr' => 250,
			'mult_expr' => 264,
			'shift_expr' => 259,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 254,
			'unary_operator' => 248,
			'xor_expr' => 407,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 339
		ACTIONS => {
			")" => 408
		}
	},
	{#State 340
		ACTIONS => {
			")" => 409
		}
	},
	{#State 341
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'mult_expr' => 264,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'literal' => 245,
			'add_expr' => 410,
			'primary_expr' => 269,
			'unary_expr' => 254,
			'unary_operator' => 248,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 342
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'mult_expr' => 264,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'literal' => 245,
			'add_expr' => 411,
			'primary_expr' => 269,
			'unary_expr' => 254,
			'unary_operator' => 248,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 343
		DEFAULT => -271
	},
	{#State 344
		DEFAULT => -160
	},
	{#State 345
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 412,
			'unary_operator' => 248,
			'scoped_name' => 252,
			'wide_string_literal' => 271,
			'boolean_literal' => 265,
			'string_literal' => 249
		}
	},
	{#State 346
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 413,
			'unary_operator' => 248,
			'scoped_name' => 252,
			'wide_string_literal' => 271,
			'boolean_literal' => 265,
			'string_literal' => 249
		}
	},
	{#State 347
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 414,
			'unary_operator' => 248,
			'scoped_name' => 252,
			'wide_string_literal' => 271,
			'boolean_literal' => 265,
			'string_literal' => 249
		}
	},
	{#State 348
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'mult_expr' => 415,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'literal' => 245,
			'unary_expr' => 254,
			'primary_expr' => 269,
			'unary_operator' => 248,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 349
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'mult_expr' => 416,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'literal' => 245,
			'unary_expr' => 254,
			'primary_expr' => 269,
			'unary_operator' => 248,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 350
		DEFAULT => -269
	},
	{#State 351
		DEFAULT => -158
	},
	{#State 352
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			'IDENTIFIER' => 56,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FIXED_PT_LITERAL' => 267,
			"(" => 253,
			'FALSE' => 246,
			'STRING_LITERAL' => 270,
			'WIDE_STRING_LITERAL' => 262,
			'WIDE_CHARACTER_LITERAL' => 255,
			'CHARACTER_LITERAL' => 263
		},
		GOTOS => {
			'and_expr' => 417,
			'mult_expr' => 264,
			'shift_expr' => 259,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 254,
			'unary_operator' => 248,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 353
		DEFAULT => -274
	},
	{#State 354
		DEFAULT => -272
	},
	{#State 355
		DEFAULT => -267
	},
	{#State 356
		DEFAULT => -266
	},
	{#State 357
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 418,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'shift_expr' => 259,
			'literal' => 245,
			'const_exp' => 247,
			'unary_operator' => 248,
			'string_literal' => 249,
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'positive_int_const' => 419,
			'unary_expr' => 254,
			'primary_expr' => 269,
			'wide_string_literal' => 271,
			'xor_expr' => 272
		}
	},
	{#State 358
		DEFAULT => -341
	},
	{#State 359
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 420,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'shift_expr' => 259,
			'literal' => 245,
			'const_exp' => 247,
			'unary_operator' => 248,
			'string_literal' => 249,
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'positive_int_const' => 421,
			'unary_expr' => 254,
			'primary_expr' => 269,
			'wide_string_literal' => 271,
			'xor_expr' => 272
		}
	},
	{#State 360
		DEFAULT => -331
	},
	{#State 361
		DEFAULT => -333
	},
	{#State 362
		ACTIONS => {
			'IDENTIFIER' => 98,
			'error' => 99
		},
		GOTOS => {
			'simple_declarators' => 423,
			'simple_declarator' => 422
		}
	},
	{#State 363
		DEFAULT => -332
	},
	{#State 364
		DEFAULT => -330
	},
	{#State 365
		DEFAULT => -334
	},
	{#State 366
		DEFAULT => -281
	},
	{#State 367
		DEFAULT => -294
	},
	{#State 368
		DEFAULT => -295
	},
	{#State 369
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 360,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'unsigned_long_int' => 57,
			'scoped_name' => 282,
			'string_type' => 283,
			'char_type' => 60,
			'param_type_spec' => 424,
			'fixed_pt_type' => 361,
			'signed_long_int' => 62,
			'signed_short_int' => 63,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 286,
			'object_type' => 71,
			'integer_type' => 73,
			'sequence_type' => 363,
			'unsigned_int' => 75,
			'op_param_type_spec' => 364,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 365,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 289,
			'signed_int' => 89,
			'boolean_type' => 92
		}
	},
	{#State 370
		DEFAULT => -315
	},
	{#State 371
		DEFAULT => -314
	},
	{#State 372
		ACTIONS => {
			";" => 425
		},
		DEFAULT => -309
	},
	{#State 373
		ACTIONS => {
			"," => 426,
			")" => 427
		}
	},
	{#State 374
		ACTIONS => {
			")" => 428
		}
	},
	{#State 375
		DEFAULT => -306
	},
	{#State 376
		ACTIONS => {
			")" => 429
		}
	},
	{#State 377
		DEFAULT => -313
	},
	{#State 378
		ACTIONS => {
			"(" => 430,
			'error' => 431
		}
	},
	{#State 379
		ACTIONS => {
			'CONTEXT' => 433
		},
		DEFAULT => -327,
		GOTOS => {
			'context_expr' => 432
		}
	},
	{#State 380
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'error' => 435,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 360,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'unsigned_long_int' => 57,
			'scoped_name' => 282,
			'string_type' => 283,
			'char_type' => 60,
			'param_type_spec' => 434,
			'fixed_pt_type' => 361,
			'signed_long_int' => 62,
			'signed_short_int' => 63,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 286,
			'object_type' => 71,
			'integer_type' => 73,
			'sequence_type' => 363,
			'unsigned_int' => 75,
			'op_param_type_spec' => 364,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 365,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 289,
			'signed_int' => 89,
			'boolean_type' => 92
		}
	},
	{#State 381
		ACTIONS => {
			"," => 436
		},
		DEFAULT => -103
	},
	{#State 382
		ACTIONS => {
			")" => 437
		}
	},
	{#State 383
		DEFAULT => -97
	},
	{#State 384
		ACTIONS => {
			")" => 438
		}
	},
	{#State 385
		DEFAULT => -107
	},
	{#State 386
		ACTIONS => {
			";" => 439,
			"," => 166
		}
	},
	{#State 387
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 440
		}
	},
	{#State 388
		DEFAULT => -93
	},
	{#State 389
		DEFAULT => -230
	},
	{#State 390
		ACTIONS => {
			"]" => 441
		}
	},
	{#State 391
		ACTIONS => {
			"]" => 442
		}
	},
	{#State 392
		DEFAULT => -277
	},
	{#State 393
		DEFAULT => -194
	},
	{#State 394
		ACTIONS => {
			"::" => 156
		},
		DEFAULT => -48
	},
	{#State 395
		DEFAULT => -44
	},
	{#State 396
		DEFAULT => -43
	},
	{#State 397
		ACTIONS => {
			"," => 443
		},
		DEFAULT => -46
	},
	{#State 398
		ACTIONS => {
			"::" => 69,
			'IDENTIFIER' => 56,
			'error' => 447
		},
		GOTOS => {
			'value_name' => 444,
			'value_names' => 445,
			'scoped_name' => 446
		}
	},
	{#State 399
		DEFAULT => -80
	},
	{#State 400
		DEFAULT => -85
	},
	{#State 401
		DEFAULT => -84
	},
	{#State 402
		DEFAULT => -108
	},
	{#State 403
		DEFAULT => -109
	},
	{#State 404
		DEFAULT => -233
	},
	{#State 405
		ACTIONS => {
			'DEFAULT' => 453,
			'error' => 451,
			'CASE' => 448
		},
		GOTOS => {
			'case_label' => 454,
			'switch_body' => 449,
			'case' => 450,
			'case_labels' => 452
		}
	},
	{#State 406
		ACTIONS => {
			"<<" => 342,
			">>" => 341
		},
		DEFAULT => -129
	},
	{#State 407
		ACTIONS => {
			"^" => 352
		},
		DEFAULT => -125
	},
	{#State 408
		DEFAULT => -147
	},
	{#State 409
		DEFAULT => -148
	},
	{#State 410
		ACTIONS => {
			"-" => 348,
			"+" => 349
		},
		DEFAULT => -131
	},
	{#State 411
		ACTIONS => {
			"-" => 348,
			"+" => 349
		},
		DEFAULT => -132
	},
	{#State 412
		DEFAULT => -139
	},
	{#State 413
		DEFAULT => -137
	},
	{#State 414
		DEFAULT => -138
	},
	{#State 415
		ACTIONS => {
			"%" => 345,
			"*" => 346,
			"/" => 347
		},
		DEFAULT => -135
	},
	{#State 416
		ACTIONS => {
			"%" => 345,
			"*" => 346,
			"/" => 347
		},
		DEFAULT => -134
	},
	{#State 417
		ACTIONS => {
			"&" => 337
		},
		DEFAULT => -127
	},
	{#State 418
		ACTIONS => {
			">" => 455
		}
	},
	{#State 419
		ACTIONS => {
			">" => 456
		}
	},
	{#State 420
		ACTIONS => {
			">" => 457
		}
	},
	{#State 421
		ACTIONS => {
			">" => 458
		}
	},
	{#State 422
		ACTIONS => {
			"," => 459
		},
		DEFAULT => -284
	},
	{#State 423
		DEFAULT => -280
	},
	{#State 424
		ACTIONS => {
			'IDENTIFIER' => 98,
			'error' => 99
		},
		GOTOS => {
			'simple_declarator' => 460
		}
	},
	{#State 425
		DEFAULT => -311
	},
	{#State 426
		ACTIONS => {
			")" => 462,
			'INOUT' => 370,
			"..." => 463,
			'OUT' => 371,
			'IN' => 377
		},
		DEFAULT => -316,
		GOTOS => {
			'param_attribute' => 369,
			'param_dcl' => 461
		}
	},
	{#State 427
		DEFAULT => -303
	},
	{#State 428
		DEFAULT => -308
	},
	{#State 429
		DEFAULT => -307
	},
	{#State 430
		ACTIONS => {
			"::" => 69,
			'IDENTIFIER' => 56,
			'error' => 465
		},
		GOTOS => {
			'exception_names' => 466,
			'scoped_name' => 464,
			'exception_name' => 467
		}
	},
	{#State 431
		DEFAULT => -319
	},
	{#State 432
		DEFAULT => -292
	},
	{#State 433
		ACTIONS => {
			"(" => 468,
			'error' => 469
		}
	},
	{#State 434
		ACTIONS => {
			'IDENTIFIER' => 98,
			'error' => 99
		},
		GOTOS => {
			'simple_declarator' => 470
		}
	},
	{#State 435
		DEFAULT => -106
	},
	{#State 436
		ACTIONS => {
			'IN' => 385
		},
		GOTOS => {
			'init_param_decl' => 381,
			'init_param_decls' => 471,
			'init_param_attribute' => 380
		}
	},
	{#State 437
		DEFAULT => -99
	},
	{#State 438
		DEFAULT => -98
	},
	{#State 439
		ACTIONS => {
			";" => -199,
			"," => -199,
			'error' => -199
		},
		DEFAULT => -92
	},
	{#State 440
		DEFAULT => -91
	},
	{#State 441
		DEFAULT => -279
	},
	{#State 442
		DEFAULT => -278
	},
	{#State 443
		ACTIONS => {
			"::" => 69,
			'IDENTIFIER' => 56
		},
		GOTOS => {
			'interface_name' => 397,
			'interface_names' => 472,
			'scoped_name' => 394
		}
	},
	{#State 444
		ACTIONS => {
			"," => 473
		},
		DEFAULT => -82
	},
	{#State 445
		ACTIONS => {
			'SUPPORTS' => 321
		},
		DEFAULT => -86,
		GOTOS => {
			'supported_interface_spec' => 474
		}
	},
	{#State 446
		ACTIONS => {
			"::" => 156
		},
		DEFAULT => -87
	},
	{#State 447
		DEFAULT => -78
	},
	{#State 448
		ACTIONS => {
			"-" => 243,
			"::" => 69,
			'TRUE' => 256,
			"+" => 257,
			"~" => 244,
			'INTEGER_LITERAL' => 258,
			'FLOATING_PT_LITERAL' => 260,
			'FALSE' => 246,
			'error' => 476,
			'WIDE_STRING_LITERAL' => 262,
			'CHARACTER_LITERAL' => 263,
			'IDENTIFIER' => 56,
			"(" => 253,
			'FIXED_PT_LITERAL' => 267,
			'STRING_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 255
		},
		GOTOS => {
			'and_expr' => 250,
			'or_expr' => 251,
			'mult_expr' => 264,
			'shift_expr' => 259,
			'scoped_name' => 252,
			'boolean_literal' => 265,
			'add_expr' => 266,
			'literal' => 245,
			'primary_expr' => 269,
			'unary_expr' => 254,
			'unary_operator' => 248,
			'const_exp' => 475,
			'xor_expr' => 272,
			'wide_string_literal' => 271,
			'string_literal' => 249
		}
	},
	{#State 449
		ACTIONS => {
			"}" => 477
		}
	},
	{#State 450
		ACTIONS => {
			'DEFAULT' => 453,
			'CASE' => 448
		},
		DEFAULT => -243,
		GOTOS => {
			'case_label' => 454,
			'switch_body' => 478,
			'case' => 450,
			'case_labels' => 452
		}
	},
	{#State 451
		ACTIONS => {
			"}" => 479
		}
	},
	{#State 452
		ACTIONS => {
			"::" => 69,
			'ENUM' => 30,
			'CHAR' => 70,
			'OBJECT' => 74,
			'STRING' => 77,
			'OCTET' => 47,
			'WSTRING' => 79,
			'UNION' => 34,
			'UNSIGNED' => 49,
			'ANY' => 50,
			'FLOAT' => 82,
			'LONG' => 51,
			'SEQUENCE' => 84,
			'IDENTIFIER' => 56,
			'DOUBLE' => 85,
			'SHORT' => 86,
			'BOOLEAN' => 88,
			'STRUCT' => 24,
			'VOID' => 61,
			'FIXED' => 91,
			'VALUEBASE' => 93,
			'WCHAR' => 66
		},
		GOTOS => {
			'union_type' => 45,
			'enum_header' => 5,
			'unsigned_short_int' => 46,
			'struct_type' => 48,
			'union_header' => 7,
			'struct_header' => 12,
			'signed_longlong_int' => 52,
			'enum_type' => 53,
			'any_type' => 54,
			'template_type_spec' => 55,
			'element_spec' => 480,
			'unsigned_long_int' => 57,
			'scoped_name' => 58,
			'string_type' => 59,
			'char_type' => 60,
			'fixed_pt_type' => 64,
			'signed_short_int' => 63,
			'signed_long_int' => 62,
			'wide_char_type' => 65,
			'octet_type' => 67,
			'wide_string_type' => 68,
			'object_type' => 71,
			'type_spec' => 481,
			'integer_type' => 73,
			'unsigned_int' => 75,
			'sequence_type' => 76,
			'unsigned_longlong_int' => 78,
			'constr_type_spec' => 80,
			'floating_pt_type' => 81,
			'value_base_type' => 83,
			'base_type_spec' => 87,
			'signed_int' => 89,
			'simple_type_spec' => 90,
			'boolean_type' => 92
		}
	},
	{#State 453
		ACTIONS => {
			":" => 482,
			'error' => 483
		}
	},
	{#State 454
		ACTIONS => {
			'CASE' => 448,
			'DEFAULT' => 453
		},
		DEFAULT => -246,
		GOTOS => {
			'case_label' => 454,
			'case_labels' => 484
		}
	},
	{#State 455
		DEFAULT => -265
	},
	{#State 456
		DEFAULT => -264
	},
	{#State 457
		DEFAULT => -340
	},
	{#State 458
		DEFAULT => -339
	},
	{#State 459
		ACTIONS => {
			'IDENTIFIER' => 98,
			'error' => 99
		},
		GOTOS => {
			'simple_declarators' => 485,
			'simple_declarator' => 422
		}
	},
	{#State 460
		DEFAULT => -312
	},
	{#State 461
		DEFAULT => -310
	},
	{#State 462
		DEFAULT => -305
	},
	{#State 463
		ACTIONS => {
			")" => 486
		}
	},
	{#State 464
		ACTIONS => {
			"::" => 156
		},
		DEFAULT => -323
	},
	{#State 465
		ACTIONS => {
			")" => 487
		}
	},
	{#State 466
		ACTIONS => {
			")" => 488
		}
	},
	{#State 467
		ACTIONS => {
			"," => 489
		},
		DEFAULT => -321
	},
	{#State 468
		ACTIONS => {
			'STRING_LITERAL' => 270,
			'error' => 492
		},
		GOTOS => {
			'string_literals' => 491,
			'string_literal' => 490
		}
	},
	{#State 469
		DEFAULT => -326
	},
	{#State 470
		DEFAULT => -105
	},
	{#State 471
		DEFAULT => -104
	},
	{#State 472
		DEFAULT => -47
	},
	{#State 473
		ACTIONS => {
			"::" => 69,
			'IDENTIFIER' => 56
		},
		GOTOS => {
			'value_name' => 444,
			'value_names' => 493,
			'scoped_name' => 446
		}
	},
	{#State 474
		DEFAULT => -77
	},
	{#State 475
		ACTIONS => {
			":" => 494,
			'error' => 495
		}
	},
	{#State 476
		DEFAULT => -250
	},
	{#State 477
		DEFAULT => -231
	},
	{#State 478
		DEFAULT => -244
	},
	{#State 479
		DEFAULT => -232
	},
	{#State 480
		ACTIONS => {
			";" => 95,
			'error' => 96
		},
		GOTOS => {
			'check_semicolon' => 496
		}
	},
	{#State 481
		ACTIONS => {
			'IDENTIFIER' => 196,
			'error' => 99
		},
		GOTOS => {
			'array_declarator' => 199,
			'simple_declarator' => 195,
			'declarator' => 497,
			'complex_declarator' => 200
		}
	},
	{#State 482
		DEFAULT => -251
	},
	{#State 483
		DEFAULT => -252
	},
	{#State 484
		DEFAULT => -247
	},
	{#State 485
		DEFAULT => -285
	},
	{#State 486
		DEFAULT => -304
	},
	{#State 487
		DEFAULT => -318
	},
	{#State 488
		DEFAULT => -317
	},
	{#State 489
		ACTIONS => {
			"::" => 69,
			'IDENTIFIER' => 56
		},
		GOTOS => {
			'exception_names' => 498,
			'scoped_name' => 464,
			'exception_name' => 467
		}
	},
	{#State 490
		ACTIONS => {
			"," => 499
		},
		DEFAULT => -328
	},
	{#State 491
		ACTIONS => {
			")" => 500
		}
	},
	{#State 492
		ACTIONS => {
			")" => 501
		}
	},
	{#State 493
		DEFAULT => -83
	},
	{#State 494
		DEFAULT => -248
	},
	{#State 495
		DEFAULT => -249
	},
	{#State 496
		DEFAULT => -245
	},
	{#State 497
		DEFAULT => -253
	},
	{#State 498
		DEFAULT => -322
	},
	{#State 499
		ACTIONS => {
			'STRING_LITERAL' => 270
		},
		GOTOS => {
			'string_literals' => 502,
			'string_literal' => 490
		}
	},
	{#State 500
		DEFAULT => -324
	},
	{#State 501
		DEFAULT => -325
	},
	{#State 502
		DEFAULT => -329
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
#line 69 "parser23.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 0,
sub
#line 75 "parser23.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 79 "parser23.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 86 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 90 "parser23.yp"
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
		 'definition', 2, undef
	],
	[#Rule 12
		 'definition', 3,
sub
#line 111 "parser23.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new CORBA::IDL::node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 13
		 'check_semicolon', 1, undef
	],
	[#Rule 14
		 'check_semicolon', 1,
sub
#line 125 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 15
		 'module', 4,
sub
#line 134 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 16
		 'module', 4,
sub
#line 141 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 17
		 'module', 3,
sub
#line 148 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 18
		 'module', 3,
sub
#line 155 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 165 "parser23.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 171 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'interface', 1, undef
	],
	[#Rule 22
		 'interface', 1, undef
	],
	[#Rule 23
		 'interface_dcl', 3,
sub
#line 188 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 196 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 204 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 26
		 'forward_dcl', 3,
sub
#line 216 "parser23.yp"
{
			if (defined $_[1] and $_[1] eq 'abstract') {
				new ForwardAbstractInterface($_[0],
						'idf'					=>	$_[3]
				);
			} else {
				new ForwardRegularInterface($_[0],
						'idf'					=>	$_[3]
				);
			}
		}
	],
	[#Rule 27
		 'forward_dcl', 3,
sub
#line 228 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface_mod', 1, undef
	],
	[#Rule 29
		 'interface_mod', 0, undef
	],
	[#Rule 30
		 'interface_header', 4,
sub
#line 244 "parser23.yp"
{
			if (defined $_[1] and $_[1] eq 'abstract') {
				new AbstractInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$_[4]
				);
			} else {
				new RegularInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$_[4]
				);
			}
		}
	],
	[#Rule 31
		 'interface_header', 3,
sub
#line 258 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 32
		 'interface_body', 1, undef
	],
	[#Rule 33
		 'exports', 1,
sub
#line 272 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 34
		 'exports', 2,
sub
#line 276 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 35
		 '_export', 1, undef
	],
	[#Rule 36
		 '_export', 1,
sub
#line 287 "parser23.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 37
		 '_export', 1,
sub
#line 292 "parser23.yp"
{
			$_[0]->Error("initializer unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 38
		 'export', 2, undef
	],
	[#Rule 39
		 'export', 2, undef
	],
	[#Rule 40
		 'export', 2, undef
	],
	[#Rule 41
		 'export', 2, undef
	],
	[#Rule 42
		 'export', 2, undef
	],
	[#Rule 43
		 'interface_inheritance_spec', 2,
sub
#line 314 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 320 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 45
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 46
		 'interface_names', 1,
sub
#line 330 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 47
		 'interface_names', 3,
sub
#line 334 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 48
		 'interface_name', 1,
sub
#line 343 "parser23.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 49
		 'scoped_name', 1, undef
	],
	[#Rule 50
		 'scoped_name', 2,
sub
#line 353 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 51
		 'scoped_name', 2,
sub
#line 357 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 52
		 'scoped_name', 3,
sub
#line 363 "parser23.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 53
		 'scoped_name', 3,
sub
#line 367 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 54
		 'value', 1, undef
	],
	[#Rule 55
		 'value', 1, undef
	],
	[#Rule 56
		 'value', 1, undef
	],
	[#Rule 57
		 'value', 1, undef
	],
	[#Rule 58
		 'value_forward_dcl', 3,
sub
#line 389 "parser23.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 59
		 'value_forward_dcl', 3,
sub
#line 397 "parser23.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 60
		 'value_box_dcl', 2,
sub
#line 407 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 61
		 'value_box_header', 3,
sub
#line 418 "parser23.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new BoxedValue($_[0],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 62
		 'value_abs_dcl', 3,
sub
#line 430 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 63
		 'value_abs_dcl', 4,
sub
#line 438 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 64
		 'value_abs_dcl', 4,
sub
#line 446 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 65
		 'value_abs_header', 4,
sub
#line 457 "parser23.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 66
		 'value_abs_header', 3,
sub
#line 464 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 67
		 'value_abs_header', 2,
sub
#line 469 "parser23.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 68
		 'value_dcl', 3,
sub
#line 478 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 69
		 'value_dcl', 4,
sub
#line 486 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 70
		 'value_dcl', 4,
sub
#line 494 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 71
		 'value_elements', 1,
sub
#line 505 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 72
		 'value_elements', 2,
sub
#line 509 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 73
		 'value_header', 4,
sub
#line 518 "parser23.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 74
		 'value_header', 3,
sub
#line 526 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 75
		 'value_mod', 1, undef
	],
	[#Rule 76
		 'value_mod', 0, undef
	],
	[#Rule 77
		 'value_inheritance_spec', 4,
sub
#line 542 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 78
		 'value_inheritance_spec', 3,
sub
#line 550 "parser23.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 79
		 'value_inheritance_spec', 1,
sub
#line 555 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 80
		 'inheritance_mod', 1, undef
	],
	[#Rule 81
		 'inheritance_mod', 0, undef
	],
	[#Rule 82
		 'value_names', 1,
sub
#line 571 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 83
		 'value_names', 3,
sub
#line 575 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 84
		 'supported_interface_spec', 2,
sub
#line 583 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 85
		 'supported_interface_spec', 2,
sub
#line 587 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 86
		 'supported_interface_spec', 0, undef
	],
	[#Rule 87
		 'value_name', 1,
sub
#line 598 "parser23.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 88
		 'value_element', 1, undef
	],
	[#Rule 89
		 'value_element', 1, undef
	],
	[#Rule 90
		 'value_element', 1, undef
	],
	[#Rule 91
		 'state_member', 4,
sub
#line 616 "parser23.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 92
		 'state_member', 4,
sub
#line 624 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 93
		 'state_member', 3,
sub
#line 629 "parser23.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 94
		 'state_mod', 1, undef
	],
	[#Rule 95
		 'state_mod', 1, undef
	],
	[#Rule 96
		 'init_dcl', 2, undef
	],
	[#Rule 97
		 'init_header_param', 3,
sub
#line 650 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 98
		 'init_header_param', 4,
sub
#line 656 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 99
		 'init_header_param', 4,
sub
#line 664 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 100
		 'init_header_param', 2,
sub
#line 672 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 101
		 'init_header', 2,
sub
#line 683 "parser23.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 102
		 'init_header', 2,
sub
#line 689 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 103
		 'init_param_decls', 1,
sub
#line 698 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 104
		 'init_param_decls', 3,
sub
#line 702 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 105
		 'init_param_decl', 3,
sub
#line 711 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 106
		 'init_param_decl', 2,
sub
#line 719 "parser23.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 107
		 'init_param_attribute', 1, undef
	],
	[#Rule 108
		 'const_dcl', 5,
sub
#line 734 "parser23.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 109
		 'const_dcl', 5,
sub
#line 742 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 110
		 'const_dcl', 4,
sub
#line 747 "parser23.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 111
		 'const_dcl', 3,
sub
#line 752 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'const_dcl', 2,
sub
#line 757 "parser23.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 113
		 'const_type', 1, undef
	],
	[#Rule 114
		 'const_type', 1, undef
	],
	[#Rule 115
		 'const_type', 1, undef
	],
	[#Rule 116
		 'const_type', 1, undef
	],
	[#Rule 117
		 'const_type', 1, undef
	],
	[#Rule 118
		 'const_type', 1, undef
	],
	[#Rule 119
		 'const_type', 1, undef
	],
	[#Rule 120
		 'const_type', 1, undef
	],
	[#Rule 121
		 'const_type', 1,
sub
#line 782 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 122
		 'const_type', 1, undef
	],
	[#Rule 123
		 'const_exp', 1, undef
	],
	[#Rule 124
		 'or_expr', 1, undef
	],
	[#Rule 125
		 'or_expr', 3,
sub
#line 800 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 126
		 'xor_expr', 1, undef
	],
	[#Rule 127
		 'xor_expr', 3,
sub
#line 810 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 128
		 'and_expr', 1, undef
	],
	[#Rule 129
		 'and_expr', 3,
sub
#line 820 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 130
		 'shift_expr', 1, undef
	],
	[#Rule 131
		 'shift_expr', 3,
sub
#line 830 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 132
		 'shift_expr', 3,
sub
#line 834 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 133
		 'add_expr', 1, undef
	],
	[#Rule 134
		 'add_expr', 3,
sub
#line 844 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 135
		 'add_expr', 3,
sub
#line 848 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 136
		 'mult_expr', 1, undef
	],
	[#Rule 137
		 'mult_expr', 3,
sub
#line 858 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 138
		 'mult_expr', 3,
sub
#line 862 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 139
		 'mult_expr', 3,
sub
#line 866 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 140
		 'unary_expr', 2,
sub
#line 874 "parser23.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 141
		 'unary_expr', 1, undef
	],
	[#Rule 142
		 'unary_operator', 1, undef
	],
	[#Rule 143
		 'unary_operator', 1, undef
	],
	[#Rule 144
		 'unary_operator', 1, undef
	],
	[#Rule 145
		 'primary_expr', 1,
sub
#line 894 "parser23.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 146
		 'primary_expr', 1,
sub
#line 900 "parser23.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 147
		 'primary_expr', 3,
sub
#line 904 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 148
		 'primary_expr', 3,
sub
#line 908 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 149
		 'literal', 1,
sub
#line 917 "parser23.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 150
		 'literal', 1,
sub
#line 924 "parser23.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 151
		 'literal', 1,
sub
#line 930 "parser23.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 152
		 'literal', 1,
sub
#line 936 "parser23.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 153
		 'literal', 1,
sub
#line 942 "parser23.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 154
		 'literal', 1,
sub
#line 948 "parser23.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 155
		 'literal', 1,
sub
#line 955 "parser23.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 156
		 'literal', 1, undef
	],
	[#Rule 157
		 'string_literal', 1, undef
	],
	[#Rule 158
		 'string_literal', 2,
sub
#line 969 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 159
		 'wide_string_literal', 1, undef
	],
	[#Rule 160
		 'wide_string_literal', 2,
sub
#line 978 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 161
		 'boolean_literal', 1,
sub
#line 986 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'boolean_literal', 1,
sub
#line 992 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'positive_int_const', 1,
sub
#line 1002 "parser23.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'type_dcl', 2,
sub
#line 1012 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 165
		 'type_dcl', 1, undef
	],
	[#Rule 166
		 'type_dcl', 1, undef
	],
	[#Rule 167
		 'type_dcl', 1, undef
	],
	[#Rule 168
		 'type_dcl', 2,
sub
#line 1022 "parser23.yp"
{
			new NativeType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 169
		 'type_dcl', 2,
sub
#line 1028 "parser23.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 170
		 'type_declarator', 2,
sub
#line 1037 "parser23.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 171
		 'type_spec', 1, undef
	],
	[#Rule 172
		 'type_spec', 1, undef
	],
	[#Rule 173
		 'simple_type_spec', 1, undef
	],
	[#Rule 174
		 'simple_type_spec', 1, undef
	],
	[#Rule 175
		 'simple_type_spec', 1,
sub
#line 1060 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 176
		 'simple_type_spec', 1,
sub
#line 1064 "parser23.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 177
		 'base_type_spec', 1, undef
	],
	[#Rule 178
		 'base_type_spec', 1, undef
	],
	[#Rule 179
		 'base_type_spec', 1, undef
	],
	[#Rule 180
		 'base_type_spec', 1, undef
	],
	[#Rule 181
		 'base_type_spec', 1, undef
	],
	[#Rule 182
		 'base_type_spec', 1, undef
	],
	[#Rule 183
		 'base_type_spec', 1, undef
	],
	[#Rule 184
		 'base_type_spec', 1, undef
	],
	[#Rule 185
		 'base_type_spec', 1, undef
	],
	[#Rule 186
		 'template_type_spec', 1, undef
	],
	[#Rule 187
		 'template_type_spec', 1, undef
	],
	[#Rule 188
		 'template_type_spec', 1, undef
	],
	[#Rule 189
		 'template_type_spec', 1, undef
	],
	[#Rule 190
		 'constr_type_spec', 1, undef
	],
	[#Rule 191
		 'constr_type_spec', 1, undef
	],
	[#Rule 192
		 'constr_type_spec', 1, undef
	],
	[#Rule 193
		 'declarators', 1,
sub
#line 1119 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 194
		 'declarators', 3,
sub
#line 1123 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 195
		 'declarator', 1,
sub
#line 1132 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 196
		 'declarator', 1, undef
	],
	[#Rule 197
		 'simple_declarator', 1, undef
	],
	[#Rule 198
		 'simple_declarator', 2,
sub
#line 1144 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 199
		 'simple_declarator', 2,
sub
#line 1149 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 200
		 'complex_declarator', 1, undef
	],
	[#Rule 201
		 'floating_pt_type', 1,
sub
#line 1164 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 202
		 'floating_pt_type', 1,
sub
#line 1170 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 203
		 'floating_pt_type', 2,
sub
#line 1176 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 204
		 'integer_type', 1, undef
	],
	[#Rule 205
		 'integer_type', 1, undef
	],
	[#Rule 206
		 'signed_int', 1, undef
	],
	[#Rule 207
		 'signed_int', 1, undef
	],
	[#Rule 208
		 'signed_int', 1, undef
	],
	[#Rule 209
		 'signed_short_int', 1,
sub
#line 1204 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 210
		 'signed_long_int', 1,
sub
#line 1214 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 211
		 'signed_longlong_int', 2,
sub
#line 1224 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 212
		 'unsigned_int', 1, undef
	],
	[#Rule 213
		 'unsigned_int', 1, undef
	],
	[#Rule 214
		 'unsigned_int', 1, undef
	],
	[#Rule 215
		 'unsigned_short_int', 2,
sub
#line 1244 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 216
		 'unsigned_long_int', 2,
sub
#line 1254 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 217
		 'unsigned_longlong_int', 3,
sub
#line 1264 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 218
		 'char_type', 1,
sub
#line 1274 "parser23.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 219
		 'wide_char_type', 1,
sub
#line 1284 "parser23.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 220
		 'boolean_type', 1,
sub
#line 1294 "parser23.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 221
		 'octet_type', 1,
sub
#line 1304 "parser23.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 222
		 'any_type', 1,
sub
#line 1314 "parser23.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 223
		 'object_type', 1,
sub
#line 1324 "parser23.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 224
		 'struct_type', 4,
sub
#line 1334 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 225
		 'struct_type', 4,
sub
#line 1341 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 226
		 'struct_header', 2,
sub
#line 1351 "parser23.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 227
		 'struct_header', 2,
sub
#line 1357 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 228
		 'member_list', 1,
sub
#line 1366 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 229
		 'member_list', 2,
sub
#line 1370 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 230
		 'member', 3,
sub
#line 1379 "parser23.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 231
		 'union_type', 8,
sub
#line 1390 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 232
		 'union_type', 8,
sub
#line 1398 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 233
		 'union_type', 6,
sub
#line 1405 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 234
		 'union_type', 5,
sub
#line 1412 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 235
		 'union_type', 3,
sub
#line 1419 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 236
		 'union_header', 2,
sub
#line 1429 "parser23.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 237
		 'union_header', 2,
sub
#line 1435 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 238
		 'switch_type_spec', 1, undef
	],
	[#Rule 239
		 'switch_type_spec', 1, undef
	],
	[#Rule 240
		 'switch_type_spec', 1, undef
	],
	[#Rule 241
		 'switch_type_spec', 1, undef
	],
	[#Rule 242
		 'switch_type_spec', 1,
sub
#line 1452 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 243
		 'switch_body', 1,
sub
#line 1460 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 244
		 'switch_body', 2,
sub
#line 1464 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 245
		 'case', 3,
sub
#line 1473 "parser23.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 246
		 'case_labels', 1,
sub
#line 1483 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 247
		 'case_labels', 2,
sub
#line 1487 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 248
		 'case_label', 3,
sub
#line 1496 "parser23.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 249
		 'case_label', 3,
sub
#line 1500 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 250
		 'case_label', 2,
sub
#line 1506 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 251
		 'case_label', 2,
sub
#line 1511 "parser23.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 252
		 'case_label', 2,
sub
#line 1515 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 253
		 'element_spec', 2,
sub
#line 1525 "parser23.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 254
		 'enum_type', 4,
sub
#line 1536 "parser23.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 255
		 'enum_type', 4,
sub
#line 1542 "parser23.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 256
		 'enum_type', 2,
sub
#line 1548 "parser23.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 257
		 'enum_header', 2,
sub
#line 1557 "parser23.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 258
		 'enum_header', 2,
sub
#line 1563 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 259
		 'enumerators', 1,
sub
#line 1571 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 260
		 'enumerators', 3,
sub
#line 1575 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 261
		 'enumerators', 2,
sub
#line 1580 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 262
		 'enumerators', 2,
sub
#line 1585 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 263
		 'enumerator', 1,
sub
#line 1594 "parser23.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 264
		 'sequence_type', 6,
sub
#line 1604 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 265
		 'sequence_type', 6,
sub
#line 1612 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'sequence_type', 4,
sub
#line 1617 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 267
		 'sequence_type', 4,
sub
#line 1624 "parser23.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'sequence_type', 2,
sub
#line 1629 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 269
		 'string_type', 4,
sub
#line 1638 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 270
		 'string_type', 1,
sub
#line 1645 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 271
		 'string_type', 4,
sub
#line 1651 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 272
		 'wide_string_type', 4,
sub
#line 1660 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 273
		 'wide_string_type', 1,
sub
#line 1667 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 274
		 'wide_string_type', 4,
sub
#line 1673 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 275
		 'array_declarator', 2,
sub
#line 1682 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 276
		 'fixed_array_sizes', 1,
sub
#line 1690 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 277
		 'fixed_array_sizes', 2,
sub
#line 1694 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 278
		 'fixed_array_size', 3,
sub
#line 1703 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 279
		 'fixed_array_size', 3,
sub
#line 1707 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 280
		 'attr_dcl', 4,
sub
#line 1716 "parser23.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 281
		 'attr_dcl', 3,
sub
#line 1724 "parser23.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 282
		 'attr_mod', 1, undef
	],
	[#Rule 283
		 'attr_mod', 0, undef
	],
	[#Rule 284
		 'simple_declarators', 1,
sub
#line 1739 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 285
		 'simple_declarators', 3,
sub
#line 1743 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 286
		 'except_dcl', 3,
sub
#line 1752 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 287
		 'except_dcl', 4,
sub
#line 1757 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 288
		 'except_dcl', 4,
sub
#line 1764 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 289
		 'except_dcl', 2,
sub
#line 1771 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 290
		 'exception_header', 2,
sub
#line 1781 "parser23.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 291
		 'exception_header', 2,
sub
#line 1787 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 292
		 'op_dcl', 4,
sub
#line 1796 "parser23.yp"
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
	[#Rule 293
		 'op_dcl', 2,
sub
#line 1806 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 294
		 'op_header', 3,
sub
#line 1817 "parser23.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 295
		 'op_header', 3,
sub
#line 1825 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 296
		 'op_mod', 1, undef
	],
	[#Rule 297
		 'op_mod', 0, undef
	],
	[#Rule 298
		 'op_attribute', 1, undef
	],
	[#Rule 299
		 'op_type_spec', 1, undef
	],
	[#Rule 300
		 'op_type_spec', 1,
sub
#line 1849 "parser23.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 301
		 'op_type_spec', 1,
sub
#line 1855 "parser23.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 302
		 'op_type_spec', 1,
sub
#line 1860 "parser23.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 303
		 'parameter_dcls', 3,
sub
#line 1869 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 304
		 'parameter_dcls', 5,
sub
#line 1873 "parser23.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 305
		 'parameter_dcls', 4,
sub
#line 1878 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 306
		 'parameter_dcls', 2,
sub
#line 1883 "parser23.yp"
{
			undef;
		}
	],
	[#Rule 307
		 'parameter_dcls', 3,
sub
#line 1887 "parser23.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 308
		 'parameter_dcls', 3,
sub
#line 1892 "parser23.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 309
		 'param_dcls', 1,
sub
#line 1900 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 310
		 'param_dcls', 3,
sub
#line 1904 "parser23.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 311
		 'param_dcls', 2,
sub
#line 1909 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 312
		 'param_dcl', 3,
sub
#line 1918 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 313
		 'param_attribute', 1, undef
	],
	[#Rule 314
		 'param_attribute', 1, undef
	],
	[#Rule 315
		 'param_attribute', 1, undef
	],
	[#Rule 316
		 'param_attribute', 0,
sub
#line 1936 "parser23.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 317
		 'raises_expr', 4,
sub
#line 1945 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 318
		 'raises_expr', 4,
sub
#line 1949 "parser23.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 319
		 'raises_expr', 2,
sub
#line 1954 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 320
		 'raises_expr', 0, undef
	],
	[#Rule 321
		 'exception_names', 1,
sub
#line 1964 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 322
		 'exception_names', 3,
sub
#line 1968 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 323
		 'exception_name', 1,
sub
#line 1976 "parser23.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 324
		 'context_expr', 4,
sub
#line 1984 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 325
		 'context_expr', 4,
sub
#line 1988 "parser23.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 326
		 'context_expr', 2,
sub
#line 1993 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 327
		 'context_expr', 0, undef
	],
	[#Rule 328
		 'string_literals', 1,
sub
#line 2003 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 329
		 'string_literals', 3,
sub
#line 2007 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 330
		 'param_type_spec', 1, undef
	],
	[#Rule 331
		 'param_type_spec', 1,
sub
#line 2018 "parser23.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 332
		 'param_type_spec', 1,
sub
#line 2023 "parser23.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 333
		 'param_type_spec', 1,
sub
#line 2028 "parser23.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 334
		 'param_type_spec', 1,
sub
#line 2033 "parser23.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 335
		 'op_param_type_spec', 1, undef
	],
	[#Rule 336
		 'op_param_type_spec', 1, undef
	],
	[#Rule 337
		 'op_param_type_spec', 1, undef
	],
	[#Rule 338
		 'op_param_type_spec', 1,
sub
#line 2047 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 339
		 'fixed_pt_type', 6,
sub
#line 2055 "parser23.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 340
		 'fixed_pt_type', 6,
sub
#line 2063 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 341
		 'fixed_pt_type', 4,
sub
#line 2068 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 342
		 'fixed_pt_type', 2,
sub
#line 2073 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 343
		 'fixed_pt_const_type', 1,
sub
#line 2082 "parser23.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 344
		 'value_base_type', 1,
sub
#line 2092 "parser23.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 2099 "parser23.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '2.3';

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
