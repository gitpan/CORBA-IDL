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
			'NATIVE' => 30,
			'ABSTRACT' => 2,
			'STRUCT' => 32,
			'VALUETYPE' => 9,
			'TYPEDEF' => 35,
			'MODULE' => 12,
			'UNION' => 37,
			'error' => 17,
			'LOCAL' => 20,
			'CONST' => 21,
			'EXCEPTION' => 23,
			'CUSTOM' => 40,
			'ENUM' => 26,
			'INTERFACE' => -32
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 28,
			'interface_header' => 29,
			'except_dcl' => 3,
			'value_header' => 31,
			'specification' => 4,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 33,
			'union_type' => 36,
			'exception_header' => 34,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 38,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'value_abs_dcl' => 22,
			'type_dcl' => 39,
			'union_header' => 24,
			'definitions' => 25,
			'definition' => 41,
			'interface_mod' => 27
		}
	},
	{#State 1
		DEFAULT => -61
	},
	{#State 2
		ACTIONS => {
			'error' => 43,
			'VALUETYPE' => 42,
			'INTERFACE' => -30
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 45,
			";" => 44
		}
	},
	{#State 4
		ACTIONS => {
			'' => 46
		}
	},
	{#State 5
		ACTIONS => {
			"{" => 48,
			'error' => 47
		}
	},
	{#State 6
		ACTIONS => {
			'error' => 50,
			";" => 49
		}
	},
	{#State 7
		DEFAULT => -60
	},
	{#State 8
		ACTIONS => {
			"{" => 51
		}
	},
	{#State 9
		ACTIONS => {
			'error' => 52,
			'IDENTIFIER' => 53
		}
	},
	{#State 10
		DEFAULT => -58
	},
	{#State 11
		ACTIONS => {
			"{" => 54
		}
	},
	{#State 12
		ACTIONS => {
			'error' => 55,
			'IDENTIFIER' => 56
		}
	},
	{#State 13
		DEFAULT => -23
	},
	{#State 14
		ACTIONS => {
			'error' => 58,
			";" => 57
		}
	},
	{#State 15
		DEFAULT => -176
	},
	{#State 16
		DEFAULT => -24
	},
	{#State 17
		DEFAULT => -3
	},
	{#State 18
		ACTIONS => {
			"{" => 60,
			'error' => 59
		}
	},
	{#State 19
		DEFAULT => -178
	},
	{#State 20
		DEFAULT => -31
	},
	{#State 21
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'FIXED' => 63,
			'WCHAR' => 73,
			'DOUBLE' => 84,
			'error' => 75,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'OCTET' => 76,
			'FLOAT' => 78,
			'WSTRING' => 90,
			'UNSIGNED' => 70
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'wide_string_type' => 81,
			'integer_type' => 83,
			'boolean_type' => 82,
			'char_type' => 65,
			'octet_type' => 66,
			'scoped_name' => 67,
			'fixed_pt_const_type' => 87,
			'wide_char_type' => 68,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'const_type' => 91,
			'string_type' => 71,
			'unsigned_longlong_int' => 74,
			'unsigned_long_int' => 94,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 22
		DEFAULT => -59
	},
	{#State 23
		ACTIONS => {
			'error' => 95,
			'IDENTIFIER' => 96
		}
	},
	{#State 24
		ACTIONS => {
			'SWITCH' => 97
		}
	},
	{#State 25
		DEFAULT => -1
	},
	{#State 26
		ACTIONS => {
			'error' => 98,
			'IDENTIFIER' => 99
		}
	},
	{#State 27
		ACTIONS => {
			'INTERFACE' => 100
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 102,
			";" => 101
		}
	},
	{#State 29
		ACTIONS => {
			"{" => 103
		}
	},
	{#State 30
		ACTIONS => {
			'error' => 104,
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarator' => 105
		}
	},
	{#State 31
		ACTIONS => {
			"{" => 107
		}
	},
	{#State 32
		ACTIONS => {
			'error' => 108,
			'IDENTIFIER' => 109
		}
	},
	{#State 33
		DEFAULT => -174
	},
	{#State 34
		ACTIONS => {
			"{" => 111,
			'error' => 110
		}
	},
	{#State 35
		ACTIONS => {
			'CHAR' => 80,
			'OBJECT' => 129,
			'VALUEBASE' => 130,
			'FIXED' => 113,
			'SEQUENCE' => 114,
			'STRUCT' => 134,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'UNION' => 137,
			'WCHAR' => 73,
			'error' => 127,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ENUM' => 26,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 119,
			'wide_char_type' => 120,
			'type_spec' => 121,
			'signed_long_int' => 69,
			'type_declarator' => 122,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'struct_type' => 135,
			'union_type' => 136,
			'sequence_type' => 138,
			'unsigned_long_int' => 94,
			'template_type_spec' => 139,
			'constr_type_spec' => 140,
			'simple_type_spec' => 141,
			'fixed_pt_type' => 142
		}
	},
	{#State 36
		DEFAULT => -175
	},
	{#State 37
		ACTIONS => {
			'error' => 143,
			'IDENTIFIER' => 144
		}
	},
	{#State 38
		ACTIONS => {
			'error' => 146,
			";" => 145
		}
	},
	{#State 39
		ACTIONS => {
			'error' => 148,
			";" => 147
		}
	},
	{#State 40
		ACTIONS => {
			'error' => 150,
			'VALUETYPE' => 149
		}
	},
	{#State 41
		ACTIONS => {
			'TYPEDEF' => 35,
			'NATIVE' => 30,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 37,
			'STRUCT' => 32,
			'LOCAL' => 20,
			'CONST' => 21,
			'EXCEPTION' => 23,
			'CUSTOM' => 40,
			'VALUETYPE' => 9,
			'ENUM' => 26,
			'INTERFACE' => -32
		},
		DEFAULT => -4,
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 28,
			'interface_header' => 29,
			'except_dcl' => 3,
			'value_header' => 31,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 33,
			'union_type' => 36,
			'exception_header' => 34,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 38,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'value_abs_dcl' => 22,
			'type_dcl' => 39,
			'definitions' => 151,
			'union_header' => 24,
			'definition' => 41,
			'interface_mod' => 27
		}
	},
	{#State 42
		ACTIONS => {
			'error' => 152,
			'IDENTIFIER' => 153
		}
	},
	{#State 43
		DEFAULT => -71
	},
	{#State 44
		DEFAULT => -8
	},
	{#State 45
		DEFAULT => -14
	},
	{#State 46
		DEFAULT => 0
	},
	{#State 47
		DEFAULT => -20
	},
	{#State 48
		ACTIONS => {
			'TYPEDEF' => 35,
			'NATIVE' => 30,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 37,
			'STRUCT' => 32,
			'error' => 154,
			'LOCAL' => 20,
			'CONST' => 21,
			'CUSTOM' => 40,
			'EXCEPTION' => 23,
			'ENUM' => 26,
			'VALUETYPE' => 9,
			'INTERFACE' => -32
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 28,
			'interface_header' => 29,
			'except_dcl' => 3,
			'value_header' => 31,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 33,
			'union_type' => 36,
			'exception_header' => 34,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 38,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'value_abs_dcl' => 22,
			'type_dcl' => 39,
			'definitions' => 155,
			'union_header' => 24,
			'definition' => 41,
			'interface_mod' => 27
		}
	},
	{#State 49
		DEFAULT => -9
	},
	{#State 50
		DEFAULT => -15
	},
	{#State 51
		ACTIONS => {
			'CHAR' => -310,
			'OBJECT' => -310,
			'ONEWAY' => 156,
			'VALUEBASE' => -310,
			'NATIVE' => 30,
			'VOID' => -310,
			'STRUCT' => 32,
			'DOUBLE' => -310,
			'LONG' => -310,
			'STRING' => -310,
			"::" => -310,
			'WSTRING' => -310,
			'UNSIGNED' => -310,
			'SHORT' => -310,
			'TYPEDEF' => 35,
			'BOOLEAN' => -310,
			'IDENTIFIER' => -310,
			'UNION' => 37,
			'READONLY' => 167,
			'WCHAR' => -310,
			'ATTRIBUTE' => -293,
			'error' => 161,
			'CONST' => 21,
			"}" => 162,
			'EXCEPTION' => 23,
			'OCTET' => -310,
			'FLOAT' => -310,
			'ENUM' => 26,
			'ANY' => -310
		},
		GOTOS => {
			'const_dcl' => 163,
			'op_mod' => 157,
			'except_dcl' => 158,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'exports' => 164,
			'export' => 165,
			'struct_type' => 33,
			'op_header' => 166,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 168,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'attr_dcl' => 169,
			'type_dcl' => 170,
			'union_header' => 24
		}
	},
	{#State 52
		DEFAULT => -81
	},
	{#State 53
		ACTIONS => {
			'CHAR' => 80,
			'OBJECT' => 129,
			'VALUEBASE' => 130,
			'FIXED' => 113,
			'SEQUENCE' => 114,
			'STRUCT' => 134,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			":" => 173,
			'UNION' => 137,
			'WCHAR' => 73,
			"{" => -77,
			'SUPPORTS' => 174,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ENUM' => 26,
			'ANY' => 128
		},
		DEFAULT => -62,
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 119,
			'wide_char_type' => 120,
			'type_spec' => 171,
			'signed_long_int' => 69,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'value_inheritance_spec' => 172,
			'struct_type' => 135,
			'union_type' => 136,
			'sequence_type' => 138,
			'unsigned_long_int' => 94,
			'template_type_spec' => 139,
			'constr_type_spec' => 140,
			'simple_type_spec' => 141,
			'fixed_pt_type' => 142
		}
	},
	{#State 54
		ACTIONS => {
			'CHAR' => 80,
			'OBJECT' => 129,
			'VALUEBASE' => 130,
			'FIXED' => 113,
			'SEQUENCE' => 114,
			'STRUCT' => 134,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'UNION' => 137,
			'WCHAR' => 73,
			'error' => 176,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ENUM' => 26,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 119,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'type_spec' => 175,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'member_list' => 177,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'member' => 178,
			'struct_type' => 135,
			'union_type' => 136,
			'sequence_type' => 138,
			'unsigned_long_int' => 94,
			'template_type_spec' => 139,
			'constr_type_spec' => 140,
			'simple_type_spec' => 141,
			'fixed_pt_type' => 142
		}
	},
	{#State 55
		DEFAULT => -22
	},
	{#State 56
		DEFAULT => -21
	},
	{#State 57
		DEFAULT => -11
	},
	{#State 58
		DEFAULT => -17
	},
	{#State 59
		DEFAULT => -265
	},
	{#State 60
		ACTIONS => {
			'error' => 179,
			'IDENTIFIER' => 181
		},
		GOTOS => {
			'enumerators' => 182,
			'enumerator' => 180
		}
	},
	{#State 61
		DEFAULT => -214
	},
	{#State 62
		DEFAULT => -126
	},
	{#State 63
		DEFAULT => -344
	},
	{#State 64
		DEFAULT => -213
	},
	{#State 65
		DEFAULT => -123
	},
	{#State 66
		DEFAULT => -131
	},
	{#State 67
		ACTIONS => {
			"::" => 183
		},
		DEFAULT => -130
	},
	{#State 68
		DEFAULT => -124
	},
	{#State 69
		DEFAULT => -216
	},
	{#State 70
		ACTIONS => {
			'SHORT' => 184,
			'LONG' => 185
		}
	},
	{#State 71
		DEFAULT => -127
	},
	{#State 72
		DEFAULT => -218
	},
	{#State 73
		DEFAULT => -228
	},
	{#State 74
		DEFAULT => -223
	},
	{#State 75
		DEFAULT => -121
	},
	{#State 76
		DEFAULT => -230
	},
	{#State 77
		DEFAULT => -221
	},
	{#State 78
		DEFAULT => -210
	},
	{#State 79
		DEFAULT => -217
	},
	{#State 80
		DEFAULT => -227
	},
	{#State 81
		DEFAULT => -128
	},
	{#State 82
		DEFAULT => -125
	},
	{#State 83
		DEFAULT => -122
	},
	{#State 84
		DEFAULT => -211
	},
	{#State 85
		ACTIONS => {
			'DOUBLE' => 186,
			'LONG' => 187
		},
		DEFAULT => -219
	},
	{#State 86
		ACTIONS => {
			"<" => 188
		},
		DEFAULT => -279
	},
	{#State 87
		DEFAULT => -129
	},
	{#State 88
		ACTIONS => {
			'error' => 189,
			'IDENTIFIER' => 190
		}
	},
	{#State 89
		DEFAULT => -215
	},
	{#State 90
		ACTIONS => {
			"<" => 191
		},
		DEFAULT => -282
	},
	{#State 91
		ACTIONS => {
			'error' => 192,
			'IDENTIFIER' => 193
		}
	},
	{#State 92
		DEFAULT => -229
	},
	{#State 93
		DEFAULT => -53
	},
	{#State 94
		DEFAULT => -222
	},
	{#State 95
		DEFAULT => -301
	},
	{#State 96
		DEFAULT => -300
	},
	{#State 97
		ACTIONS => {
			'error' => 195,
			"(" => 194
		}
	},
	{#State 98
		DEFAULT => -267
	},
	{#State 99
		DEFAULT => -266
	},
	{#State 100
		ACTIONS => {
			'error' => 196,
			'IDENTIFIER' => 197
		}
	},
	{#State 101
		DEFAULT => -7
	},
	{#State 102
		DEFAULT => -13
	},
	{#State 103
		ACTIONS => {
			'CHAR' => -310,
			'OBJECT' => -310,
			'ONEWAY' => 156,
			'VALUEBASE' => -310,
			'NATIVE' => 30,
			'VOID' => -310,
			'STRUCT' => 32,
			'DOUBLE' => -310,
			'LONG' => -310,
			'STRING' => -310,
			"::" => -310,
			'WSTRING' => -310,
			'UNSIGNED' => -310,
			'SHORT' => -310,
			'TYPEDEF' => 35,
			'BOOLEAN' => -310,
			'IDENTIFIER' => -310,
			'UNION' => 37,
			'READONLY' => 167,
			'WCHAR' => -310,
			'ATTRIBUTE' => -293,
			'error' => 198,
			'CONST' => 21,
			"}" => 199,
			'EXCEPTION' => 23,
			'OCTET' => -310,
			'FLOAT' => -310,
			'ENUM' => 26,
			'ANY' => -310
		},
		GOTOS => {
			'const_dcl' => 163,
			'op_mod' => 157,
			'except_dcl' => 158,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'exports' => 200,
			'export' => 165,
			'struct_type' => 33,
			'op_header' => 166,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 168,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'attr_dcl' => 169,
			'type_dcl' => 170,
			'union_header' => 24,
			'interface_body' => 201
		}
	},
	{#State 104
		DEFAULT => -180
	},
	{#State 105
		DEFAULT => -177
	},
	{#State 106
		DEFAULT => -208
	},
	{#State 107
		ACTIONS => {
			'PRIVATE' => 202,
			'ONEWAY' => 156,
			'FACTORY' => 206,
			'UNSIGNED' => -310,
			'SHORT' => -310,
			'WCHAR' => -310,
			'error' => 208,
			'CONST' => 21,
			"}" => 209,
			'EXCEPTION' => 23,
			'OCTET' => -310,
			'FLOAT' => -310,
			'ENUM' => 26,
			'ANY' => -310,
			'CHAR' => -310,
			'OBJECT' => -310,
			'NATIVE' => 30,
			'VALUEBASE' => -310,
			'VOID' => -310,
			'STRUCT' => 32,
			'DOUBLE' => -310,
			'LONG' => -310,
			'STRING' => -310,
			"::" => -310,
			'WSTRING' => -310,
			'BOOLEAN' => -310,
			'TYPEDEF' => 35,
			'IDENTIFIER' => -310,
			'UNION' => 37,
			'READONLY' => 167,
			'ATTRIBUTE' => -293,
			'PUBLIC' => 212
		},
		GOTOS => {
			'const_dcl' => 163,
			'op_mod' => 157,
			'value_elements' => 210,
			'except_dcl' => 158,
			'state_member' => 203,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'state_mod' => 204,
			'value_element' => 205,
			'export' => 211,
			'struct_type' => 33,
			'init_header' => 207,
			'union_type' => 36,
			'exception_header' => 34,
			'op_header' => 166,
			'struct_header' => 11,
			'op_dcl' => 168,
			'enum_type' => 15,
			'init_dcl' => 213,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 169,
			'type_dcl' => 170,
			'union_header' => 24
		}
	},
	{#State 108
		DEFAULT => -347
	},
	{#State 109
		ACTIONS => {
			"{" => -235
		},
		DEFAULT => -346
	},
	{#State 110
		DEFAULT => -299
	},
	{#State 111
		ACTIONS => {
			'CHAR' => 80,
			'OBJECT' => 129,
			'VALUEBASE' => 130,
			'FIXED' => 113,
			'SEQUENCE' => 114,
			'STRUCT' => 134,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'UNION' => 137,
			'WCHAR' => 73,
			'error' => 214,
			"}" => 216,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ENUM' => 26,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 119,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'type_spec' => 175,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'member_list' => 215,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'member' => 178,
			'struct_type' => 135,
			'union_type' => 136,
			'sequence_type' => 138,
			'unsigned_long_int' => 94,
			'template_type_spec' => 139,
			'constr_type_spec' => 140,
			'simple_type_spec' => 141,
			'fixed_pt_type' => 142
		}
	},
	{#State 112
		DEFAULT => -188
	},
	{#State 113
		ACTIONS => {
			"<" => 218,
			'error' => 217
		}
	},
	{#State 114
		ACTIONS => {
			"<" => 220,
			'error' => 219
		}
	},
	{#State 115
		DEFAULT => -196
	},
	{#State 116
		DEFAULT => -190
	},
	{#State 117
		DEFAULT => -195
	},
	{#State 118
		DEFAULT => -193
	},
	{#State 119
		ACTIONS => {
			"::" => 183
		},
		DEFAULT => -187
	},
	{#State 120
		DEFAULT => -191
	},
	{#State 121
		ACTIONS => {
			'error' => 223,
			'IDENTIFIER' => 227
		},
		GOTOS => {
			'declarators' => 221,
			'declarator' => 222,
			'simple_declarator' => 225,
			'array_declarator' => 226,
			'complex_declarator' => 224
		}
	},
	{#State 122
		DEFAULT => -173
	},
	{#State 123
		DEFAULT => -198
	},
	{#State 124
		DEFAULT => -194
	},
	{#State 125
		DEFAULT => -185
	},
	{#State 126
		DEFAULT => -203
	},
	{#State 127
		DEFAULT => -179
	},
	{#State 128
		DEFAULT => -231
	},
	{#State 129
		DEFAULT => -232
	},
	{#State 130
		DEFAULT => -345
	},
	{#State 131
		DEFAULT => -199
	},
	{#State 132
		DEFAULT => -192
	},
	{#State 133
		DEFAULT => -189
	},
	{#State 134
		ACTIONS => {
			'IDENTIFIER' => 228
		}
	},
	{#State 135
		DEFAULT => -201
	},
	{#State 136
		DEFAULT => -202
	},
	{#State 137
		ACTIONS => {
			'IDENTIFIER' => 229
		}
	},
	{#State 138
		DEFAULT => -197
	},
	{#State 139
		DEFAULT => -186
	},
	{#State 140
		DEFAULT => -184
	},
	{#State 141
		DEFAULT => -183
	},
	{#State 142
		DEFAULT => -200
	},
	{#State 143
		DEFAULT => -349
	},
	{#State 144
		ACTIONS => {
			'SWITCH' => -245
		},
		DEFAULT => -348
	},
	{#State 145
		DEFAULT => -10
	},
	{#State 146
		DEFAULT => -16
	},
	{#State 147
		DEFAULT => -6
	},
	{#State 148
		DEFAULT => -12
	},
	{#State 149
		ACTIONS => {
			'error' => 230,
			'IDENTIFIER' => 231
		}
	},
	{#State 150
		DEFAULT => -83
	},
	{#State 151
		DEFAULT => -5
	},
	{#State 152
		DEFAULT => -70
	},
	{#State 153
		ACTIONS => {
			"{" => -68,
			'SUPPORTS' => 174,
			":" => 173
		},
		DEFAULT => -63,
		GOTOS => {
			'value_inheritance_spec' => 232
		}
	},
	{#State 154
		ACTIONS => {
			"}" => 233
		}
	},
	{#State 155
		ACTIONS => {
			"}" => 234
		}
	},
	{#State 156
		DEFAULT => -311
	},
	{#State 157
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'OBJECT' => 129,
			'IDENTIFIER' => 93,
			'VALUEBASE' => 130,
			'VOID' => 240,
			'WCHAR' => 73,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'OCTET' => 76,
			'FLOAT' => 78,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'wide_string_type' => 239,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 235,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 236,
			'op_type_spec' => 241,
			'base_type_spec' => 237,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'unsigned_long_int' => 94,
			'param_type_spec' => 238,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 158
		ACTIONS => {
			'error' => 243,
			";" => 242
		}
	},
	{#State 159
		DEFAULT => -309
	},
	{#State 160
		ACTIONS => {
			'ATTRIBUTE' => 244
		}
	},
	{#State 161
		ACTIONS => {
			"}" => 245
		}
	},
	{#State 162
		DEFAULT => -65
	},
	{#State 163
		ACTIONS => {
			'error' => 247,
			";" => 246
		}
	},
	{#State 164
		ACTIONS => {
			"}" => 248
		}
	},
	{#State 165
		ACTIONS => {
			'ONEWAY' => 156,
			'NATIVE' => 30,
			'STRUCT' => 32,
			'TYPEDEF' => 35,
			'UNION' => 37,
			'READONLY' => 167,
			'ATTRIBUTE' => -293,
			'CONST' => 21,
			"}" => -36,
			'EXCEPTION' => 23,
			'ENUM' => 26
		},
		DEFAULT => -310,
		GOTOS => {
			'const_dcl' => 163,
			'op_mod' => 157,
			'except_dcl' => 158,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'exports' => 249,
			'export' => 165,
			'struct_type' => 33,
			'op_header' => 166,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 168,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'attr_dcl' => 169,
			'type_dcl' => 170,
			'union_header' => 24
		}
	},
	{#State 166
		ACTIONS => {
			'error' => 251,
			"(" => 250
		},
		GOTOS => {
			'parameter_dcls' => 252
		}
	},
	{#State 167
		DEFAULT => -292
	},
	{#State 168
		ACTIONS => {
			'error' => 254,
			";" => 253
		}
	},
	{#State 169
		ACTIONS => {
			'error' => 256,
			";" => 255
		}
	},
	{#State 170
		ACTIONS => {
			'error' => 258,
			";" => 257
		}
	},
	{#State 171
		DEFAULT => -64
	},
	{#State 172
		DEFAULT => -79
	},
	{#State 173
		ACTIONS => {
			'error' => 261,
			'IDENTIFIER' => 93,
			"::" => 88,
			'TRUNCATABLE' => 262
		},
		GOTOS => {
			'scoped_name' => 259,
			'value_name' => 260,
			'value_names' => 263
		}
	},
	{#State 174
		ACTIONS => {
			'error' => 265,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 264,
			'interface_names' => 267,
			'interface_name' => 266
		}
	},
	{#State 175
		ACTIONS => {
			'IDENTIFIER' => 227
		},
		GOTOS => {
			'declarators' => 268,
			'declarator' => 222,
			'simple_declarator' => 225,
			'array_declarator' => 226,
			'complex_declarator' => 224
		}
	},
	{#State 176
		ACTIONS => {
			"}" => 269
		}
	},
	{#State 177
		ACTIONS => {
			"}" => 270
		}
	},
	{#State 178
		ACTIONS => {
			'CHAR' => 80,
			'OBJECT' => 129,
			'VALUEBASE' => 130,
			'FIXED' => 113,
			'SEQUENCE' => 114,
			'STRUCT' => 134,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'UNION' => 137,
			'WCHAR' => 73,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ENUM' => 26,
			'ANY' => 128
		},
		DEFAULT => -236,
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 119,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'type_spec' => 175,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'member_list' => 271,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'member' => 178,
			'struct_type' => 135,
			'union_type' => 136,
			'sequence_type' => 138,
			'unsigned_long_int' => 94,
			'template_type_spec' => 139,
			'constr_type_spec' => 140,
			'simple_type_spec' => 141,
			'fixed_pt_type' => 142
		}
	},
	{#State 179
		ACTIONS => {
			"}" => 272
		}
	},
	{#State 180
		ACTIONS => {
			";" => 273,
			"," => 274
		},
		DEFAULT => -268
	},
	{#State 181
		DEFAULT => -272
	},
	{#State 182
		ACTIONS => {
			"}" => 275
		}
	},
	{#State 183
		ACTIONS => {
			'error' => 276,
			'IDENTIFIER' => 277
		}
	},
	{#State 184
		DEFAULT => -224
	},
	{#State 185
		ACTIONS => {
			'LONG' => 278
		},
		DEFAULT => -225
	},
	{#State 186
		DEFAULT => -212
	},
	{#State 187
		DEFAULT => -220
	},
	{#State 188
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 288,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'primary_expr' => 298,
			'and_expr' => 299,
			'scoped_name' => 281,
			'positive_int_const' => 282,
			'wide_string_literal' => 283,
			'boolean_literal' => 285,
			'mult_expr' => 301,
			'const_exp' => 286,
			'or_expr' => 287,
			'unary_expr' => 305,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 189
		DEFAULT => -55
	},
	{#State 190
		DEFAULT => -54
	},
	{#State 191
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 310,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'primary_expr' => 298,
			'and_expr' => 299,
			'scoped_name' => 281,
			'positive_int_const' => 309,
			'wide_string_literal' => 283,
			'boolean_literal' => 285,
			'mult_expr' => 301,
			'const_exp' => 286,
			'or_expr' => 287,
			'unary_expr' => 305,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 192
		DEFAULT => -120
	},
	{#State 193
		ACTIONS => {
			'error' => 311,
			"=" => 312
		}
	},
	{#State 194
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'error' => 316,
			'LONG' => 320,
			"::" => 88,
			'ENUM' => 26,
			'UNSIGNED' => 70
		},
		GOTOS => {
			'switch_type_spec' => 317,
			'unsigned_int' => 61,
			'signed_int' => 64,
			'integer_type' => 319,
			'boolean_type' => 318,
			'unsigned_longlong_int' => 74,
			'char_type' => 313,
			'enum_type' => 315,
			'unsigned_long_int' => 94,
			'scoped_name' => 314,
			'enum_header' => 18,
			'signed_long_int' => 69,
			'unsigned_short_int' => 77,
			'signed_short_int' => 89,
			'signed_longlong_int' => 79
		}
	},
	{#State 195
		DEFAULT => -244
	},
	{#State 196
		DEFAULT => -29
	},
	{#State 197
		ACTIONS => {
			"{" => -33,
			":" => 321
		},
		DEFAULT => -28,
		GOTOS => {
			'interface_inheritance_spec' => 322
		}
	},
	{#State 198
		ACTIONS => {
			"}" => 323
		}
	},
	{#State 199
		DEFAULT => -25
	},
	{#State 200
		DEFAULT => -35
	},
	{#State 201
		ACTIONS => {
			"}" => 324
		}
	},
	{#State 202
		DEFAULT => -104
	},
	{#State 203
		DEFAULT => -98
	},
	{#State 204
		ACTIONS => {
			'CHAR' => 80,
			'OBJECT' => 129,
			'VALUEBASE' => 130,
			'FIXED' => 113,
			'SEQUENCE' => 114,
			'STRUCT' => 134,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'UNION' => 137,
			'WCHAR' => 73,
			'error' => 326,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ENUM' => 26,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 119,
			'wide_char_type' => 120,
			'type_spec' => 325,
			'signed_long_int' => 69,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'struct_type' => 135,
			'union_type' => 136,
			'sequence_type' => 138,
			'unsigned_long_int' => 94,
			'template_type_spec' => 139,
			'constr_type_spec' => 140,
			'simple_type_spec' => 141,
			'fixed_pt_type' => 142
		}
	},
	{#State 205
		ACTIONS => {
			'PRIVATE' => 202,
			'ONEWAY' => 156,
			'FACTORY' => 206,
			'CONST' => 21,
			'EXCEPTION' => 23,
			"}" => -75,
			'ENUM' => 26,
			'NATIVE' => 30,
			'STRUCT' => 32,
			'TYPEDEF' => 35,
			'UNION' => 37,
			'READONLY' => 167,
			'ATTRIBUTE' => -293,
			'PUBLIC' => 212
		},
		DEFAULT => -310,
		GOTOS => {
			'const_dcl' => 163,
			'op_mod' => 157,
			'value_elements' => 327,
			'except_dcl' => 158,
			'state_member' => 203,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'state_mod' => 204,
			'value_element' => 205,
			'export' => 211,
			'struct_type' => 33,
			'init_header' => 207,
			'union_type' => 36,
			'exception_header' => 34,
			'op_header' => 166,
			'struct_header' => 11,
			'op_dcl' => 168,
			'enum_type' => 15,
			'init_dcl' => 213,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 169,
			'type_dcl' => 170,
			'union_header' => 24
		}
	},
	{#State 206
		ACTIONS => {
			'error' => 328,
			'IDENTIFIER' => 329
		}
	},
	{#State 207
		ACTIONS => {
			'error' => 331,
			"(" => 330
		}
	},
	{#State 208
		ACTIONS => {
			"}" => 332
		}
	},
	{#State 209
		DEFAULT => -72
	},
	{#State 210
		ACTIONS => {
			"}" => 333
		}
	},
	{#State 211
		DEFAULT => -97
	},
	{#State 212
		DEFAULT => -103
	},
	{#State 213
		DEFAULT => -99
	},
	{#State 214
		ACTIONS => {
			"}" => 334
		}
	},
	{#State 215
		ACTIONS => {
			"}" => 335
		}
	},
	{#State 216
		DEFAULT => -296
	},
	{#State 217
		DEFAULT => -343
	},
	{#State 218
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 337,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'primary_expr' => 298,
			'and_expr' => 299,
			'scoped_name' => 281,
			'positive_int_const' => 336,
			'wide_string_literal' => 283,
			'boolean_literal' => 285,
			'mult_expr' => 301,
			'const_exp' => 286,
			'or_expr' => 287,
			'unary_expr' => 305,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 219
		DEFAULT => -277
	},
	{#State 220
		ACTIONS => {
			'CHAR' => 80,
			'OBJECT' => 129,
			'VALUEBASE' => 130,
			'FIXED' => 113,
			'SEQUENCE' => 114,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'WCHAR' => 73,
			'error' => 338,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'wide_string_type' => 131,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 119,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 123,
			'sequence_type' => 138,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'unsigned_long_int' => 94,
			'template_type_spec' => 139,
			'unsigned_short_int' => 77,
			'simple_type_spec' => 339,
			'fixed_pt_type' => 142,
			'signed_longlong_int' => 79
		}
	},
	{#State 221
		DEFAULT => -181
	},
	{#State 222
		ACTIONS => {
			"," => 340
		},
		DEFAULT => -204
	},
	{#State 223
		DEFAULT => -182
	},
	{#State 224
		DEFAULT => -207
	},
	{#State 225
		DEFAULT => -206
	},
	{#State 226
		DEFAULT => -209
	},
	{#State 227
		ACTIONS => {
			"[" => 343
		},
		DEFAULT => -208,
		GOTOS => {
			'fixed_array_sizes' => 341,
			'fixed_array_size' => 342
		}
	},
	{#State 228
		DEFAULT => -235
	},
	{#State 229
		DEFAULT => -245
	},
	{#State 230
		DEFAULT => -82
	},
	{#State 231
		ACTIONS => {
			'SUPPORTS' => 174,
			":" => 173
		},
		DEFAULT => -78,
		GOTOS => {
			'value_inheritance_spec' => 344
		}
	},
	{#State 232
		DEFAULT => -69
	},
	{#State 233
		DEFAULT => -19
	},
	{#State 234
		DEFAULT => -18
	},
	{#State 235
		ACTIONS => {
			"::" => 183
		},
		DEFAULT => -339
	},
	{#State 236
		DEFAULT => -337
	},
	{#State 237
		DEFAULT => -336
	},
	{#State 238
		DEFAULT => -312
	},
	{#State 239
		DEFAULT => -338
	},
	{#State 240
		DEFAULT => -313
	},
	{#State 241
		ACTIONS => {
			'error' => 345,
			'IDENTIFIER' => 346
		}
	},
	{#State 242
		DEFAULT => -40
	},
	{#State 243
		DEFAULT => -45
	},
	{#State 244
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'OBJECT' => 129,
			'IDENTIFIER' => 93,
			'VALUEBASE' => 130,
			'WCHAR' => 73,
			'DOUBLE' => 84,
			'error' => 347,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'OCTET' => 76,
			'FLOAT' => 78,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'wide_string_type' => 239,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 235,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 236,
			'base_type_spec' => 237,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'unsigned_long_int' => 94,
			'param_type_spec' => 348,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 245
		DEFAULT => -67
	},
	{#State 246
		DEFAULT => -39
	},
	{#State 247
		DEFAULT => -44
	},
	{#State 248
		DEFAULT => -66
	},
	{#State 249
		DEFAULT => -37
	},
	{#State 250
		ACTIONS => {
			'error' => 350,
			")" => 354,
			'OUT' => 355,
			'INOUT' => 351,
			'IN' => 349
		},
		GOTOS => {
			'param_dcl' => 356,
			'param_dcls' => 353,
			'param_attribute' => 352
		}
	},
	{#State 251
		DEFAULT => -306
	},
	{#State 252
		ACTIONS => {
			'RAISES' => 360,
			'CONTEXT' => 357
		},
		DEFAULT => -302,
		GOTOS => {
			'context_expr' => 359,
			'raises_expr' => 358
		}
	},
	{#State 253
		DEFAULT => -42
	},
	{#State 254
		DEFAULT => -47
	},
	{#State 255
		DEFAULT => -41
	},
	{#State 256
		DEFAULT => -46
	},
	{#State 257
		DEFAULT => -38
	},
	{#State 258
		DEFAULT => -43
	},
	{#State 259
		ACTIONS => {
			"::" => 183
		},
		DEFAULT => -96
	},
	{#State 260
		ACTIONS => {
			"," => 361
		},
		DEFAULT => -94
	},
	{#State 261
		DEFAULT => -91
	},
	{#State 262
		ACTIONS => {
			'error' => 362,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 259,
			'value_name' => 260,
			'value_names' => 363
		}
	},
	{#State 263
		ACTIONS => {
			'SUPPORTS' => 364
		},
		DEFAULT => -84
	},
	{#State 264
		ACTIONS => {
			"::" => 183
		},
		DEFAULT => -52
	},
	{#State 265
		DEFAULT => -93
	},
	{#State 266
		ACTIONS => {
			"," => 365
		},
		DEFAULT => -50
	},
	{#State 267
		DEFAULT => -92
	},
	{#State 268
		ACTIONS => {
			'error' => 367,
			";" => 366
		}
	},
	{#State 269
		DEFAULT => -234
	},
	{#State 270
		DEFAULT => -233
	},
	{#State 271
		DEFAULT => -237
	},
	{#State 272
		DEFAULT => -264
	},
	{#State 273
		DEFAULT => -271
	},
	{#State 274
		ACTIONS => {
			'IDENTIFIER' => 181
		},
		DEFAULT => -270,
		GOTOS => {
			'enumerators' => 368,
			'enumerator' => 180
		}
	},
	{#State 275
		DEFAULT => -263
	},
	{#State 276
		DEFAULT => -57
	},
	{#State 277
		DEFAULT => -56
	},
	{#State 278
		DEFAULT => -226
	},
	{#State 279
		DEFAULT => -161
	},
	{#State 280
		DEFAULT => -162
	},
	{#State 281
		ACTIONS => {
			"::" => 183
		},
		DEFAULT => -154
	},
	{#State 282
		ACTIONS => {
			">" => 369
		}
	},
	{#State 283
		DEFAULT => -160
	},
	{#State 284
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 371,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 301,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'const_exp' => 370,
			'and_expr' => 299,
			'or_expr' => 287,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 285
		DEFAULT => -165
	},
	{#State 286
		DEFAULT => -172
	},
	{#State 287
		ACTIONS => {
			"|" => 372
		},
		DEFAULT => -132
	},
	{#State 288
		ACTIONS => {
			">" => 373
		}
	},
	{#State 289
		ACTIONS => {
			"^" => 374
		},
		DEFAULT => -133
	},
	{#State 290
		ACTIONS => {
			"<<" => 375,
			">>" => 376
		},
		DEFAULT => -137
	},
	{#State 291
		DEFAULT => -171
	},
	{#State 292
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 292
		},
		DEFAULT => -168,
		GOTOS => {
			'wide_string_literal' => 377
		}
	},
	{#State 293
		DEFAULT => -155
	},
	{#State 294
		DEFAULT => -170
	},
	{#State 295
		ACTIONS => {
			"+" => 378,
			"-" => 379
		},
		DEFAULT => -139
	},
	{#State 296
		DEFAULT => -159
	},
	{#State 297
		DEFAULT => -164
	},
	{#State 298
		DEFAULT => -150
	},
	{#State 299
		ACTIONS => {
			"&" => 380
		},
		DEFAULT => -135
	},
	{#State 300
		DEFAULT => -158
	},
	{#State 301
		ACTIONS => {
			"%" => 382,
			"*" => 381,
			"/" => 383
		},
		DEFAULT => -142
	},
	{#State 302
		ACTIONS => {
			'STRING_LITERAL' => 302
		},
		DEFAULT => -166,
		GOTOS => {
			'string_literal' => 384
		}
	},
	{#State 303
		DEFAULT => -163
	},
	{#State 304
		DEFAULT => -152
	},
	{#State 305
		DEFAULT => -145
	},
	{#State 306
		DEFAULT => -151
	},
	{#State 307
		DEFAULT => -153
	},
	{#State 308
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'boolean_literal' => 285,
			'scoped_name' => 281,
			'primary_expr' => 385,
			'literal' => 293,
			'wide_string_literal' => 283
		}
	},
	{#State 309
		ACTIONS => {
			">" => 386
		}
	},
	{#State 310
		ACTIONS => {
			">" => 387
		}
	},
	{#State 311
		DEFAULT => -119
	},
	{#State 312
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 389,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 301,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'const_exp' => 388,
			'and_expr' => 299,
			'or_expr' => 287,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 313
		DEFAULT => -247
	},
	{#State 314
		ACTIONS => {
			"::" => 183
		},
		DEFAULT => -250
	},
	{#State 315
		DEFAULT => -249
	},
	{#State 316
		ACTIONS => {
			")" => 390
		}
	},
	{#State 317
		ACTIONS => {
			")" => 391
		}
	},
	{#State 318
		DEFAULT => -248
	},
	{#State 319
		DEFAULT => -246
	},
	{#State 320
		ACTIONS => {
			'LONG' => 187
		},
		DEFAULT => -219
	},
	{#State 321
		ACTIONS => {
			'error' => 392,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 264,
			'interface_names' => 393,
			'interface_name' => 266
		}
	},
	{#State 322
		DEFAULT => -34
	},
	{#State 323
		DEFAULT => -27
	},
	{#State 324
		DEFAULT => -26
	},
	{#State 325
		ACTIONS => {
			'error' => 395,
			'IDENTIFIER' => 227
		},
		GOTOS => {
			'declarators' => 394,
			'declarator' => 222,
			'simple_declarator' => 225,
			'array_declarator' => 226,
			'complex_declarator' => 224
		}
	},
	{#State 326
		ACTIONS => {
			";" => 396
		}
	},
	{#State 327
		DEFAULT => -76
	},
	{#State 328
		DEFAULT => -112
	},
	{#State 329
		DEFAULT => -111
	},
	{#State 330
		ACTIONS => {
			'error' => 401,
			")" => 402,
			'IN' => 399
		},
		GOTOS => {
			'init_param_decls' => 398,
			'init_param_attribute' => 397,
			'init_param_decl' => 400
		}
	},
	{#State 331
		DEFAULT => -110
	},
	{#State 332
		DEFAULT => -74
	},
	{#State 333
		DEFAULT => -73
	},
	{#State 334
		DEFAULT => -298
	},
	{#State 335
		DEFAULT => -297
	},
	{#State 336
		ACTIONS => {
			"," => 403
		}
	},
	{#State 337
		ACTIONS => {
			">" => 404
		}
	},
	{#State 338
		ACTIONS => {
			">" => 405
		}
	},
	{#State 339
		ACTIONS => {
			">" => 407,
			"," => 406
		}
	},
	{#State 340
		ACTIONS => {
			'IDENTIFIER' => 227
		},
		GOTOS => {
			'declarators' => 408,
			'declarator' => 222,
			'simple_declarator' => 225,
			'array_declarator' => 226,
			'complex_declarator' => 224
		}
	},
	{#State 341
		DEFAULT => -284
	},
	{#State 342
		ACTIONS => {
			"[" => 343
		},
		DEFAULT => -285,
		GOTOS => {
			'fixed_array_sizes' => 409,
			'fixed_array_size' => 342
		}
	},
	{#State 343
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 411,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'primary_expr' => 298,
			'and_expr' => 299,
			'scoped_name' => 281,
			'positive_int_const' => 410,
			'wide_string_literal' => 283,
			'boolean_literal' => 285,
			'mult_expr' => 301,
			'const_exp' => 286,
			'or_expr' => 287,
			'unary_expr' => 305,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 344
		DEFAULT => -80
	},
	{#State 345
		DEFAULT => -308
	},
	{#State 346
		DEFAULT => -307
	},
	{#State 347
		DEFAULT => -291
	},
	{#State 348
		ACTIONS => {
			'error' => 412,
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarators' => 414,
			'simple_declarator' => 413
		}
	},
	{#State 349
		DEFAULT => -322
	},
	{#State 350
		ACTIONS => {
			")" => 415
		}
	},
	{#State 351
		DEFAULT => -324
	},
	{#State 352
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'OBJECT' => 129,
			'IDENTIFIER' => 93,
			'VALUEBASE' => 130,
			'WCHAR' => 73,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'OCTET' => 76,
			'FLOAT' => 78,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'wide_string_type' => 239,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 235,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 236,
			'base_type_spec' => 237,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'unsigned_long_int' => 94,
			'param_type_spec' => 416,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 353
		ACTIONS => {
			")" => 417
		}
	},
	{#State 354
		DEFAULT => -315
	},
	{#State 355
		DEFAULT => -323
	},
	{#State 356
		ACTIONS => {
			";" => 418,
			"," => 419
		},
		DEFAULT => -317
	},
	{#State 357
		ACTIONS => {
			'error' => 421,
			"(" => 420
		}
	},
	{#State 358
		ACTIONS => {
			'CONTEXT' => 357
		},
		DEFAULT => -303,
		GOTOS => {
			'context_expr' => 422
		}
	},
	{#State 359
		DEFAULT => -305
	},
	{#State 360
		ACTIONS => {
			'error' => 424,
			"(" => 423
		}
	},
	{#State 361
		ACTIONS => {
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 259,
			'value_name' => 260,
			'value_names' => 425
		}
	},
	{#State 362
		DEFAULT => -90
	},
	{#State 363
		ACTIONS => {
			'SUPPORTS' => 426
		},
		DEFAULT => -85
	},
	{#State 364
		ACTIONS => {
			'error' => 427,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 264,
			'interface_names' => 428,
			'interface_name' => 266
		}
	},
	{#State 365
		ACTIONS => {
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 264,
			'interface_names' => 429,
			'interface_name' => 266
		}
	},
	{#State 366
		DEFAULT => -238
	},
	{#State 367
		DEFAULT => -239
	},
	{#State 368
		DEFAULT => -269
	},
	{#State 369
		DEFAULT => -278
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
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 301,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'and_expr' => 299,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'xor_expr' => 432,
			'shift_expr' => 290,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 373
		DEFAULT => -280
	},
	{#State 374
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 301,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'and_expr' => 433,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'shift_expr' => 290,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 375
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 301,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 434
		}
	},
	{#State 376
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 301,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 435
		}
	},
	{#State 377
		DEFAULT => -169
	},
	{#State 378
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 436,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308
		}
	},
	{#State 379
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 437,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308
		}
	},
	{#State 380
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 301,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'shift_expr' => 438,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 381
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'unary_expr' => 439,
			'scoped_name' => 281,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308
		}
	},
	{#State 382
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'unary_expr' => 440,
			'scoped_name' => 281,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308
		}
	},
	{#State 383
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'CHARACTER_LITERAL' => 279,
			"+" => 304,
			'FIXED_PT_LITERAL' => 303,
			'WIDE_CHARACTER_LITERAL' => 280,
			"-" => 306,
			"::" => 88,
			'FALSE' => 291,
			'WIDE_STRING_LITERAL' => 292,
			'INTEGER_LITERAL' => 300,
			"~" => 307,
			"(" => 284,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'unary_expr' => 441,
			'scoped_name' => 281,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308
		}
	},
	{#State 384
		DEFAULT => -167
	},
	{#State 385
		DEFAULT => -149
	},
	{#State 386
		DEFAULT => -281
	},
	{#State 387
		DEFAULT => -283
	},
	{#State 388
		DEFAULT => -117
	},
	{#State 389
		DEFAULT => -118
	},
	{#State 390
		DEFAULT => -243
	},
	{#State 391
		ACTIONS => {
			"{" => 443,
			'error' => 442
		}
	},
	{#State 392
		DEFAULT => -49
	},
	{#State 393
		DEFAULT => -48
	},
	{#State 394
		ACTIONS => {
			";" => 444
		}
	},
	{#State 395
		ACTIONS => {
			";" => 445
		}
	},
	{#State 396
		DEFAULT => -102
	},
	{#State 397
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'OBJECT' => 129,
			'IDENTIFIER' => 93,
			'VALUEBASE' => 130,
			'WCHAR' => 73,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'OCTET' => 76,
			'FLOAT' => 78,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'wide_string_type' => 239,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 235,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 236,
			'base_type_spec' => 237,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'unsigned_long_int' => 94,
			'param_type_spec' => 446,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 398
		ACTIONS => {
			")" => 447
		}
	},
	{#State 399
		DEFAULT => -116
	},
	{#State 400
		ACTIONS => {
			"," => 448
		},
		DEFAULT => -113
	},
	{#State 401
		ACTIONS => {
			")" => 449
		}
	},
	{#State 402
		ACTIONS => {
			";" => 450
		}
	},
	{#State 403
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 452,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'primary_expr' => 298,
			'and_expr' => 299,
			'scoped_name' => 281,
			'positive_int_const' => 451,
			'wide_string_literal' => 283,
			'boolean_literal' => 285,
			'mult_expr' => 301,
			'const_exp' => 286,
			'or_expr' => 287,
			'unary_expr' => 305,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 404
		DEFAULT => -342
	},
	{#State 405
		DEFAULT => -276
	},
	{#State 406
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 454,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'string_literal' => 296,
			'primary_expr' => 298,
			'and_expr' => 299,
			'scoped_name' => 281,
			'positive_int_const' => 453,
			'wide_string_literal' => 283,
			'boolean_literal' => 285,
			'mult_expr' => 301,
			'const_exp' => 286,
			'or_expr' => 287,
			'unary_expr' => 305,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 407
		DEFAULT => -275
	},
	{#State 408
		DEFAULT => -205
	},
	{#State 409
		DEFAULT => -286
	},
	{#State 410
		ACTIONS => {
			"]" => 455
		}
	},
	{#State 411
		ACTIONS => {
			"]" => 456
		}
	},
	{#State 412
		DEFAULT => -290
	},
	{#State 413
		ACTIONS => {
			"," => 457
		},
		DEFAULT => -294
	},
	{#State 414
		DEFAULT => -289
	},
	{#State 415
		DEFAULT => -316
	},
	{#State 416
		ACTIONS => {
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarator' => 458
		}
	},
	{#State 417
		DEFAULT => -314
	},
	{#State 418
		DEFAULT => -320
	},
	{#State 419
		ACTIONS => {
			'OUT' => 355,
			'INOUT' => 351,
			'IN' => 349
		},
		DEFAULT => -319,
		GOTOS => {
			'param_dcl' => 356,
			'param_dcls' => 459,
			'param_attribute' => 352
		}
	},
	{#State 420
		ACTIONS => {
			'error' => 460,
			'STRING_LITERAL' => 302
		},
		GOTOS => {
			'string_literal' => 461,
			'string_literals' => 462
		}
	},
	{#State 421
		DEFAULT => -333
	},
	{#State 422
		DEFAULT => -304
	},
	{#State 423
		ACTIONS => {
			'error' => 464,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 463,
			'exception_names' => 465,
			'exception_name' => 466
		}
	},
	{#State 424
		DEFAULT => -327
	},
	{#State 425
		DEFAULT => -95
	},
	{#State 426
		ACTIONS => {
			'error' => 467,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 264,
			'interface_names' => 468,
			'interface_name' => 266
		}
	},
	{#State 427
		DEFAULT => -88
	},
	{#State 428
		DEFAULT => -86
	},
	{#State 429
		DEFAULT => -51
	},
	{#State 430
		DEFAULT => -156
	},
	{#State 431
		DEFAULT => -157
	},
	{#State 432
		ACTIONS => {
			"^" => 374
		},
		DEFAULT => -134
	},
	{#State 433
		ACTIONS => {
			"&" => 380
		},
		DEFAULT => -136
	},
	{#State 434
		ACTIONS => {
			"+" => 378,
			"-" => 379
		},
		DEFAULT => -141
	},
	{#State 435
		ACTIONS => {
			"+" => 378,
			"-" => 379
		},
		DEFAULT => -140
	},
	{#State 436
		ACTIONS => {
			"%" => 382,
			"*" => 381,
			"/" => 383
		},
		DEFAULT => -143
	},
	{#State 437
		ACTIONS => {
			"%" => 382,
			"*" => 381,
			"/" => 383
		},
		DEFAULT => -144
	},
	{#State 438
		ACTIONS => {
			"<<" => 375,
			">>" => 376
		},
		DEFAULT => -138
	},
	{#State 439
		DEFAULT => -146
	},
	{#State 440
		DEFAULT => -148
	},
	{#State 441
		DEFAULT => -147
	},
	{#State 442
		DEFAULT => -242
	},
	{#State 443
		ACTIONS => {
			'error' => 472,
			'CASE' => 469,
			'DEFAULT' => 471
		},
		GOTOS => {
			'case_labels' => 474,
			'switch_body' => 473,
			'case' => 470,
			'case_label' => 475
		}
	},
	{#State 444
		DEFAULT => -100
	},
	{#State 445
		DEFAULT => -101
	},
	{#State 446
		ACTIONS => {
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarator' => 476
		}
	},
	{#State 447
		ACTIONS => {
			'error' => 478,
			";" => 477
		}
	},
	{#State 448
		ACTIONS => {
			'IN' => 399
		},
		GOTOS => {
			'init_param_decls' => 479,
			'init_param_attribute' => 397,
			'init_param_decl' => 400
		}
	},
	{#State 449
		ACTIONS => {
			'error' => 481,
			";" => 480
		}
	},
	{#State 450
		DEFAULT => -105
	},
	{#State 451
		ACTIONS => {
			">" => 482
		}
	},
	{#State 452
		ACTIONS => {
			">" => 483
		}
	},
	{#State 453
		ACTIONS => {
			">" => 484
		}
	},
	{#State 454
		ACTIONS => {
			">" => 485
		}
	},
	{#State 455
		DEFAULT => -287
	},
	{#State 456
		DEFAULT => -288
	},
	{#State 457
		ACTIONS => {
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarators' => 486,
			'simple_declarator' => 413
		}
	},
	{#State 458
		DEFAULT => -321
	},
	{#State 459
		DEFAULT => -318
	},
	{#State 460
		ACTIONS => {
			")" => 487
		}
	},
	{#State 461
		ACTIONS => {
			"," => 488
		},
		DEFAULT => -334
	},
	{#State 462
		ACTIONS => {
			")" => 489
		}
	},
	{#State 463
		ACTIONS => {
			"::" => 183
		},
		DEFAULT => -330
	},
	{#State 464
		ACTIONS => {
			")" => 490
		}
	},
	{#State 465
		ACTIONS => {
			")" => 491
		}
	},
	{#State 466
		ACTIONS => {
			"," => 492
		},
		DEFAULT => -328
	},
	{#State 467
		DEFAULT => -89
	},
	{#State 468
		DEFAULT => -87
	},
	{#State 469
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 297,
			'CHARACTER_LITERAL' => 279,
			'WIDE_CHARACTER_LITERAL' => 280,
			"::" => 88,
			'INTEGER_LITERAL' => 300,
			"(" => 284,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 302,
			'FIXED_PT_LITERAL' => 303,
			"+" => 304,
			'error' => 494,
			"-" => 306,
			'WIDE_STRING_LITERAL' => 292,
			'FALSE' => 291,
			"~" => 307,
			'TRUE' => 294
		},
		GOTOS => {
			'mult_expr' => 301,
			'string_literal' => 296,
			'boolean_literal' => 285,
			'primary_expr' => 298,
			'const_exp' => 493,
			'and_expr' => 299,
			'or_expr' => 287,
			'unary_expr' => 305,
			'scoped_name' => 281,
			'xor_expr' => 289,
			'shift_expr' => 290,
			'wide_string_literal' => 283,
			'literal' => 293,
			'unary_operator' => 308,
			'add_expr' => 295
		}
	},
	{#State 470
		ACTIONS => {
			'CASE' => 469,
			'DEFAULT' => 471
		},
		DEFAULT => -251,
		GOTOS => {
			'case_labels' => 474,
			'switch_body' => 495,
			'case' => 470,
			'case_label' => 475
		}
	},
	{#State 471
		ACTIONS => {
			'error' => 496,
			":" => 497
		}
	},
	{#State 472
		ACTIONS => {
			"}" => 498
		}
	},
	{#State 473
		ACTIONS => {
			"}" => 499
		}
	},
	{#State 474
		ACTIONS => {
			'CHAR' => 80,
			'OBJECT' => 129,
			'VALUEBASE' => 130,
			'FIXED' => 113,
			'SEQUENCE' => 114,
			'STRUCT' => 134,
			'DOUBLE' => 84,
			'LONG' => 85,
			'STRING' => 86,
			"::" => 88,
			'WSTRING' => 90,
			'UNSIGNED' => 70,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'UNION' => 137,
			'WCHAR' => 73,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ENUM' => 26,
			'ANY' => 128
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 112,
			'signed_int' => 64,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 119,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'type_spec' => 500,
			'string_type' => 123,
			'struct_header' => 11,
			'element_spec' => 501,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'struct_type' => 135,
			'union_type' => 136,
			'sequence_type' => 138,
			'unsigned_long_int' => 94,
			'template_type_spec' => 139,
			'constr_type_spec' => 140,
			'simple_type_spec' => 141,
			'fixed_pt_type' => 142
		}
	},
	{#State 475
		ACTIONS => {
			'CASE' => 469,
			'DEFAULT' => 471
		},
		DEFAULT => -255,
		GOTOS => {
			'case_labels' => 502,
			'case_label' => 475
		}
	},
	{#State 476
		DEFAULT => -115
	},
	{#State 477
		DEFAULT => -106
	},
	{#State 478
		DEFAULT => -107
	},
	{#State 479
		DEFAULT => -114
	},
	{#State 480
		DEFAULT => -108
	},
	{#State 481
		DEFAULT => -109
	},
	{#State 482
		DEFAULT => -340
	},
	{#State 483
		DEFAULT => -341
	},
	{#State 484
		DEFAULT => -273
	},
	{#State 485
		DEFAULT => -274
	},
	{#State 486
		DEFAULT => -295
	},
	{#State 487
		DEFAULT => -332
	},
	{#State 488
		ACTIONS => {
			'STRING_LITERAL' => 302
		},
		GOTOS => {
			'string_literal' => 461,
			'string_literals' => 503
		}
	},
	{#State 489
		DEFAULT => -331
	},
	{#State 490
		DEFAULT => -326
	},
	{#State 491
		DEFAULT => -325
	},
	{#State 492
		ACTIONS => {
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 463,
			'exception_names' => 504,
			'exception_name' => 466
		}
	},
	{#State 493
		ACTIONS => {
			'error' => 505,
			":" => 506
		}
	},
	{#State 494
		DEFAULT => -259
	},
	{#State 495
		DEFAULT => -252
	},
	{#State 496
		DEFAULT => -261
	},
	{#State 497
		DEFAULT => -260
	},
	{#State 498
		DEFAULT => -241
	},
	{#State 499
		DEFAULT => -240
	},
	{#State 500
		ACTIONS => {
			'IDENTIFIER' => 227
		},
		GOTOS => {
			'declarator' => 507,
			'simple_declarator' => 225,
			'array_declarator' => 226,
			'complex_declarator' => 224
		}
	},
	{#State 501
		ACTIONS => {
			'error' => 509,
			";" => 508
		}
	},
	{#State 502
		DEFAULT => -256
	},
	{#State 503
		DEFAULT => -335
	},
	{#State 504
		DEFAULT => -329
	},
	{#State 505
		DEFAULT => -258
	},
	{#State 506
		DEFAULT => -257
	},
	{#State 507
		DEFAULT => -262
	},
	{#State 508
		DEFAULT => -253
	},
	{#State 509
		DEFAULT => -254
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
			$_[0]->Error("definition declaration excepted.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 86 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 87 "parser24.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
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
		 'definition', 2,
sub
#line 99 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 105 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 111 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 117 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'definition', 2,
sub
#line 123 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 17
		 'definition', 2,
sub
#line 129 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 18
		 'module', 4,
sub
#line 139 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->configure('list_decl' => $_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 19
		 'module', 4,
sub
#line 145 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'module', 2,
sub
#line 151 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'module_header', 2,
sub
#line 160 "parser24.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 22
		 'module_header', 2,
sub
#line 166 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 23
		 'interface', 1, undef
	],
	[#Rule 24
		 'interface', 1, undef
	],
	[#Rule 25
		 'interface_dcl', 3,
sub
#line 181 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[]);
		}
	],
	[#Rule 26
		 'interface_dcl', 4,
sub
#line 187 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3]);
		}
	],
	[#Rule 27
		 'interface_dcl', 4,
sub
#line 193 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'forward_dcl', 3,
sub
#line 204 "parser24.yp"
{
			new ForwardInterface($_[0],
					'modifier'				=>	$_[1],
					'idf'					=>	$_[3]
			);
		}
	],
	[#Rule 29
		 'forward_dcl', 3,
sub
#line 211 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 30
		 'interface_mod', 1, undef
	],
	[#Rule 31
		 'interface_mod', 1, undef
	],
	[#Rule 32
		 'interface_mod', 0, undef
	],
	[#Rule 33
		 'interface_header', 3,
sub
#line 226 "parser24.yp"
{
			new Interface($_[0],
					'modifier'				=>	$_[1],
					'idf'					=>	$_[3]
			);
		}
	],
	[#Rule 34
		 'interface_header', 4,
sub
#line 233 "parser24.yp"
{
			new Interface($_[0],
					'modifier'				=>	$_[1],
					'idf'					=>	$_[3],
					'list_inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 35
		 'interface_body', 1, undef
	],
	[#Rule 36
		 'exports', 1,
sub
#line 248 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 37
		 'exports', 2,
sub
#line 249 "parser24.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
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
		 'export', 2,
sub
#line 260 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 44
		 'export', 2,
sub
#line 266 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 45
		 'export', 2,
sub
#line 272 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 46
		 'export', 2,
sub
#line 278 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 47
		 'export', 2,
sub
#line 284 "parser24.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 48
		 'interface_inheritance_spec', 2,
sub
#line 293 "parser24.yp"
{ $_[2]; }
	],
	[#Rule 49
		 'interface_inheritance_spec', 2,
sub
#line 295 "parser24.yp"
{
			$_[0]->Error("Interface name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 50
		 'interface_names', 1,
sub
#line 302 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 51
		 'interface_names', 3,
sub
#line 303 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 52
		 'interface_name', 1,
sub
#line 309 "parser24.yp"
{
				Interface->Lookup($_[0],$_[1])
		}
	],
	[#Rule 53
		 'scoped_name', 1, undef
	],
	[#Rule 54
		 'scoped_name', 2,
sub
#line 318 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 55
		 'scoped_name', 2,
sub
#line 322 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 56
		 'scoped_name', 3,
sub
#line 328 "parser24.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 57
		 'scoped_name', 3,
sub
#line 332 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 58
		 'value', 1, undef
	],
	[#Rule 59
		 'value', 1, undef
	],
	[#Rule 60
		 'value', 1, undef
	],
	[#Rule 61
		 'value', 1, undef
	],
	[#Rule 62
		 'value_forward_dcl', 2,
sub
#line 350 "parser24.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 63
		 'value_forward_dcl', 3,
sub
#line 356 "parser24.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 64
		 'value_box_dcl', 3,
sub
#line 366 "parser24.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 65
		 'value_abs_dcl', 3,
sub
#line 377 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[])
					if (defined $_[1]);
		}
	],
	[#Rule 66
		 'value_abs_dcl', 4,
sub
#line 384 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 67
		 'value_abs_dcl', 4,
sub
#line 391 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 68
		 'value_abs_header', 3,
sub
#line 401 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 69
		 'value_abs_header', 4,
sub
#line 407 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 70
		 'value_abs_header', 3,
sub
#line 414 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 71
		 'value_abs_header', 2,
sub
#line 419 "parser24.yp"
{
			$_[0]->Error("'valuetype' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 72
		 'value_dcl', 3,
sub
#line 428 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[])
					if (defined $_[1]);
		}
	],
	[#Rule 73
		 'value_dcl', 4,
sub
#line 435 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 74
		 'value_dcl', 4,
sub
#line 442 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 75
		 'value_elements', 1,
sub
#line 451 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 76
		 'value_elements', 2,
sub
#line 452 "parser24.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 77
		 'value_header', 2,
sub
#line 458 "parser24.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 78
		 'value_header', 3,
sub
#line 464 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 79
		 'value_header', 3,
sub
#line 471 "parser24.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 80
		 'value_header', 4,
sub
#line 478 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 81
		 'value_header', 2,
sub
#line 486 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 82
		 'value_header', 3,
sub
#line 491 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 83
		 'value_header', 2,
sub
#line 496 "parser24.yp"
{
			$_[0]->Error("valuetype excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 84
		 'value_inheritance_spec', 2,
sub
#line 505 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'list_value'			=>	$_[2]
			);
		}
	],
	[#Rule 85
		 'value_inheritance_spec', 3,
sub
#line 511 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3]
			);
		}
	],
	[#Rule 86
		 'value_inheritance_spec', 4,
sub
#line 518 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'list_value'		=>	$_[2],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 87
		 'value_inheritance_spec', 5,
sub
#line 525 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[5]
			);
		}
	],
	[#Rule 88
		 'value_inheritance_spec', 4,
sub
#line 533 "parser24.yp"
{
			$_[0]->Error("interface_name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 89
		 'value_inheritance_spec', 5,
sub
#line 538 "parser24.yp"
{
			$_[0]->Error("interface_name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 90
		 'value_inheritance_spec', 3,
sub
#line 543 "parser24.yp"
{
			$_[0]->Error("value_name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 91
		 'value_inheritance_spec', 2,
sub
#line 548 "parser24.yp"
{
			$_[0]->Error("'truncatable' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 92
		 'value_inheritance_spec', 2,
sub
#line 553 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[2]
			);
		}
	],
	[#Rule 93
		 'value_inheritance_spec', 2,
sub
#line 559 "parser24.yp"
{
			$_[0]->Error("interface_name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 94
		 'value_names', 1,
sub
#line 566 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 95
		 'value_names', 3,
sub
#line 567 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 96
		 'value_name', 1,
sub
#line 573 "parser24.yp"
{
			RegularValue->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 97
		 'value_element', 1, undef
	],
	[#Rule 98
		 'value_element', 1, undef
	],
	[#Rule 99
		 'value_element', 1, undef
	],
	[#Rule 100
		 'state_member', 4,
sub
#line 588 "parser24.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 101
		 'state_member', 4,
sub
#line 596 "parser24.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 102
		 'state_member', 3,
sub
#line 601 "parser24.yp"
{
			$_[0]->Error("type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 103
		 'state_mod', 1, undef
	],
	[#Rule 104
		 'state_mod', 1, undef
	],
	[#Rule 105
		 'init_dcl', 4, undef
	],
	[#Rule 106
		 'init_dcl', 5,
sub
#line 616 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 107
		 'init_dcl', 5,
sub
#line 624 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 108
		 'init_dcl', 5,
sub
#line 634 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 109
		 'init_dcl', 5,
sub
#line 641 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 110
		 'init_dcl', 2,
sub
#line 648 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 111
		 'init_header', 2,
sub
#line 658 "parser24.yp"
{
			new Factory($_[0],							# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 112
		 'init_header', 2,
sub
#line 664 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 113
		 'init_param_decls', 1,
sub
#line 672 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 114
		 'init_param_decls', 3,
sub
#line 674 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 115
		 'init_param_decl', 3,
sub
#line 680 "parser24.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 116
		 'init_param_attribute', 1, undef
	],
	[#Rule 117
		 'const_dcl', 5,
sub
#line 697 "parser24.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 118
		 'const_dcl', 5,
sub
#line 705 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'const_dcl', 4,
sub
#line 710 "parser24.yp"
{
			$_[0]->Error("'=' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 120
		 'const_dcl', 3,
sub
#line 715 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 121
		 'const_dcl', 2,
sub
#line 720 "parser24.yp"
{
			$_[0]->Error("const_type excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 122
		 'const_type', 1, undef
	],
	[#Rule 123
		 'const_type', 1, undef
	],
	[#Rule 124
		 'const_type', 1, undef
	],
	[#Rule 125
		 'const_type', 1, undef
	],
	[#Rule 126
		 'const_type', 1, undef
	],
	[#Rule 127
		 'const_type', 1, undef
	],
	[#Rule 128
		 'const_type', 1, undef
	],
	[#Rule 129
		 'const_type', 1, undef
	],
	[#Rule 130
		 'const_type', 1,
sub
#line 737 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 131
		 'const_type', 1, undef
	],
	[#Rule 132
		 'const_exp', 1, undef
	],
	[#Rule 133
		 'or_expr', 1, undef
	],
	[#Rule 134
		 'or_expr', 3,
sub
#line 752 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 135
		 'xor_expr', 1, undef
	],
	[#Rule 136
		 'xor_expr', 3,
sub
#line 761 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 137
		 'and_expr', 1, undef
	],
	[#Rule 138
		 'and_expr', 3,
sub
#line 770 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 139
		 'shift_expr', 1, undef
	],
	[#Rule 140
		 'shift_expr', 3,
sub
#line 779 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 141
		 'shift_expr', 3,
sub
#line 783 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 142
		 'add_expr', 1, undef
	],
	[#Rule 143
		 'add_expr', 3,
sub
#line 792 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 144
		 'add_expr', 3,
sub
#line 796 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 145
		 'mult_expr', 1, undef
	],
	[#Rule 146
		 'mult_expr', 3,
sub
#line 805 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'mult_expr', 3,
sub
#line 809 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 148
		 'mult_expr', 3,
sub
#line 813 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 149
		 'unary_expr', 2,
sub
#line 821 "parser24.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 150
		 'unary_expr', 1, undef
	],
	[#Rule 151
		 'unary_operator', 1, undef
	],
	[#Rule 152
		 'unary_operator', 1, undef
	],
	[#Rule 153
		 'unary_operator', 1, undef
	],
	[#Rule 154
		 'primary_expr', 1,
sub
#line 837 "parser24.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 155
		 'primary_expr', 1,
sub
#line 843 "parser24.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 156
		 'primary_expr', 3,
sub
#line 847 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 157
		 'primary_expr', 3,
sub
#line 851 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 158
		 'literal', 1,
sub
#line 860 "parser24.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 159
		 'literal', 1,
sub
#line 867 "parser24.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 873 "parser24.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 879 "parser24.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 885 "parser24.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'literal', 1,
sub
#line 891 "parser24.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 164
		 'literal', 1,
sub
#line 898 "parser24.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 165
		 'literal', 1, undef
	],
	[#Rule 166
		 'string_literal', 1, undef
	],
	[#Rule 167
		 'string_literal', 2,
sub
#line 909 "parser24.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 168
		 'wide_string_literal', 1, undef
	],
	[#Rule 169
		 'wide_string_literal', 2,
sub
#line 915 "parser24.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 170
		 'boolean_literal', 1,
sub
#line 921 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 171
		 'boolean_literal', 1,
sub
#line 927 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 172
		 'positive_int_const', 1,
sub
#line 937 "parser24.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 173
		 'type_dcl', 2,
sub
#line 948 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 174
		 'type_dcl', 1, undef
	],
	[#Rule 175
		 'type_dcl', 1, undef
	],
	[#Rule 176
		 'type_dcl', 1, undef
	],
	[#Rule 177
		 'type_dcl', 2,
sub
#line 955 "parser24.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 178
		 'type_dcl', 1, undef
	],
	[#Rule 179
		 'type_dcl', 2,
sub
#line 963 "parser24.yp"
{
			$_[0]->Error("type_declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 180
		 'type_dcl', 2,
sub
#line 968 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 181
		 'type_declarator', 2,
sub
#line 977 "parser24.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 182
		 'type_declarator', 2,
sub
#line 984 "parser24.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 183
		 'type_spec', 1, undef
	],
	[#Rule 184
		 'type_spec', 1, undef
	],
	[#Rule 185
		 'simple_type_spec', 1, undef
	],
	[#Rule 186
		 'simple_type_spec', 1, undef
	],
	[#Rule 187
		 'simple_type_spec', 1,
sub
#line 1001 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 188
		 'base_type_spec', 1, undef
	],
	[#Rule 189
		 'base_type_spec', 1, undef
	],
	[#Rule 190
		 'base_type_spec', 1, undef
	],
	[#Rule 191
		 'base_type_spec', 1, undef
	],
	[#Rule 192
		 'base_type_spec', 1, undef
	],
	[#Rule 193
		 'base_type_spec', 1, undef
	],
	[#Rule 194
		 'base_type_spec', 1, undef
	],
	[#Rule 195
		 'base_type_spec', 1, undef
	],
	[#Rule 196
		 'base_type_spec', 1, undef
	],
	[#Rule 197
		 'template_type_spec', 1, undef
	],
	[#Rule 198
		 'template_type_spec', 1, undef
	],
	[#Rule 199
		 'template_type_spec', 1, undef
	],
	[#Rule 200
		 'template_type_spec', 1, undef
	],
	[#Rule 201
		 'constr_type_spec', 1, undef
	],
	[#Rule 202
		 'constr_type_spec', 1, undef
	],
	[#Rule 203
		 'constr_type_spec', 1, undef
	],
	[#Rule 204
		 'declarators', 1,
sub
#line 1036 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 205
		 'declarators', 3,
sub
#line 1037 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 206
		 'declarator', 1,
sub
#line 1042 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 207
		 'declarator', 1, undef
	],
	[#Rule 208
		 'simple_declarator', 1, undef
	],
	[#Rule 209
		 'complex_declarator', 1, undef
	],
	[#Rule 210
		 'floating_pt_type', 1,
sub
#line 1059 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 211
		 'floating_pt_type', 1,
sub
#line 1065 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 212
		 'floating_pt_type', 2,
sub
#line 1071 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 213
		 'integer_type', 1, undef
	],
	[#Rule 214
		 'integer_type', 1, undef
	],
	[#Rule 215
		 'signed_int', 1, undef
	],
	[#Rule 216
		 'signed_int', 1, undef
	],
	[#Rule 217
		 'signed_int', 1, undef
	],
	[#Rule 218
		 'signed_short_int', 1,
sub
#line 1094 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 219
		 'signed_long_int', 1,
sub
#line 1104 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 220
		 'signed_longlong_int', 2,
sub
#line 1114 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 221
		 'unsigned_int', 1, undef
	],
	[#Rule 222
		 'unsigned_int', 1, undef
	],
	[#Rule 223
		 'unsigned_int', 1, undef
	],
	[#Rule 224
		 'unsigned_short_int', 2,
sub
#line 1131 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 225
		 'unsigned_long_int', 2,
sub
#line 1141 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 226
		 'unsigned_longlong_int', 3,
sub
#line 1151 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 227
		 'char_type', 1,
sub
#line 1161 "parser24.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 228
		 'wide_char_type', 1,
sub
#line 1171 "parser24.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 229
		 'boolean_type', 1,
sub
#line 1181 "parser24.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'octet_type', 1,
sub
#line 1191 "parser24.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 231
		 'any_type', 1,
sub
#line 1201 "parser24.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 232
		 'object_type', 1,
sub
#line 1211 "parser24.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 233
		 'struct_type', 4,
sub
#line 1221 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 234
		 'struct_type', 4,
sub
#line 1228 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 235
		 'struct_header', 2,
sub
#line 1237 "parser24.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 236
		 'member_list', 1,
sub
#line 1246 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 237
		 'member_list', 2,
sub
#line 1247 "parser24.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 238
		 'member', 3,
sub
#line 1253 "parser24.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 239
		 'member', 3,
sub
#line 1260 "parser24.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 240
		 'union_type', 8,
sub
#line 1273 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			);
		}
	],
	[#Rule 241
		 'union_type', 8,
sub
#line 1281 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'union_type', 6,
sub
#line 1287 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'union_type', 5,
sub
#line 1293 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 244
		 'union_type', 3,
sub
#line 1299 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 245
		 'union_header', 2,
sub
#line 1308 "parser24.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 246
		 'switch_type_spec', 1, undef
	],
	[#Rule 247
		 'switch_type_spec', 1, undef
	],
	[#Rule 248
		 'switch_type_spec', 1, undef
	],
	[#Rule 249
		 'switch_type_spec', 1, undef
	],
	[#Rule 250
		 'switch_type_spec', 1,
sub
#line 1322 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 251
		 'switch_body', 1,
sub
#line 1329 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 252
		 'switch_body', 2,
sub
#line 1330 "parser24.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 253
		 'case', 3,
sub
#line 1336 "parser24.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 254
		 'case', 3,
sub
#line 1343 "parser24.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 255
		 'case_labels', 1,
sub
#line 1354 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 256
		 'case_labels', 2,
sub
#line 1355 "parser24.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 257
		 'case_label', 3,
sub
#line 1361 "parser24.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 258
		 'case_label', 3,
sub
#line 1365 "parser24.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 259
		 'case_label', 2,
sub
#line 1371 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 260
		 'case_label', 2,
sub
#line 1376 "parser24.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 261
		 'case_label', 2,
sub
#line 1380 "parser24.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 262
		 'element_spec', 2,
sub
#line 1390 "parser24.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 263
		 'enum_type', 4,
sub
#line 1401 "parser24.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 264
		 'enum_type', 4,
sub
#line 1408 "parser24.yp"
{
			$_[0]->Error("enumerator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 265
		 'enum_type', 2,
sub
#line 1413 "parser24.yp"
{
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'enum_header', 2,
sub
#line 1421 "parser24.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 267
		 'enum_header', 2,
sub
#line 1427 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'enumerators', 1,
sub
#line 1434 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 269
		 'enumerators', 3,
sub
#line 1435 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 270
		 'enumerators', 2,
sub
#line 1437 "parser24.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 271
		 'enumerators', 2,
sub
#line 1442 "parser24.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 272
		 'enumerator', 1,
sub
#line 1451 "parser24.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 273
		 'sequence_type', 6,
sub
#line 1461 "parser24.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 274
		 'sequence_type', 6,
sub
#line 1469 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 275
		 'sequence_type', 4,
sub
#line 1474 "parser24.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 276
		 'sequence_type', 4,
sub
#line 1481 "parser24.yp"
{
			$_[0]->Error("simple_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'sequence_type', 2,
sub
#line 1486 "parser24.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'string_type', 4,
sub
#line 1495 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 279
		 'string_type', 1,
sub
#line 1502 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 280
		 'string_type', 4,
sub
#line 1508 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 281
		 'wide_string_type', 4,
sub
#line 1517 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 282
		 'wide_string_type', 1,
sub
#line 1524 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 283
		 'wide_string_type', 4,
sub
#line 1530 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 284
		 'array_declarator', 2,
sub
#line 1538 "parser24.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 285
		 'fixed_array_sizes', 1,
sub
#line 1542 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 286
		 'fixed_array_sizes', 2,
sub
#line 1544 "parser24.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 287
		 'fixed_array_size', 3,
sub
#line 1549 "parser24.yp"
{ $_[2]; }
	],
	[#Rule 288
		 'fixed_array_size', 3,
sub
#line 1551 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 289
		 'attr_dcl', 4,
sub
#line 1560 "parser24.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 290
		 'attr_dcl', 4,
sub
#line 1568 "parser24.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 291
		 'attr_dcl', 3,
sub
#line 1573 "parser24.yp"
{
			$_[0]->Error("type excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 292
		 'attr_mod', 1, undef
	],
	[#Rule 293
		 'attr_mod', 0, undef
	],
	[#Rule 294
		 'simple_declarators', 1,
sub
#line 1585 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 295
		 'simple_declarators', 3,
sub
#line 1587 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 296
		 'except_dcl', 3,
sub
#line 1593 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 297
		 'except_dcl', 4,
sub
#line 1598 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 298
		 'except_dcl', 4,
sub
#line 1606 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members excepted.\n");
			$_[0]->YYErrok();
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 299
		 'except_dcl', 2,
sub
#line 1616 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 300
		 'exception_header', 2,
sub
#line 1625 "parser24.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 301
		 'exception_header', 2,
sub
#line 1631 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 302
		 'op_dcl', 2,
sub
#line 1640 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 303
		 'op_dcl', 3,
sub
#line 1649 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 304
		 'op_dcl', 4,
sub
#line 1659 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3],
					'list_context'	=>	$_[4]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 305
		 'op_dcl', 3,
sub
#line 1670 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 306
		 'op_dcl', 2,
sub
#line 1680 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 307
		 'op_header', 3,
sub
#line 1690 "parser24.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 308
		 'op_header', 3,
sub
#line 1698 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 309
		 'op_mod', 1, undef
	],
	[#Rule 310
		 'op_mod', 0, undef
	],
	[#Rule 311
		 'op_attribute', 1, undef
	],
	[#Rule 312
		 'op_type_spec', 1, undef
	],
	[#Rule 313
		 'op_type_spec', 1,
sub
#line 1718 "parser24.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 314
		 'parameter_dcls', 3,
sub
#line 1728 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 315
		 'parameter_dcls', 2,
sub
#line 1732 "parser24.yp"
{
			undef;
		}
	],
	[#Rule 316
		 'parameter_dcls', 3,
sub
#line 1736 "parser24.yp"
{
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 317
		 'param_dcls', 1,
sub
#line 1743 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 318
		 'param_dcls', 3,
sub
#line 1744 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 319
		 'param_dcls', 2,
sub
#line 1746 "parser24.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 320
		 'param_dcls', 2,
sub
#line 1751 "parser24.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 321
		 'param_dcl', 3,
sub
#line 1760 "parser24.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
        }
	],
	[#Rule 322
		 'param_attribute', 1, undef
	],
	[#Rule 323
		 'param_attribute', 1, undef
	],
	[#Rule 324
		 'param_attribute', 1, undef
	],
	[#Rule 325
		 'raises_expr', 4,
sub
#line 1779 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 326
		 'raises_expr', 4,
sub
#line 1783 "parser24.yp"
{
			$_[0]->Error("name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 327
		 'raises_expr', 2,
sub
#line 1788 "parser24.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 328
		 'exception_names', 1,
sub
#line 1795 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 329
		 'exception_names', 3,
sub
#line 1796 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 330
		 'exception_name', 1,
sub
#line 1801 "parser24.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 331
		 'context_expr', 4,
sub
#line 1809 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 332
		 'context_expr', 4,
sub
#line 1813 "parser24.yp"
{
			$_[0]->Error("string excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 333
		 'context_expr', 2,
sub
#line 1818 "parser24.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 334
		 'string_literals', 1,
sub
#line 1825 "parser24.yp"
{ [$_[1]]; }
	],
	[#Rule 335
		 'string_literals', 3,
sub
#line 1826 "parser24.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 336
		 'param_type_spec', 1, undef
	],
	[#Rule 337
		 'param_type_spec', 1, undef
	],
	[#Rule 338
		 'param_type_spec', 1, undef
	],
	[#Rule 339
		 'param_type_spec', 1,
sub
#line 1835 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 340
		 'fixed_pt_type', 6,
sub
#line 1843 "parser24.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 341
		 'fixed_pt_type', 6,
sub
#line 1851 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 342
		 'fixed_pt_type', 4,
sub
#line 1856 "parser24.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 343
		 'fixed_pt_type', 2,
sub
#line 1861 "parser24.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 344
		 'fixed_pt_const_type', 1,
sub
#line 1870 "parser24.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 345
		 'value_base_type', 1,
sub
#line 1880 "parser24.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 346
		 'constr_forward_decl', 2,
sub
#line 1890 "parser24.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 347
		 'constr_forward_decl', 2,
sub
#line 1896 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 348
		 'constr_forward_decl', 2,
sub
#line 1901 "parser24.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 349
		 'constr_forward_decl', 2,
sub
#line 1907 "parser24.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1913 "parser24.yp"


use strict;
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
