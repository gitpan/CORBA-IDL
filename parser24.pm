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
			'NATIVE' => 31,
			'ABSTRACT' => 2,
			'STRUCT' => 33,
			'VALUETYPE' => -77,
			'TYPEDEF' => 36,
			'MODULE' => 11,
			'IDENTIFIER' => 38,
			'UNION' => 39,
			'error' => 17,
			'LOCAL' => 20,
			'CONST' => 21,
			'EXCEPTION' => 24,
			'CUSTOM' => 42,
			'ENUM' => 27,
			'INTERFACE' => -30
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 29,
			'interface_header' => 30,
			'except_dcl' => 3,
			'value_header' => 32,
			'specification' => 4,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 9,
			'struct_type' => 34,
			'union_type' => 37,
			'exception_header' => 35,
			'struct_header' => 10,
			'interface_dcl' => 12,
			'value' => 13,
			'value_box_header' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 40,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'value_abs_dcl' => 23,
			'value_mod' => 22,
			'type_dcl' => 41,
			'union_header' => 25,
			'definitions' => 26,
			'definition' => 43,
			'interface_mod' => 28
		}
	},
	{#State 1
		DEFAULT => -58
	},
	{#State 2
		ACTIONS => {
			'error' => 45,
			'VALUETYPE' => 44,
			'INTERFACE' => -28
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 48
		}
	},
	{#State 4
		ACTIONS => {
			'' => 49
		}
	},
	{#State 5
		ACTIONS => {
			"{" => 51,
			'error' => 50
		}
	},
	{#State 6
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 52
		}
	},
	{#State 7
		DEFAULT => -57
	},
	{#State 8
		ACTIONS => {
			"{" => 53
		}
	},
	{#State 9
		DEFAULT => -55
	},
	{#State 10
		ACTIONS => {
			"{" => 54
		}
	},
	{#State 11
		ACTIONS => {
			'error' => 55,
			'IDENTIFIER' => 56
		}
	},
	{#State 12
		DEFAULT => -21
	},
	{#State 13
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 57
		}
	},
	{#State 14
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 88,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'wide_char_type' => 68,
			'type_spec' => 70,
			'signed_long_int' => 69,
			'string_type' => 72,
			'struct_header' => 10,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'base_type_spec' => 77,
			'enum_type' => 78,
			'enum_header' => 18,
			'union_header' => 25,
			'unsigned_short_int' => 80,
			'signed_longlong_int' => 82,
			'wide_string_type' => 87,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 96,
			'struct_type' => 98,
			'union_type' => 100,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 15
		DEFAULT => -168
	},
	{#State 16
		DEFAULT => -22
	},
	{#State 17
		DEFAULT => -3
	},
	{#State 18
		ACTIONS => {
			"{" => 110,
			'error' => 109
		}
	},
	{#State 19
		DEFAULT => -170
	},
	{#State 20
		DEFAULT => -29
	},
	{#State 21
		ACTIONS => {
			'CHAR' => 84,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'FIXED' => 112,
			'WCHAR' => 74,
			'DOUBLE' => 92,
			'error' => 118,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'OCTET' => 79,
			'FLOAT' => 81,
			'WSTRING' => 97,
			'UNSIGNED' => 71
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 111,
			'signed_int' => 61,
			'wide_string_type' => 119,
			'integer_type' => 121,
			'boolean_type' => 120,
			'char_type' => 113,
			'octet_type' => 114,
			'scoped_name' => 115,
			'fixed_pt_const_type' => 122,
			'wide_char_type' => 116,
			'signed_long_int' => 69,
			'signed_short_int' => 96,
			'const_type' => 123,
			'string_type' => 117,
			'unsigned_longlong_int' => 75,
			'unsigned_long_int' => 104,
			'unsigned_short_int' => 80,
			'signed_longlong_int' => 82
		}
	},
	{#State 22
		ACTIONS => {
			'VALUETYPE' => 124
		}
	},
	{#State 23
		DEFAULT => -56
	},
	{#State 24
		ACTIONS => {
			'error' => 125,
			'IDENTIFIER' => 126
		}
	},
	{#State 25
		ACTIONS => {
			'SWITCH' => 127
		}
	},
	{#State 26
		DEFAULT => -1
	},
	{#State 27
		ACTIONS => {
			'error' => 128,
			'IDENTIFIER' => 129
		}
	},
	{#State 28
		ACTIONS => {
			'INTERFACE' => 130
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 131
		}
	},
	{#State 30
		ACTIONS => {
			"{" => 132
		}
	},
	{#State 31
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 135
		},
		GOTOS => {
			'simple_declarator' => 134
		}
	},
	{#State 32
		ACTIONS => {
			"{" => 136
		}
	},
	{#State 33
		ACTIONS => {
			'error' => 137,
			'IDENTIFIER' => 138
		}
	},
	{#State 34
		DEFAULT => -166
	},
	{#State 35
		ACTIONS => {
			"{" => 140,
			'error' => 139
		}
	},
	{#State 36
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 88,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'error' => 143,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'wide_char_type' => 68,
			'type_spec' => 141,
			'signed_long_int' => 69,
			'type_declarator' => 142,
			'string_type' => 72,
			'struct_header' => 10,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'base_type_spec' => 77,
			'enum_type' => 78,
			'enum_header' => 18,
			'union_header' => 25,
			'unsigned_short_int' => 80,
			'signed_longlong_int' => 82,
			'wide_string_type' => 87,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 96,
			'struct_type' => 98,
			'union_type' => 100,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 37
		DEFAULT => -167
	},
	{#State 38
		ACTIONS => {
			'error' => 144
		}
	},
	{#State 39
		ACTIONS => {
			'error' => 145,
			'IDENTIFIER' => 146
		}
	},
	{#State 40
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 147
		}
	},
	{#State 41
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 148
		}
	},
	{#State 42
		DEFAULT => -76
	},
	{#State 43
		ACTIONS => {
			'TYPEDEF' => 36,
			'IDENTIFIER' => 38,
			'NATIVE' => 31,
			'MODULE' => 11,
			'ABSTRACT' => 2,
			'UNION' => 39,
			'STRUCT' => 33,
			'LOCAL' => 20,
			'CONST' => 21,
			'EXCEPTION' => 24,
			'CUSTOM' => 42,
			'VALUETYPE' => -77,
			'ENUM' => 27,
			'INTERFACE' => -30
		},
		DEFAULT => -4,
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 29,
			'interface_header' => 30,
			'except_dcl' => 3,
			'value_header' => 32,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 9,
			'struct_type' => 34,
			'union_type' => 37,
			'exception_header' => 35,
			'struct_header' => 10,
			'interface_dcl' => 12,
			'value' => 13,
			'value_box_header' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 40,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'value_abs_dcl' => 23,
			'value_mod' => 22,
			'type_dcl' => 41,
			'definitions' => 149,
			'union_header' => 25,
			'definition' => 43,
			'interface_mod' => 28
		}
	},
	{#State 44
		ACTIONS => {
			'error' => 150,
			'IDENTIFIER' => 151
		}
	},
	{#State 45
		DEFAULT => -68
	},
	{#State 46
		DEFAULT => -13
	},
	{#State 47
		DEFAULT => -14
	},
	{#State 48
		DEFAULT => -8
	},
	{#State 49
		DEFAULT => 0
	},
	{#State 50
		ACTIONS => {
			"}" => 152
		}
	},
	{#State 51
		ACTIONS => {
			'NATIVE' => 31,
			'ABSTRACT' => 2,
			'STRUCT' => 33,
			'VALUETYPE' => -77,
			'TYPEDEF' => 36,
			'MODULE' => 11,
			'IDENTIFIER' => 38,
			'UNION' => 39,
			'error' => 153,
			'LOCAL' => 20,
			'CONST' => 21,
			"}" => 154,
			'EXCEPTION' => 24,
			'CUSTOM' => 42,
			'ENUM' => 27,
			'INTERFACE' => -30
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 29,
			'interface_header' => 30,
			'except_dcl' => 3,
			'value_header' => 32,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 9,
			'struct_type' => 34,
			'union_type' => 37,
			'exception_header' => 35,
			'struct_header' => 10,
			'interface_dcl' => 12,
			'value' => 13,
			'value_box_header' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 40,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'value_abs_dcl' => 23,
			'value_mod' => 22,
			'type_dcl' => 41,
			'definitions' => 155,
			'union_header' => 25,
			'definition' => 43,
			'interface_mod' => 28
		}
	},
	{#State 52
		DEFAULT => -9
	},
	{#State 53
		ACTIONS => {
			'PRIVATE' => 157,
			'ONEWAY' => 158,
			'FIXED' => -299,
			'SEQUENCE' => -299,
			'FACTORY' => 165,
			'UNSIGNED' => -299,
			'SHORT' => -299,
			'WCHAR' => -299,
			'error' => 167,
			'CONST' => 21,
			'FLOAT' => -299,
			'OCTET' => -299,
			"}" => 168,
			'EXCEPTION' => 24,
			'ENUM' => 27,
			'ANY' => -299,
			'CHAR' => -299,
			'OBJECT' => -299,
			'NATIVE' => 31,
			'VALUEBASE' => -299,
			'VOID' => -299,
			'STRUCT' => 33,
			'DOUBLE' => -299,
			'LONG' => -299,
			'STRING' => -299,
			"::" => -299,
			'WSTRING' => -299,
			'TYPEDEF' => 36,
			'BOOLEAN' => -299,
			'IDENTIFIER' => -299,
			'UNION' => 39,
			'READONLY' => 174,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 175
		},
		GOTOS => {
			'init_header_param' => 156,
			'const_dcl' => 169,
			'op_mod' => 159,
			'state_member' => 161,
			'except_dcl' => 160,
			'op_attribute' => 162,
			'attr_mod' => 163,
			'state_mod' => 164,
			'exports' => 170,
			'_export' => 171,
			'export' => 172,
			'init_header' => 166,
			'struct_type' => 34,
			'op_header' => 173,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 176,
			'init_dcl' => 177,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 178,
			'type_dcl' => 179,
			'union_header' => 25
		}
	},
	{#State 54
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 88,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'error' => 181,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'type_spec' => 180,
			'string_type' => 72,
			'struct_header' => 10,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'base_type_spec' => 77,
			'enum_type' => 78,
			'enum_header' => 18,
			'member_list' => 182,
			'union_header' => 25,
			'unsigned_short_int' => 80,
			'signed_longlong_int' => 82,
			'wide_string_type' => 87,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 96,
			'member' => 183,
			'struct_type' => 98,
			'union_type' => 100,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 55
		DEFAULT => -20
	},
	{#State 56
		DEFAULT => -19
	},
	{#State 57
		DEFAULT => -11
	},
	{#State 58
		DEFAULT => -207
	},
	{#State 59
		DEFAULT => -179
	},
	{#State 60
		ACTIONS => {
			"<" => 185,
			'error' => 184
		}
	},
	{#State 61
		DEFAULT => -206
	},
	{#State 62
		ACTIONS => {
			"<" => 187,
			'error' => 186
		}
	},
	{#State 63
		DEFAULT => -187
	},
	{#State 64
		DEFAULT => -181
	},
	{#State 65
		DEFAULT => -186
	},
	{#State 66
		DEFAULT => -184
	},
	{#State 67
		ACTIONS => {
			"::" => 188
		},
		DEFAULT => -177
	},
	{#State 68
		DEFAULT => -182
	},
	{#State 69
		DEFAULT => -209
	},
	{#State 70
		DEFAULT => -61
	},
	{#State 71
		ACTIONS => {
			'SHORT' => 189,
			'LONG' => 190
		}
	},
	{#State 72
		DEFAULT => -189
	},
	{#State 73
		DEFAULT => -211
	},
	{#State 74
		DEFAULT => -221
	},
	{#State 75
		DEFAULT => -216
	},
	{#State 76
		DEFAULT => -185
	},
	{#State 77
		DEFAULT => -175
	},
	{#State 78
		DEFAULT => -194
	},
	{#State 79
		DEFAULT => -223
	},
	{#State 80
		DEFAULT => -214
	},
	{#State 81
		DEFAULT => -203
	},
	{#State 82
		DEFAULT => -210
	},
	{#State 83
		DEFAULT => -224
	},
	{#State 84
		DEFAULT => -220
	},
	{#State 85
		DEFAULT => -225
	},
	{#State 86
		DEFAULT => -346
	},
	{#State 87
		DEFAULT => -190
	},
	{#State 88
		DEFAULT => -178
	},
	{#State 89
		DEFAULT => -183
	},
	{#State 90
		DEFAULT => -180
	},
	{#State 91
		ACTIONS => {
			'error' => 191,
			'IDENTIFIER' => 192
		}
	},
	{#State 92
		DEFAULT => -204
	},
	{#State 93
		ACTIONS => {
			'DOUBLE' => 193,
			'LONG' => 194
		},
		DEFAULT => -212
	},
	{#State 94
		ACTIONS => {
			"<" => 195
		},
		DEFAULT => -272
	},
	{#State 95
		ACTIONS => {
			'error' => 196,
			'IDENTIFIER' => 197
		}
	},
	{#State 96
		DEFAULT => -208
	},
	{#State 97
		ACTIONS => {
			"<" => 198
		},
		DEFAULT => -275
	},
	{#State 98
		DEFAULT => -192
	},
	{#State 99
		DEFAULT => -222
	},
	{#State 100
		DEFAULT => -193
	},
	{#State 101
		DEFAULT => -50
	},
	{#State 102
		ACTIONS => {
			'error' => 199,
			'IDENTIFIER' => 200
		}
	},
	{#State 103
		DEFAULT => -188
	},
	{#State 104
		DEFAULT => -215
	},
	{#State 105
		DEFAULT => -176
	},
	{#State 106
		DEFAULT => -174
	},
	{#State 107
		DEFAULT => -173
	},
	{#State 108
		DEFAULT => -191
	},
	{#State 109
		DEFAULT => -258
	},
	{#State 110
		ACTIONS => {
			'error' => 201,
			'IDENTIFIER' => 203
		},
		GOTOS => {
			'enumerators' => 204,
			'enumerator' => 202
		}
	},
	{#State 111
		DEFAULT => -118
	},
	{#State 112
		DEFAULT => -345
	},
	{#State 113
		DEFAULT => -115
	},
	{#State 114
		DEFAULT => -123
	},
	{#State 115
		ACTIONS => {
			"::" => 188
		},
		DEFAULT => -122
	},
	{#State 116
		DEFAULT => -116
	},
	{#State 117
		DEFAULT => -119
	},
	{#State 118
		DEFAULT => -113
	},
	{#State 119
		DEFAULT => -120
	},
	{#State 120
		DEFAULT => -117
	},
	{#State 121
		DEFAULT => -114
	},
	{#State 122
		DEFAULT => -121
	},
	{#State 123
		ACTIONS => {
			'error' => 205,
			'IDENTIFIER' => 206
		}
	},
	{#State 124
		ACTIONS => {
			'error' => 207,
			'IDENTIFIER' => 208
		}
	},
	{#State 125
		DEFAULT => -293
	},
	{#State 126
		DEFAULT => -292
	},
	{#State 127
		ACTIONS => {
			'error' => 210,
			"(" => 209
		}
	},
	{#State 128
		DEFAULT => -260
	},
	{#State 129
		DEFAULT => -259
	},
	{#State 130
		ACTIONS => {
			'error' => 211,
			'IDENTIFIER' => 212
		}
	},
	{#State 131
		DEFAULT => -7
	},
	{#State 132
		ACTIONS => {
			'PRIVATE' => 157,
			'ONEWAY' => 158,
			'FIXED' => -299,
			'SEQUENCE' => -299,
			'FACTORY' => 165,
			'UNSIGNED' => -299,
			'SHORT' => -299,
			'WCHAR' => -299,
			'error' => 213,
			'CONST' => 21,
			'FLOAT' => -299,
			'OCTET' => -299,
			"}" => 214,
			'EXCEPTION' => 24,
			'ENUM' => 27,
			'ANY' => -299,
			'CHAR' => -299,
			'OBJECT' => -299,
			'NATIVE' => 31,
			'VALUEBASE' => -299,
			'VOID' => -299,
			'STRUCT' => 33,
			'DOUBLE' => -299,
			'LONG' => -299,
			'STRING' => -299,
			"::" => -299,
			'WSTRING' => -299,
			'TYPEDEF' => 36,
			'BOOLEAN' => -299,
			'IDENTIFIER' => -299,
			'UNION' => 39,
			'READONLY' => 174,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 175
		},
		GOTOS => {
			'init_header_param' => 156,
			'const_dcl' => 169,
			'op_mod' => 159,
			'state_member' => 161,
			'except_dcl' => 160,
			'op_attribute' => 162,
			'attr_mod' => 163,
			'state_mod' => 164,
			'exports' => 215,
			'_export' => 171,
			'export' => 172,
			'init_header' => 166,
			'struct_type' => 34,
			'op_header' => 173,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 176,
			'init_dcl' => 177,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 178,
			'type_dcl' => 179,
			'union_header' => 25,
			'interface_body' => 216
		}
	},
	{#State 133
		ACTIONS => {
			";" => 217,
			"," => 218
		}
	},
	{#State 134
		DEFAULT => -169
	},
	{#State 135
		DEFAULT => -199
	},
	{#State 136
		ACTIONS => {
			'PRIVATE' => 157,
			'ONEWAY' => 158,
			'FIXED' => -299,
			'SEQUENCE' => -299,
			'FACTORY' => 165,
			'UNSIGNED' => -299,
			'SHORT' => -299,
			'WCHAR' => -299,
			'error' => 221,
			'CONST' => 21,
			'FLOAT' => -299,
			'OCTET' => -299,
			"}" => 222,
			'EXCEPTION' => 24,
			'ENUM' => 27,
			'ANY' => -299,
			'CHAR' => -299,
			'OBJECT' => -299,
			'NATIVE' => 31,
			'VALUEBASE' => -299,
			'VOID' => -299,
			'STRUCT' => 33,
			'DOUBLE' => -299,
			'LONG' => -299,
			'STRING' => -299,
			"::" => -299,
			'WSTRING' => -299,
			'TYPEDEF' => 36,
			'BOOLEAN' => -299,
			'IDENTIFIER' => -299,
			'UNION' => 39,
			'READONLY' => 174,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 175
		},
		GOTOS => {
			'init_header_param' => 156,
			'const_dcl' => 169,
			'op_mod' => 159,
			'value_elements' => 223,
			'except_dcl' => 160,
			'state_member' => 219,
			'op_attribute' => 162,
			'attr_mod' => 163,
			'state_mod' => 164,
			'value_element' => 220,
			'export' => 224,
			'init_header' => 166,
			'struct_type' => 34,
			'op_header' => 173,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 176,
			'init_dcl' => 225,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 178,
			'type_dcl' => 179,
			'union_header' => 25
		}
	},
	{#State 137
		ACTIONS => {
			"{" => -229
		},
		DEFAULT => -348
	},
	{#State 138
		ACTIONS => {
			"{" => -228
		},
		DEFAULT => -347
	},
	{#State 139
		DEFAULT => -291
	},
	{#State 140
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 88,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'error' => 226,
			"}" => 228,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'type_spec' => 180,
			'string_type' => 72,
			'struct_header' => 10,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'base_type_spec' => 77,
			'enum_type' => 78,
			'enum_header' => 18,
			'member_list' => 227,
			'union_header' => 25,
			'unsigned_short_int' => 80,
			'signed_longlong_int' => 82,
			'wide_string_type' => 87,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 96,
			'member' => 183,
			'struct_type' => 98,
			'union_type' => 100,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 141
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 234
		},
		GOTOS => {
			'declarators' => 229,
			'declarator' => 230,
			'simple_declarator' => 232,
			'array_declarator' => 233,
			'complex_declarator' => 231
		}
	},
	{#State 142
		DEFAULT => -165
	},
	{#State 143
		DEFAULT => -171
	},
	{#State 144
		ACTIONS => {
			";" => 235
		}
	},
	{#State 145
		ACTIONS => {
			'SWITCH' => -239
		},
		DEFAULT => -350
	},
	{#State 146
		ACTIONS => {
			'SWITCH' => -238
		},
		DEFAULT => -349
	},
	{#State 147
		DEFAULT => -10
	},
	{#State 148
		DEFAULT => -6
	},
	{#State 149
		DEFAULT => -5
	},
	{#State 150
		DEFAULT => -67
	},
	{#State 151
		ACTIONS => {
			"{" => -87,
			'SUPPORTS' => 238,
			":" => 237
		},
		DEFAULT => -60,
		GOTOS => {
			'supported_interface_spec' => 239,
			'value_inheritance_spec' => 236
		}
	},
	{#State 152
		DEFAULT => -18
	},
	{#State 153
		ACTIONS => {
			"}" => 240
		}
	},
	{#State 154
		DEFAULT => -17
	},
	{#State 155
		ACTIONS => {
			"}" => 241
		}
	},
	{#State 156
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 242
		}
	},
	{#State 157
		DEFAULT => -96
	},
	{#State 158
		DEFAULT => -300
	},
	{#State 159
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 247,
			'SEQUENCE' => 62,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'WCHAR' => 74,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'wide_string_type' => 246,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 243,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'signed_short_int' => 96,
			'string_type' => 244,
			'op_type_spec' => 249,
			'op_param_type_spec' => 248,
			'sequence_type' => 250,
			'base_type_spec' => 245,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'unsigned_long_int' => 104,
			'unsigned_short_int' => 80,
			'fixed_pt_type' => 251,
			'signed_longlong_int' => 82
		}
	},
	{#State 160
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 252
		}
	},
	{#State 161
		DEFAULT => -37
	},
	{#State 162
		DEFAULT => -298
	},
	{#State 163
		ACTIONS => {
			'ATTRIBUTE' => 253
		}
	},
	{#State 164
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 88,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'error' => 255,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'wide_char_type' => 68,
			'type_spec' => 254,
			'signed_long_int' => 69,
			'string_type' => 72,
			'struct_header' => 10,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'base_type_spec' => 77,
			'enum_type' => 78,
			'enum_header' => 18,
			'union_header' => 25,
			'unsigned_short_int' => 80,
			'signed_longlong_int' => 82,
			'wide_string_type' => 87,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 96,
			'struct_type' => 98,
			'union_type' => 100,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 165
		ACTIONS => {
			'error' => 256,
			'IDENTIFIER' => 257
		}
	},
	{#State 166
		ACTIONS => {
			'error' => 259,
			"(" => 258
		}
	},
	{#State 167
		ACTIONS => {
			"}" => 260
		}
	},
	{#State 168
		DEFAULT => -63
	},
	{#State 169
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 261
		}
	},
	{#State 170
		ACTIONS => {
			"}" => 262
		}
	},
	{#State 171
		ACTIONS => {
			'PRIVATE' => 157,
			'ONEWAY' => 158,
			'FACTORY' => 165,
			'CONST' => 21,
			'EXCEPTION' => 24,
			"}" => -34,
			'ENUM' => 27,
			'NATIVE' => 31,
			'STRUCT' => 33,
			'TYPEDEF' => 36,
			'UNION' => 39,
			'READONLY' => 174,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 175
		},
		DEFAULT => -299,
		GOTOS => {
			'init_header_param' => 156,
			'const_dcl' => 169,
			'op_mod' => 159,
			'state_member' => 161,
			'except_dcl' => 160,
			'op_attribute' => 162,
			'attr_mod' => 163,
			'state_mod' => 164,
			'exports' => 263,
			'_export' => 171,
			'export' => 172,
			'init_header' => 166,
			'struct_type' => 34,
			'op_header' => 173,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 176,
			'init_dcl' => 177,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 178,
			'type_dcl' => 179,
			'union_header' => 25
		}
	},
	{#State 172
		DEFAULT => -36
	},
	{#State 173
		ACTIONS => {
			'error' => 265,
			"(" => 264
		},
		GOTOS => {
			'parameter_dcls' => 266
		}
	},
	{#State 174
		DEFAULT => -284
	},
	{#State 175
		DEFAULT => -95
	},
	{#State 176
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 267
		}
	},
	{#State 177
		DEFAULT => -38
	},
	{#State 178
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 268
		}
	},
	{#State 179
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 269
		}
	},
	{#State 180
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 234
		},
		GOTOS => {
			'declarators' => 270,
			'declarator' => 230,
			'simple_declarator' => 232,
			'array_declarator' => 233,
			'complex_declarator' => 231
		}
	},
	{#State 181
		ACTIONS => {
			"}" => 271
		}
	},
	{#State 182
		ACTIONS => {
			"}" => 272
		}
	},
	{#State 183
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 88,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		DEFAULT => -230,
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'type_spec' => 180,
			'string_type' => 72,
			'struct_header' => 10,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'base_type_spec' => 77,
			'enum_type' => 78,
			'enum_header' => 18,
			'member_list' => 273,
			'union_header' => 25,
			'unsigned_short_int' => 80,
			'signed_longlong_int' => 82,
			'wide_string_type' => 87,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 96,
			'member' => 183,
			'struct_type' => 98,
			'union_type' => 100,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 184
		DEFAULT => -344
	},
	{#State 185
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 283,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'primary_expr' => 293,
			'and_expr' => 294,
			'scoped_name' => 276,
			'positive_int_const' => 277,
			'wide_string_literal' => 278,
			'boolean_literal' => 280,
			'mult_expr' => 296,
			'const_exp' => 281,
			'or_expr' => 282,
			'unary_expr' => 300,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 186
		DEFAULT => -270
	},
	{#State 187
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 88,
			'SEQUENCE' => 62,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'WCHAR' => 74,
			'error' => 304,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'wide_string_type' => 87,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'signed_short_int' => 96,
			'string_type' => 72,
			'sequence_type' => 103,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'base_type_spec' => 77,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'unsigned_short_int' => 80,
			'simple_type_spec' => 305,
			'fixed_pt_type' => 108,
			'signed_longlong_int' => 82
		}
	},
	{#State 188
		ACTIONS => {
			'error' => 306,
			'IDENTIFIER' => 307
		}
	},
	{#State 189
		DEFAULT => -217
	},
	{#State 190
		ACTIONS => {
			'LONG' => 308
		},
		DEFAULT => -218
	},
	{#State 191
		DEFAULT => -229
	},
	{#State 192
		DEFAULT => -228
	},
	{#State 193
		DEFAULT => -205
	},
	{#State 194
		DEFAULT => -213
	},
	{#State 195
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 310,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'primary_expr' => 293,
			'and_expr' => 294,
			'scoped_name' => 276,
			'positive_int_const' => 309,
			'wide_string_literal' => 278,
			'boolean_literal' => 280,
			'mult_expr' => 296,
			'const_exp' => 281,
			'or_expr' => 282,
			'unary_expr' => 300,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 196
		DEFAULT => -52
	},
	{#State 197
		DEFAULT => -51
	},
	{#State 198
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 312,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'primary_expr' => 293,
			'and_expr' => 294,
			'scoped_name' => 276,
			'positive_int_const' => 311,
			'wide_string_literal' => 278,
			'boolean_literal' => 280,
			'mult_expr' => 296,
			'const_exp' => 281,
			'or_expr' => 282,
			'unary_expr' => 300,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 199
		DEFAULT => -239
	},
	{#State 200
		DEFAULT => -238
	},
	{#State 201
		ACTIONS => {
			"}" => 313
		}
	},
	{#State 202
		ACTIONS => {
			";" => 314,
			"," => 315
		},
		DEFAULT => -261
	},
	{#State 203
		DEFAULT => -265
	},
	{#State 204
		ACTIONS => {
			"}" => 316
		}
	},
	{#State 205
		DEFAULT => -112
	},
	{#State 206
		ACTIONS => {
			'error' => 317,
			"=" => 318
		}
	},
	{#State 207
		DEFAULT => -75
	},
	{#State 208
		ACTIONS => {
			":" => 237,
			";" => -59,
			"{" => -87,
			'error' => -59,
			'SUPPORTS' => 238
		},
		DEFAULT => -62,
		GOTOS => {
			'supported_interface_spec' => 239,
			'value_inheritance_spec' => 319
		}
	},
	{#State 209
		ACTIONS => {
			'CHAR' => 84,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'error' => 323,
			'LONG' => 327,
			"::" => 95,
			'ENUM' => 27,
			'UNSIGNED' => 71
		},
		GOTOS => {
			'switch_type_spec' => 324,
			'unsigned_int' => 58,
			'signed_int' => 61,
			'integer_type' => 326,
			'boolean_type' => 325,
			'unsigned_longlong_int' => 75,
			'char_type' => 320,
			'enum_type' => 322,
			'unsigned_long_int' => 104,
			'scoped_name' => 321,
			'enum_header' => 18,
			'signed_long_int' => 69,
			'unsigned_short_int' => 80,
			'signed_short_int' => 96,
			'signed_longlong_int' => 82
		}
	},
	{#State 210
		DEFAULT => -237
	},
	{#State 211
		ACTIONS => {
			"{" => -32
		},
		DEFAULT => -27
	},
	{#State 212
		ACTIONS => {
			"{" => -46,
			":" => 328
		},
		DEFAULT => -26,
		GOTOS => {
			'interface_inheritance_spec' => 329
		}
	},
	{#State 213
		ACTIONS => {
			"}" => 330
		}
	},
	{#State 214
		DEFAULT => -23
	},
	{#State 215
		DEFAULT => -33
	},
	{#State 216
		ACTIONS => {
			"}" => 331
		}
	},
	{#State 217
		DEFAULT => -201
	},
	{#State 218
		DEFAULT => -200
	},
	{#State 219
		DEFAULT => -90
	},
	{#State 220
		ACTIONS => {
			'PRIVATE' => 157,
			'ONEWAY' => 158,
			'FACTORY' => 165,
			'CONST' => 21,
			'EXCEPTION' => 24,
			"}" => -72,
			'ENUM' => 27,
			'NATIVE' => 31,
			'STRUCT' => 33,
			'TYPEDEF' => 36,
			'UNION' => 39,
			'READONLY' => 174,
			'ATTRIBUTE' => -285,
			'PUBLIC' => 175
		},
		DEFAULT => -299,
		GOTOS => {
			'init_header_param' => 156,
			'const_dcl' => 169,
			'op_mod' => 159,
			'value_elements' => 332,
			'except_dcl' => 160,
			'state_member' => 219,
			'op_attribute' => 162,
			'attr_mod' => 163,
			'state_mod' => 164,
			'value_element' => 220,
			'export' => 224,
			'init_header' => 166,
			'struct_type' => 34,
			'op_header' => 173,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 176,
			'init_dcl' => 225,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 178,
			'type_dcl' => 179,
			'union_header' => 25
		}
	},
	{#State 221
		ACTIONS => {
			"}" => 333
		}
	},
	{#State 222
		DEFAULT => -69
	},
	{#State 223
		ACTIONS => {
			"}" => 334
		}
	},
	{#State 224
		DEFAULT => -89
	},
	{#State 225
		DEFAULT => -91
	},
	{#State 226
		ACTIONS => {
			"}" => 335
		}
	},
	{#State 227
		ACTIONS => {
			"}" => 336
		}
	},
	{#State 228
		DEFAULT => -288
	},
	{#State 229
		DEFAULT => -172
	},
	{#State 230
		ACTIONS => {
			"," => 337
		},
		DEFAULT => -195
	},
	{#State 231
		DEFAULT => -198
	},
	{#State 232
		DEFAULT => -197
	},
	{#State 233
		DEFAULT => -202
	},
	{#State 234
		ACTIONS => {
			"[" => 340
		},
		DEFAULT => -199,
		GOTOS => {
			'fixed_array_sizes' => 338,
			'fixed_array_size' => 339
		}
	},
	{#State 235
		DEFAULT => -12
	},
	{#State 236
		DEFAULT => -66
	},
	{#State 237
		ACTIONS => {
			'TRUNCATABLE' => 342
		},
		DEFAULT => -82,
		GOTOS => {
			'inheritance_mod' => 341
		}
	},
	{#State 238
		ACTIONS => {
			'error' => 344,
			'IDENTIFIER' => 101,
			"::" => 95
		},
		GOTOS => {
			'scoped_name' => 343,
			'interface_names' => 346,
			'interface_name' => 345
		}
	},
	{#State 239
		DEFAULT => -80
	},
	{#State 240
		DEFAULT => -16
	},
	{#State 241
		DEFAULT => -15
	},
	{#State 242
		DEFAULT => -97
	},
	{#State 243
		ACTIONS => {
			"::" => 188
		},
		DEFAULT => -340
	},
	{#State 244
		DEFAULT => -338
	},
	{#State 245
		DEFAULT => -337
	},
	{#State 246
		DEFAULT => -339
	},
	{#State 247
		DEFAULT => -302
	},
	{#State 248
		DEFAULT => -301
	},
	{#State 249
		ACTIONS => {
			'error' => 347,
			'IDENTIFIER' => 348
		}
	},
	{#State 250
		DEFAULT => -303
	},
	{#State 251
		DEFAULT => -304
	},
	{#State 252
		DEFAULT => -41
	},
	{#State 253
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 351,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'error' => 349,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'wide_string_type' => 246,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 243,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'signed_short_int' => 96,
			'string_type' => 244,
			'op_param_type_spec' => 352,
			'struct_type' => 98,
			'union_type' => 100,
			'struct_header' => 10,
			'sequence_type' => 353,
			'base_type_spec' => 245,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'enum_type' => 78,
			'unsigned_long_int' => 104,
			'param_type_spec' => 350,
			'enum_header' => 18,
			'constr_type_spec' => 354,
			'unsigned_short_int' => 80,
			'union_header' => 25,
			'fixed_pt_type' => 355,
			'signed_longlong_int' => 82
		}
	},
	{#State 254
		ACTIONS => {
			'error' => 357,
			'IDENTIFIER' => 234
		},
		GOTOS => {
			'declarators' => 356,
			'declarator' => 230,
			'simple_declarator' => 232,
			'array_declarator' => 233,
			'complex_declarator' => 231
		}
	},
	{#State 255
		ACTIONS => {
			";" => 358
		}
	},
	{#State 256
		DEFAULT => -103
	},
	{#State 257
		DEFAULT => -102
	},
	{#State 258
		ACTIONS => {
			'error' => 363,
			")" => 364,
			'IN' => 361
		},
		GOTOS => {
			'init_param_decls' => 360,
			'init_param_attribute' => 359,
			'init_param_decl' => 362
		}
	},
	{#State 259
		DEFAULT => -101
	},
	{#State 260
		DEFAULT => -65
	},
	{#State 261
		DEFAULT => -40
	},
	{#State 262
		DEFAULT => -64
	},
	{#State 263
		DEFAULT => -35
	},
	{#State 264
		ACTIONS => {
			'CHAR' => -318,
			'OBJECT' => -318,
			'FIXED' => -318,
			'VALUEBASE' => -318,
			'VOID' => -318,
			'IN' => 365,
			'SEQUENCE' => -318,
			'STRUCT' => -318,
			'DOUBLE' => -318,
			'LONG' => -318,
			'STRING' => -318,
			"::" => -318,
			'WSTRING' => -318,
			"..." => 366,
			'UNSIGNED' => -318,
			'SHORT' => -318,
			")" => 371,
			'BOOLEAN' => -318,
			'OUT' => 372,
			'IDENTIFIER' => -318,
			'UNION' => -318,
			'WCHAR' => -318,
			'error' => 367,
			'INOUT' => 368,
			'OCTET' => -318,
			'FLOAT' => -318,
			'ENUM' => -318,
			'ANY' => -318
		},
		GOTOS => {
			'param_dcl' => 373,
			'param_dcls' => 370,
			'param_attribute' => 369
		}
	},
	{#State 265
		DEFAULT => -295
	},
	{#State 266
		ACTIONS => {
			'RAISES' => 375
		},
		DEFAULT => -322,
		GOTOS => {
			'raises_expr' => 374
		}
	},
	{#State 267
		DEFAULT => -43
	},
	{#State 268
		DEFAULT => -42
	},
	{#State 269
		DEFAULT => -39
	},
	{#State 270
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 376
		}
	},
	{#State 271
		DEFAULT => -227
	},
	{#State 272
		DEFAULT => -226
	},
	{#State 273
		DEFAULT => -231
	},
	{#State 274
		DEFAULT => -153
	},
	{#State 275
		DEFAULT => -154
	},
	{#State 276
		ACTIONS => {
			"::" => 188
		},
		DEFAULT => -146
	},
	{#State 277
		ACTIONS => {
			"," => 377
		}
	},
	{#State 278
		DEFAULT => -152
	},
	{#State 279
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 379,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 296,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'const_exp' => 378,
			'and_expr' => 294,
			'or_expr' => 282,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 280
		DEFAULT => -157
	},
	{#State 281
		DEFAULT => -164
	},
	{#State 282
		ACTIONS => {
			"|" => 380
		},
		DEFAULT => -124
	},
	{#State 283
		ACTIONS => {
			">" => 381
		}
	},
	{#State 284
		ACTIONS => {
			"^" => 382
		},
		DEFAULT => -125
	},
	{#State 285
		ACTIONS => {
			"<<" => 383,
			">>" => 384
		},
		DEFAULT => -129
	},
	{#State 286
		DEFAULT => -163
	},
	{#State 287
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 287
		},
		DEFAULT => -160,
		GOTOS => {
			'wide_string_literal' => 385
		}
	},
	{#State 288
		DEFAULT => -147
	},
	{#State 289
		DEFAULT => -162
	},
	{#State 290
		ACTIONS => {
			"+" => 386,
			"-" => 387
		},
		DEFAULT => -131
	},
	{#State 291
		DEFAULT => -151
	},
	{#State 292
		DEFAULT => -156
	},
	{#State 293
		DEFAULT => -142
	},
	{#State 294
		ACTIONS => {
			"&" => 388
		},
		DEFAULT => -127
	},
	{#State 295
		DEFAULT => -150
	},
	{#State 296
		ACTIONS => {
			"%" => 390,
			"*" => 389,
			"/" => 391
		},
		DEFAULT => -134
	},
	{#State 297
		ACTIONS => {
			'STRING_LITERAL' => 297
		},
		DEFAULT => -158,
		GOTOS => {
			'string_literal' => 392
		}
	},
	{#State 298
		DEFAULT => -155
	},
	{#State 299
		DEFAULT => -144
	},
	{#State 300
		DEFAULT => -137
	},
	{#State 301
		DEFAULT => -143
	},
	{#State 302
		DEFAULT => -145
	},
	{#State 303
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'boolean_literal' => 280,
			'scoped_name' => 276,
			'primary_expr' => 393,
			'literal' => 288,
			'wide_string_literal' => 278
		}
	},
	{#State 304
		ACTIONS => {
			">" => 394
		}
	},
	{#State 305
		ACTIONS => {
			">" => 396,
			"," => 395
		}
	},
	{#State 306
		DEFAULT => -54
	},
	{#State 307
		DEFAULT => -53
	},
	{#State 308
		DEFAULT => -219
	},
	{#State 309
		ACTIONS => {
			">" => 397
		}
	},
	{#State 310
		ACTIONS => {
			">" => 398
		}
	},
	{#State 311
		ACTIONS => {
			">" => 399
		}
	},
	{#State 312
		ACTIONS => {
			">" => 400
		}
	},
	{#State 313
		DEFAULT => -257
	},
	{#State 314
		DEFAULT => -264
	},
	{#State 315
		ACTIONS => {
			'IDENTIFIER' => 203
		},
		DEFAULT => -263,
		GOTOS => {
			'enumerators' => 401,
			'enumerator' => 202
		}
	},
	{#State 316
		DEFAULT => -256
	},
	{#State 317
		DEFAULT => -111
	},
	{#State 318
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 403,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 296,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'const_exp' => 402,
			'and_expr' => 294,
			'or_expr' => 282,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 319
		DEFAULT => -74
	},
	{#State 320
		DEFAULT => -241
	},
	{#State 321
		ACTIONS => {
			"::" => 188
		},
		DEFAULT => -244
	},
	{#State 322
		DEFAULT => -243
	},
	{#State 323
		ACTIONS => {
			")" => 404
		}
	},
	{#State 324
		ACTIONS => {
			")" => 405
		}
	},
	{#State 325
		DEFAULT => -242
	},
	{#State 326
		DEFAULT => -240
	},
	{#State 327
		ACTIONS => {
			'LONG' => 194
		},
		DEFAULT => -212
	},
	{#State 328
		ACTIONS => {
			'error' => 406,
			'IDENTIFIER' => 101,
			"::" => 95
		},
		GOTOS => {
			'scoped_name' => 343,
			'interface_names' => 407,
			'interface_name' => 345
		}
	},
	{#State 329
		DEFAULT => -31
	},
	{#State 330
		DEFAULT => -25
	},
	{#State 331
		DEFAULT => -24
	},
	{#State 332
		DEFAULT => -73
	},
	{#State 333
		DEFAULT => -71
	},
	{#State 334
		DEFAULT => -70
	},
	{#State 335
		DEFAULT => -290
	},
	{#State 336
		DEFAULT => -289
	},
	{#State 337
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 234
		},
		GOTOS => {
			'declarators' => 408,
			'declarator' => 230,
			'simple_declarator' => 232,
			'array_declarator' => 233,
			'complex_declarator' => 231
		}
	},
	{#State 338
		DEFAULT => -277
	},
	{#State 339
		ACTIONS => {
			"[" => 340
		},
		DEFAULT => -278,
		GOTOS => {
			'fixed_array_sizes' => 409,
			'fixed_array_size' => 339
		}
	},
	{#State 340
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 411,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'primary_expr' => 293,
			'and_expr' => 294,
			'scoped_name' => 276,
			'positive_int_const' => 410,
			'wide_string_literal' => 278,
			'boolean_literal' => 280,
			'mult_expr' => 296,
			'const_exp' => 281,
			'or_expr' => 282,
			'unary_expr' => 300,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 341
		ACTIONS => {
			'error' => 414,
			'IDENTIFIER' => 101,
			"::" => 95
		},
		GOTOS => {
			'scoped_name' => 412,
			'value_name' => 413,
			'value_names' => 415
		}
	},
	{#State 342
		DEFAULT => -81
	},
	{#State 343
		ACTIONS => {
			"::" => 188
		},
		DEFAULT => -49
	},
	{#State 344
		DEFAULT => -86
	},
	{#State 345
		ACTIONS => {
			"," => 416
		},
		DEFAULT => -47
	},
	{#State 346
		DEFAULT => -85
	},
	{#State 347
		DEFAULT => -297
	},
	{#State 348
		DEFAULT => -296
	},
	{#State 349
		DEFAULT => -283
	},
	{#State 350
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 135
		},
		GOTOS => {
			'simple_declarators' => 418,
			'simple_declarator' => 417
		}
	},
	{#State 351
		DEFAULT => -333
	},
	{#State 352
		DEFAULT => -332
	},
	{#State 353
		DEFAULT => -334
	},
	{#State 354
		DEFAULT => -336
	},
	{#State 355
		DEFAULT => -335
	},
	{#State 356
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 419
		}
	},
	{#State 357
		ACTIONS => {
			";" => 420,
			"," => 218
		}
	},
	{#State 358
		DEFAULT => -94
	},
	{#State 359
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 351,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'error' => 421,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'wide_string_type' => 246,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 243,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'signed_short_int' => 96,
			'string_type' => 244,
			'op_param_type_spec' => 352,
			'struct_type' => 98,
			'union_type' => 100,
			'struct_header' => 10,
			'sequence_type' => 353,
			'base_type_spec' => 245,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'enum_type' => 78,
			'unsigned_long_int' => 104,
			'param_type_spec' => 422,
			'enum_header' => 18,
			'constr_type_spec' => 354,
			'unsigned_short_int' => 80,
			'union_header' => 25,
			'fixed_pt_type' => 355,
			'signed_longlong_int' => 82
		}
	},
	{#State 360
		ACTIONS => {
			")" => 423
		}
	},
	{#State 361
		DEFAULT => -108
	},
	{#State 362
		ACTIONS => {
			"," => 424
		},
		DEFAULT => -104
	},
	{#State 363
		ACTIONS => {
			")" => 425
		}
	},
	{#State 364
		DEFAULT => -98
	},
	{#State 365
		DEFAULT => -315
	},
	{#State 366
		ACTIONS => {
			")" => 426
		}
	},
	{#State 367
		ACTIONS => {
			")" => 427
		}
	},
	{#State 368
		DEFAULT => -317
	},
	{#State 369
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 351,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'wide_string_type' => 246,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 243,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'signed_short_int' => 96,
			'string_type' => 244,
			'op_param_type_spec' => 352,
			'struct_type' => 98,
			'union_type' => 100,
			'struct_header' => 10,
			'sequence_type' => 353,
			'base_type_spec' => 245,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'enum_type' => 78,
			'unsigned_long_int' => 104,
			'param_type_spec' => 428,
			'enum_header' => 18,
			'constr_type_spec' => 354,
			'unsigned_short_int' => 80,
			'union_header' => 25,
			'fixed_pt_type' => 355,
			'signed_longlong_int' => 82
		}
	},
	{#State 370
		ACTIONS => {
			")" => 430,
			"," => 429
		}
	},
	{#State 371
		DEFAULT => -308
	},
	{#State 372
		DEFAULT => -316
	},
	{#State 373
		ACTIONS => {
			";" => 431
		},
		DEFAULT => -311
	},
	{#State 374
		ACTIONS => {
			'CONTEXT' => 432
		},
		DEFAULT => -329,
		GOTOS => {
			'context_expr' => 433
		}
	},
	{#State 375
		ACTIONS => {
			'error' => 435,
			"(" => 434
		}
	},
	{#State 376
		DEFAULT => -232
	},
	{#State 377
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 437,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'primary_expr' => 293,
			'and_expr' => 294,
			'scoped_name' => 276,
			'positive_int_const' => 436,
			'wide_string_literal' => 278,
			'boolean_literal' => 280,
			'mult_expr' => 296,
			'const_exp' => 281,
			'or_expr' => 282,
			'unary_expr' => 300,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 378
		ACTIONS => {
			")" => 438
		}
	},
	{#State 379
		ACTIONS => {
			")" => 439
		}
	},
	{#State 380
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 296,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'and_expr' => 294,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'xor_expr' => 440,
			'shift_expr' => 285,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 381
		DEFAULT => -343
	},
	{#State 382
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 296,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'and_expr' => 441,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'shift_expr' => 285,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 383
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 296,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 442
		}
	},
	{#State 384
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 296,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 443
		}
	},
	{#State 385
		DEFAULT => -161
	},
	{#State 386
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303
		}
	},
	{#State 387
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 445,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303
		}
	},
	{#State 388
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 296,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'shift_expr' => 446,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 389
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'unary_expr' => 447,
			'scoped_name' => 276,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303
		}
	},
	{#State 390
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'unary_expr' => 448,
			'scoped_name' => 276,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303
		}
	},
	{#State 391
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'CHARACTER_LITERAL' => 274,
			"+" => 299,
			'FIXED_PT_LITERAL' => 298,
			'WIDE_CHARACTER_LITERAL' => 275,
			"-" => 301,
			"::" => 95,
			'FALSE' => 286,
			'WIDE_STRING_LITERAL' => 287,
			'INTEGER_LITERAL' => 295,
			"~" => 302,
			"(" => 279,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'unary_expr' => 449,
			'scoped_name' => 276,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303
		}
	},
	{#State 392
		DEFAULT => -159
	},
	{#State 393
		DEFAULT => -141
	},
	{#State 394
		DEFAULT => -269
	},
	{#State 395
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 451,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'string_literal' => 291,
			'primary_expr' => 293,
			'and_expr' => 294,
			'scoped_name' => 276,
			'positive_int_const' => 450,
			'wide_string_literal' => 278,
			'boolean_literal' => 280,
			'mult_expr' => 296,
			'const_exp' => 281,
			'or_expr' => 282,
			'unary_expr' => 300,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 396
		DEFAULT => -268
	},
	{#State 397
		DEFAULT => -271
	},
	{#State 398
		DEFAULT => -273
	},
	{#State 399
		DEFAULT => -274
	},
	{#State 400
		DEFAULT => -276
	},
	{#State 401
		DEFAULT => -262
	},
	{#State 402
		DEFAULT => -109
	},
	{#State 403
		DEFAULT => -110
	},
	{#State 404
		DEFAULT => -236
	},
	{#State 405
		ACTIONS => {
			"{" => 453,
			'error' => 452
		}
	},
	{#State 406
		DEFAULT => -45
	},
	{#State 407
		DEFAULT => -44
	},
	{#State 408
		DEFAULT => -196
	},
	{#State 409
		DEFAULT => -279
	},
	{#State 410
		ACTIONS => {
			"]" => 454
		}
	},
	{#State 411
		ACTIONS => {
			"]" => 455
		}
	},
	{#State 412
		ACTIONS => {
			"::" => 188
		},
		DEFAULT => -88
	},
	{#State 413
		ACTIONS => {
			"," => 456
		},
		DEFAULT => -83
	},
	{#State 414
		DEFAULT => -79
	},
	{#State 415
		ACTIONS => {
			'SUPPORTS' => 238
		},
		DEFAULT => -87,
		GOTOS => {
			'supported_interface_spec' => 457
		}
	},
	{#State 416
		ACTIONS => {
			'IDENTIFIER' => 101,
			"::" => 95
		},
		GOTOS => {
			'scoped_name' => 343,
			'interface_names' => 458,
			'interface_name' => 345
		}
	},
	{#State 417
		ACTIONS => {
			"," => 459
		},
		DEFAULT => -286
	},
	{#State 418
		DEFAULT => -282
	},
	{#State 419
		DEFAULT => -92
	},
	{#State 420
		ACTIONS => {
			";" => -201,
			"," => -201,
			'error' => -201
		},
		DEFAULT => -93
	},
	{#State 421
		DEFAULT => -107
	},
	{#State 422
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 135
		},
		GOTOS => {
			'simple_declarator' => 460
		}
	},
	{#State 423
		DEFAULT => -99
	},
	{#State 424
		ACTIONS => {
			'IN' => 361
		},
		GOTOS => {
			'init_param_decls' => 461,
			'init_param_attribute' => 359,
			'init_param_decl' => 362
		}
	},
	{#State 425
		DEFAULT => -100
	},
	{#State 426
		DEFAULT => -309
	},
	{#State 427
		DEFAULT => -310
	},
	{#State 428
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 135
		},
		GOTOS => {
			'simple_declarator' => 462
		}
	},
	{#State 429
		ACTIONS => {
			'IN' => 365,
			"..." => 463,
			")" => 464,
			'OUT' => 372,
			'INOUT' => 368
		},
		DEFAULT => -318,
		GOTOS => {
			'param_dcl' => 465,
			'param_attribute' => 369
		}
	},
	{#State 430
		DEFAULT => -305
	},
	{#State 431
		DEFAULT => -313
	},
	{#State 432
		ACTIONS => {
			'error' => 467,
			"(" => 466
		}
	},
	{#State 433
		DEFAULT => -294
	},
	{#State 434
		ACTIONS => {
			'error' => 469,
			'IDENTIFIER' => 101,
			"::" => 95
		},
		GOTOS => {
			'scoped_name' => 468,
			'exception_names' => 470,
			'exception_name' => 471
		}
	},
	{#State 435
		DEFAULT => -321
	},
	{#State 436
		ACTIONS => {
			">" => 472
		}
	},
	{#State 437
		ACTIONS => {
			">" => 473
		}
	},
	{#State 438
		DEFAULT => -148
	},
	{#State 439
		DEFAULT => -149
	},
	{#State 440
		ACTIONS => {
			"^" => 382
		},
		DEFAULT => -126
	},
	{#State 441
		ACTIONS => {
			"&" => 388
		},
		DEFAULT => -128
	},
	{#State 442
		ACTIONS => {
			"+" => 386,
			"-" => 387
		},
		DEFAULT => -133
	},
	{#State 443
		ACTIONS => {
			"+" => 386,
			"-" => 387
		},
		DEFAULT => -132
	},
	{#State 444
		ACTIONS => {
			"%" => 390,
			"*" => 389,
			"/" => 391
		},
		DEFAULT => -135
	},
	{#State 445
		ACTIONS => {
			"%" => 390,
			"*" => 389,
			"/" => 391
		},
		DEFAULT => -136
	},
	{#State 446
		ACTIONS => {
			"<<" => 383,
			">>" => 384
		},
		DEFAULT => -130
	},
	{#State 447
		DEFAULT => -138
	},
	{#State 448
		DEFAULT => -140
	},
	{#State 449
		DEFAULT => -139
	},
	{#State 450
		ACTIONS => {
			">" => 474
		}
	},
	{#State 451
		ACTIONS => {
			">" => 475
		}
	},
	{#State 452
		DEFAULT => -235
	},
	{#State 453
		ACTIONS => {
			'error' => 479,
			'CASE' => 476,
			'DEFAULT' => 478
		},
		GOTOS => {
			'case_labels' => 481,
			'switch_body' => 480,
			'case' => 477,
			'case_label' => 482
		}
	},
	{#State 454
		DEFAULT => -280
	},
	{#State 455
		DEFAULT => -281
	},
	{#State 456
		ACTIONS => {
			'IDENTIFIER' => 101,
			"::" => 95
		},
		GOTOS => {
			'scoped_name' => 412,
			'value_name' => 413,
			'value_names' => 483
		}
	},
	{#State 457
		DEFAULT => -78
	},
	{#State 458
		DEFAULT => -48
	},
	{#State 459
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 135
		},
		GOTOS => {
			'simple_declarators' => 484,
			'simple_declarator' => 417
		}
	},
	{#State 460
		DEFAULT => -106
	},
	{#State 461
		DEFAULT => -105
	},
	{#State 462
		DEFAULT => -314
	},
	{#State 463
		ACTIONS => {
			")" => 485
		}
	},
	{#State 464
		DEFAULT => -307
	},
	{#State 465
		DEFAULT => -312
	},
	{#State 466
		ACTIONS => {
			'error' => 486,
			'STRING_LITERAL' => 297
		},
		GOTOS => {
			'string_literal' => 487,
			'string_literals' => 488
		}
	},
	{#State 467
		DEFAULT => -328
	},
	{#State 468
		ACTIONS => {
			"::" => 188
		},
		DEFAULT => -325
	},
	{#State 469
		ACTIONS => {
			")" => 489
		}
	},
	{#State 470
		ACTIONS => {
			")" => 490
		}
	},
	{#State 471
		ACTIONS => {
			"," => 491
		},
		DEFAULT => -323
	},
	{#State 472
		DEFAULT => -341
	},
	{#State 473
		DEFAULT => -342
	},
	{#State 474
		DEFAULT => -266
	},
	{#State 475
		DEFAULT => -267
	},
	{#State 476
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 292,
			'CHARACTER_LITERAL' => 274,
			'WIDE_CHARACTER_LITERAL' => 275,
			"::" => 95,
			'INTEGER_LITERAL' => 295,
			"(" => 279,
			'IDENTIFIER' => 101,
			'STRING_LITERAL' => 297,
			'FIXED_PT_LITERAL' => 298,
			"+" => 299,
			'error' => 493,
			"-" => 301,
			'WIDE_STRING_LITERAL' => 287,
			'FALSE' => 286,
			"~" => 302,
			'TRUE' => 289
		},
		GOTOS => {
			'mult_expr' => 296,
			'string_literal' => 291,
			'boolean_literal' => 280,
			'primary_expr' => 293,
			'const_exp' => 492,
			'and_expr' => 294,
			'or_expr' => 282,
			'unary_expr' => 300,
			'scoped_name' => 276,
			'xor_expr' => 284,
			'shift_expr' => 285,
			'wide_string_literal' => 278,
			'literal' => 288,
			'unary_operator' => 303,
			'add_expr' => 290
		}
	},
	{#State 477
		ACTIONS => {
			'CASE' => 476,
			'DEFAULT' => 478
		},
		DEFAULT => -245,
		GOTOS => {
			'case_labels' => 481,
			'switch_body' => 494,
			'case' => 477,
			'case_label' => 482
		}
	},
	{#State 478
		ACTIONS => {
			'error' => 495,
			":" => 496
		}
	},
	{#State 479
		ACTIONS => {
			"}" => 497
		}
	},
	{#State 480
		ACTIONS => {
			"}" => 498
		}
	},
	{#State 481
		ACTIONS => {
			'CHAR' => 84,
			'OBJECT' => 85,
			'VALUEBASE' => 86,
			'FIXED' => 60,
			'VOID' => 88,
			'SEQUENCE' => 62,
			'STRUCT' => 91,
			'DOUBLE' => 92,
			'LONG' => 93,
			'STRING' => 94,
			"::" => 95,
			'WSTRING' => 97,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 99,
			'IDENTIFIER' => 101,
			'UNION' => 102,
			'WCHAR' => 74,
			'FLOAT' => 81,
			'OCTET' => 79,
			'ENUM' => 27,
			'ANY' => 83
		},
		GOTOS => {
			'unsigned_int' => 58,
			'floating_pt_type' => 59,
			'signed_int' => 61,
			'char_type' => 64,
			'value_base_type' => 63,
			'object_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'type_spec' => 499,
			'string_type' => 72,
			'struct_header' => 10,
			'element_spec' => 500,
			'unsigned_longlong_int' => 75,
			'any_type' => 76,
			'base_type_spec' => 77,
			'enum_type' => 78,
			'enum_header' => 18,
			'union_header' => 25,
			'unsigned_short_int' => 80,
			'signed_longlong_int' => 82,
			'wide_string_type' => 87,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 96,
			'struct_type' => 98,
			'union_type' => 100,
			'sequence_type' => 103,
			'unsigned_long_int' => 104,
			'template_type_spec' => 105,
			'constr_type_spec' => 106,
			'simple_type_spec' => 107,
			'fixed_pt_type' => 108
		}
	},
	{#State 482
		ACTIONS => {
			'CASE' => 476,
			'DEFAULT' => 478
		},
		DEFAULT => -248,
		GOTOS => {
			'case_labels' => 501,
			'case_label' => 482
		}
	},
	{#State 483
		DEFAULT => -84
	},
	{#State 484
		DEFAULT => -287
	},
	{#State 485
		DEFAULT => -306
	},
	{#State 486
		ACTIONS => {
			")" => 502
		}
	},
	{#State 487
		ACTIONS => {
			"," => 503
		},
		DEFAULT => -330
	},
	{#State 488
		ACTIONS => {
			")" => 504
		}
	},
	{#State 489
		DEFAULT => -320
	},
	{#State 490
		DEFAULT => -319
	},
	{#State 491
		ACTIONS => {
			'IDENTIFIER' => 101,
			"::" => 95
		},
		GOTOS => {
			'scoped_name' => 468,
			'exception_names' => 505,
			'exception_name' => 471
		}
	},
	{#State 492
		ACTIONS => {
			'error' => 506,
			":" => 507
		}
	},
	{#State 493
		DEFAULT => -252
	},
	{#State 494
		DEFAULT => -246
	},
	{#State 495
		DEFAULT => -254
	},
	{#State 496
		DEFAULT => -253
	},
	{#State 497
		DEFAULT => -234
	},
	{#State 498
		DEFAULT => -233
	},
	{#State 499
		ACTIONS => {
			'error' => 133,
			'IDENTIFIER' => 234
		},
		GOTOS => {
			'declarator' => 508,
			'simple_declarator' => 232,
			'array_declarator' => 233,
			'complex_declarator' => 231
		}
	},
	{#State 500
		ACTIONS => {
			'error' => 47,
			";" => 46
		},
		GOTOS => {
			'check_semicolon' => 509
		}
	},
	{#State 501
		DEFAULT => -249
	},
	{#State 502
		DEFAULT => -327
	},
	{#State 503
		ACTIONS => {
			'STRING_LITERAL' => 297
		},
		GOTOS => {
			'string_literal' => 487,
			'string_literals' => 510
		}
	},
	{#State 504
		DEFAULT => -326
	},
	{#State 505
		DEFAULT => -324
	},
	{#State 506
		DEFAULT => -251
	},
	{#State 507
		DEFAULT => -250
	},
	{#State 508
		DEFAULT => -255
	},
	{#State 509
		DEFAULT => -247
	},
	{#State 510
		DEFAULT => -331
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
#line 70 "parser24.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 0,
sub
#line 76 "parser24.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 80 "parser24.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 87 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 91 "parser24.yp"
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
#line 112 "parser24.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
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
#line 126 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 15
		 'module', 4,
sub
#line 135 "parser24.yp"
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
#line 142 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 17
		 'module', 3,
sub
#line 148 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module', 3,
sub
#line 154 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 163 "parser24.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 169 "parser24.yp"
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
#line 186 "parser24.yp"
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
#line 194 "parser24.yp"
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
#line 202 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 26
		 'forward_dcl', 3,
sub
#line 213 "parser24.yp"
{
			if (defined $_[1] and $_[1] eq 'abstract') {
				new ForwardAbstractInterface($_[0],
						'idf'					=>	$_[3]
				);
			} elsif (defined $_[1] and $_[1] eq 'local') {
				new ForwardLocalInterface($_[0],
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
#line 229 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface_mod', 1, undef
	],
	[#Rule 29
		 'interface_mod', 1, undef
	],
	[#Rule 30
		 'interface_mod', 0, undef
	],
	[#Rule 31
		 'interface_header', 4,
sub
#line 247 "parser24.yp"
{
			if (defined $_[1] and $_[1] eq 'abstract') {
				new AbstractInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$_[4]
				);
			} elsif (defined $_[1] and $_[1] eq 'local') {
				new LocalInterface($_[0],
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
	[#Rule 32
		 'interface_header', 3,
sub
#line 266 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 33
		 'interface_body', 1, undef
	],
	[#Rule 34
		 'exports', 1,
sub
#line 280 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 35
		 'exports', 2,
sub
#line 284 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 36
		 '_export', 1, undef
	],
	[#Rule 37
		 '_export', 1,
sub
#line 295 "parser24.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 38
		 '_export', 1,
sub
#line 300 "parser24.yp"
{
			$_[0]->Error("initializer unexpected.\n");
			$_[1];						#default action
		}
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
		 'export', 2, undef
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 322 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 45
		 'interface_inheritance_spec', 2,
sub
#line 328 "parser24.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 46
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 47
		 'interface_names', 1,
sub
#line 338 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 48
		 'interface_names', 3,
sub
#line 342 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 49
		 'interface_name', 1,
sub
#line 351 "parser24.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 50
		 'scoped_name', 1, undef
	],
	[#Rule 51
		 'scoped_name', 2,
sub
#line 361 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 52
		 'scoped_name', 2,
sub
#line 365 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 53
		 'scoped_name', 3,
sub
#line 371 "parser24.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 54
		 'scoped_name', 3,
sub
#line 375 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
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
		 'value', 1, undef
	],
	[#Rule 59
		 'value_forward_dcl', 3,
sub
#line 397 "parser24.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 60
		 'value_forward_dcl', 3,
sub
#line 405 "parser24.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 61
		 'value_box_dcl', 2,
sub
#line 415 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 62
		 'value_box_header', 3,
sub
#line 426 "parser24.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new BoxedValue($_[0],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 63
		 'value_abs_dcl', 3,
sub
#line 438 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 64
		 'value_abs_dcl', 4,
sub
#line 446 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 65
		 'value_abs_dcl', 4,
sub
#line 454 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 66
		 'value_abs_header', 4,
sub
#line 464 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 67
		 'value_abs_header', 3,
sub
#line 471 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 68
		 'value_abs_header', 2,
sub
#line 476 "parser24.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 69
		 'value_dcl', 3,
sub
#line 485 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 70
		 'value_dcl', 4,
sub
#line 493 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 71
		 'value_dcl', 4,
sub
#line 501 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 72
		 'value_elements', 1,
sub
#line 511 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 73
		 'value_elements', 2,
sub
#line 515 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 74
		 'value_header', 4,
sub
#line 524 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 75
		 'value_header', 3,
sub
#line 532 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 76
		 'value_mod', 1, undef
	],
	[#Rule 77
		 'value_mod', 0, undef
	],
	[#Rule 78
		 'value_inheritance_spec', 4,
sub
#line 548 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 79
		 'value_inheritance_spec', 3,
sub
#line 556 "parser24.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 80
		 'value_inheritance_spec', 1,
sub
#line 561 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 81
		 'inheritance_mod', 1, undef
	],
	[#Rule 82
		 'inheritance_mod', 0, undef
	],
	[#Rule 83
		 'value_names', 1,
sub
#line 577 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 84
		 'value_names', 3,
sub
#line 581 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 85
		 'supported_interface_spec', 2,
sub
#line 589 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 86
		 'supported_interface_spec', 2,
sub
#line 593 "parser24.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 87
		 'supported_interface_spec', 0, undef
	],
	[#Rule 88
		 'value_name', 1,
sub
#line 604 "parser24.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 89
		 'value_element', 1, undef
	],
	[#Rule 90
		 'value_element', 1, undef
	],
	[#Rule 91
		 'value_element', 1, undef
	],
	[#Rule 92
		 'state_member', 4,
sub
#line 622 "parser24.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 93
		 'state_member', 4,
sub
#line 630 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 94
		 'state_member', 3,
sub
#line 635 "parser24.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 95
		 'state_mod', 1, undef
	],
	[#Rule 96
		 'state_mod', 1, undef
	],
	[#Rule 97
		 'init_dcl', 2, undef
	],
	[#Rule 98
		 'init_header_param', 3,
sub
#line 656 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 99
		 'init_header_param', 4,
sub
#line 662 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 100
		 'init_header_param', 4,
sub
#line 670 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 101
		 'init_header_param', 2,
sub
#line 677 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 102
		 'init_header', 2,
sub
#line 687 "parser24.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 103
		 'init_header', 2,
sub
#line 693 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 104
		 'init_param_decls', 1,
sub
#line 702 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 105
		 'init_param_decls', 3,
sub
#line 706 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 106
		 'init_param_decl', 3,
sub
#line 715 "parser24.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 107
		 'init_param_decl', 2,
sub
#line 723 "parser24.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 108
		 'init_param_attribute', 1, undef
	],
	[#Rule 109
		 'const_dcl', 5,
sub
#line 738 "parser24.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 110
		 'const_dcl', 5,
sub
#line 746 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 111
		 'const_dcl', 4,
sub
#line 751 "parser24.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'const_dcl', 3,
sub
#line 756 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 113
		 'const_dcl', 2,
sub
#line 761 "parser24.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
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
		 'const_type', 1, undef
	],
	[#Rule 122
		 'const_type', 1,
sub
#line 786 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 123
		 'const_type', 1, undef
	],
	[#Rule 124
		 'const_exp', 1, undef
	],
	[#Rule 125
		 'or_expr', 1, undef
	],
	[#Rule 126
		 'or_expr', 3,
sub
#line 804 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 127
		 'xor_expr', 1, undef
	],
	[#Rule 128
		 'xor_expr', 3,
sub
#line 814 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 129
		 'and_expr', 1, undef
	],
	[#Rule 130
		 'and_expr', 3,
sub
#line 824 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 131
		 'shift_expr', 1, undef
	],
	[#Rule 132
		 'shift_expr', 3,
sub
#line 834 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 133
		 'shift_expr', 3,
sub
#line 838 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 134
		 'add_expr', 1, undef
	],
	[#Rule 135
		 'add_expr', 3,
sub
#line 848 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 136
		 'add_expr', 3,
sub
#line 852 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 137
		 'mult_expr', 1, undef
	],
	[#Rule 138
		 'mult_expr', 3,
sub
#line 862 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 139
		 'mult_expr', 3,
sub
#line 866 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 140
		 'mult_expr', 3,
sub
#line 870 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 141
		 'unary_expr', 2,
sub
#line 878 "parser24.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 142
		 'unary_expr', 1, undef
	],
	[#Rule 143
		 'unary_operator', 1, undef
	],
	[#Rule 144
		 'unary_operator', 1, undef
	],
	[#Rule 145
		 'unary_operator', 1, undef
	],
	[#Rule 146
		 'primary_expr', 1,
sub
#line 898 "parser24.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 147
		 'primary_expr', 1,
sub
#line 904 "parser24.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 148
		 'primary_expr', 3,
sub
#line 908 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 149
		 'primary_expr', 3,
sub
#line 912 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 150
		 'literal', 1,
sub
#line 921 "parser24.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 151
		 'literal', 1,
sub
#line 928 "parser24.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 152
		 'literal', 1,
sub
#line 934 "parser24.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 153
		 'literal', 1,
sub
#line 940 "parser24.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 154
		 'literal', 1,
sub
#line 946 "parser24.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 155
		 'literal', 1,
sub
#line 952 "parser24.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 156
		 'literal', 1,
sub
#line 959 "parser24.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 157
		 'literal', 1, undef
	],
	[#Rule 158
		 'string_literal', 1, undef
	],
	[#Rule 159
		 'string_literal', 2,
sub
#line 973 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 160
		 'wide_string_literal', 1, undef
	],
	[#Rule 161
		 'wide_string_literal', 2,
sub
#line 982 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 162
		 'boolean_literal', 1,
sub
#line 990 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 163
		 'boolean_literal', 1,
sub
#line 996 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 164
		 'positive_int_const', 1,
sub
#line 1006 "parser24.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'type_dcl', 2,
sub
#line 1016 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 166
		 'type_dcl', 1, undef
	],
	[#Rule 167
		 'type_dcl', 1, undef
	],
	[#Rule 168
		 'type_dcl', 1, undef
	],
	[#Rule 169
		 'type_dcl', 2,
sub
#line 1026 "parser24.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 170
		 'type_dcl', 1, undef
	],
	[#Rule 171
		 'type_dcl', 2,
sub
#line 1035 "parser24.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 172
		 'type_declarator', 2,
sub
#line 1044 "parser24.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 173
		 'type_spec', 1, undef
	],
	[#Rule 174
		 'type_spec', 1, undef
	],
	[#Rule 175
		 'simple_type_spec', 1, undef
	],
	[#Rule 176
		 'simple_type_spec', 1, undef
	],
	[#Rule 177
		 'simple_type_spec', 1,
sub
#line 1067 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 178
		 'simple_type_spec', 1,
sub
#line 1071 "parser24.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
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
		 'base_type_spec', 1, undef
	],
	[#Rule 187
		 'base_type_spec', 1, undef
	],
	[#Rule 188
		 'template_type_spec', 1, undef
	],
	[#Rule 189
		 'template_type_spec', 1, undef
	],
	[#Rule 190
		 'template_type_spec', 1, undef
	],
	[#Rule 191
		 'template_type_spec', 1, undef
	],
	[#Rule 192
		 'constr_type_spec', 1, undef
	],
	[#Rule 193
		 'constr_type_spec', 1, undef
	],
	[#Rule 194
		 'constr_type_spec', 1, undef
	],
	[#Rule 195
		 'declarators', 1,
sub
#line 1126 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 196
		 'declarators', 3,
sub
#line 1130 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 197
		 'declarator', 1,
sub
#line 1139 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 198
		 'declarator', 1, undef
	],
	[#Rule 199
		 'simple_declarator', 1, undef
	],
	[#Rule 200
		 'simple_declarator', 2,
sub
#line 1151 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 201
		 'simple_declarator', 2,
sub
#line 1156 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 202
		 'complex_declarator', 1, undef
	],
	[#Rule 203
		 'floating_pt_type', 1,
sub
#line 1171 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 204
		 'floating_pt_type', 1,
sub
#line 1177 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 205
		 'floating_pt_type', 2,
sub
#line 1183 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 206
		 'integer_type', 1, undef
	],
	[#Rule 207
		 'integer_type', 1, undef
	],
	[#Rule 208
		 'signed_int', 1, undef
	],
	[#Rule 209
		 'signed_int', 1, undef
	],
	[#Rule 210
		 'signed_int', 1, undef
	],
	[#Rule 211
		 'signed_short_int', 1,
sub
#line 1211 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 212
		 'signed_long_int', 1,
sub
#line 1221 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 213
		 'signed_longlong_int', 2,
sub
#line 1231 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 214
		 'unsigned_int', 1, undef
	],
	[#Rule 215
		 'unsigned_int', 1, undef
	],
	[#Rule 216
		 'unsigned_int', 1, undef
	],
	[#Rule 217
		 'unsigned_short_int', 2,
sub
#line 1251 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 218
		 'unsigned_long_int', 2,
sub
#line 1261 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 219
		 'unsigned_longlong_int', 3,
sub
#line 1271 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 220
		 'char_type', 1,
sub
#line 1281 "parser24.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 221
		 'wide_char_type', 1,
sub
#line 1291 "parser24.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 222
		 'boolean_type', 1,
sub
#line 1301 "parser24.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 223
		 'octet_type', 1,
sub
#line 1311 "parser24.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 224
		 'any_type', 1,
sub
#line 1321 "parser24.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 225
		 'object_type', 1,
sub
#line 1331 "parser24.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 226
		 'struct_type', 4,
sub
#line 1341 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 227
		 'struct_type', 4,
sub
#line 1348 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 228
		 'struct_header', 2,
sub
#line 1357 "parser24.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 229
		 'struct_header', 2,
sub
#line 1363 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 230
		 'member_list', 1,
sub
#line 1372 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 231
		 'member_list', 2,
sub
#line 1376 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 232
		 'member', 3,
sub
#line 1385 "parser24.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 233
		 'union_type', 8,
sub
#line 1396 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 234
		 'union_type', 8,
sub
#line 1404 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 235
		 'union_type', 6,
sub
#line 1410 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 236
		 'union_type', 5,
sub
#line 1416 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 237
		 'union_type', 3,
sub
#line 1422 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 238
		 'union_header', 2,
sub
#line 1431 "parser24.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 239
		 'union_header', 2,
sub
#line 1437 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 240
		 'switch_type_spec', 1, undef
	],
	[#Rule 241
		 'switch_type_spec', 1, undef
	],
	[#Rule 242
		 'switch_type_spec', 1, undef
	],
	[#Rule 243
		 'switch_type_spec', 1, undef
	],
	[#Rule 244
		 'switch_type_spec', 1,
sub
#line 1454 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 245
		 'switch_body', 1,
sub
#line 1462 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 246
		 'switch_body', 2,
sub
#line 1466 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 247
		 'case', 3,
sub
#line 1475 "parser24.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 248
		 'case_labels', 1,
sub
#line 1485 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 249
		 'case_labels', 2,
sub
#line 1489 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 250
		 'case_label', 3,
sub
#line 1498 "parser24.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 251
		 'case_label', 3,
sub
#line 1502 "parser24.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 252
		 'case_label', 2,
sub
#line 1508 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 253
		 'case_label', 2,
sub
#line 1513 "parser24.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 254
		 'case_label', 2,
sub
#line 1517 "parser24.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 255
		 'element_spec', 2,
sub
#line 1527 "parser24.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 256
		 'enum_type', 4,
sub
#line 1538 "parser24.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 257
		 'enum_type', 4,
sub
#line 1544 "parser24.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 258
		 'enum_type', 2,
sub
#line 1549 "parser24.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 259
		 'enum_header', 2,
sub
#line 1557 "parser24.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 260
		 'enum_header', 2,
sub
#line 1563 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 261
		 'enumerators', 1,
sub
#line 1571 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 262
		 'enumerators', 3,
sub
#line 1575 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 263
		 'enumerators', 2,
sub
#line 1580 "parser24.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 264
		 'enumerators', 2,
sub
#line 1585 "parser24.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 265
		 'enumerator', 1,
sub
#line 1594 "parser24.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 266
		 'sequence_type', 6,
sub
#line 1604 "parser24.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 267
		 'sequence_type', 6,
sub
#line 1612 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'sequence_type', 4,
sub
#line 1617 "parser24.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 269
		 'sequence_type', 4,
sub
#line 1624 "parser24.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 270
		 'sequence_type', 2,
sub
#line 1629 "parser24.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 271
		 'string_type', 4,
sub
#line 1638 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 272
		 'string_type', 1,
sub
#line 1645 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 273
		 'string_type', 4,
sub
#line 1651 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 274
		 'wide_string_type', 4,
sub
#line 1660 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 275
		 'wide_string_type', 1,
sub
#line 1667 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 276
		 'wide_string_type', 4,
sub
#line 1673 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'array_declarator', 2,
sub
#line 1682 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 278
		 'fixed_array_sizes', 1,
sub
#line 1690 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 279
		 'fixed_array_sizes', 2,
sub
#line 1694 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 280
		 'fixed_array_size', 3,
sub
#line 1703 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 281
		 'fixed_array_size', 3,
sub
#line 1707 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 282
		 'attr_dcl', 4,
sub
#line 1716 "parser24.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 283
		 'attr_dcl', 3,
sub
#line 1724 "parser24.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 284
		 'attr_mod', 1, undef
	],
	[#Rule 285
		 'attr_mod', 0, undef
	],
	[#Rule 286
		 'simple_declarators', 1,
sub
#line 1739 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 287
		 'simple_declarators', 3,
sub
#line 1743 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 288
		 'except_dcl', 3,
sub
#line 1752 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 289
		 'except_dcl', 4,
sub
#line 1757 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 290
		 'except_dcl', 4,
sub
#line 1764 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 291
		 'except_dcl', 2,
sub
#line 1770 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 292
		 'exception_header', 2,
sub
#line 1779 "parser24.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 293
		 'exception_header', 2,
sub
#line 1785 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 294
		 'op_dcl', 4,
sub
#line 1794 "parser24.yp"
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
	[#Rule 295
		 'op_dcl', 2,
sub
#line 1804 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 296
		 'op_header', 3,
sub
#line 1814 "parser24.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 297
		 'op_header', 3,
sub
#line 1822 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 298
		 'op_mod', 1, undef
	],
	[#Rule 299
		 'op_mod', 0, undef
	],
	[#Rule 300
		 'op_attribute', 1, undef
	],
	[#Rule 301
		 'op_type_spec', 1, undef
	],
	[#Rule 302
		 'op_type_spec', 1,
sub
#line 1846 "parser24.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 303
		 'op_type_spec', 1,
sub
#line 1852 "parser24.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 304
		 'op_type_spec', 1,
sub
#line 1857 "parser24.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 305
		 'parameter_dcls', 3,
sub
#line 1866 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 306
		 'parameter_dcls', 5,
sub
#line 1870 "parser24.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 307
		 'parameter_dcls', 4,
sub
#line 1875 "parser24.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 308
		 'parameter_dcls', 2,
sub
#line 1880 "parser24.yp"
{
			undef;
		}
	],
	[#Rule 309
		 'parameter_dcls', 3,
sub
#line 1884 "parser24.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 310
		 'parameter_dcls', 3,
sub
#line 1889 "parser24.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 311
		 'param_dcls', 1,
sub
#line 1897 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 312
		 'param_dcls', 3,
sub
#line 1901 "parser24.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 313
		 'param_dcls', 2,
sub
#line 1906 "parser24.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 314
		 'param_dcl', 3,
sub
#line 1915 "parser24.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 315
		 'param_attribute', 1, undef
	],
	[#Rule 316
		 'param_attribute', 1, undef
	],
	[#Rule 317
		 'param_attribute', 1, undef
	],
	[#Rule 318
		 'param_attribute', 0,
sub
#line 1933 "parser24.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 319
		 'raises_expr', 4,
sub
#line 1942 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 320
		 'raises_expr', 4,
sub
#line 1946 "parser24.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 321
		 'raises_expr', 2,
sub
#line 1951 "parser24.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 322
		 'raises_expr', 0, undef
	],
	[#Rule 323
		 'exception_names', 1,
sub
#line 1961 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 324
		 'exception_names', 3,
sub
#line 1965 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 325
		 'exception_name', 1,
sub
#line 1973 "parser24.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 326
		 'context_expr', 4,
sub
#line 1981 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 327
		 'context_expr', 4,
sub
#line 1985 "parser24.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 328
		 'context_expr', 2,
sub
#line 1990 "parser24.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 329
		 'context_expr', 0, undef
	],
	[#Rule 330
		 'string_literals', 1,
sub
#line 2000 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 331
		 'string_literals', 3,
sub
#line 2004 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 332
		 'param_type_spec', 1, undef
	],
	[#Rule 333
		 'param_type_spec', 1,
sub
#line 2015 "parser24.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 334
		 'param_type_spec', 1,
sub
#line 2020 "parser24.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 335
		 'param_type_spec', 1,
sub
#line 2025 "parser24.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 336
		 'param_type_spec', 1,
sub
#line 2030 "parser24.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 337
		 'op_param_type_spec', 1, undef
	],
	[#Rule 338
		 'op_param_type_spec', 1, undef
	],
	[#Rule 339
		 'op_param_type_spec', 1, undef
	],
	[#Rule 340
		 'op_param_type_spec', 1,
sub
#line 2044 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 341
		 'fixed_pt_type', 6,
sub
#line 2052 "parser24.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 342
		 'fixed_pt_type', 6,
sub
#line 2060 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 343
		 'fixed_pt_type', 4,
sub
#line 2065 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 344
		 'fixed_pt_type', 2,
sub
#line 2070 "parser24.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 345
		 'fixed_pt_const_type', 1,
sub
#line 2079 "parser24.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 346
		 'value_base_type', 1,
sub
#line 2089 "parser24.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 347
		 'constr_forward_decl', 2,
sub
#line 2099 "parser24.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 348
		 'constr_forward_decl', 2,
sub
#line 2105 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 349
		 'constr_forward_decl', 2,
sub
#line 2110 "parser24.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 350
		 'constr_forward_decl', 2,
sub
#line 2116 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 2122 "parser24.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '2.4';

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
