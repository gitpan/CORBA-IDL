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
			'TYPEDEF' => 34,
			'IDENTIFIER' => 36,
			'NATIVE' => 29,
			'MODULE' => 11,
			'ABSTRACT' => 2,
			'UNION' => 37,
			'STRUCT' => 31,
			'error' => 17,
			'CONST' => 19,
			'CUSTOM' => 40,
			'EXCEPTION' => 22,
			'VALUETYPE' => -75,
			'ENUM' => 25,
			'INTERFACE' => -29
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 27,
			'interface_header' => 28,
			'except_dcl' => 3,
			'value_header' => 30,
			'specification' => 4,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 9,
			'struct_type' => 32,
			'union_type' => 35,
			'exception_header' => 33,
			'struct_header' => 10,
			'interface_dcl' => 12,
			'value' => 13,
			'value_box_header' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 38,
			'enum_header' => 18,
			'value_abs_dcl' => 21,
			'value_mod' => 20,
			'type_dcl' => 39,
			'union_header' => 23,
			'definitions' => 24,
			'definition' => 41,
			'interface_mod' => 26
		}
	},
	{#State 1
		DEFAULT => -56
	},
	{#State 2
		ACTIONS => {
			'error' => 43,
			'VALUETYPE' => 42,
			'INTERFACE' => -28
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 46
		}
	},
	{#State 4
		ACTIONS => {
			'' => 47
		}
	},
	{#State 5
		ACTIONS => {
			"{" => 49,
			'error' => 48
		}
	},
	{#State 6
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 50
		}
	},
	{#State 7
		DEFAULT => -55
	},
	{#State 8
		ACTIONS => {
			"{" => 51
		}
	},
	{#State 9
		DEFAULT => -53
	},
	{#State 10
		ACTIONS => {
			"{" => 52
		}
	},
	{#State 11
		ACTIONS => {
			'error' => 53,
			'IDENTIFIER' => 54
		}
	},
	{#State 12
		DEFAULT => -21
	},
	{#State 13
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 55
		}
	},
	{#State 14
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 86,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'wide_char_type' => 66,
			'type_spec' => 68,
			'signed_long_int' => 67,
			'string_type' => 70,
			'struct_header' => 10,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'base_type_spec' => 75,
			'enum_type' => 76,
			'enum_header' => 18,
			'union_header' => 23,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 85,
			'boolean_type' => 87,
			'integer_type' => 88,
			'signed_short_int' => 93,
			'struct_type' => 95,
			'union_type' => 97,
			'sequence_type' => 99,
			'unsigned_long_int' => 100,
			'template_type_spec' => 101,
			'constr_type_spec' => 102,
			'simple_type_spec' => 103,
			'fixed_pt_type' => 104
		}
	},
	{#State 15
		DEFAULT => -166
	},
	{#State 16
		DEFAULT => -22
	},
	{#State 17
		DEFAULT => -3
	},
	{#State 18
		ACTIONS => {
			"{" => 106,
			'error' => 105
		}
	},
	{#State 19
		ACTIONS => {
			'CHAR' => 82,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'FIXED' => 108,
			'WCHAR' => 72,
			'DOUBLE' => 89,
			'error' => 114,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'OCTET' => 77,
			'FLOAT' => 79,
			'WSTRING' => 94,
			'UNSIGNED' => 69
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 107,
			'signed_int' => 59,
			'wide_string_type' => 115,
			'integer_type' => 117,
			'boolean_type' => 116,
			'char_type' => 109,
			'octet_type' => 110,
			'scoped_name' => 111,
			'fixed_pt_const_type' => 118,
			'wide_char_type' => 112,
			'signed_long_int' => 67,
			'signed_short_int' => 93,
			'const_type' => 119,
			'string_type' => 113,
			'unsigned_longlong_int' => 73,
			'unsigned_long_int' => 100,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80
		}
	},
	{#State 20
		ACTIONS => {
			'VALUETYPE' => 120
		}
	},
	{#State 21
		DEFAULT => -54
	},
	{#State 22
		ACTIONS => {
			'error' => 121,
			'IDENTIFIER' => 122
		}
	},
	{#State 23
		ACTIONS => {
			'SWITCH' => 123
		}
	},
	{#State 24
		DEFAULT => -1
	},
	{#State 25
		ACTIONS => {
			'error' => 124,
			'IDENTIFIER' => 125
		}
	},
	{#State 26
		ACTIONS => {
			'INTERFACE' => 126
		}
	},
	{#State 27
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 127
		}
	},
	{#State 28
		ACTIONS => {
			"{" => 128
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 131
		},
		GOTOS => {
			'simple_declarator' => 130
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
			'IDENTIFIER' => 134
		}
	},
	{#State 32
		DEFAULT => -164
	},
	{#State 33
		ACTIONS => {
			"{" => 136,
			'error' => 135
		}
	},
	{#State 34
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 86,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'error' => 139,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'wide_char_type' => 66,
			'type_spec' => 137,
			'signed_long_int' => 67,
			'type_declarator' => 138,
			'string_type' => 70,
			'struct_header' => 10,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'base_type_spec' => 75,
			'enum_type' => 76,
			'enum_header' => 18,
			'union_header' => 23,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 85,
			'boolean_type' => 87,
			'integer_type' => 88,
			'signed_short_int' => 93,
			'struct_type' => 95,
			'union_type' => 97,
			'sequence_type' => 99,
			'unsigned_long_int' => 100,
			'template_type_spec' => 101,
			'constr_type_spec' => 102,
			'simple_type_spec' => 103,
			'fixed_pt_type' => 104
		}
	},
	{#State 35
		DEFAULT => -165
	},
	{#State 36
		ACTIONS => {
			'error' => 140
		}
	},
	{#State 37
		ACTIONS => {
			'error' => 141,
			'IDENTIFIER' => 142
		}
	},
	{#State 38
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 143
		}
	},
	{#State 39
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 144
		}
	},
	{#State 40
		DEFAULT => -74
	},
	{#State 41
		ACTIONS => {
			'TYPEDEF' => 34,
			'IDENTIFIER' => 36,
			'NATIVE' => 29,
			'MODULE' => 11,
			'ABSTRACT' => 2,
			'UNION' => 37,
			'STRUCT' => 31,
			'CONST' => 19,
			'CUSTOM' => 40,
			'EXCEPTION' => 22,
			'VALUETYPE' => -75,
			'ENUM' => 25,
			'INTERFACE' => -29
		},
		DEFAULT => -4,
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 27,
			'interface_header' => 28,
			'except_dcl' => 3,
			'value_header' => 30,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 9,
			'struct_type' => 32,
			'union_type' => 35,
			'exception_header' => 33,
			'struct_header' => 10,
			'interface_dcl' => 12,
			'value' => 13,
			'value_box_header' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 38,
			'enum_header' => 18,
			'value_mod' => 20,
			'value_abs_dcl' => 21,
			'type_dcl' => 39,
			'definitions' => 145,
			'union_header' => 23,
			'definition' => 41,
			'interface_mod' => 26
		}
	},
	{#State 42
		ACTIONS => {
			'error' => 146,
			'IDENTIFIER' => 147
		}
	},
	{#State 43
		DEFAULT => -66
	},
	{#State 44
		DEFAULT => -13
	},
	{#State 45
		DEFAULT => -14
	},
	{#State 46
		DEFAULT => -8
	},
	{#State 47
		DEFAULT => 0
	},
	{#State 48
		ACTIONS => {
			"}" => 148
		}
	},
	{#State 49
		ACTIONS => {
			'TYPEDEF' => 34,
			'IDENTIFIER' => 36,
			'NATIVE' => 29,
			'MODULE' => 11,
			'ABSTRACT' => 2,
			'UNION' => 37,
			'STRUCT' => 31,
			'error' => 149,
			'CONST' => 19,
			'CUSTOM' => 40,
			'EXCEPTION' => 22,
			"}" => 150,
			'VALUETYPE' => -75,
			'ENUM' => 25,
			'INTERFACE' => -29
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 27,
			'interface_header' => 28,
			'except_dcl' => 3,
			'value_header' => 30,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 9,
			'struct_type' => 32,
			'union_type' => 35,
			'exception_header' => 33,
			'struct_header' => 10,
			'interface_dcl' => 12,
			'value' => 13,
			'value_box_header' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 38,
			'enum_header' => 18,
			'value_mod' => 20,
			'value_abs_dcl' => 21,
			'type_dcl' => 39,
			'definitions' => 151,
			'union_header' => 23,
			'definition' => 41,
			'interface_mod' => 26
		}
	},
	{#State 50
		DEFAULT => -9
	},
	{#State 51
		ACTIONS => {
			'PRIVATE' => 153,
			'ONEWAY' => 154,
			'FIXED' => -296,
			'SEQUENCE' => -296,
			'FACTORY' => 161,
			'UNSIGNED' => -296,
			'SHORT' => -296,
			'WCHAR' => -296,
			'error' => 163,
			'CONST' => 19,
			'FLOAT' => -296,
			'OCTET' => -296,
			"}" => 164,
			'EXCEPTION' => 22,
			'ENUM' => 25,
			'ANY' => -296,
			'CHAR' => -296,
			'OBJECT' => -296,
			'NATIVE' => 29,
			'VALUEBASE' => -296,
			'VOID' => -296,
			'STRUCT' => 31,
			'DOUBLE' => -296,
			'LONG' => -296,
			'STRING' => -296,
			"::" => -296,
			'WSTRING' => -296,
			'TYPEDEF' => 34,
			'BOOLEAN' => -296,
			'IDENTIFIER' => -296,
			'UNION' => 37,
			'READONLY' => 170,
			'ATTRIBUTE' => -282,
			'PUBLIC' => 171
		},
		GOTOS => {
			'init_header_param' => 152,
			'const_dcl' => 165,
			'op_mod' => 155,
			'state_member' => 157,
			'except_dcl' => 156,
			'op_attribute' => 158,
			'attr_mod' => 159,
			'state_mod' => 160,
			'exports' => 166,
			'_export' => 167,
			'export' => 168,
			'init_header' => 162,
			'struct_type' => 32,
			'op_header' => 169,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 172,
			'init_dcl' => 173,
			'enum_header' => 18,
			'attr_dcl' => 174,
			'type_dcl' => 175,
			'union_header' => 23
		}
	},
	{#State 52
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 86,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'error' => 177,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'type_spec' => 176,
			'string_type' => 70,
			'struct_header' => 10,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'base_type_spec' => 75,
			'enum_type' => 76,
			'enum_header' => 18,
			'member_list' => 178,
			'union_header' => 23,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 85,
			'boolean_type' => 87,
			'integer_type' => 88,
			'signed_short_int' => 93,
			'member' => 179,
			'struct_type' => 95,
			'union_type' => 97,
			'sequence_type' => 99,
			'unsigned_long_int' => 100,
			'template_type_spec' => 101,
			'constr_type_spec' => 102,
			'simple_type_spec' => 103,
			'fixed_pt_type' => 104
		}
	},
	{#State 53
		DEFAULT => -20
	},
	{#State 54
		DEFAULT => -19
	},
	{#State 55
		DEFAULT => -11
	},
	{#State 56
		DEFAULT => -204
	},
	{#State 57
		DEFAULT => -176
	},
	{#State 58
		ACTIONS => {
			"<" => 181,
			'error' => 180
		}
	},
	{#State 59
		DEFAULT => -203
	},
	{#State 60
		ACTIONS => {
			"<" => 183,
			'error' => 182
		}
	},
	{#State 61
		DEFAULT => -184
	},
	{#State 62
		DEFAULT => -178
	},
	{#State 63
		DEFAULT => -183
	},
	{#State 64
		DEFAULT => -181
	},
	{#State 65
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -174
	},
	{#State 66
		DEFAULT => -179
	},
	{#State 67
		DEFAULT => -206
	},
	{#State 68
		DEFAULT => -59
	},
	{#State 69
		ACTIONS => {
			'SHORT' => 185,
			'LONG' => 186
		}
	},
	{#State 70
		DEFAULT => -186
	},
	{#State 71
		DEFAULT => -208
	},
	{#State 72
		DEFAULT => -218
	},
	{#State 73
		DEFAULT => -213
	},
	{#State 74
		DEFAULT => -182
	},
	{#State 75
		DEFAULT => -172
	},
	{#State 76
		DEFAULT => -191
	},
	{#State 77
		DEFAULT => -220
	},
	{#State 78
		DEFAULT => -211
	},
	{#State 79
		DEFAULT => -200
	},
	{#State 80
		DEFAULT => -207
	},
	{#State 81
		DEFAULT => -221
	},
	{#State 82
		DEFAULT => -217
	},
	{#State 83
		DEFAULT => -222
	},
	{#State 84
		DEFAULT => -343
	},
	{#State 85
		DEFAULT => -187
	},
	{#State 86
		DEFAULT => -175
	},
	{#State 87
		DEFAULT => -180
	},
	{#State 88
		DEFAULT => -177
	},
	{#State 89
		DEFAULT => -201
	},
	{#State 90
		ACTIONS => {
			'DOUBLE' => 187,
			'LONG' => 188
		},
		DEFAULT => -209
	},
	{#State 91
		ACTIONS => {
			"<" => 189
		},
		DEFAULT => -269
	},
	{#State 92
		ACTIONS => {
			'error' => 190,
			'IDENTIFIER' => 191
		}
	},
	{#State 93
		DEFAULT => -205
	},
	{#State 94
		ACTIONS => {
			"<" => 192
		},
		DEFAULT => -272
	},
	{#State 95
		DEFAULT => -189
	},
	{#State 96
		DEFAULT => -219
	},
	{#State 97
		DEFAULT => -190
	},
	{#State 98
		DEFAULT => -48
	},
	{#State 99
		DEFAULT => -185
	},
	{#State 100
		DEFAULT => -212
	},
	{#State 101
		DEFAULT => -173
	},
	{#State 102
		DEFAULT => -171
	},
	{#State 103
		DEFAULT => -170
	},
	{#State 104
		DEFAULT => -188
	},
	{#State 105
		DEFAULT => -255
	},
	{#State 106
		ACTIONS => {
			'error' => 193,
			'IDENTIFIER' => 195
		},
		GOTOS => {
			'enumerators' => 196,
			'enumerator' => 194
		}
	},
	{#State 107
		DEFAULT => -116
	},
	{#State 108
		DEFAULT => -342
	},
	{#State 109
		DEFAULT => -113
	},
	{#State 110
		DEFAULT => -121
	},
	{#State 111
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -120
	},
	{#State 112
		DEFAULT => -114
	},
	{#State 113
		DEFAULT => -117
	},
	{#State 114
		DEFAULT => -111
	},
	{#State 115
		DEFAULT => -118
	},
	{#State 116
		DEFAULT => -115
	},
	{#State 117
		DEFAULT => -112
	},
	{#State 118
		DEFAULT => -119
	},
	{#State 119
		ACTIONS => {
			'error' => 197,
			'IDENTIFIER' => 198
		}
	},
	{#State 120
		ACTIONS => {
			'error' => 199,
			'IDENTIFIER' => 200
		}
	},
	{#State 121
		DEFAULT => -290
	},
	{#State 122
		DEFAULT => -289
	},
	{#State 123
		ACTIONS => {
			'error' => 202,
			"(" => 201
		}
	},
	{#State 124
		DEFAULT => -257
	},
	{#State 125
		DEFAULT => -256
	},
	{#State 126
		ACTIONS => {
			'error' => 203,
			'IDENTIFIER' => 204
		}
	},
	{#State 127
		DEFAULT => -7
	},
	{#State 128
		ACTIONS => {
			'PRIVATE' => 153,
			'ONEWAY' => 154,
			'FIXED' => -296,
			'SEQUENCE' => -296,
			'FACTORY' => 161,
			'UNSIGNED' => -296,
			'SHORT' => -296,
			'WCHAR' => -296,
			'error' => 205,
			'CONST' => 19,
			'FLOAT' => -296,
			'OCTET' => -296,
			"}" => 206,
			'EXCEPTION' => 22,
			'ENUM' => 25,
			'ANY' => -296,
			'CHAR' => -296,
			'OBJECT' => -296,
			'NATIVE' => 29,
			'VALUEBASE' => -296,
			'VOID' => -296,
			'STRUCT' => 31,
			'DOUBLE' => -296,
			'LONG' => -296,
			'STRING' => -296,
			"::" => -296,
			'WSTRING' => -296,
			'TYPEDEF' => 34,
			'BOOLEAN' => -296,
			'IDENTIFIER' => -296,
			'UNION' => 37,
			'READONLY' => 170,
			'ATTRIBUTE' => -282,
			'PUBLIC' => 171
		},
		GOTOS => {
			'init_header_param' => 152,
			'const_dcl' => 165,
			'op_mod' => 155,
			'state_member' => 157,
			'except_dcl' => 156,
			'op_attribute' => 158,
			'attr_mod' => 159,
			'state_mod' => 160,
			'exports' => 207,
			'_export' => 167,
			'export' => 168,
			'init_header' => 162,
			'struct_type' => 32,
			'op_header' => 169,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 172,
			'init_dcl' => 173,
			'enum_header' => 18,
			'attr_dcl' => 174,
			'type_dcl' => 175,
			'union_header' => 23,
			'interface_body' => 208
		}
	},
	{#State 129
		ACTIONS => {
			";" => 209,
			"," => 210
		}
	},
	{#State 130
		DEFAULT => -167
	},
	{#State 131
		DEFAULT => -196
	},
	{#State 132
		ACTIONS => {
			'PRIVATE' => 153,
			'ONEWAY' => 154,
			'FIXED' => -296,
			'SEQUENCE' => -296,
			'FACTORY' => 161,
			'UNSIGNED' => -296,
			'SHORT' => -296,
			'WCHAR' => -296,
			'error' => 213,
			'CONST' => 19,
			'FLOAT' => -296,
			'OCTET' => -296,
			"}" => 214,
			'EXCEPTION' => 22,
			'ENUM' => 25,
			'ANY' => -296,
			'CHAR' => -296,
			'OBJECT' => -296,
			'NATIVE' => 29,
			'VALUEBASE' => -296,
			'VOID' => -296,
			'STRUCT' => 31,
			'DOUBLE' => -296,
			'LONG' => -296,
			'STRING' => -296,
			"::" => -296,
			'WSTRING' => -296,
			'TYPEDEF' => 34,
			'BOOLEAN' => -296,
			'IDENTIFIER' => -296,
			'UNION' => 37,
			'READONLY' => 170,
			'ATTRIBUTE' => -282,
			'PUBLIC' => 171
		},
		GOTOS => {
			'init_header_param' => 152,
			'const_dcl' => 165,
			'op_mod' => 155,
			'value_elements' => 215,
			'except_dcl' => 156,
			'state_member' => 211,
			'op_attribute' => 158,
			'attr_mod' => 159,
			'state_mod' => 160,
			'value_element' => 212,
			'export' => 216,
			'init_header' => 162,
			'struct_type' => 32,
			'op_header' => 169,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 172,
			'init_dcl' => 217,
			'enum_header' => 18,
			'attr_dcl' => 174,
			'type_dcl' => 175,
			'union_header' => 23
		}
	},
	{#State 133
		DEFAULT => -226
	},
	{#State 134
		DEFAULT => -225
	},
	{#State 135
		DEFAULT => -288
	},
	{#State 136
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 86,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'error' => 218,
			"}" => 220,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'type_spec' => 176,
			'string_type' => 70,
			'struct_header' => 10,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'base_type_spec' => 75,
			'enum_type' => 76,
			'enum_header' => 18,
			'member_list' => 219,
			'union_header' => 23,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 85,
			'boolean_type' => 87,
			'integer_type' => 88,
			'signed_short_int' => 93,
			'member' => 179,
			'struct_type' => 95,
			'union_type' => 97,
			'sequence_type' => 99,
			'unsigned_long_int' => 100,
			'template_type_spec' => 101,
			'constr_type_spec' => 102,
			'simple_type_spec' => 103,
			'fixed_pt_type' => 104
		}
	},
	{#State 137
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 226
		},
		GOTOS => {
			'declarators' => 221,
			'declarator' => 222,
			'simple_declarator' => 224,
			'array_declarator' => 225,
			'complex_declarator' => 223
		}
	},
	{#State 138
		DEFAULT => -163
	},
	{#State 139
		DEFAULT => -168
	},
	{#State 140
		ACTIONS => {
			";" => 227
		}
	},
	{#State 141
		DEFAULT => -236
	},
	{#State 142
		DEFAULT => -235
	},
	{#State 143
		DEFAULT => -10
	},
	{#State 144
		DEFAULT => -6
	},
	{#State 145
		DEFAULT => -5
	},
	{#State 146
		DEFAULT => -65
	},
	{#State 147
		ACTIONS => {
			"{" => -85,
			'SUPPORTS' => 230,
			":" => 229
		},
		DEFAULT => -58,
		GOTOS => {
			'supported_interface_spec' => 231,
			'value_inheritance_spec' => 228
		}
	},
	{#State 148
		DEFAULT => -18
	},
	{#State 149
		ACTIONS => {
			"}" => 232
		}
	},
	{#State 150
		DEFAULT => -17
	},
	{#State 151
		ACTIONS => {
			"}" => 233
		}
	},
	{#State 152
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 234
		}
	},
	{#State 153
		DEFAULT => -94
	},
	{#State 154
		DEFAULT => -297
	},
	{#State 155
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 239,
			'SEQUENCE' => 60,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'WCHAR' => 72,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'wide_string_type' => 238,
			'integer_type' => 88,
			'boolean_type' => 87,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 235,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'signed_short_int' => 93,
			'string_type' => 236,
			'op_type_spec' => 241,
			'op_param_type_spec' => 240,
			'sequence_type' => 242,
			'base_type_spec' => 237,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'unsigned_long_int' => 100,
			'unsigned_short_int' => 78,
			'fixed_pt_type' => 243,
			'signed_longlong_int' => 80
		}
	},
	{#State 156
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 244
		}
	},
	{#State 157
		DEFAULT => -36
	},
	{#State 158
		DEFAULT => -295
	},
	{#State 159
		ACTIONS => {
			'ATTRIBUTE' => 245
		}
	},
	{#State 160
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 86,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'error' => 247,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'wide_char_type' => 66,
			'type_spec' => 246,
			'signed_long_int' => 67,
			'string_type' => 70,
			'struct_header' => 10,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'base_type_spec' => 75,
			'enum_type' => 76,
			'enum_header' => 18,
			'union_header' => 23,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 85,
			'boolean_type' => 87,
			'integer_type' => 88,
			'signed_short_int' => 93,
			'struct_type' => 95,
			'union_type' => 97,
			'sequence_type' => 99,
			'unsigned_long_int' => 100,
			'template_type_spec' => 101,
			'constr_type_spec' => 102,
			'simple_type_spec' => 103,
			'fixed_pt_type' => 104
		}
	},
	{#State 161
		ACTIONS => {
			'error' => 248,
			'IDENTIFIER' => 249
		}
	},
	{#State 162
		ACTIONS => {
			'error' => 251,
			"(" => 250
		}
	},
	{#State 163
		ACTIONS => {
			"}" => 252
		}
	},
	{#State 164
		DEFAULT => -61
	},
	{#State 165
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 253
		}
	},
	{#State 166
		ACTIONS => {
			"}" => 254
		}
	},
	{#State 167
		ACTIONS => {
			'PRIVATE' => 153,
			'ONEWAY' => 154,
			'FACTORY' => 161,
			'CONST' => 19,
			'EXCEPTION' => 22,
			"}" => -33,
			'ENUM' => 25,
			'NATIVE' => 29,
			'STRUCT' => 31,
			'TYPEDEF' => 34,
			'UNION' => 37,
			'READONLY' => 170,
			'ATTRIBUTE' => -282,
			'PUBLIC' => 171
		},
		DEFAULT => -296,
		GOTOS => {
			'init_header_param' => 152,
			'const_dcl' => 165,
			'op_mod' => 155,
			'state_member' => 157,
			'except_dcl' => 156,
			'op_attribute' => 158,
			'attr_mod' => 159,
			'state_mod' => 160,
			'exports' => 255,
			'_export' => 167,
			'export' => 168,
			'init_header' => 162,
			'struct_type' => 32,
			'op_header' => 169,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 172,
			'init_dcl' => 173,
			'enum_header' => 18,
			'attr_dcl' => 174,
			'type_dcl' => 175,
			'union_header' => 23
		}
	},
	{#State 168
		DEFAULT => -35
	},
	{#State 169
		ACTIONS => {
			'error' => 257,
			"(" => 256
		},
		GOTOS => {
			'parameter_dcls' => 258
		}
	},
	{#State 170
		DEFAULT => -281
	},
	{#State 171
		DEFAULT => -93
	},
	{#State 172
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 259
		}
	},
	{#State 173
		DEFAULT => -37
	},
	{#State 174
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 260
		}
	},
	{#State 175
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 261
		}
	},
	{#State 176
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 226
		},
		GOTOS => {
			'declarators' => 262,
			'declarator' => 222,
			'simple_declarator' => 224,
			'array_declarator' => 225,
			'complex_declarator' => 223
		}
	},
	{#State 177
		ACTIONS => {
			"}" => 263
		}
	},
	{#State 178
		ACTIONS => {
			"}" => 264
		}
	},
	{#State 179
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 86,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		DEFAULT => -227,
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'type_spec' => 176,
			'string_type' => 70,
			'struct_header' => 10,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'base_type_spec' => 75,
			'enum_type' => 76,
			'enum_header' => 18,
			'member_list' => 265,
			'union_header' => 23,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 85,
			'boolean_type' => 87,
			'integer_type' => 88,
			'signed_short_int' => 93,
			'member' => 179,
			'struct_type' => 95,
			'union_type' => 97,
			'sequence_type' => 99,
			'unsigned_long_int' => 100,
			'template_type_spec' => 101,
			'constr_type_spec' => 102,
			'simple_type_spec' => 103,
			'fixed_pt_type' => 104
		}
	},
	{#State 180
		DEFAULT => -341
	},
	{#State 181
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 275,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'primary_expr' => 285,
			'and_expr' => 286,
			'scoped_name' => 268,
			'positive_int_const' => 269,
			'wide_string_literal' => 270,
			'boolean_literal' => 272,
			'mult_expr' => 288,
			'const_exp' => 273,
			'or_expr' => 274,
			'unary_expr' => 292,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 182
		DEFAULT => -267
	},
	{#State 183
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 86,
			'SEQUENCE' => 60,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'WCHAR' => 72,
			'error' => 296,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'wide_string_type' => 85,
			'integer_type' => 88,
			'boolean_type' => 87,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'signed_short_int' => 93,
			'string_type' => 70,
			'sequence_type' => 99,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'base_type_spec' => 75,
			'unsigned_long_int' => 100,
			'template_type_spec' => 101,
			'unsigned_short_int' => 78,
			'simple_type_spec' => 297,
			'fixed_pt_type' => 104,
			'signed_longlong_int' => 80
		}
	},
	{#State 184
		ACTIONS => {
			'error' => 298,
			'IDENTIFIER' => 299
		}
	},
	{#State 185
		DEFAULT => -214
	},
	{#State 186
		ACTIONS => {
			'LONG' => 300
		},
		DEFAULT => -215
	},
	{#State 187
		DEFAULT => -202
	},
	{#State 188
		DEFAULT => -210
	},
	{#State 189
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 302,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'primary_expr' => 285,
			'and_expr' => 286,
			'scoped_name' => 268,
			'positive_int_const' => 301,
			'wide_string_literal' => 270,
			'boolean_literal' => 272,
			'mult_expr' => 288,
			'const_exp' => 273,
			'or_expr' => 274,
			'unary_expr' => 292,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 190
		DEFAULT => -50
	},
	{#State 191
		DEFAULT => -49
	},
	{#State 192
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 304,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'primary_expr' => 285,
			'and_expr' => 286,
			'scoped_name' => 268,
			'positive_int_const' => 303,
			'wide_string_literal' => 270,
			'boolean_literal' => 272,
			'mult_expr' => 288,
			'const_exp' => 273,
			'or_expr' => 274,
			'unary_expr' => 292,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 193
		ACTIONS => {
			"}" => 305
		}
	},
	{#State 194
		ACTIONS => {
			";" => 306,
			"," => 307
		},
		DEFAULT => -258
	},
	{#State 195
		DEFAULT => -262
	},
	{#State 196
		ACTIONS => {
			"}" => 308
		}
	},
	{#State 197
		DEFAULT => -110
	},
	{#State 198
		ACTIONS => {
			'error' => 309,
			"=" => 310
		}
	},
	{#State 199
		DEFAULT => -73
	},
	{#State 200
		ACTIONS => {
			":" => 229,
			";" => -57,
			"{" => -85,
			'error' => -57,
			'SUPPORTS' => 230
		},
		DEFAULT => -60,
		GOTOS => {
			'supported_interface_spec' => 231,
			'value_inheritance_spec' => 311
		}
	},
	{#State 201
		ACTIONS => {
			'CHAR' => 82,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'error' => 315,
			'LONG' => 319,
			"::" => 92,
			'ENUM' => 25,
			'UNSIGNED' => 69
		},
		GOTOS => {
			'switch_type_spec' => 316,
			'unsigned_int' => 56,
			'signed_int' => 59,
			'integer_type' => 318,
			'boolean_type' => 317,
			'unsigned_longlong_int' => 73,
			'char_type' => 312,
			'enum_type' => 314,
			'unsigned_long_int' => 100,
			'scoped_name' => 313,
			'enum_header' => 18,
			'signed_long_int' => 67,
			'unsigned_short_int' => 78,
			'signed_short_int' => 93,
			'signed_longlong_int' => 80
		}
	},
	{#State 202
		DEFAULT => -234
	},
	{#State 203
		ACTIONS => {
			"{" => -31
		},
		DEFAULT => -27
	},
	{#State 204
		ACTIONS => {
			":" => 320
		},
		DEFAULT => -26,
		GOTOS => {
			'interface_inheritance_spec' => 321
		}
	},
	{#State 205
		ACTIONS => {
			"}" => 322
		}
	},
	{#State 206
		DEFAULT => -23
	},
	{#State 207
		DEFAULT => -32
	},
	{#State 208
		ACTIONS => {
			"}" => 323
		}
	},
	{#State 209
		DEFAULT => -198
	},
	{#State 210
		DEFAULT => -197
	},
	{#State 211
		DEFAULT => -88
	},
	{#State 212
		ACTIONS => {
			'PRIVATE' => 153,
			'ONEWAY' => 154,
			'FACTORY' => 161,
			'CONST' => 19,
			'EXCEPTION' => 22,
			"}" => -70,
			'ENUM' => 25,
			'NATIVE' => 29,
			'STRUCT' => 31,
			'TYPEDEF' => 34,
			'UNION' => 37,
			'READONLY' => 170,
			'ATTRIBUTE' => -282,
			'PUBLIC' => 171
		},
		DEFAULT => -296,
		GOTOS => {
			'init_header_param' => 152,
			'const_dcl' => 165,
			'op_mod' => 155,
			'value_elements' => 324,
			'except_dcl' => 156,
			'state_member' => 211,
			'op_attribute' => 158,
			'attr_mod' => 159,
			'state_mod' => 160,
			'value_element' => 212,
			'export' => 216,
			'init_header' => 162,
			'struct_type' => 32,
			'op_header' => 169,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 10,
			'enum_type' => 15,
			'op_dcl' => 172,
			'init_dcl' => 217,
			'enum_header' => 18,
			'attr_dcl' => 174,
			'type_dcl' => 175,
			'union_header' => 23
		}
	},
	{#State 213
		ACTIONS => {
			"}" => 325
		}
	},
	{#State 214
		DEFAULT => -67
	},
	{#State 215
		ACTIONS => {
			"}" => 326
		}
	},
	{#State 216
		DEFAULT => -87
	},
	{#State 217
		DEFAULT => -89
	},
	{#State 218
		ACTIONS => {
			"}" => 327
		}
	},
	{#State 219
		ACTIONS => {
			"}" => 328
		}
	},
	{#State 220
		DEFAULT => -285
	},
	{#State 221
		DEFAULT => -169
	},
	{#State 222
		ACTIONS => {
			"," => 329
		},
		DEFAULT => -192
	},
	{#State 223
		DEFAULT => -195
	},
	{#State 224
		DEFAULT => -194
	},
	{#State 225
		DEFAULT => -199
	},
	{#State 226
		ACTIONS => {
			"[" => 332
		},
		DEFAULT => -196,
		GOTOS => {
			'fixed_array_sizes' => 330,
			'fixed_array_size' => 331
		}
	},
	{#State 227
		DEFAULT => -12
	},
	{#State 228
		DEFAULT => -64
	},
	{#State 229
		ACTIONS => {
			'TRUNCATABLE' => 334
		},
		DEFAULT => -80,
		GOTOS => {
			'inheritance_mod' => 333
		}
	},
	{#State 230
		ACTIONS => {
			'error' => 336,
			'IDENTIFIER' => 98,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 335,
			'interface_names' => 338,
			'interface_name' => 337
		}
	},
	{#State 231
		DEFAULT => -78
	},
	{#State 232
		DEFAULT => -16
	},
	{#State 233
		DEFAULT => -15
	},
	{#State 234
		DEFAULT => -95
	},
	{#State 235
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -337
	},
	{#State 236
		DEFAULT => -335
	},
	{#State 237
		DEFAULT => -334
	},
	{#State 238
		DEFAULT => -336
	},
	{#State 239
		DEFAULT => -299
	},
	{#State 240
		DEFAULT => -298
	},
	{#State 241
		ACTIONS => {
			'error' => 339,
			'IDENTIFIER' => 340
		}
	},
	{#State 242
		DEFAULT => -300
	},
	{#State 243
		DEFAULT => -301
	},
	{#State 244
		DEFAULT => -40
	},
	{#State 245
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 343,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'error' => 341,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'wide_string_type' => 238,
			'integer_type' => 88,
			'boolean_type' => 87,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 235,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'signed_short_int' => 93,
			'string_type' => 236,
			'op_param_type_spec' => 344,
			'struct_type' => 95,
			'union_type' => 97,
			'struct_header' => 10,
			'sequence_type' => 345,
			'base_type_spec' => 237,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'enum_type' => 76,
			'unsigned_long_int' => 100,
			'param_type_spec' => 342,
			'enum_header' => 18,
			'constr_type_spec' => 346,
			'unsigned_short_int' => 78,
			'union_header' => 23,
			'fixed_pt_type' => 347,
			'signed_longlong_int' => 80
		}
	},
	{#State 246
		ACTIONS => {
			'error' => 349,
			'IDENTIFIER' => 226
		},
		GOTOS => {
			'declarators' => 348,
			'declarator' => 222,
			'simple_declarator' => 224,
			'array_declarator' => 225,
			'complex_declarator' => 223
		}
	},
	{#State 247
		ACTIONS => {
			";" => 350
		}
	},
	{#State 248
		DEFAULT => -101
	},
	{#State 249
		DEFAULT => -100
	},
	{#State 250
		ACTIONS => {
			'error' => 355,
			")" => 356,
			'IN' => 353
		},
		GOTOS => {
			'init_param_decls' => 352,
			'init_param_attribute' => 351,
			'init_param_decl' => 354
		}
	},
	{#State 251
		DEFAULT => -99
	},
	{#State 252
		DEFAULT => -63
	},
	{#State 253
		DEFAULT => -39
	},
	{#State 254
		DEFAULT => -62
	},
	{#State 255
		DEFAULT => -34
	},
	{#State 256
		ACTIONS => {
			'CHAR' => -315,
			'OBJECT' => -315,
			'FIXED' => -315,
			'VALUEBASE' => -315,
			'VOID' => -315,
			'IN' => 357,
			'SEQUENCE' => -315,
			'STRUCT' => -315,
			'DOUBLE' => -315,
			'LONG' => -315,
			'STRING' => -315,
			"::" => -315,
			'WSTRING' => -315,
			"..." => 358,
			'UNSIGNED' => -315,
			'SHORT' => -315,
			")" => 363,
			'BOOLEAN' => -315,
			'OUT' => 364,
			'IDENTIFIER' => -315,
			'UNION' => -315,
			'WCHAR' => -315,
			'error' => 359,
			'INOUT' => 360,
			'OCTET' => -315,
			'FLOAT' => -315,
			'ENUM' => -315,
			'ANY' => -315
		},
		GOTOS => {
			'param_dcl' => 365,
			'param_dcls' => 362,
			'param_attribute' => 361
		}
	},
	{#State 257
		DEFAULT => -292
	},
	{#State 258
		ACTIONS => {
			'RAISES' => 367
		},
		DEFAULT => -319,
		GOTOS => {
			'raises_expr' => 366
		}
	},
	{#State 259
		DEFAULT => -42
	},
	{#State 260
		DEFAULT => -41
	},
	{#State 261
		DEFAULT => -38
	},
	{#State 262
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 368
		}
	},
	{#State 263
		DEFAULT => -224
	},
	{#State 264
		DEFAULT => -223
	},
	{#State 265
		DEFAULT => -228
	},
	{#State 266
		DEFAULT => -151
	},
	{#State 267
		DEFAULT => -152
	},
	{#State 268
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -144
	},
	{#State 269
		ACTIONS => {
			"," => 369
		}
	},
	{#State 270
		DEFAULT => -150
	},
	{#State 271
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 371,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 288,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'const_exp' => 370,
			'and_expr' => 286,
			'or_expr' => 274,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 272
		DEFAULT => -155
	},
	{#State 273
		DEFAULT => -162
	},
	{#State 274
		ACTIONS => {
			"|" => 372
		},
		DEFAULT => -122
	},
	{#State 275
		ACTIONS => {
			">" => 373
		}
	},
	{#State 276
		ACTIONS => {
			"^" => 374
		},
		DEFAULT => -123
	},
	{#State 277
		ACTIONS => {
			"<<" => 375,
			">>" => 376
		},
		DEFAULT => -127
	},
	{#State 278
		DEFAULT => -161
	},
	{#State 279
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 279
		},
		DEFAULT => -158,
		GOTOS => {
			'wide_string_literal' => 377
		}
	},
	{#State 280
		DEFAULT => -145
	},
	{#State 281
		DEFAULT => -160
	},
	{#State 282
		ACTIONS => {
			"+" => 378,
			"-" => 379
		},
		DEFAULT => -129
	},
	{#State 283
		DEFAULT => -149
	},
	{#State 284
		DEFAULT => -154
	},
	{#State 285
		DEFAULT => -140
	},
	{#State 286
		ACTIONS => {
			"&" => 380
		},
		DEFAULT => -125
	},
	{#State 287
		DEFAULT => -148
	},
	{#State 288
		ACTIONS => {
			"%" => 382,
			"*" => 381,
			"/" => 383
		},
		DEFAULT => -132
	},
	{#State 289
		ACTIONS => {
			'STRING_LITERAL' => 289
		},
		DEFAULT => -156,
		GOTOS => {
			'string_literal' => 384
		}
	},
	{#State 290
		DEFAULT => -153
	},
	{#State 291
		DEFAULT => -142
	},
	{#State 292
		DEFAULT => -135
	},
	{#State 293
		DEFAULT => -141
	},
	{#State 294
		DEFAULT => -143
	},
	{#State 295
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'boolean_literal' => 272,
			'scoped_name' => 268,
			'primary_expr' => 385,
			'literal' => 280,
			'wide_string_literal' => 270
		}
	},
	{#State 296
		ACTIONS => {
			">" => 386
		}
	},
	{#State 297
		ACTIONS => {
			">" => 388,
			"," => 387
		}
	},
	{#State 298
		DEFAULT => -52
	},
	{#State 299
		DEFAULT => -51
	},
	{#State 300
		DEFAULT => -216
	},
	{#State 301
		ACTIONS => {
			">" => 389
		}
	},
	{#State 302
		ACTIONS => {
			">" => 390
		}
	},
	{#State 303
		ACTIONS => {
			">" => 391
		}
	},
	{#State 304
		ACTIONS => {
			">" => 392
		}
	},
	{#State 305
		DEFAULT => -254
	},
	{#State 306
		DEFAULT => -261
	},
	{#State 307
		ACTIONS => {
			'IDENTIFIER' => 195
		},
		DEFAULT => -260,
		GOTOS => {
			'enumerators' => 393,
			'enumerator' => 194
		}
	},
	{#State 308
		DEFAULT => -253
	},
	{#State 309
		DEFAULT => -109
	},
	{#State 310
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 395,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 288,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'const_exp' => 394,
			'and_expr' => 286,
			'or_expr' => 274,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 311
		DEFAULT => -72
	},
	{#State 312
		DEFAULT => -238
	},
	{#State 313
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -241
	},
	{#State 314
		DEFAULT => -240
	},
	{#State 315
		ACTIONS => {
			")" => 396
		}
	},
	{#State 316
		ACTIONS => {
			")" => 397
		}
	},
	{#State 317
		DEFAULT => -239
	},
	{#State 318
		DEFAULT => -237
	},
	{#State 319
		ACTIONS => {
			'LONG' => 188
		},
		DEFAULT => -209
	},
	{#State 320
		ACTIONS => {
			'error' => 398,
			'IDENTIFIER' => 98,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 335,
			'interface_names' => 399,
			'interface_name' => 337
		}
	},
	{#State 321
		DEFAULT => -30
	},
	{#State 322
		DEFAULT => -25
	},
	{#State 323
		DEFAULT => -24
	},
	{#State 324
		DEFAULT => -71
	},
	{#State 325
		DEFAULT => -69
	},
	{#State 326
		DEFAULT => -68
	},
	{#State 327
		DEFAULT => -287
	},
	{#State 328
		DEFAULT => -286
	},
	{#State 329
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 226
		},
		GOTOS => {
			'declarators' => 400,
			'declarator' => 222,
			'simple_declarator' => 224,
			'array_declarator' => 225,
			'complex_declarator' => 223
		}
	},
	{#State 330
		DEFAULT => -274
	},
	{#State 331
		ACTIONS => {
			"[" => 332
		},
		DEFAULT => -275,
		GOTOS => {
			'fixed_array_sizes' => 401,
			'fixed_array_size' => 331
		}
	},
	{#State 332
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 403,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'primary_expr' => 285,
			'and_expr' => 286,
			'scoped_name' => 268,
			'positive_int_const' => 402,
			'wide_string_literal' => 270,
			'boolean_literal' => 272,
			'mult_expr' => 288,
			'const_exp' => 273,
			'or_expr' => 274,
			'unary_expr' => 292,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 333
		ACTIONS => {
			'error' => 406,
			'IDENTIFIER' => 98,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 404,
			'value_name' => 405,
			'value_names' => 407
		}
	},
	{#State 334
		DEFAULT => -79
	},
	{#State 335
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -47
	},
	{#State 336
		DEFAULT => -84
	},
	{#State 337
		ACTIONS => {
			"," => 408
		},
		DEFAULT => -45
	},
	{#State 338
		DEFAULT => -83
	},
	{#State 339
		DEFAULT => -294
	},
	{#State 340
		DEFAULT => -293
	},
	{#State 341
		DEFAULT => -280
	},
	{#State 342
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 131
		},
		GOTOS => {
			'simple_declarators' => 410,
			'simple_declarator' => 409
		}
	},
	{#State 343
		DEFAULT => -330
	},
	{#State 344
		DEFAULT => -329
	},
	{#State 345
		DEFAULT => -331
	},
	{#State 346
		DEFAULT => -333
	},
	{#State 347
		DEFAULT => -332
	},
	{#State 348
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 411
		}
	},
	{#State 349
		ACTIONS => {
			";" => 412,
			"," => 210
		}
	},
	{#State 350
		DEFAULT => -92
	},
	{#State 351
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 343,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'error' => 413,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'wide_string_type' => 238,
			'integer_type' => 88,
			'boolean_type' => 87,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 235,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'signed_short_int' => 93,
			'string_type' => 236,
			'op_param_type_spec' => 344,
			'struct_type' => 95,
			'union_type' => 97,
			'struct_header' => 10,
			'sequence_type' => 345,
			'base_type_spec' => 237,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'enum_type' => 76,
			'unsigned_long_int' => 100,
			'param_type_spec' => 414,
			'enum_header' => 18,
			'constr_type_spec' => 346,
			'unsigned_short_int' => 78,
			'union_header' => 23,
			'fixed_pt_type' => 347,
			'signed_longlong_int' => 80
		}
	},
	{#State 352
		ACTIONS => {
			")" => 415
		}
	},
	{#State 353
		DEFAULT => -106
	},
	{#State 354
		ACTIONS => {
			"," => 416
		},
		DEFAULT => -102
	},
	{#State 355
		ACTIONS => {
			")" => 417
		}
	},
	{#State 356
		DEFAULT => -96
	},
	{#State 357
		DEFAULT => -312
	},
	{#State 358
		ACTIONS => {
			")" => 418
		}
	},
	{#State 359
		ACTIONS => {
			")" => 419
		}
	},
	{#State 360
		DEFAULT => -314
	},
	{#State 361
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 343,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'wide_string_type' => 238,
			'integer_type' => 88,
			'boolean_type' => 87,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 235,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'signed_short_int' => 93,
			'string_type' => 236,
			'op_param_type_spec' => 344,
			'struct_type' => 95,
			'union_type' => 97,
			'struct_header' => 10,
			'sequence_type' => 345,
			'base_type_spec' => 237,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'enum_type' => 76,
			'unsigned_long_int' => 100,
			'param_type_spec' => 420,
			'enum_header' => 18,
			'constr_type_spec' => 346,
			'unsigned_short_int' => 78,
			'union_header' => 23,
			'fixed_pt_type' => 347,
			'signed_longlong_int' => 80
		}
	},
	{#State 362
		ACTIONS => {
			")" => 422,
			"," => 421
		}
	},
	{#State 363
		DEFAULT => -305
	},
	{#State 364
		DEFAULT => -313
	},
	{#State 365
		ACTIONS => {
			";" => 423
		},
		DEFAULT => -308
	},
	{#State 366
		ACTIONS => {
			'CONTEXT' => 424
		},
		DEFAULT => -326,
		GOTOS => {
			'context_expr' => 425
		}
	},
	{#State 367
		ACTIONS => {
			'error' => 427,
			"(" => 426
		}
	},
	{#State 368
		DEFAULT => -229
	},
	{#State 369
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 429,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'primary_expr' => 285,
			'and_expr' => 286,
			'scoped_name' => 268,
			'positive_int_const' => 428,
			'wide_string_literal' => 270,
			'boolean_literal' => 272,
			'mult_expr' => 288,
			'const_exp' => 273,
			'or_expr' => 274,
			'unary_expr' => 292,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 370
		ACTIONS => {
			")" => 430
		}
	},
	{#State 371
		ACTIONS => {
			")" => 431
		}
	},
	{#State 372
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 288,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'and_expr' => 286,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'xor_expr' => 432,
			'shift_expr' => 277,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 373
		DEFAULT => -340
	},
	{#State 374
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 288,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'and_expr' => 433,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'shift_expr' => 277,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 375
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 288,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 434
		}
	},
	{#State 376
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 288,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 435
		}
	},
	{#State 377
		DEFAULT => -159
	},
	{#State 378
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 436,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295
		}
	},
	{#State 379
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 437,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295
		}
	},
	{#State 380
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 288,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'shift_expr' => 438,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 381
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'unary_expr' => 439,
			'scoped_name' => 268,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295
		}
	},
	{#State 382
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'unary_expr' => 440,
			'scoped_name' => 268,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295
		}
	},
	{#State 383
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'CHARACTER_LITERAL' => 266,
			"+" => 291,
			'FIXED_PT_LITERAL' => 290,
			'WIDE_CHARACTER_LITERAL' => 267,
			"-" => 293,
			"::" => 92,
			'FALSE' => 278,
			'WIDE_STRING_LITERAL' => 279,
			'INTEGER_LITERAL' => 287,
			"~" => 294,
			"(" => 271,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'unary_expr' => 441,
			'scoped_name' => 268,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295
		}
	},
	{#State 384
		DEFAULT => -157
	},
	{#State 385
		DEFAULT => -139
	},
	{#State 386
		DEFAULT => -266
	},
	{#State 387
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 443,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'string_literal' => 283,
			'primary_expr' => 285,
			'and_expr' => 286,
			'scoped_name' => 268,
			'positive_int_const' => 442,
			'wide_string_literal' => 270,
			'boolean_literal' => 272,
			'mult_expr' => 288,
			'const_exp' => 273,
			'or_expr' => 274,
			'unary_expr' => 292,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 388
		DEFAULT => -265
	},
	{#State 389
		DEFAULT => -268
	},
	{#State 390
		DEFAULT => -270
	},
	{#State 391
		DEFAULT => -271
	},
	{#State 392
		DEFAULT => -273
	},
	{#State 393
		DEFAULT => -259
	},
	{#State 394
		DEFAULT => -107
	},
	{#State 395
		DEFAULT => -108
	},
	{#State 396
		DEFAULT => -233
	},
	{#State 397
		ACTIONS => {
			"{" => 445,
			'error' => 444
		}
	},
	{#State 398
		DEFAULT => -44
	},
	{#State 399
		DEFAULT => -43
	},
	{#State 400
		DEFAULT => -193
	},
	{#State 401
		DEFAULT => -276
	},
	{#State 402
		ACTIONS => {
			"]" => 446
		}
	},
	{#State 403
		ACTIONS => {
			"]" => 447
		}
	},
	{#State 404
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -86
	},
	{#State 405
		ACTIONS => {
			"," => 448
		},
		DEFAULT => -81
	},
	{#State 406
		DEFAULT => -77
	},
	{#State 407
		ACTIONS => {
			'SUPPORTS' => 230
		},
		DEFAULT => -85,
		GOTOS => {
			'supported_interface_spec' => 449
		}
	},
	{#State 408
		ACTIONS => {
			'IDENTIFIER' => 98,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 335,
			'interface_names' => 450,
			'interface_name' => 337
		}
	},
	{#State 409
		ACTIONS => {
			"," => 451
		},
		DEFAULT => -283
	},
	{#State 410
		DEFAULT => -279
	},
	{#State 411
		DEFAULT => -90
	},
	{#State 412
		ACTIONS => {
			";" => -198,
			"," => -198,
			'error' => -198
		},
		DEFAULT => -91
	},
	{#State 413
		DEFAULT => -105
	},
	{#State 414
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 131
		},
		GOTOS => {
			'simple_declarator' => 452
		}
	},
	{#State 415
		DEFAULT => -97
	},
	{#State 416
		ACTIONS => {
			'IN' => 353
		},
		GOTOS => {
			'init_param_decls' => 453,
			'init_param_attribute' => 351,
			'init_param_decl' => 354
		}
	},
	{#State 417
		DEFAULT => -98
	},
	{#State 418
		DEFAULT => -306
	},
	{#State 419
		DEFAULT => -307
	},
	{#State 420
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 131
		},
		GOTOS => {
			'simple_declarator' => 454
		}
	},
	{#State 421
		ACTIONS => {
			'IN' => 357,
			"..." => 455,
			")" => 456,
			'OUT' => 364,
			'INOUT' => 360
		},
		DEFAULT => -315,
		GOTOS => {
			'param_dcl' => 457,
			'param_attribute' => 361
		}
	},
	{#State 422
		DEFAULT => -302
	},
	{#State 423
		DEFAULT => -310
	},
	{#State 424
		ACTIONS => {
			'error' => 459,
			"(" => 458
		}
	},
	{#State 425
		DEFAULT => -291
	},
	{#State 426
		ACTIONS => {
			'error' => 461,
			'IDENTIFIER' => 98,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 460,
			'exception_names' => 462,
			'exception_name' => 463
		}
	},
	{#State 427
		DEFAULT => -318
	},
	{#State 428
		ACTIONS => {
			">" => 464
		}
	},
	{#State 429
		ACTIONS => {
			">" => 465
		}
	},
	{#State 430
		DEFAULT => -146
	},
	{#State 431
		DEFAULT => -147
	},
	{#State 432
		ACTIONS => {
			"^" => 374
		},
		DEFAULT => -124
	},
	{#State 433
		ACTIONS => {
			"&" => 380
		},
		DEFAULT => -126
	},
	{#State 434
		ACTIONS => {
			"+" => 378,
			"-" => 379
		},
		DEFAULT => -131
	},
	{#State 435
		ACTIONS => {
			"+" => 378,
			"-" => 379
		},
		DEFAULT => -130
	},
	{#State 436
		ACTIONS => {
			"%" => 382,
			"*" => 381,
			"/" => 383
		},
		DEFAULT => -133
	},
	{#State 437
		ACTIONS => {
			"%" => 382,
			"*" => 381,
			"/" => 383
		},
		DEFAULT => -134
	},
	{#State 438
		ACTIONS => {
			"<<" => 375,
			">>" => 376
		},
		DEFAULT => -128
	},
	{#State 439
		DEFAULT => -136
	},
	{#State 440
		DEFAULT => -138
	},
	{#State 441
		DEFAULT => -137
	},
	{#State 442
		ACTIONS => {
			">" => 466
		}
	},
	{#State 443
		ACTIONS => {
			">" => 467
		}
	},
	{#State 444
		DEFAULT => -232
	},
	{#State 445
		ACTIONS => {
			'error' => 471,
			'CASE' => 468,
			'DEFAULT' => 470
		},
		GOTOS => {
			'case_labels' => 473,
			'switch_body' => 472,
			'case' => 469,
			'case_label' => 474
		}
	},
	{#State 446
		DEFAULT => -277
	},
	{#State 447
		DEFAULT => -278
	},
	{#State 448
		ACTIONS => {
			'IDENTIFIER' => 98,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 404,
			'value_name' => 405,
			'value_names' => 475
		}
	},
	{#State 449
		DEFAULT => -76
	},
	{#State 450
		DEFAULT => -46
	},
	{#State 451
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 131
		},
		GOTOS => {
			'simple_declarators' => 476,
			'simple_declarator' => 409
		}
	},
	{#State 452
		DEFAULT => -104
	},
	{#State 453
		DEFAULT => -103
	},
	{#State 454
		DEFAULT => -311
	},
	{#State 455
		ACTIONS => {
			")" => 477
		}
	},
	{#State 456
		DEFAULT => -304
	},
	{#State 457
		DEFAULT => -309
	},
	{#State 458
		ACTIONS => {
			'error' => 478,
			'STRING_LITERAL' => 289
		},
		GOTOS => {
			'string_literal' => 479,
			'string_literals' => 480
		}
	},
	{#State 459
		DEFAULT => -325
	},
	{#State 460
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -322
	},
	{#State 461
		ACTIONS => {
			")" => 481
		}
	},
	{#State 462
		ACTIONS => {
			")" => 482
		}
	},
	{#State 463
		ACTIONS => {
			"," => 483
		},
		DEFAULT => -320
	},
	{#State 464
		DEFAULT => -338
	},
	{#State 465
		DEFAULT => -339
	},
	{#State 466
		DEFAULT => -263
	},
	{#State 467
		DEFAULT => -264
	},
	{#State 468
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 284,
			'CHARACTER_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 267,
			"::" => 92,
			'INTEGER_LITERAL' => 287,
			"(" => 271,
			'IDENTIFIER' => 98,
			'STRING_LITERAL' => 289,
			'FIXED_PT_LITERAL' => 290,
			"+" => 291,
			'error' => 485,
			"-" => 293,
			'WIDE_STRING_LITERAL' => 279,
			'FALSE' => 278,
			"~" => 294,
			'TRUE' => 281
		},
		GOTOS => {
			'mult_expr' => 288,
			'string_literal' => 283,
			'boolean_literal' => 272,
			'primary_expr' => 285,
			'const_exp' => 484,
			'and_expr' => 286,
			'or_expr' => 274,
			'unary_expr' => 292,
			'scoped_name' => 268,
			'xor_expr' => 276,
			'shift_expr' => 277,
			'wide_string_literal' => 270,
			'literal' => 280,
			'unary_operator' => 295,
			'add_expr' => 282
		}
	},
	{#State 469
		ACTIONS => {
			'CASE' => 468,
			'DEFAULT' => 470
		},
		DEFAULT => -242,
		GOTOS => {
			'case_labels' => 473,
			'switch_body' => 486,
			'case' => 469,
			'case_label' => 474
		}
	},
	{#State 470
		ACTIONS => {
			'error' => 487,
			":" => 488
		}
	},
	{#State 471
		ACTIONS => {
			"}" => 489
		}
	},
	{#State 472
		ACTIONS => {
			"}" => 490
		}
	},
	{#State 473
		ACTIONS => {
			'CHAR' => 82,
			'OBJECT' => 83,
			'VALUEBASE' => 84,
			'FIXED' => 58,
			'VOID' => 86,
			'SEQUENCE' => 60,
			'STRUCT' => 31,
			'DOUBLE' => 89,
			'LONG' => 90,
			'STRING' => 91,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 98,
			'UNION' => 37,
			'WCHAR' => 72,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 25,
			'ANY' => 81
		},
		GOTOS => {
			'unsigned_int' => 56,
			'floating_pt_type' => 57,
			'signed_int' => 59,
			'char_type' => 62,
			'value_base_type' => 61,
			'object_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'type_spec' => 491,
			'string_type' => 70,
			'struct_header' => 10,
			'element_spec' => 492,
			'unsigned_longlong_int' => 73,
			'any_type' => 74,
			'base_type_spec' => 75,
			'enum_type' => 76,
			'enum_header' => 18,
			'union_header' => 23,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 85,
			'boolean_type' => 87,
			'integer_type' => 88,
			'signed_short_int' => 93,
			'struct_type' => 95,
			'union_type' => 97,
			'sequence_type' => 99,
			'unsigned_long_int' => 100,
			'template_type_spec' => 101,
			'constr_type_spec' => 102,
			'simple_type_spec' => 103,
			'fixed_pt_type' => 104
		}
	},
	{#State 474
		ACTIONS => {
			'CASE' => 468,
			'DEFAULT' => 470
		},
		DEFAULT => -245,
		GOTOS => {
			'case_labels' => 493,
			'case_label' => 474
		}
	},
	{#State 475
		DEFAULT => -82
	},
	{#State 476
		DEFAULT => -284
	},
	{#State 477
		DEFAULT => -303
	},
	{#State 478
		ACTIONS => {
			")" => 494
		}
	},
	{#State 479
		ACTIONS => {
			"," => 495
		},
		DEFAULT => -327
	},
	{#State 480
		ACTIONS => {
			")" => 496
		}
	},
	{#State 481
		DEFAULT => -317
	},
	{#State 482
		DEFAULT => -316
	},
	{#State 483
		ACTIONS => {
			'IDENTIFIER' => 98,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 460,
			'exception_names' => 497,
			'exception_name' => 463
		}
	},
	{#State 484
		ACTIONS => {
			'error' => 498,
			":" => 499
		}
	},
	{#State 485
		DEFAULT => -249
	},
	{#State 486
		DEFAULT => -243
	},
	{#State 487
		DEFAULT => -251
	},
	{#State 488
		DEFAULT => -250
	},
	{#State 489
		DEFAULT => -231
	},
	{#State 490
		DEFAULT => -230
	},
	{#State 491
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 226
		},
		GOTOS => {
			'declarator' => 500,
			'simple_declarator' => 224,
			'array_declarator' => 225,
			'complex_declarator' => 223
		}
	},
	{#State 492
		ACTIONS => {
			'error' => 45,
			";" => 44
		},
		GOTOS => {
			'check_semicolon' => 501
		}
	},
	{#State 493
		DEFAULT => -246
	},
	{#State 494
		DEFAULT => -324
	},
	{#State 495
		ACTIONS => {
			'STRING_LITERAL' => 289
		},
		GOTOS => {
			'string_literal' => 479,
			'string_literals' => 502
		}
	},
	{#State 496
		DEFAULT => -323
	},
	{#State 497
		DEFAULT => -321
	},
	{#State 498
		DEFAULT => -248
	},
	{#State 499
		DEFAULT => -247
	},
	{#State 500
		DEFAULT => -252
	},
	{#State 501
		DEFAULT => -244
	},
	{#State 502
		DEFAULT => -328
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
		}
	],
	[#Rule 17
		 'module', 3,
sub
#line 147 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module', 3,
sub
#line 153 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 162 "parser23.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 168 "parser23.yp"
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
#line 185 "parser23.yp"
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
#line 193 "parser23.yp"
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
#line 201 "parser23.yp"
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
#line 212 "parser23.yp"
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
#line 224 "parser23.yp"
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
#line 240 "parser23.yp"
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
#line 254 "parser23.yp"
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
#line 268 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 34
		 'exports', 2,
sub
#line 272 "parser23.yp"
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
#line 283 "parser23.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 37
		 '_export', 1,
sub
#line 288 "parser23.yp"
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
#line 310 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 316 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 45
		 'interface_names', 1,
sub
#line 324 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 46
		 'interface_names', 3,
sub
#line 328 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 47
		 'interface_name', 1,
sub
#line 337 "parser23.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 48
		 'scoped_name', 1, undef
	],
	[#Rule 49
		 'scoped_name', 2,
sub
#line 347 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 50
		 'scoped_name', 2,
sub
#line 351 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 51
		 'scoped_name', 3,
sub
#line 357 "parser23.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 52
		 'scoped_name', 3,
sub
#line 361 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 53
		 'value', 1, undef
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
		 'value_forward_dcl', 3,
sub
#line 383 "parser23.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 58
		 'value_forward_dcl', 3,
sub
#line 391 "parser23.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 59
		 'value_box_dcl', 2,
sub
#line 401 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 60
		 'value_box_header', 3,
sub
#line 412 "parser23.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new BoxedValue($_[0],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 61
		 'value_abs_dcl', 3,
sub
#line 424 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 62
		 'value_abs_dcl', 4,
sub
#line 432 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 63
		 'value_abs_dcl', 4,
sub
#line 440 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 64
		 'value_abs_header', 4,
sub
#line 450 "parser23.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 65
		 'value_abs_header', 3,
sub
#line 457 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 66
		 'value_abs_header', 2,
sub
#line 462 "parser23.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 67
		 'value_dcl', 3,
sub
#line 471 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 68
		 'value_dcl', 4,
sub
#line 479 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 69
		 'value_dcl', 4,
sub
#line 487 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 70
		 'value_elements', 1,
sub
#line 497 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 71
		 'value_elements', 2,
sub
#line 501 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 72
		 'value_header', 4,
sub
#line 510 "parser23.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 73
		 'value_header', 3,
sub
#line 518 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 74
		 'value_mod', 1, undef
	],
	[#Rule 75
		 'value_mod', 0, undef
	],
	[#Rule 76
		 'value_inheritance_spec', 4,
sub
#line 534 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 77
		 'value_inheritance_spec', 3,
sub
#line 542 "parser23.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 78
		 'value_inheritance_spec', 1,
sub
#line 547 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 79
		 'inheritance_mod', 1, undef
	],
	[#Rule 80
		 'inheritance_mod', 0, undef
	],
	[#Rule 81
		 'value_names', 1,
sub
#line 563 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 82
		 'value_names', 3,
sub
#line 567 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 83
		 'supported_interface_spec', 2,
sub
#line 575 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 84
		 'supported_interface_spec', 2,
sub
#line 579 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 85
		 'supported_interface_spec', 0, undef
	],
	[#Rule 86
		 'value_name', 1,
sub
#line 590 "parser23.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 87
		 'value_element', 1, undef
	],
	[#Rule 88
		 'value_element', 1, undef
	],
	[#Rule 89
		 'value_element', 1, undef
	],
	[#Rule 90
		 'state_member', 4,
sub
#line 608 "parser23.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 91
		 'state_member', 4,
sub
#line 616 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 92
		 'state_member', 3,
sub
#line 621 "parser23.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 93
		 'state_mod', 1, undef
	],
	[#Rule 94
		 'state_mod', 1, undef
	],
	[#Rule 95
		 'init_dcl', 2, undef
	],
	[#Rule 96
		 'init_header_param', 3,
sub
#line 642 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 97
		 'init_header_param', 4,
sub
#line 648 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 98
		 'init_header_param', 4,
sub
#line 656 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 99
		 'init_header_param', 2,
sub
#line 663 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 100
		 'init_header', 2,
sub
#line 673 "parser23.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 101
		 'init_header', 2,
sub
#line 679 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 102
		 'init_param_decls', 1,
sub
#line 688 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 103
		 'init_param_decls', 3,
sub
#line 692 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 104
		 'init_param_decl', 3,
sub
#line 701 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 105
		 'init_param_decl', 2,
sub
#line 709 "parser23.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 106
		 'init_param_attribute', 1, undef
	],
	[#Rule 107
		 'const_dcl', 5,
sub
#line 724 "parser23.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 108
		 'const_dcl', 5,
sub
#line 732 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 109
		 'const_dcl', 4,
sub
#line 737 "parser23.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 110
		 'const_dcl', 3,
sub
#line 742 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 111
		 'const_dcl', 2,
sub
#line 747 "parser23.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'const_type', 1, undef
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
		 'const_type', 1,
sub
#line 772 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 121
		 'const_type', 1, undef
	],
	[#Rule 122
		 'const_exp', 1, undef
	],
	[#Rule 123
		 'or_expr', 1, undef
	],
	[#Rule 124
		 'or_expr', 3,
sub
#line 790 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 125
		 'xor_expr', 1, undef
	],
	[#Rule 126
		 'xor_expr', 3,
sub
#line 800 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 127
		 'and_expr', 1, undef
	],
	[#Rule 128
		 'and_expr', 3,
sub
#line 810 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 129
		 'shift_expr', 1, undef
	],
	[#Rule 130
		 'shift_expr', 3,
sub
#line 820 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 131
		 'shift_expr', 3,
sub
#line 824 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 132
		 'add_expr', 1, undef
	],
	[#Rule 133
		 'add_expr', 3,
sub
#line 834 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 134
		 'add_expr', 3,
sub
#line 838 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 135
		 'mult_expr', 1, undef
	],
	[#Rule 136
		 'mult_expr', 3,
sub
#line 848 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 137
		 'mult_expr', 3,
sub
#line 852 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 138
		 'mult_expr', 3,
sub
#line 856 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 139
		 'unary_expr', 2,
sub
#line 864 "parser23.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 140
		 'unary_expr', 1, undef
	],
	[#Rule 141
		 'unary_operator', 1, undef
	],
	[#Rule 142
		 'unary_operator', 1, undef
	],
	[#Rule 143
		 'unary_operator', 1, undef
	],
	[#Rule 144
		 'primary_expr', 1,
sub
#line 884 "parser23.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 145
		 'primary_expr', 1,
sub
#line 890 "parser23.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 146
		 'primary_expr', 3,
sub
#line 894 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 147
		 'primary_expr', 3,
sub
#line 898 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 148
		 'literal', 1,
sub
#line 907 "parser23.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 149
		 'literal', 1,
sub
#line 914 "parser23.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 150
		 'literal', 1,
sub
#line 920 "parser23.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 151
		 'literal', 1,
sub
#line 926 "parser23.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 152
		 'literal', 1,
sub
#line 932 "parser23.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 153
		 'literal', 1,
sub
#line 938 "parser23.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 154
		 'literal', 1,
sub
#line 945 "parser23.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 155
		 'literal', 1, undef
	],
	[#Rule 156
		 'string_literal', 1, undef
	],
	[#Rule 157
		 'string_literal', 2,
sub
#line 959 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 158
		 'wide_string_literal', 1, undef
	],
	[#Rule 159
		 'wide_string_literal', 2,
sub
#line 968 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 160
		 'boolean_literal', 1,
sub
#line 976 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 161
		 'boolean_literal', 1,
sub
#line 982 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 162
		 'positive_int_const', 1,
sub
#line 992 "parser23.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'type_dcl', 2,
sub
#line 1002 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 164
		 'type_dcl', 1, undef
	],
	[#Rule 165
		 'type_dcl', 1, undef
	],
	[#Rule 166
		 'type_dcl', 1, undef
	],
	[#Rule 167
		 'type_dcl', 2,
sub
#line 1012 "parser23.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 168
		 'type_dcl', 2,
sub
#line 1019 "parser23.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 169
		 'type_declarator', 2,
sub
#line 1028 "parser23.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 170
		 'type_spec', 1, undef
	],
	[#Rule 171
		 'type_spec', 1, undef
	],
	[#Rule 172
		 'simple_type_spec', 1, undef
	],
	[#Rule 173
		 'simple_type_spec', 1, undef
	],
	[#Rule 174
		 'simple_type_spec', 1,
sub
#line 1051 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 175
		 'simple_type_spec', 1,
sub
#line 1055 "parser23.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 176
		 'base_type_spec', 1, undef
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
		 'template_type_spec', 1, undef
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
		 'constr_type_spec', 1, undef
	],
	[#Rule 190
		 'constr_type_spec', 1, undef
	],
	[#Rule 191
		 'constr_type_spec', 1, undef
	],
	[#Rule 192
		 'declarators', 1,
sub
#line 1110 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 193
		 'declarators', 3,
sub
#line 1114 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 194
		 'declarator', 1,
sub
#line 1123 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 195
		 'declarator', 1, undef
	],
	[#Rule 196
		 'simple_declarator', 1, undef
	],
	[#Rule 197
		 'simple_declarator', 2,
sub
#line 1135 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 198
		 'simple_declarator', 2,
sub
#line 1140 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 199
		 'complex_declarator', 1, undef
	],
	[#Rule 200
		 'floating_pt_type', 1,
sub
#line 1155 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 201
		 'floating_pt_type', 1,
sub
#line 1161 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 202
		 'floating_pt_type', 2,
sub
#line 1167 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 203
		 'integer_type', 1, undef
	],
	[#Rule 204
		 'integer_type', 1, undef
	],
	[#Rule 205
		 'signed_int', 1, undef
	],
	[#Rule 206
		 'signed_int', 1, undef
	],
	[#Rule 207
		 'signed_int', 1, undef
	],
	[#Rule 208
		 'signed_short_int', 1,
sub
#line 1195 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 209
		 'signed_long_int', 1,
sub
#line 1205 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 210
		 'signed_longlong_int', 2,
sub
#line 1215 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 211
		 'unsigned_int', 1, undef
	],
	[#Rule 212
		 'unsigned_int', 1, undef
	],
	[#Rule 213
		 'unsigned_int', 1, undef
	],
	[#Rule 214
		 'unsigned_short_int', 2,
sub
#line 1235 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 215
		 'unsigned_long_int', 2,
sub
#line 1245 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 216
		 'unsigned_longlong_int', 3,
sub
#line 1255 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 217
		 'char_type', 1,
sub
#line 1265 "parser23.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 218
		 'wide_char_type', 1,
sub
#line 1275 "parser23.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 219
		 'boolean_type', 1,
sub
#line 1285 "parser23.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 220
		 'octet_type', 1,
sub
#line 1295 "parser23.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 221
		 'any_type', 1,
sub
#line 1305 "parser23.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 222
		 'object_type', 1,
sub
#line 1315 "parser23.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 223
		 'struct_type', 4,
sub
#line 1325 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 224
		 'struct_type', 4,
sub
#line 1332 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 225
		 'struct_header', 2,
sub
#line 1341 "parser23.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 226
		 'struct_header', 2,
sub
#line 1347 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 227
		 'member_list', 1,
sub
#line 1356 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 228
		 'member_list', 2,
sub
#line 1360 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 229
		 'member', 3,
sub
#line 1369 "parser23.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 230
		 'union_type', 8,
sub
#line 1380 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 231
		 'union_type', 8,
sub
#line 1388 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 232
		 'union_type', 6,
sub
#line 1394 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'union_type', 5,
sub
#line 1400 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 234
		 'union_type', 3,
sub
#line 1406 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 235
		 'union_header', 2,
sub
#line 1415 "parser23.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 236
		 'union_header', 2,
sub
#line 1421 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 237
		 'switch_type_spec', 1, undef
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
		 'switch_type_spec', 1,
sub
#line 1438 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 242
		 'switch_body', 1,
sub
#line 1446 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 243
		 'switch_body', 2,
sub
#line 1450 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 244
		 'case', 3,
sub
#line 1459 "parser23.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 245
		 'case_labels', 1,
sub
#line 1469 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 246
		 'case_labels', 2,
sub
#line 1473 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 247
		 'case_label', 3,
sub
#line 1482 "parser23.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 248
		 'case_label', 3,
sub
#line 1486 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 249
		 'case_label', 2,
sub
#line 1492 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 250
		 'case_label', 2,
sub
#line 1497 "parser23.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 251
		 'case_label', 2,
sub
#line 1501 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 252
		 'element_spec', 2,
sub
#line 1511 "parser23.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 253
		 'enum_type', 4,
sub
#line 1522 "parser23.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 254
		 'enum_type', 4,
sub
#line 1528 "parser23.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 255
		 'enum_type', 2,
sub
#line 1533 "parser23.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 256
		 'enum_header', 2,
sub
#line 1541 "parser23.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 257
		 'enum_header', 2,
sub
#line 1547 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 258
		 'enumerators', 1,
sub
#line 1555 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 259
		 'enumerators', 3,
sub
#line 1559 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 260
		 'enumerators', 2,
sub
#line 1564 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 261
		 'enumerators', 2,
sub
#line 1569 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 262
		 'enumerator', 1,
sub
#line 1578 "parser23.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 263
		 'sequence_type', 6,
sub
#line 1588 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 264
		 'sequence_type', 6,
sub
#line 1596 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 265
		 'sequence_type', 4,
sub
#line 1601 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 266
		 'sequence_type', 4,
sub
#line 1608 "parser23.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'sequence_type', 2,
sub
#line 1613 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'string_type', 4,
sub
#line 1622 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 269
		 'string_type', 1,
sub
#line 1629 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 270
		 'string_type', 4,
sub
#line 1635 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 271
		 'wide_string_type', 4,
sub
#line 1644 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 272
		 'wide_string_type', 1,
sub
#line 1651 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 273
		 'wide_string_type', 4,
sub
#line 1657 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 274
		 'array_declarator', 2,
sub
#line 1666 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 275
		 'fixed_array_sizes', 1,
sub
#line 1674 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 276
		 'fixed_array_sizes', 2,
sub
#line 1678 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 277
		 'fixed_array_size', 3,
sub
#line 1687 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 278
		 'fixed_array_size', 3,
sub
#line 1691 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'attr_dcl', 4,
sub
#line 1700 "parser23.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 280
		 'attr_dcl', 3,
sub
#line 1708 "parser23.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 281
		 'attr_mod', 1, undef
	],
	[#Rule 282
		 'attr_mod', 0, undef
	],
	[#Rule 283
		 'simple_declarators', 1,
sub
#line 1723 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 284
		 'simple_declarators', 3,
sub
#line 1727 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 285
		 'except_dcl', 3,
sub
#line 1736 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 286
		 'except_dcl', 4,
sub
#line 1741 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 287
		 'except_dcl', 4,
sub
#line 1748 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 288
		 'except_dcl', 2,
sub
#line 1754 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 289
		 'exception_header', 2,
sub
#line 1763 "parser23.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 290
		 'exception_header', 2,
sub
#line 1769 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 291
		 'op_dcl', 4,
sub
#line 1778 "parser23.yp"
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
	[#Rule 292
		 'op_dcl', 2,
sub
#line 1788 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 293
		 'op_header', 3,
sub
#line 1798 "parser23.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 294
		 'op_header', 3,
sub
#line 1806 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 295
		 'op_mod', 1, undef
	],
	[#Rule 296
		 'op_mod', 0, undef
	],
	[#Rule 297
		 'op_attribute', 1, undef
	],
	[#Rule 298
		 'op_type_spec', 1, undef
	],
	[#Rule 299
		 'op_type_spec', 1,
sub
#line 1830 "parser23.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 300
		 'op_type_spec', 1,
sub
#line 1836 "parser23.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 301
		 'op_type_spec', 1,
sub
#line 1841 "parser23.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 302
		 'parameter_dcls', 3,
sub
#line 1850 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 303
		 'parameter_dcls', 5,
sub
#line 1854 "parser23.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 304
		 'parameter_dcls', 4,
sub
#line 1859 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 305
		 'parameter_dcls', 2,
sub
#line 1864 "parser23.yp"
{
			undef;
		}
	],
	[#Rule 306
		 'parameter_dcls', 3,
sub
#line 1868 "parser23.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 307
		 'parameter_dcls', 3,
sub
#line 1873 "parser23.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 308
		 'param_dcls', 1,
sub
#line 1881 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 309
		 'param_dcls', 3,
sub
#line 1885 "parser23.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 310
		 'param_dcls', 2,
sub
#line 1890 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 311
		 'param_dcl', 3,
sub
#line 1899 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 312
		 'param_attribute', 1, undef
	],
	[#Rule 313
		 'param_attribute', 1, undef
	],
	[#Rule 314
		 'param_attribute', 1, undef
	],
	[#Rule 315
		 'param_attribute', 0,
sub
#line 1917 "parser23.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 316
		 'raises_expr', 4,
sub
#line 1926 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 317
		 'raises_expr', 4,
sub
#line 1930 "parser23.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 318
		 'raises_expr', 2,
sub
#line 1935 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 319
		 'raises_expr', 0, undef
	],
	[#Rule 320
		 'exception_names', 1,
sub
#line 1945 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 321
		 'exception_names', 3,
sub
#line 1949 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 322
		 'exception_name', 1,
sub
#line 1957 "parser23.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 323
		 'context_expr', 4,
sub
#line 1965 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 324
		 'context_expr', 4,
sub
#line 1969 "parser23.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 325
		 'context_expr', 2,
sub
#line 1974 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 326
		 'context_expr', 0, undef
	],
	[#Rule 327
		 'string_literals', 1,
sub
#line 1984 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 328
		 'string_literals', 3,
sub
#line 1988 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 329
		 'param_type_spec', 1, undef
	],
	[#Rule 330
		 'param_type_spec', 1,
sub
#line 1999 "parser23.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 331
		 'param_type_spec', 1,
sub
#line 2004 "parser23.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 332
		 'param_type_spec', 1,
sub
#line 2009 "parser23.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 333
		 'param_type_spec', 1,
sub
#line 2014 "parser23.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 334
		 'op_param_type_spec', 1, undef
	],
	[#Rule 335
		 'op_param_type_spec', 1, undef
	],
	[#Rule 336
		 'op_param_type_spec', 1, undef
	],
	[#Rule 337
		 'op_param_type_spec', 1,
sub
#line 2028 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 338
		 'fixed_pt_type', 6,
sub
#line 2036 "parser23.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 339
		 'fixed_pt_type', 6,
sub
#line 2044 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 340
		 'fixed_pt_type', 4,
sub
#line 2049 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 341
		 'fixed_pt_type', 2,
sub
#line 2054 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 342
		 'fixed_pt_const_type', 1,
sub
#line 2063 "parser23.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 343
		 'value_base_type', 1,
sub
#line 2073 "parser23.yp"
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

#line 2080 "parser23.yp"


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
