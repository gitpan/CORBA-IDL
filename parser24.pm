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
		DEFAULT => -62
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
		DEFAULT => -61
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
		DEFAULT => -59
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
		DEFAULT => -175
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
		DEFAULT => -177
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
		DEFAULT => -60
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
		DEFAULT => -173
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
		DEFAULT => -174
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
		DEFAULT => -72
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
			'CHAR' => -309,
			'OBJECT' => -309,
			'ONEWAY' => 156,
			'VALUEBASE' => -309,
			'NATIVE' => 30,
			'VOID' => -309,
			'STRUCT' => 32,
			'DOUBLE' => -309,
			'LONG' => -309,
			'STRING' => -309,
			"::" => -309,
			'WSTRING' => -309,
			'UNSIGNED' => -309,
			'SHORT' => -309,
			'TYPEDEF' => 35,
			'BOOLEAN' => -309,
			'IDENTIFIER' => -309,
			'UNION' => 37,
			'READONLY' => 167,
			'WCHAR' => -309,
			'ATTRIBUTE' => -292,
			'error' => 161,
			'CONST' => 21,
			"}" => 162,
			'EXCEPTION' => 23,
			'OCTET' => -309,
			'FLOAT' => -309,
			'ENUM' => 26,
			'ANY' => -309
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
		DEFAULT => -82
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
			"{" => -78,
			'SUPPORTS' => 174,
			'FLOAT' => 78,
			'OCTET' => 76,
			'ENUM' => 26,
			'ANY' => 128
		},
		DEFAULT => -63,
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
			'fixed_pt_type' => 142,
			'supported_interface_spec' => 175
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
			'error' => 177,
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
			'type_spec' => 176,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'member_list' => 178,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'member' => 179,
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
		DEFAULT => -264
	},
	{#State 60
		ACTIONS => {
			'error' => 180,
			'IDENTIFIER' => 182
		},
		GOTOS => {
			'enumerators' => 183,
			'enumerator' => 181
		}
	},
	{#State 61
		DEFAULT => -213
	},
	{#State 62
		DEFAULT => -125
	},
	{#State 63
		DEFAULT => -343
	},
	{#State 64
		DEFAULT => -212
	},
	{#State 65
		DEFAULT => -122
	},
	{#State 66
		DEFAULT => -130
	},
	{#State 67
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -129
	},
	{#State 68
		DEFAULT => -123
	},
	{#State 69
		DEFAULT => -215
	},
	{#State 70
		ACTIONS => {
			'SHORT' => 185,
			'LONG' => 186
		}
	},
	{#State 71
		DEFAULT => -126
	},
	{#State 72
		DEFAULT => -217
	},
	{#State 73
		DEFAULT => -227
	},
	{#State 74
		DEFAULT => -222
	},
	{#State 75
		DEFAULT => -120
	},
	{#State 76
		DEFAULT => -229
	},
	{#State 77
		DEFAULT => -220
	},
	{#State 78
		DEFAULT => -209
	},
	{#State 79
		DEFAULT => -216
	},
	{#State 80
		DEFAULT => -226
	},
	{#State 81
		DEFAULT => -127
	},
	{#State 82
		DEFAULT => -124
	},
	{#State 83
		DEFAULT => -121
	},
	{#State 84
		DEFAULT => -210
	},
	{#State 85
		ACTIONS => {
			'DOUBLE' => 187,
			'LONG' => 188
		},
		DEFAULT => -218
	},
	{#State 86
		ACTIONS => {
			"<" => 189
		},
		DEFAULT => -278
	},
	{#State 87
		DEFAULT => -128
	},
	{#State 88
		ACTIONS => {
			'error' => 190,
			'IDENTIFIER' => 191
		}
	},
	{#State 89
		DEFAULT => -214
	},
	{#State 90
		ACTIONS => {
			"<" => 192
		},
		DEFAULT => -281
	},
	{#State 91
		ACTIONS => {
			'error' => 193,
			'IDENTIFIER' => 194
		}
	},
	{#State 92
		DEFAULT => -228
	},
	{#State 93
		DEFAULT => -54
	},
	{#State 94
		DEFAULT => -221
	},
	{#State 95
		DEFAULT => -300
	},
	{#State 96
		DEFAULT => -299
	},
	{#State 97
		ACTIONS => {
			'error' => 196,
			"(" => 195
		}
	},
	{#State 98
		DEFAULT => -266
	},
	{#State 99
		DEFAULT => -265
	},
	{#State 100
		ACTIONS => {
			'error' => 197,
			'IDENTIFIER' => 198
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
			'CHAR' => -309,
			'OBJECT' => -309,
			'ONEWAY' => 156,
			'VALUEBASE' => -309,
			'NATIVE' => 30,
			'VOID' => -309,
			'STRUCT' => 32,
			'DOUBLE' => -309,
			'LONG' => -309,
			'STRING' => -309,
			"::" => -309,
			'WSTRING' => -309,
			'UNSIGNED' => -309,
			'SHORT' => -309,
			'TYPEDEF' => 35,
			'BOOLEAN' => -309,
			'IDENTIFIER' => -309,
			'UNION' => 37,
			'READONLY' => 167,
			'WCHAR' => -309,
			'ATTRIBUTE' => -292,
			'error' => 199,
			'CONST' => 21,
			"}" => 200,
			'EXCEPTION' => 23,
			'OCTET' => -309,
			'FLOAT' => -309,
			'ENUM' => 26,
			'ANY' => -309
		},
		GOTOS => {
			'const_dcl' => 163,
			'op_mod' => 157,
			'except_dcl' => 158,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'exports' => 201,
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
			'interface_body' => 202
		}
	},
	{#State 104
		DEFAULT => -179
	},
	{#State 105
		DEFAULT => -176
	},
	{#State 106
		DEFAULT => -207
	},
	{#State 107
		ACTIONS => {
			'PRIVATE' => 204,
			'ONEWAY' => 156,
			'FACTORY' => 208,
			'UNSIGNED' => -309,
			'SHORT' => -309,
			'WCHAR' => -309,
			'error' => 210,
			'CONST' => 21,
			"}" => 211,
			'EXCEPTION' => 23,
			'OCTET' => -309,
			'FLOAT' => -309,
			'ENUM' => 26,
			'ANY' => -309,
			'CHAR' => -309,
			'OBJECT' => -309,
			'NATIVE' => 30,
			'VALUEBASE' => -309,
			'VOID' => -309,
			'STRUCT' => 32,
			'DOUBLE' => -309,
			'LONG' => -309,
			'STRING' => -309,
			"::" => -309,
			'WSTRING' => -309,
			'BOOLEAN' => -309,
			'TYPEDEF' => 35,
			'IDENTIFIER' => -309,
			'UNION' => 37,
			'READONLY' => 167,
			'ATTRIBUTE' => -292,
			'PUBLIC' => 214
		},
		GOTOS => {
			'init_header_param' => 203,
			'const_dcl' => 163,
			'op_mod' => 157,
			'value_elements' => 212,
			'except_dcl' => 158,
			'state_member' => 205,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'state_mod' => 206,
			'value_element' => 207,
			'export' => 213,
			'init_header' => 209,
			'struct_type' => 33,
			'op_header' => 166,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 168,
			'init_dcl' => 215,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 169,
			'type_dcl' => 170,
			'union_header' => 24
		}
	},
	{#State 108
		DEFAULT => -346
	},
	{#State 109
		ACTIONS => {
			"{" => -234
		},
		DEFAULT => -345
	},
	{#State 110
		DEFAULT => -298
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
			'error' => 216,
			"}" => 218,
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
			'type_spec' => 176,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'member_list' => 217,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'member' => 179,
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
		DEFAULT => -187
	},
	{#State 113
		ACTIONS => {
			"<" => 220,
			'error' => 219
		}
	},
	{#State 114
		ACTIONS => {
			"<" => 222,
			'error' => 221
		}
	},
	{#State 115
		DEFAULT => -195
	},
	{#State 116
		DEFAULT => -189
	},
	{#State 117
		DEFAULT => -194
	},
	{#State 118
		DEFAULT => -192
	},
	{#State 119
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -186
	},
	{#State 120
		DEFAULT => -190
	},
	{#State 121
		ACTIONS => {
			'error' => 225,
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarators' => 223,
			'declarator' => 224,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 122
		DEFAULT => -172
	},
	{#State 123
		DEFAULT => -197
	},
	{#State 124
		DEFAULT => -193
	},
	{#State 125
		DEFAULT => -184
	},
	{#State 126
		DEFAULT => -202
	},
	{#State 127
		DEFAULT => -178
	},
	{#State 128
		DEFAULT => -230
	},
	{#State 129
		DEFAULT => -231
	},
	{#State 130
		DEFAULT => -344
	},
	{#State 131
		DEFAULT => -198
	},
	{#State 132
		DEFAULT => -191
	},
	{#State 133
		DEFAULT => -188
	},
	{#State 134
		ACTIONS => {
			'IDENTIFIER' => 230
		}
	},
	{#State 135
		DEFAULT => -200
	},
	{#State 136
		DEFAULT => -201
	},
	{#State 137
		ACTIONS => {
			'IDENTIFIER' => 231
		}
	},
	{#State 138
		DEFAULT => -196
	},
	{#State 139
		DEFAULT => -185
	},
	{#State 140
		DEFAULT => -183
	},
	{#State 141
		DEFAULT => -182
	},
	{#State 142
		DEFAULT => -199
	},
	{#State 143
		DEFAULT => -348
	},
	{#State 144
		ACTIONS => {
			'SWITCH' => -244
		},
		DEFAULT => -347
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
			'error' => 232,
			'IDENTIFIER' => 233
		}
	},
	{#State 150
		DEFAULT => -84
	},
	{#State 151
		DEFAULT => -5
	},
	{#State 152
		DEFAULT => -71
	},
	{#State 153
		ACTIONS => {
			"{" => -69,
			'SUPPORTS' => 174,
			":" => 173
		},
		DEFAULT => -64,
		GOTOS => {
			'supported_interface_spec' => 175,
			'value_inheritance_spec' => 234
		}
	},
	{#State 154
		ACTIONS => {
			"}" => 235
		}
	},
	{#State 155
		ACTIONS => {
			"}" => 236
		}
	},
	{#State 156
		DEFAULT => -310
	},
	{#State 157
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'OBJECT' => 129,
			'IDENTIFIER' => 93,
			'VALUEBASE' => 130,
			'VOID' => 242,
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
			'wide_string_type' => 241,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 237,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 238,
			'op_type_spec' => 243,
			'base_type_spec' => 239,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'unsigned_long_int' => 94,
			'param_type_spec' => 240,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 158
		ACTIONS => {
			'error' => 245,
			";" => 244
		}
	},
	{#State 159
		DEFAULT => -308
	},
	{#State 160
		ACTIONS => {
			'ATTRIBUTE' => 246
		}
	},
	{#State 161
		ACTIONS => {
			"}" => 247
		}
	},
	{#State 162
		DEFAULT => -66
	},
	{#State 163
		ACTIONS => {
			'error' => 249,
			";" => 248
		}
	},
	{#State 164
		ACTIONS => {
			"}" => 250
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
			'ATTRIBUTE' => -292,
			'CONST' => 21,
			"}" => -37,
			'EXCEPTION' => 23,
			'ENUM' => 26
		},
		DEFAULT => -309,
		GOTOS => {
			'const_dcl' => 163,
			'op_mod' => 157,
			'except_dcl' => 158,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'exports' => 251,
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
			'error' => 253,
			"(" => 252
		},
		GOTOS => {
			'parameter_dcls' => 254
		}
	},
	{#State 167
		DEFAULT => -291
	},
	{#State 168
		ACTIONS => {
			'error' => 256,
			";" => 255
		}
	},
	{#State 169
		ACTIONS => {
			'error' => 258,
			";" => 257
		}
	},
	{#State 170
		ACTIONS => {
			'error' => 260,
			";" => 259
		}
	},
	{#State 171
		DEFAULT => -65
	},
	{#State 172
		DEFAULT => -80
	},
	{#State 173
		ACTIONS => {
			'TRUNCATABLE' => 262
		},
		DEFAULT => -90,
		GOTOS => {
			'inheritance_mod' => 261
		}
	},
	{#State 174
		ACTIONS => {
			'error' => 264,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 263,
			'interface_names' => 266,
			'interface_name' => 265
		}
	},
	{#State 175
		DEFAULT => -88
	},
	{#State 176
		ACTIONS => {
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarators' => 267,
			'declarator' => 224,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 177
		ACTIONS => {
			"}" => 268
		}
	},
	{#State 178
		ACTIONS => {
			"}" => 269
		}
	},
	{#State 179
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
		DEFAULT => -235,
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
			'type_spec' => 176,
			'string_type' => 123,
			'struct_header' => 11,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'base_type_spec' => 125,
			'enum_type' => 126,
			'enum_header' => 18,
			'member_list' => 270,
			'union_header' => 24,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79,
			'wide_string_type' => 131,
			'boolean_type' => 132,
			'integer_type' => 133,
			'signed_short_int' => 89,
			'member' => 179,
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
	{#State 180
		ACTIONS => {
			"}" => 271
		}
	},
	{#State 181
		ACTIONS => {
			";" => 272,
			"," => 273
		},
		DEFAULT => -267
	},
	{#State 182
		DEFAULT => -271
	},
	{#State 183
		ACTIONS => {
			"}" => 274
		}
	},
	{#State 184
		ACTIONS => {
			'error' => 275,
			'IDENTIFIER' => 276
		}
	},
	{#State 185
		DEFAULT => -223
	},
	{#State 186
		ACTIONS => {
			'LONG' => 277
		},
		DEFAULT => -224
	},
	{#State 187
		DEFAULT => -211
	},
	{#State 188
		DEFAULT => -219
	},
	{#State 189
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 287,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'primary_expr' => 297,
			'and_expr' => 298,
			'scoped_name' => 280,
			'positive_int_const' => 281,
			'wide_string_literal' => 282,
			'boolean_literal' => 284,
			'mult_expr' => 300,
			'const_exp' => 285,
			'or_expr' => 286,
			'unary_expr' => 304,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 190
		DEFAULT => -56
	},
	{#State 191
		DEFAULT => -55
	},
	{#State 192
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 309,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'primary_expr' => 297,
			'and_expr' => 298,
			'scoped_name' => 280,
			'positive_int_const' => 308,
			'wide_string_literal' => 282,
			'boolean_literal' => 284,
			'mult_expr' => 300,
			'const_exp' => 285,
			'or_expr' => 286,
			'unary_expr' => 304,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 193
		DEFAULT => -119
	},
	{#State 194
		ACTIONS => {
			'error' => 310,
			"=" => 311
		}
	},
	{#State 195
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'IDENTIFIER' => 93,
			'error' => 315,
			'LONG' => 319,
			"::" => 88,
			'ENUM' => 26,
			'UNSIGNED' => 70
		},
		GOTOS => {
			'switch_type_spec' => 316,
			'unsigned_int' => 61,
			'signed_int' => 64,
			'integer_type' => 318,
			'boolean_type' => 317,
			'unsigned_longlong_int' => 74,
			'char_type' => 312,
			'enum_type' => 314,
			'unsigned_long_int' => 94,
			'scoped_name' => 313,
			'enum_header' => 18,
			'signed_long_int' => 69,
			'unsigned_short_int' => 77,
			'signed_short_int' => 89,
			'signed_longlong_int' => 79
		}
	},
	{#State 196
		DEFAULT => -243
	},
	{#State 197
		ACTIONS => {
			"{" => -35
		},
		DEFAULT => -29
	},
	{#State 198
		ACTIONS => {
			"{" => -33,
			":" => 320
		},
		DEFAULT => -28,
		GOTOS => {
			'interface_inheritance_spec' => 321
		}
	},
	{#State 199
		ACTIONS => {
			"}" => 322
		}
	},
	{#State 200
		DEFAULT => -25
	},
	{#State 201
		DEFAULT => -36
	},
	{#State 202
		ACTIONS => {
			"}" => 323
		}
	},
	{#State 203
		ACTIONS => {
			'error' => 325,
			";" => 324
		}
	},
	{#State 204
		DEFAULT => -103
	},
	{#State 205
		DEFAULT => -97
	},
	{#State 206
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
			'error' => 327,
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
			'type_spec' => 326,
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
	{#State 207
		ACTIONS => {
			'PRIVATE' => 204,
			'ONEWAY' => 156,
			'FACTORY' => 208,
			'CONST' => 21,
			'EXCEPTION' => 23,
			"}" => -76,
			'ENUM' => 26,
			'NATIVE' => 30,
			'STRUCT' => 32,
			'TYPEDEF' => 35,
			'UNION' => 37,
			'READONLY' => 167,
			'ATTRIBUTE' => -292,
			'PUBLIC' => 214
		},
		DEFAULT => -309,
		GOTOS => {
			'init_header_param' => 203,
			'const_dcl' => 163,
			'op_mod' => 157,
			'value_elements' => 328,
			'except_dcl' => 158,
			'state_member' => 205,
			'op_attribute' => 159,
			'attr_mod' => 160,
			'state_mod' => 206,
			'value_element' => 207,
			'export' => 213,
			'init_header' => 209,
			'struct_type' => 33,
			'op_header' => 166,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 168,
			'init_dcl' => 215,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 169,
			'type_dcl' => 170,
			'union_header' => 24
		}
	},
	{#State 208
		ACTIONS => {
			'error' => 329,
			'IDENTIFIER' => 330
		}
	},
	{#State 209
		ACTIONS => {
			'error' => 332,
			"(" => 331
		}
	},
	{#State 210
		ACTIONS => {
			"}" => 333
		}
	},
	{#State 211
		DEFAULT => -73
	},
	{#State 212
		ACTIONS => {
			"}" => 334
		}
	},
	{#State 213
		DEFAULT => -96
	},
	{#State 214
		DEFAULT => -102
	},
	{#State 215
		DEFAULT => -98
	},
	{#State 216
		ACTIONS => {
			"}" => 335
		}
	},
	{#State 217
		ACTIONS => {
			"}" => 336
		}
	},
	{#State 218
		DEFAULT => -295
	},
	{#State 219
		DEFAULT => -342
	},
	{#State 220
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 338,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'primary_expr' => 297,
			'and_expr' => 298,
			'scoped_name' => 280,
			'positive_int_const' => 337,
			'wide_string_literal' => 282,
			'boolean_literal' => 284,
			'mult_expr' => 300,
			'const_exp' => 285,
			'or_expr' => 286,
			'unary_expr' => 304,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 221
		DEFAULT => -276
	},
	{#State 222
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
			'error' => 339,
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
			'simple_type_spec' => 340,
			'fixed_pt_type' => 142,
			'signed_longlong_int' => 79
		}
	},
	{#State 223
		DEFAULT => -180
	},
	{#State 224
		ACTIONS => {
			"," => 341
		},
		DEFAULT => -203
	},
	{#State 225
		DEFAULT => -181
	},
	{#State 226
		DEFAULT => -206
	},
	{#State 227
		DEFAULT => -205
	},
	{#State 228
		DEFAULT => -208
	},
	{#State 229
		ACTIONS => {
			"[" => 344
		},
		DEFAULT => -207,
		GOTOS => {
			'fixed_array_sizes' => 342,
			'fixed_array_size' => 343
		}
	},
	{#State 230
		DEFAULT => -234
	},
	{#State 231
		DEFAULT => -244
	},
	{#State 232
		DEFAULT => -83
	},
	{#State 233
		ACTIONS => {
			'SUPPORTS' => 174,
			":" => 173
		},
		DEFAULT => -79,
		GOTOS => {
			'supported_interface_spec' => 175,
			'value_inheritance_spec' => 345
		}
	},
	{#State 234
		DEFAULT => -70
	},
	{#State 235
		DEFAULT => -19
	},
	{#State 236
		DEFAULT => -18
	},
	{#State 237
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -338
	},
	{#State 238
		DEFAULT => -336
	},
	{#State 239
		DEFAULT => -335
	},
	{#State 240
		DEFAULT => -311
	},
	{#State 241
		DEFAULT => -337
	},
	{#State 242
		DEFAULT => -312
	},
	{#State 243
		ACTIONS => {
			'error' => 346,
			'IDENTIFIER' => 347
		}
	},
	{#State 244
		DEFAULT => -41
	},
	{#State 245
		DEFAULT => -46
	},
	{#State 246
		ACTIONS => {
			'CHAR' => 80,
			'SHORT' => 72,
			'BOOLEAN' => 92,
			'OBJECT' => 129,
			'IDENTIFIER' => 93,
			'VALUEBASE' => 130,
			'WCHAR' => 73,
			'DOUBLE' => 84,
			'error' => 348,
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
			'wide_string_type' => 241,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 237,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 238,
			'base_type_spec' => 239,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'unsigned_long_int' => 94,
			'param_type_spec' => 349,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 247
		DEFAULT => -68
	},
	{#State 248
		DEFAULT => -40
	},
	{#State 249
		DEFAULT => -45
	},
	{#State 250
		DEFAULT => -67
	},
	{#State 251
		DEFAULT => -38
	},
	{#State 252
		ACTIONS => {
			'error' => 351,
			")" => 355,
			'OUT' => 356,
			'INOUT' => 352,
			'IN' => 350
		},
		GOTOS => {
			'param_dcl' => 357,
			'param_dcls' => 354,
			'param_attribute' => 353
		}
	},
	{#State 253
		DEFAULT => -305
	},
	{#State 254
		ACTIONS => {
			'RAISES' => 361,
			'CONTEXT' => 358
		},
		DEFAULT => -301,
		GOTOS => {
			'context_expr' => 360,
			'raises_expr' => 359
		}
	},
	{#State 255
		DEFAULT => -43
	},
	{#State 256
		DEFAULT => -48
	},
	{#State 257
		DEFAULT => -42
	},
	{#State 258
		DEFAULT => -47
	},
	{#State 259
		DEFAULT => -39
	},
	{#State 260
		DEFAULT => -44
	},
	{#State 261
		ACTIONS => {
			'error' => 364,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 362,
			'value_name' => 363,
			'value_names' => 365
		}
	},
	{#State 262
		DEFAULT => -89
	},
	{#State 263
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -53
	},
	{#State 264
		DEFAULT => -94
	},
	{#State 265
		ACTIONS => {
			"," => 366
		},
		DEFAULT => -51
	},
	{#State 266
		DEFAULT => -93
	},
	{#State 267
		ACTIONS => {
			'error' => 368,
			";" => 367
		}
	},
	{#State 268
		DEFAULT => -233
	},
	{#State 269
		DEFAULT => -232
	},
	{#State 270
		DEFAULT => -236
	},
	{#State 271
		DEFAULT => -263
	},
	{#State 272
		DEFAULT => -270
	},
	{#State 273
		ACTIONS => {
			'IDENTIFIER' => 182
		},
		DEFAULT => -269,
		GOTOS => {
			'enumerators' => 369,
			'enumerator' => 181
		}
	},
	{#State 274
		DEFAULT => -262
	},
	{#State 275
		DEFAULT => -58
	},
	{#State 276
		DEFAULT => -57
	},
	{#State 277
		DEFAULT => -225
	},
	{#State 278
		DEFAULT => -160
	},
	{#State 279
		DEFAULT => -161
	},
	{#State 280
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -153
	},
	{#State 281
		ACTIONS => {
			">" => 370
		}
	},
	{#State 282
		DEFAULT => -159
	},
	{#State 283
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 372,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 300,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'const_exp' => 371,
			'and_expr' => 298,
			'or_expr' => 286,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 284
		DEFAULT => -164
	},
	{#State 285
		DEFAULT => -171
	},
	{#State 286
		ACTIONS => {
			"|" => 373
		},
		DEFAULT => -131
	},
	{#State 287
		ACTIONS => {
			">" => 374
		}
	},
	{#State 288
		ACTIONS => {
			"^" => 375
		},
		DEFAULT => -132
	},
	{#State 289
		ACTIONS => {
			"<<" => 376,
			">>" => 377
		},
		DEFAULT => -136
	},
	{#State 290
		DEFAULT => -170
	},
	{#State 291
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 291
		},
		DEFAULT => -167,
		GOTOS => {
			'wide_string_literal' => 378
		}
	},
	{#State 292
		DEFAULT => -154
	},
	{#State 293
		DEFAULT => -169
	},
	{#State 294
		ACTIONS => {
			"+" => 379,
			"-" => 380
		},
		DEFAULT => -138
	},
	{#State 295
		DEFAULT => -158
	},
	{#State 296
		DEFAULT => -163
	},
	{#State 297
		DEFAULT => -149
	},
	{#State 298
		ACTIONS => {
			"&" => 381
		},
		DEFAULT => -134
	},
	{#State 299
		DEFAULT => -157
	},
	{#State 300
		ACTIONS => {
			"%" => 383,
			"*" => 382,
			"/" => 384
		},
		DEFAULT => -141
	},
	{#State 301
		ACTIONS => {
			'STRING_LITERAL' => 301
		},
		DEFAULT => -165,
		GOTOS => {
			'string_literal' => 385
		}
	},
	{#State 302
		DEFAULT => -162
	},
	{#State 303
		DEFAULT => -151
	},
	{#State 304
		DEFAULT => -144
	},
	{#State 305
		DEFAULT => -150
	},
	{#State 306
		DEFAULT => -152
	},
	{#State 307
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'boolean_literal' => 284,
			'scoped_name' => 280,
			'primary_expr' => 386,
			'literal' => 292,
			'wide_string_literal' => 282
		}
	},
	{#State 308
		ACTIONS => {
			">" => 387
		}
	},
	{#State 309
		ACTIONS => {
			">" => 388
		}
	},
	{#State 310
		DEFAULT => -118
	},
	{#State 311
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 390,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 300,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'const_exp' => 389,
			'and_expr' => 298,
			'or_expr' => 286,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 312
		DEFAULT => -246
	},
	{#State 313
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -249
	},
	{#State 314
		DEFAULT => -248
	},
	{#State 315
		ACTIONS => {
			")" => 391
		}
	},
	{#State 316
		ACTIONS => {
			")" => 392
		}
	},
	{#State 317
		DEFAULT => -247
	},
	{#State 318
		DEFAULT => -245
	},
	{#State 319
		ACTIONS => {
			'LONG' => 188
		},
		DEFAULT => -218
	},
	{#State 320
		ACTIONS => {
			'error' => 393,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 263,
			'interface_names' => 394,
			'interface_name' => 265
		}
	},
	{#State 321
		DEFAULT => -34
	},
	{#State 322
		DEFAULT => -27
	},
	{#State 323
		DEFAULT => -26
	},
	{#State 324
		DEFAULT => -104
	},
	{#State 325
		DEFAULT => -105
	},
	{#State 326
		ACTIONS => {
			'error' => 396,
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarators' => 395,
			'declarator' => 224,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 327
		ACTIONS => {
			";" => 397
		}
	},
	{#State 328
		DEFAULT => -77
	},
	{#State 329
		DEFAULT => -111
	},
	{#State 330
		DEFAULT => -110
	},
	{#State 331
		ACTIONS => {
			'error' => 402,
			")" => 403,
			'IN' => 400
		},
		GOTOS => {
			'init_param_decls' => 399,
			'init_param_attribute' => 398,
			'init_param_decl' => 401
		}
	},
	{#State 332
		DEFAULT => -109
	},
	{#State 333
		DEFAULT => -75
	},
	{#State 334
		DEFAULT => -74
	},
	{#State 335
		DEFAULT => -297
	},
	{#State 336
		DEFAULT => -296
	},
	{#State 337
		ACTIONS => {
			"," => 404
		}
	},
	{#State 338
		ACTIONS => {
			">" => 405
		}
	},
	{#State 339
		ACTIONS => {
			">" => 406
		}
	},
	{#State 340
		ACTIONS => {
			">" => 408,
			"," => 407
		}
	},
	{#State 341
		ACTIONS => {
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarators' => 409,
			'declarator' => 224,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 342
		DEFAULT => -283
	},
	{#State 343
		ACTIONS => {
			"[" => 344
		},
		DEFAULT => -284,
		GOTOS => {
			'fixed_array_sizes' => 410,
			'fixed_array_size' => 343
		}
	},
	{#State 344
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 412,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'primary_expr' => 297,
			'and_expr' => 298,
			'scoped_name' => 280,
			'positive_int_const' => 411,
			'wide_string_literal' => 282,
			'boolean_literal' => 284,
			'mult_expr' => 300,
			'const_exp' => 285,
			'or_expr' => 286,
			'unary_expr' => 304,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 345
		DEFAULT => -81
	},
	{#State 346
		DEFAULT => -307
	},
	{#State 347
		DEFAULT => -306
	},
	{#State 348
		DEFAULT => -290
	},
	{#State 349
		ACTIONS => {
			'error' => 413,
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarators' => 415,
			'simple_declarator' => 414
		}
	},
	{#State 350
		DEFAULT => -321
	},
	{#State 351
		ACTIONS => {
			")" => 416
		}
	},
	{#State 352
		DEFAULT => -323
	},
	{#State 353
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
			'wide_string_type' => 241,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 237,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 238,
			'base_type_spec' => 239,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'unsigned_long_int' => 94,
			'param_type_spec' => 417,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 354
		ACTIONS => {
			")" => 418
		}
	},
	{#State 355
		DEFAULT => -314
	},
	{#State 356
		DEFAULT => -322
	},
	{#State 357
		ACTIONS => {
			";" => 419,
			"," => 420
		},
		DEFAULT => -316
	},
	{#State 358
		ACTIONS => {
			'error' => 422,
			"(" => 421
		}
	},
	{#State 359
		ACTIONS => {
			'CONTEXT' => 358
		},
		DEFAULT => -302,
		GOTOS => {
			'context_expr' => 423
		}
	},
	{#State 360
		DEFAULT => -304
	},
	{#State 361
		ACTIONS => {
			'error' => 425,
			"(" => 424
		}
	},
	{#State 362
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -95
	},
	{#State 363
		ACTIONS => {
			"," => 426
		},
		DEFAULT => -91
	},
	{#State 364
		DEFAULT => -87
	},
	{#State 365
		ACTIONS => {
			'SUPPORTS' => 174
		},
		DEFAULT => -85,
		GOTOS => {
			'supported_interface_spec' => 427
		}
	},
	{#State 366
		ACTIONS => {
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 263,
			'interface_names' => 428,
			'interface_name' => 265
		}
	},
	{#State 367
		DEFAULT => -237
	},
	{#State 368
		DEFAULT => -238
	},
	{#State 369
		DEFAULT => -268
	},
	{#State 370
		DEFAULT => -277
	},
	{#State 371
		ACTIONS => {
			")" => 429
		}
	},
	{#State 372
		ACTIONS => {
			")" => 430
		}
	},
	{#State 373
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 300,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'and_expr' => 298,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'xor_expr' => 431,
			'shift_expr' => 289,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 374
		DEFAULT => -279
	},
	{#State 375
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 300,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'and_expr' => 432,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'shift_expr' => 289,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 376
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 300,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 433
		}
	},
	{#State 377
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 300,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 434
		}
	},
	{#State 378
		DEFAULT => -168
	},
	{#State 379
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 435,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307
		}
	},
	{#State 380
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 436,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307
		}
	},
	{#State 381
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 300,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'shift_expr' => 437,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 382
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'unary_expr' => 438,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307
		}
	},
	{#State 383
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'unary_expr' => 439,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307
		}
	},
	{#State 384
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 88,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'unary_expr' => 440,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307
		}
	},
	{#State 385
		DEFAULT => -166
	},
	{#State 386
		DEFAULT => -148
	},
	{#State 387
		DEFAULT => -280
	},
	{#State 388
		DEFAULT => -282
	},
	{#State 389
		DEFAULT => -116
	},
	{#State 390
		DEFAULT => -117
	},
	{#State 391
		DEFAULT => -242
	},
	{#State 392
		ACTIONS => {
			"{" => 442,
			'error' => 441
		}
	},
	{#State 393
		DEFAULT => -50
	},
	{#State 394
		DEFAULT => -49
	},
	{#State 395
		ACTIONS => {
			";" => 443
		}
	},
	{#State 396
		ACTIONS => {
			";" => 444
		}
	},
	{#State 397
		DEFAULT => -101
	},
	{#State 398
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
			'wide_string_type' => 241,
			'integer_type' => 133,
			'boolean_type' => 132,
			'char_type' => 116,
			'value_base_type' => 115,
			'object_type' => 117,
			'octet_type' => 118,
			'scoped_name' => 237,
			'wide_char_type' => 120,
			'signed_long_int' => 69,
			'signed_short_int' => 89,
			'string_type' => 238,
			'base_type_spec' => 239,
			'unsigned_longlong_int' => 74,
			'any_type' => 124,
			'unsigned_long_int' => 94,
			'param_type_spec' => 445,
			'unsigned_short_int' => 77,
			'signed_longlong_int' => 79
		}
	},
	{#State 399
		ACTIONS => {
			")" => 446
		}
	},
	{#State 400
		DEFAULT => -115
	},
	{#State 401
		ACTIONS => {
			"," => 447
		},
		DEFAULT => -112
	},
	{#State 402
		ACTIONS => {
			")" => 448
		}
	},
	{#State 403
		DEFAULT => -106
	},
	{#State 404
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 450,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'primary_expr' => 297,
			'and_expr' => 298,
			'scoped_name' => 280,
			'positive_int_const' => 449,
			'wide_string_literal' => 282,
			'boolean_literal' => 284,
			'mult_expr' => 300,
			'const_exp' => 285,
			'or_expr' => 286,
			'unary_expr' => 304,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 405
		DEFAULT => -341
	},
	{#State 406
		DEFAULT => -275
	},
	{#State 407
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 452,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'string_literal' => 295,
			'primary_expr' => 297,
			'and_expr' => 298,
			'scoped_name' => 280,
			'positive_int_const' => 451,
			'wide_string_literal' => 282,
			'boolean_literal' => 284,
			'mult_expr' => 300,
			'const_exp' => 285,
			'or_expr' => 286,
			'unary_expr' => 304,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 408
		DEFAULT => -274
	},
	{#State 409
		DEFAULT => -204
	},
	{#State 410
		DEFAULT => -285
	},
	{#State 411
		ACTIONS => {
			"]" => 453
		}
	},
	{#State 412
		ACTIONS => {
			"]" => 454
		}
	},
	{#State 413
		DEFAULT => -289
	},
	{#State 414
		ACTIONS => {
			"," => 455
		},
		DEFAULT => -293
	},
	{#State 415
		DEFAULT => -288
	},
	{#State 416
		DEFAULT => -315
	},
	{#State 417
		ACTIONS => {
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarator' => 456
		}
	},
	{#State 418
		DEFAULT => -313
	},
	{#State 419
		DEFAULT => -319
	},
	{#State 420
		ACTIONS => {
			'OUT' => 356,
			'INOUT' => 352,
			'IN' => 350
		},
		DEFAULT => -318,
		GOTOS => {
			'param_dcl' => 357,
			'param_dcls' => 457,
			'param_attribute' => 353
		}
	},
	{#State 421
		ACTIONS => {
			'error' => 458,
			'STRING_LITERAL' => 301
		},
		GOTOS => {
			'string_literal' => 459,
			'string_literals' => 460
		}
	},
	{#State 422
		DEFAULT => -332
	},
	{#State 423
		DEFAULT => -303
	},
	{#State 424
		ACTIONS => {
			'error' => 462,
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 461,
			'exception_names' => 463,
			'exception_name' => 464
		}
	},
	{#State 425
		DEFAULT => -326
	},
	{#State 426
		ACTIONS => {
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 362,
			'value_name' => 363,
			'value_names' => 465
		}
	},
	{#State 427
		DEFAULT => -86
	},
	{#State 428
		DEFAULT => -52
	},
	{#State 429
		DEFAULT => -155
	},
	{#State 430
		DEFAULT => -156
	},
	{#State 431
		ACTIONS => {
			"^" => 375
		},
		DEFAULT => -133
	},
	{#State 432
		ACTIONS => {
			"&" => 381
		},
		DEFAULT => -135
	},
	{#State 433
		ACTIONS => {
			"+" => 379,
			"-" => 380
		},
		DEFAULT => -140
	},
	{#State 434
		ACTIONS => {
			"+" => 379,
			"-" => 380
		},
		DEFAULT => -139
	},
	{#State 435
		ACTIONS => {
			"%" => 383,
			"*" => 382,
			"/" => 384
		},
		DEFAULT => -142
	},
	{#State 436
		ACTIONS => {
			"%" => 383,
			"*" => 382,
			"/" => 384
		},
		DEFAULT => -143
	},
	{#State 437
		ACTIONS => {
			"<<" => 376,
			">>" => 377
		},
		DEFAULT => -137
	},
	{#State 438
		DEFAULT => -145
	},
	{#State 439
		DEFAULT => -147
	},
	{#State 440
		DEFAULT => -146
	},
	{#State 441
		DEFAULT => -241
	},
	{#State 442
		ACTIONS => {
			'error' => 469,
			'CASE' => 466,
			'DEFAULT' => 468
		},
		GOTOS => {
			'case_labels' => 471,
			'switch_body' => 470,
			'case' => 467,
			'case_label' => 472
		}
	},
	{#State 443
		DEFAULT => -99
	},
	{#State 444
		DEFAULT => -100
	},
	{#State 445
		ACTIONS => {
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarator' => 473
		}
	},
	{#State 446
		DEFAULT => -107
	},
	{#State 447
		ACTIONS => {
			'IN' => 400
		},
		GOTOS => {
			'init_param_decls' => 474,
			'init_param_attribute' => 398,
			'init_param_decl' => 401
		}
	},
	{#State 448
		DEFAULT => -108
	},
	{#State 449
		ACTIONS => {
			">" => 475
		}
	},
	{#State 450
		ACTIONS => {
			">" => 476
		}
	},
	{#State 451
		ACTIONS => {
			">" => 477
		}
	},
	{#State 452
		ACTIONS => {
			">" => 478
		}
	},
	{#State 453
		DEFAULT => -286
	},
	{#State 454
		DEFAULT => -287
	},
	{#State 455
		ACTIONS => {
			'IDENTIFIER' => 106
		},
		GOTOS => {
			'simple_declarators' => 479,
			'simple_declarator' => 414
		}
	},
	{#State 456
		DEFAULT => -320
	},
	{#State 457
		DEFAULT => -317
	},
	{#State 458
		ACTIONS => {
			")" => 480
		}
	},
	{#State 459
		ACTIONS => {
			"," => 481
		},
		DEFAULT => -333
	},
	{#State 460
		ACTIONS => {
			")" => 482
		}
	},
	{#State 461
		ACTIONS => {
			"::" => 184
		},
		DEFAULT => -329
	},
	{#State 462
		ACTIONS => {
			")" => 483
		}
	},
	{#State 463
		ACTIONS => {
			")" => 484
		}
	},
	{#State 464
		ACTIONS => {
			"," => 485
		},
		DEFAULT => -327
	},
	{#State 465
		DEFAULT => -92
	},
	{#State 466
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 88,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 93,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 487,
			"-" => 305,
			'WIDE_STRING_LITERAL' => 291,
			'FALSE' => 290,
			"~" => 306,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 300,
			'string_literal' => 295,
			'boolean_literal' => 284,
			'primary_expr' => 297,
			'const_exp' => 486,
			'and_expr' => 298,
			'or_expr' => 286,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'xor_expr' => 288,
			'shift_expr' => 289,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 467
		ACTIONS => {
			'CASE' => 466,
			'DEFAULT' => 468
		},
		DEFAULT => -250,
		GOTOS => {
			'case_labels' => 471,
			'switch_body' => 488,
			'case' => 467,
			'case_label' => 472
		}
	},
	{#State 468
		ACTIONS => {
			'error' => 489,
			":" => 490
		}
	},
	{#State 469
		ACTIONS => {
			"}" => 491
		}
	},
	{#State 470
		ACTIONS => {
			"}" => 492
		}
	},
	{#State 471
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
			'type_spec' => 493,
			'string_type' => 123,
			'struct_header' => 11,
			'element_spec' => 494,
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
	{#State 472
		ACTIONS => {
			'CASE' => 466,
			'DEFAULT' => 468
		},
		DEFAULT => -254,
		GOTOS => {
			'case_labels' => 495,
			'case_label' => 472
		}
	},
	{#State 473
		DEFAULT => -114
	},
	{#State 474
		DEFAULT => -113
	},
	{#State 475
		DEFAULT => -339
	},
	{#State 476
		DEFAULT => -340
	},
	{#State 477
		DEFAULT => -272
	},
	{#State 478
		DEFAULT => -273
	},
	{#State 479
		DEFAULT => -294
	},
	{#State 480
		DEFAULT => -331
	},
	{#State 481
		ACTIONS => {
			'STRING_LITERAL' => 301
		},
		GOTOS => {
			'string_literal' => 459,
			'string_literals' => 496
		}
	},
	{#State 482
		DEFAULT => -330
	},
	{#State 483
		DEFAULT => -325
	},
	{#State 484
		DEFAULT => -324
	},
	{#State 485
		ACTIONS => {
			'IDENTIFIER' => 93,
			"::" => 88
		},
		GOTOS => {
			'scoped_name' => 461,
			'exception_names' => 497,
			'exception_name' => 464
		}
	},
	{#State 486
		ACTIONS => {
			'error' => 498,
			":" => 499
		}
	},
	{#State 487
		DEFAULT => -258
	},
	{#State 488
		DEFAULT => -251
	},
	{#State 489
		DEFAULT => -260
	},
	{#State 490
		DEFAULT => -259
	},
	{#State 491
		DEFAULT => -240
	},
	{#State 492
		DEFAULT => -239
	},
	{#State 493
		ACTIONS => {
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarator' => 500,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 494
		ACTIONS => {
			'error' => 502,
			";" => 501
		}
	},
	{#State 495
		DEFAULT => -255
	},
	{#State 496
		DEFAULT => -334
	},
	{#State 497
		DEFAULT => -328
	},
	{#State 498
		DEFAULT => -257
	},
	{#State 499
		DEFAULT => -256
	},
	{#State 500
		DEFAULT => -261
	},
	{#State 501
		DEFAULT => -252
	},
	{#State 502
		DEFAULT => -253
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
		 'definition', 2,
sub
#line 112 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 118 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 124 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 130 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'definition', 2,
sub
#line 136 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 17
		 'definition', 2,
sub
#line 142 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 18
		 'module', 4,
sub
#line 152 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 19
		 'module', 4,
sub
#line 159 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'module', 2,
sub
#line 165 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'module_header', 2,
sub
#line 174 "parser24.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 22
		 'module_header', 2,
sub
#line 180 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
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
#line 197 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 26
		 'interface_dcl', 4,
sub
#line 205 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 27
		 'interface_dcl', 4,
sub
#line 213 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'forward_dcl', 3,
sub
#line 224 "parser24.yp"
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
	[#Rule 29
		 'forward_dcl', 3,
sub
#line 240 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
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
#line 258 "parser24.yp"
{
			if (defined $_[1] and $_[1] eq 'abstract') {
				new AbstractInterface($_[0],
						'idf'					=>	$_[3]
				);
			} elsif (defined $_[1] and $_[1] eq 'local') {
				new LocalInterface($_[0],
						'idf'					=>	$_[3]
				);
			} else {
				new RegularInterface($_[0],
						'idf'					=>	$_[3]
				);
			}
		}
	],
	[#Rule 34
		 'interface_header', 4,
sub
#line 274 "parser24.yp"
{
			my $inheritance = new InheritanceSpec($_[0],
					'list_interface'		=>	$_[4]
			);
			if (defined $_[1] and $_[1] eq 'abstract') {
				new AbstractInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$inheritance
				);
			} elsif (defined $_[1] and $_[1] eq 'local') {
				new LocalInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$inheritance
				);
			} else {
				new RegularInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$inheritance
				);
			}
		}
	],
	[#Rule 35
		 'interface_header', 3,
sub
#line 296 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 36
		 'interface_body', 1, undef
	],
	[#Rule 37
		 'exports', 1,
sub
#line 310 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 38
		 'exports', 2,
sub
#line 314 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
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
		 'export', 2,
sub
#line 333 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 45
		 'export', 2,
sub
#line 339 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 46
		 'export', 2,
sub
#line 345 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 47
		 'export', 2,
sub
#line 351 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 48
		 'export', 2,
sub
#line 357 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 49
		 'interface_inheritance_spec', 2,
sub
#line 367 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 50
		 'interface_inheritance_spec', 2,
sub
#line 371 "parser24.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 51
		 'interface_names', 1,
sub
#line 379 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 52
		 'interface_names', 3,
sub
#line 383 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 53
		 'interface_name', 1,
sub
#line 392 "parser24.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 54
		 'scoped_name', 1, undef
	],
	[#Rule 55
		 'scoped_name', 2,
sub
#line 402 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 56
		 'scoped_name', 2,
sub
#line 406 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 57
		 'scoped_name', 3,
sub
#line 412 "parser24.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 58
		 'scoped_name', 3,
sub
#line 416 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
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
		 'value', 1, undef
	],
	[#Rule 63
		 'value_forward_dcl', 2,
sub
#line 438 "parser24.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 64
		 'value_forward_dcl', 3,
sub
#line 444 "parser24.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 65
		 'value_box_dcl', 3,
sub
#line 454 "parser24.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 66
		 'value_abs_dcl', 3,
sub
#line 465 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 67
		 'value_abs_dcl', 4,
sub
#line 473 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 68
		 'value_abs_dcl', 4,
sub
#line 481 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 69
		 'value_abs_header', 3,
sub
#line 491 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 70
		 'value_abs_header', 4,
sub
#line 497 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 71
		 'value_abs_header', 3,
sub
#line 504 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 72
		 'value_abs_header', 2,
sub
#line 509 "parser24.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 73
		 'value_dcl', 3,
sub
#line 518 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 74
		 'value_dcl', 4,
sub
#line 526 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 75
		 'value_dcl', 4,
sub
#line 534 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 76
		 'value_elements', 1,
sub
#line 544 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 77
		 'value_elements', 2,
sub
#line 548 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 78
		 'value_header', 2,
sub
#line 557 "parser24.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 79
		 'value_header', 3,
sub
#line 563 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 80
		 'value_header', 3,
sub
#line 570 "parser24.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 81
		 'value_header', 4,
sub
#line 577 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 82
		 'value_header', 2,
sub
#line 585 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 83
		 'value_header', 3,
sub
#line 590 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 84
		 'value_header', 2,
sub
#line 595 "parser24.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 85
		 'value_inheritance_spec', 3,
sub
#line 604 "parser24.yp"
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
#line 611 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 87
		 'value_inheritance_spec', 3,
sub
#line 619 "parser24.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 88
		 'value_inheritance_spec', 1,
sub
#line 624 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 89
		 'inheritance_mod', 1, undef
	],
	[#Rule 90
		 'inheritance_mod', 0, undef
	],
	[#Rule 91
		 'value_names', 1,
sub
#line 640 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 92
		 'value_names', 3,
sub
#line 644 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 93
		 'supported_interface_spec', 2,
sub
#line 652 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 94
		 'supported_interface_spec', 2,
sub
#line 656 "parser24.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 95
		 'value_name', 1,
sub
#line 665 "parser24.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 96
		 'value_element', 1, undef
	],
	[#Rule 97
		 'value_element', 1, undef
	],
	[#Rule 98
		 'value_element', 1, undef
	],
	[#Rule 99
		 'state_member', 4,
sub
#line 683 "parser24.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 100
		 'state_member', 4,
sub
#line 691 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 101
		 'state_member', 3,
sub
#line 696 "parser24.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 102
		 'state_mod', 1, undef
	],
	[#Rule 103
		 'state_mod', 1, undef
	],
	[#Rule 104
		 'init_dcl', 2, undef
	],
	[#Rule 105
		 'init_dcl', 2,
sub
#line 714 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 106
		 'init_header_param', 3,
sub
#line 723 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 107
		 'init_header_param', 4,
sub
#line 729 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 108
		 'init_header_param', 4,
sub
#line 737 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 109
		 'init_header_param', 2,
sub
#line 744 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 110
		 'init_header', 2,
sub
#line 754 "parser24.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 111
		 'init_header', 2,
sub
#line 760 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'init_param_decls', 1,
sub
#line 769 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 113
		 'init_param_decls', 3,
sub
#line 773 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 114
		 'init_param_decl', 3,
sub
#line 782 "parser24.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 115
		 'init_param_attribute', 1, undef
	],
	[#Rule 116
		 'const_dcl', 5,
sub
#line 800 "parser24.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 117
		 'const_dcl', 5,
sub
#line 808 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 118
		 'const_dcl', 4,
sub
#line 813 "parser24.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'const_dcl', 3,
sub
#line 818 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 120
		 'const_dcl', 2,
sub
#line 823 "parser24.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 121
		 'const_type', 1, undef
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
		 'const_type', 1,
sub
#line 848 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 130
		 'const_type', 1, undef
	],
	[#Rule 131
		 'const_exp', 1, undef
	],
	[#Rule 132
		 'or_expr', 1, undef
	],
	[#Rule 133
		 'or_expr', 3,
sub
#line 866 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 134
		 'xor_expr', 1, undef
	],
	[#Rule 135
		 'xor_expr', 3,
sub
#line 876 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 136
		 'and_expr', 1, undef
	],
	[#Rule 137
		 'and_expr', 3,
sub
#line 886 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 138
		 'shift_expr', 1, undef
	],
	[#Rule 139
		 'shift_expr', 3,
sub
#line 896 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 140
		 'shift_expr', 3,
sub
#line 900 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 141
		 'add_expr', 1, undef
	],
	[#Rule 142
		 'add_expr', 3,
sub
#line 910 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 143
		 'add_expr', 3,
sub
#line 914 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 144
		 'mult_expr', 1, undef
	],
	[#Rule 145
		 'mult_expr', 3,
sub
#line 924 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 146
		 'mult_expr', 3,
sub
#line 928 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'mult_expr', 3,
sub
#line 932 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 148
		 'unary_expr', 2,
sub
#line 940 "parser24.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 149
		 'unary_expr', 1, undef
	],
	[#Rule 150
		 'unary_operator', 1, undef
	],
	[#Rule 151
		 'unary_operator', 1, undef
	],
	[#Rule 152
		 'unary_operator', 1, undef
	],
	[#Rule 153
		 'primary_expr', 1,
sub
#line 960 "parser24.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 154
		 'primary_expr', 1,
sub
#line 966 "parser24.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 155
		 'primary_expr', 3,
sub
#line 970 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 156
		 'primary_expr', 3,
sub
#line 974 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 157
		 'literal', 1,
sub
#line 983 "parser24.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 158
		 'literal', 1,
sub
#line 990 "parser24.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 159
		 'literal', 1,
sub
#line 996 "parser24.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 1002 "parser24.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 1008 "parser24.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1014 "parser24.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 163
		 'literal', 1,
sub
#line 1021 "parser24.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 164
		 'literal', 1, undef
	],
	[#Rule 165
		 'string_literal', 1, undef
	],
	[#Rule 166
		 'string_literal', 2,
sub
#line 1035 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 167
		 'wide_string_literal', 1, undef
	],
	[#Rule 168
		 'wide_string_literal', 2,
sub
#line 1044 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 169
		 'boolean_literal', 1,
sub
#line 1052 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 170
		 'boolean_literal', 1,
sub
#line 1058 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 171
		 'positive_int_const', 1,
sub
#line 1068 "parser24.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 172
		 'type_dcl', 2,
sub
#line 1078 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 173
		 'type_dcl', 1, undef
	],
	[#Rule 174
		 'type_dcl', 1, undef
	],
	[#Rule 175
		 'type_dcl', 1, undef
	],
	[#Rule 176
		 'type_dcl', 2,
sub
#line 1088 "parser24.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 177
		 'type_dcl', 1, undef
	],
	[#Rule 178
		 'type_dcl', 2,
sub
#line 1097 "parser24.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 179
		 'type_dcl', 2,
sub
#line 1102 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 180
		 'type_declarator', 2,
sub
#line 1111 "parser24.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 181
		 'type_declarator', 2,
sub
#line 1118 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 182
		 'type_spec', 1, undef
	],
	[#Rule 183
		 'type_spec', 1, undef
	],
	[#Rule 184
		 'simple_type_spec', 1, undef
	],
	[#Rule 185
		 'simple_type_spec', 1, undef
	],
	[#Rule 186
		 'simple_type_spec', 1,
sub
#line 1139 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 187
		 'base_type_spec', 1, undef
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
		 'template_type_spec', 1, undef
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
		 'constr_type_spec', 1, undef
	],
	[#Rule 201
		 'constr_type_spec', 1, undef
	],
	[#Rule 202
		 'constr_type_spec', 1, undef
	],
	[#Rule 203
		 'declarators', 1,
sub
#line 1191 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 204
		 'declarators', 3,
sub
#line 1195 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 205
		 'declarator', 1,
sub
#line 1204 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 206
		 'declarator', 1, undef
	],
	[#Rule 207
		 'simple_declarator', 1, undef
	],
	[#Rule 208
		 'complex_declarator', 1, undef
	],
	[#Rule 209
		 'floating_pt_type', 1,
sub
#line 1226 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 210
		 'floating_pt_type', 1,
sub
#line 1232 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 211
		 'floating_pt_type', 2,
sub
#line 1238 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 212
		 'integer_type', 1, undef
	],
	[#Rule 213
		 'integer_type', 1, undef
	],
	[#Rule 214
		 'signed_int', 1, undef
	],
	[#Rule 215
		 'signed_int', 1, undef
	],
	[#Rule 216
		 'signed_int', 1, undef
	],
	[#Rule 217
		 'signed_short_int', 1,
sub
#line 1266 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 218
		 'signed_long_int', 1,
sub
#line 1276 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 219
		 'signed_longlong_int', 2,
sub
#line 1286 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 220
		 'unsigned_int', 1, undef
	],
	[#Rule 221
		 'unsigned_int', 1, undef
	],
	[#Rule 222
		 'unsigned_int', 1, undef
	],
	[#Rule 223
		 'unsigned_short_int', 2,
sub
#line 1306 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 224
		 'unsigned_long_int', 2,
sub
#line 1316 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 225
		 'unsigned_longlong_int', 3,
sub
#line 1326 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 226
		 'char_type', 1,
sub
#line 1336 "parser24.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 227
		 'wide_char_type', 1,
sub
#line 1346 "parser24.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 228
		 'boolean_type', 1,
sub
#line 1356 "parser24.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 229
		 'octet_type', 1,
sub
#line 1366 "parser24.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'any_type', 1,
sub
#line 1376 "parser24.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 231
		 'object_type', 1,
sub
#line 1386 "parser24.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 232
		 'struct_type', 4,
sub
#line 1396 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 233
		 'struct_type', 4,
sub
#line 1403 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 234
		 'struct_header', 2,
sub
#line 1412 "parser24.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 235
		 'member_list', 1,
sub
#line 1422 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 236
		 'member_list', 2,
sub
#line 1426 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 237
		 'member', 3,
sub
#line 1435 "parser24.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 238
		 'member', 3,
sub
#line 1442 "parser24.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 239
		 'union_type', 8,
sub
#line 1455 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 240
		 'union_type', 8,
sub
#line 1463 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 241
		 'union_type', 6,
sub
#line 1469 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'union_type', 5,
sub
#line 1475 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'union_type', 3,
sub
#line 1481 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 244
		 'union_header', 2,
sub
#line 1490 "parser24.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 245
		 'switch_type_spec', 1, undef
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
		 'switch_type_spec', 1,
sub
#line 1508 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 250
		 'switch_body', 1,
sub
#line 1516 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 251
		 'switch_body', 2,
sub
#line 1520 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 252
		 'case', 3,
sub
#line 1529 "parser24.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 253
		 'case', 3,
sub
#line 1536 "parser24.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 254
		 'case_labels', 1,
sub
#line 1548 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 255
		 'case_labels', 2,
sub
#line 1552 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 256
		 'case_label', 3,
sub
#line 1561 "parser24.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 257
		 'case_label', 3,
sub
#line 1565 "parser24.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 258
		 'case_label', 2,
sub
#line 1571 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 259
		 'case_label', 2,
sub
#line 1576 "parser24.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 260
		 'case_label', 2,
sub
#line 1580 "parser24.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 261
		 'element_spec', 2,
sub
#line 1590 "parser24.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 262
		 'enum_type', 4,
sub
#line 1601 "parser24.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 263
		 'enum_type', 4,
sub
#line 1607 "parser24.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 264
		 'enum_type', 2,
sub
#line 1612 "parser24.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 265
		 'enum_header', 2,
sub
#line 1620 "parser24.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 266
		 'enum_header', 2,
sub
#line 1626 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'enumerators', 1,
sub
#line 1634 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 268
		 'enumerators', 3,
sub
#line 1638 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 269
		 'enumerators', 2,
sub
#line 1643 "parser24.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 270
		 'enumerators', 2,
sub
#line 1648 "parser24.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 271
		 'enumerator', 1,
sub
#line 1657 "parser24.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 272
		 'sequence_type', 6,
sub
#line 1667 "parser24.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 273
		 'sequence_type', 6,
sub
#line 1675 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 274
		 'sequence_type', 4,
sub
#line 1680 "parser24.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 275
		 'sequence_type', 4,
sub
#line 1687 "parser24.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 276
		 'sequence_type', 2,
sub
#line 1692 "parser24.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'string_type', 4,
sub
#line 1701 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 278
		 'string_type', 1,
sub
#line 1708 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 279
		 'string_type', 4,
sub
#line 1714 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 280
		 'wide_string_type', 4,
sub
#line 1723 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 281
		 'wide_string_type', 1,
sub
#line 1730 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 282
		 'wide_string_type', 4,
sub
#line 1736 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 283
		 'array_declarator', 2,
sub
#line 1745 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 284
		 'fixed_array_sizes', 1,
sub
#line 1753 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 285
		 'fixed_array_sizes', 2,
sub
#line 1757 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 286
		 'fixed_array_size', 3,
sub
#line 1766 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 287
		 'fixed_array_size', 3,
sub
#line 1770 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 288
		 'attr_dcl', 4,
sub
#line 1779 "parser24.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 289
		 'attr_dcl', 4,
sub
#line 1787 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 290
		 'attr_dcl', 3,
sub
#line 1792 "parser24.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 291
		 'attr_mod', 1, undef
	],
	[#Rule 292
		 'attr_mod', 0, undef
	],
	[#Rule 293
		 'simple_declarators', 1,
sub
#line 1807 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 294
		 'simple_declarators', 3,
sub
#line 1811 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 295
		 'except_dcl', 3,
sub
#line 1820 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 296
		 'except_dcl', 4,
sub
#line 1825 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 297
		 'except_dcl', 4,
sub
#line 1832 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 298
		 'except_dcl', 2,
sub
#line 1838 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 299
		 'exception_header', 2,
sub
#line 1847 "parser24.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 300
		 'exception_header', 2,
sub
#line 1853 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 301
		 'op_dcl', 2,
sub
#line 1862 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 302
		 'op_dcl', 3,
sub
#line 1870 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 303
		 'op_dcl', 4,
sub
#line 1879 "parser24.yp"
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
	[#Rule 304
		 'op_dcl', 3,
sub
#line 1889 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 305
		 'op_dcl', 2,
sub
#line 1898 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 306
		 'op_header', 3,
sub
#line 1908 "parser24.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 307
		 'op_header', 3,
sub
#line 1916 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 308
		 'op_mod', 1, undef
	],
	[#Rule 309
		 'op_mod', 0, undef
	],
	[#Rule 310
		 'op_attribute', 1, undef
	],
	[#Rule 311
		 'op_type_spec', 1, undef
	],
	[#Rule 312
		 'op_type_spec', 1,
sub
#line 1940 "parser24.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 313
		 'parameter_dcls', 3,
sub
#line 1950 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 314
		 'parameter_dcls', 2,
sub
#line 1954 "parser24.yp"
{
			undef;
		}
	],
	[#Rule 315
		 'parameter_dcls', 3,
sub
#line 1958 "parser24.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 316
		 'param_dcls', 1,
sub
#line 1966 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 317
		 'param_dcls', 3,
sub
#line 1970 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 318
		 'param_dcls', 2,
sub
#line 1975 "parser24.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 319
		 'param_dcls', 2,
sub
#line 1980 "parser24.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 320
		 'param_dcl', 3,
sub
#line 1989 "parser24.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 321
		 'param_attribute', 1, undef
	],
	[#Rule 322
		 'param_attribute', 1, undef
	],
	[#Rule 323
		 'param_attribute', 1, undef
	],
	[#Rule 324
		 'raises_expr', 4,
sub
#line 2011 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 325
		 'raises_expr', 4,
sub
#line 2015 "parser24.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 326
		 'raises_expr', 2,
sub
#line 2020 "parser24.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 327
		 'exception_names', 1,
sub
#line 2028 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 328
		 'exception_names', 3,
sub
#line 2032 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 329
		 'exception_name', 1,
sub
#line 2040 "parser24.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 330
		 'context_expr', 4,
sub
#line 2048 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 331
		 'context_expr', 4,
sub
#line 2052 "parser24.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 332
		 'context_expr', 2,
sub
#line 2057 "parser24.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 333
		 'string_literals', 1,
sub
#line 2065 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 334
		 'string_literals', 3,
sub
#line 2069 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 335
		 'param_type_spec', 1, undef
	],
	[#Rule 336
		 'param_type_spec', 1, undef
	],
	[#Rule 337
		 'param_type_spec', 1, undef
	],
	[#Rule 338
		 'param_type_spec', 1,
sub
#line 2084 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 339
		 'fixed_pt_type', 6,
sub
#line 2092 "parser24.yp"
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
#line 2100 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 341
		 'fixed_pt_type', 4,
sub
#line 2105 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 342
		 'fixed_pt_type', 2,
sub
#line 2110 "parser24.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 343
		 'fixed_pt_const_type', 1,
sub
#line 2119 "parser24.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 344
		 'value_base_type', 1,
sub
#line 2129 "parser24.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 345
		 'constr_forward_decl', 2,
sub
#line 2139 "parser24.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 346
		 'constr_forward_decl', 2,
sub
#line 2145 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 347
		 'constr_forward_decl', 2,
sub
#line 2150 "parser24.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 348
		 'constr_forward_decl', 2,
sub
#line 2156 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 2162 "parser24.yp"


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
