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
			'TYPEDEF' => 33,
			'NATIVE' => 28,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 35,
			'STRUCT' => 30,
			'error' => 17,
			'CONST' => 19,
			'CUSTOM' => 38,
			'EXCEPTION' => 21,
			'VALUETYPE' => 9,
			'ENUM' => 24,
			'INTERFACE' => -31
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 26,
			'interface_header' => 27,
			'except_dcl' => 3,
			'value_header' => 29,
			'specification' => 4,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 31,
			'union_type' => 34,
			'exception_header' => 32,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 36,
			'enum_header' => 18,
			'value_abs_dcl' => 20,
			'type_dcl' => 37,
			'union_header' => 22,
			'definitions' => 23,
			'definition' => 39,
			'interface_mod' => 25
		}
	},
	{#State 1
		DEFAULT => -61
	},
	{#State 2
		ACTIONS => {
			'error' => 41,
			'VALUETYPE' => 40,
			'INTERFACE' => -30
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 43,
			";" => 42
		}
	},
	{#State 4
		ACTIONS => {
			'' => 44
		}
	},
	{#State 5
		ACTIONS => {
			"{" => 46,
			'error' => 45
		}
	},
	{#State 6
		ACTIONS => {
			'error' => 48,
			";" => 47
		}
	},
	{#State 7
		DEFAULT => -60
	},
	{#State 8
		ACTIONS => {
			"{" => 49
		}
	},
	{#State 9
		ACTIONS => {
			'error' => 50,
			'IDENTIFIER' => 51
		}
	},
	{#State 10
		DEFAULT => -58
	},
	{#State 11
		ACTIONS => {
			"{" => 52
		}
	},
	{#State 12
		ACTIONS => {
			'error' => 53,
			'IDENTIFIER' => 54
		}
	},
	{#State 13
		DEFAULT => -23
	},
	{#State 14
		ACTIONS => {
			'error' => 56,
			";" => 55
		}
	},
	{#State 15
		DEFAULT => -174
	},
	{#State 16
		DEFAULT => -24
	},
	{#State 17
		DEFAULT => -3
	},
	{#State 18
		ACTIONS => {
			"{" => 58,
			'error' => 57
		}
	},
	{#State 19
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'FIXED' => 61,
			'WCHAR' => 71,
			'DOUBLE' => 82,
			'error' => 73,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'OCTET' => 74,
			'FLOAT' => 76,
			'WSTRING' => 88,
			'UNSIGNED' => 68
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 79,
			'integer_type' => 81,
			'boolean_type' => 80,
			'char_type' => 63,
			'octet_type' => 64,
			'scoped_name' => 65,
			'fixed_pt_const_type' => 85,
			'wide_char_type' => 66,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'const_type' => 89,
			'string_type' => 69,
			'unsigned_longlong_int' => 72,
			'unsigned_long_int' => 92,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 20
		DEFAULT => -59
	},
	{#State 21
		ACTIONS => {
			'error' => 93,
			'IDENTIFIER' => 94
		}
	},
	{#State 22
		ACTIONS => {
			'SWITCH' => 95
		}
	},
	{#State 23
		DEFAULT => -1
	},
	{#State 24
		ACTIONS => {
			'error' => 96,
			'IDENTIFIER' => 97
		}
	},
	{#State 25
		ACTIONS => {
			'INTERFACE' => 98
		}
	},
	{#State 26
		ACTIONS => {
			'error' => 100,
			";" => 99
		}
	},
	{#State 27
		ACTIONS => {
			"{" => 101
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 102,
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarator' => 103
		}
	},
	{#State 29
		ACTIONS => {
			"{" => 105
		}
	},
	{#State 30
		ACTIONS => {
			'IDENTIFIER' => 106
		}
	},
	{#State 31
		DEFAULT => -172
	},
	{#State 32
		ACTIONS => {
			"{" => 108,
			'error' => 107
		}
	},
	{#State 33
		ACTIONS => {
			'CHAR' => 78,
			'OBJECT' => 126,
			'VALUEBASE' => 127,
			'FIXED' => 110,
			'SEQUENCE' => 111,
			'STRUCT' => 30,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'UNION' => 35,
			'WCHAR' => 71,
			'error' => 124,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ENUM' => 24,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 116,
			'wide_char_type' => 117,
			'type_spec' => 118,
			'signed_long_int' => 67,
			'type_declarator' => 119,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'struct_type' => 131,
			'union_type' => 132,
			'sequence_type' => 133,
			'unsigned_long_int' => 92,
			'template_type_spec' => 134,
			'constr_type_spec' => 135,
			'simple_type_spec' => 136,
			'fixed_pt_type' => 137
		}
	},
	{#State 34
		DEFAULT => -173
	},
	{#State 35
		ACTIONS => {
			'IDENTIFIER' => 138
		}
	},
	{#State 36
		ACTIONS => {
			'error' => 140,
			";" => 139
		}
	},
	{#State 37
		ACTIONS => {
			'error' => 142,
			";" => 141
		}
	},
	{#State 38
		ACTIONS => {
			'error' => 144,
			'VALUETYPE' => 143
		}
	},
	{#State 39
		ACTIONS => {
			'TYPEDEF' => 33,
			'NATIVE' => 28,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 35,
			'STRUCT' => 30,
			'CONST' => 19,
			'CUSTOM' => 38,
			'EXCEPTION' => 21,
			'VALUETYPE' => 9,
			'ENUM' => 24,
			'INTERFACE' => -31
		},
		DEFAULT => -4,
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 26,
			'interface_header' => 27,
			'except_dcl' => 3,
			'value_header' => 29,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 31,
			'union_type' => 34,
			'exception_header' => 32,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 36,
			'enum_header' => 18,
			'value_abs_dcl' => 20,
			'type_dcl' => 37,
			'union_header' => 22,
			'definitions' => 145,
			'definition' => 39,
			'interface_mod' => 25
		}
	},
	{#State 40
		ACTIONS => {
			'error' => 146,
			'IDENTIFIER' => 147
		}
	},
	{#State 41
		DEFAULT => -71
	},
	{#State 42
		DEFAULT => -8
	},
	{#State 43
		DEFAULT => -14
	},
	{#State 44
		DEFAULT => 0
	},
	{#State 45
		DEFAULT => -20
	},
	{#State 46
		ACTIONS => {
			'TYPEDEF' => 33,
			'NATIVE' => 28,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 35,
			'STRUCT' => 30,
			'error' => 148,
			'CONST' => 19,
			'CUSTOM' => 38,
			'EXCEPTION' => 21,
			'VALUETYPE' => 9,
			'ENUM' => 24,
			'INTERFACE' => -31
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 26,
			'interface_header' => 27,
			'except_dcl' => 3,
			'value_header' => 29,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 31,
			'union_type' => 34,
			'exception_header' => 32,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'enum_type' => 15,
			'forward_dcl' => 16,
			'module' => 36,
			'enum_header' => 18,
			'value_abs_dcl' => 20,
			'type_dcl' => 37,
			'union_header' => 22,
			'definitions' => 149,
			'definition' => 39,
			'interface_mod' => 25
		}
	},
	{#State 47
		DEFAULT => -9
	},
	{#State 48
		DEFAULT => -15
	},
	{#State 49
		ACTIONS => {
			'CHAR' => -307,
			'OBJECT' => -307,
			'ONEWAY' => 150,
			'VALUEBASE' => -307,
			'NATIVE' => 28,
			'VOID' => -307,
			'STRUCT' => 30,
			'DOUBLE' => -307,
			'LONG' => -307,
			'STRING' => -307,
			"::" => -307,
			'WSTRING' => -307,
			'UNSIGNED' => -307,
			'SHORT' => -307,
			'TYPEDEF' => 33,
			'BOOLEAN' => -307,
			'IDENTIFIER' => -307,
			'UNION' => 35,
			'READONLY' => 161,
			'WCHAR' => -307,
			'ATTRIBUTE' => -290,
			'error' => 155,
			'CONST' => 19,
			"}" => 156,
			'EXCEPTION' => 21,
			'OCTET' => -307,
			'FLOAT' => -307,
			'ENUM' => 24,
			'ANY' => -307
		},
		GOTOS => {
			'const_dcl' => 157,
			'op_mod' => 151,
			'except_dcl' => 152,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'exports' => 158,
			'export' => 159,
			'struct_type' => 31,
			'op_header' => 160,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 162,
			'enum_header' => 18,
			'attr_dcl' => 163,
			'type_dcl' => 164,
			'union_header' => 22
		}
	},
	{#State 50
		DEFAULT => -81
	},
	{#State 51
		ACTIONS => {
			'CHAR' => 78,
			'OBJECT' => 126,
			'VALUEBASE' => 127,
			'FIXED' => 110,
			'SEQUENCE' => 111,
			'STRUCT' => 30,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			":" => 167,
			'UNION' => 35,
			'WCHAR' => 71,
			"{" => -77,
			'SUPPORTS' => 168,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ENUM' => 24,
			'ANY' => 125
		},
		DEFAULT => -62,
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 116,
			'wide_char_type' => 117,
			'type_spec' => 165,
			'signed_long_int' => 67,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'value_inheritance_spec' => 166,
			'struct_type' => 131,
			'union_type' => 132,
			'sequence_type' => 133,
			'unsigned_long_int' => 92,
			'template_type_spec' => 134,
			'constr_type_spec' => 135,
			'simple_type_spec' => 136,
			'fixed_pt_type' => 137,
			'supported_interface_spec' => 169
		}
	},
	{#State 52
		ACTIONS => {
			'CHAR' => 78,
			'OBJECT' => 126,
			'VALUEBASE' => 127,
			'FIXED' => 110,
			'SEQUENCE' => 111,
			'STRUCT' => 30,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'UNION' => 35,
			'WCHAR' => 71,
			'error' => 171,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ENUM' => 24,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 116,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'type_spec' => 170,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'member_list' => 172,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'member' => 173,
			'struct_type' => 131,
			'union_type' => 132,
			'sequence_type' => 133,
			'unsigned_long_int' => 92,
			'template_type_spec' => 134,
			'constr_type_spec' => 135,
			'simple_type_spec' => 136,
			'fixed_pt_type' => 137
		}
	},
	{#State 53
		DEFAULT => -22
	},
	{#State 54
		DEFAULT => -21
	},
	{#State 55
		DEFAULT => -11
	},
	{#State 56
		DEFAULT => -17
	},
	{#State 57
		DEFAULT => -262
	},
	{#State 58
		ACTIONS => {
			'error' => 174,
			'IDENTIFIER' => 176
		},
		GOTOS => {
			'enumerators' => 177,
			'enumerator' => 175
		}
	},
	{#State 59
		DEFAULT => -211
	},
	{#State 60
		DEFAULT => -124
	},
	{#State 61
		DEFAULT => -341
	},
	{#State 62
		DEFAULT => -210
	},
	{#State 63
		DEFAULT => -121
	},
	{#State 64
		DEFAULT => -129
	},
	{#State 65
		ACTIONS => {
			"::" => 178
		},
		DEFAULT => -128
	},
	{#State 66
		DEFAULT => -122
	},
	{#State 67
		DEFAULT => -213
	},
	{#State 68
		ACTIONS => {
			'SHORT' => 179,
			'LONG' => 180
		}
	},
	{#State 69
		DEFAULT => -125
	},
	{#State 70
		DEFAULT => -215
	},
	{#State 71
		DEFAULT => -225
	},
	{#State 72
		DEFAULT => -220
	},
	{#State 73
		DEFAULT => -119
	},
	{#State 74
		DEFAULT => -227
	},
	{#State 75
		DEFAULT => -218
	},
	{#State 76
		DEFAULT => -207
	},
	{#State 77
		DEFAULT => -214
	},
	{#State 78
		DEFAULT => -224
	},
	{#State 79
		DEFAULT => -126
	},
	{#State 80
		DEFAULT => -123
	},
	{#State 81
		DEFAULT => -120
	},
	{#State 82
		DEFAULT => -208
	},
	{#State 83
		ACTIONS => {
			'DOUBLE' => 181,
			'LONG' => 182
		},
		DEFAULT => -216
	},
	{#State 84
		ACTIONS => {
			"<" => 183
		},
		DEFAULT => -276
	},
	{#State 85
		DEFAULT => -127
	},
	{#State 86
		ACTIONS => {
			'error' => 184,
			'IDENTIFIER' => 185
		}
	},
	{#State 87
		DEFAULT => -212
	},
	{#State 88
		ACTIONS => {
			"<" => 186
		},
		DEFAULT => -279
	},
	{#State 89
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 188
		}
	},
	{#State 90
		DEFAULT => -226
	},
	{#State 91
		DEFAULT => -53
	},
	{#State 92
		DEFAULT => -219
	},
	{#State 93
		DEFAULT => -298
	},
	{#State 94
		DEFAULT => -297
	},
	{#State 95
		ACTIONS => {
			'error' => 190,
			"(" => 189
		}
	},
	{#State 96
		DEFAULT => -264
	},
	{#State 97
		DEFAULT => -263
	},
	{#State 98
		ACTIONS => {
			'error' => 191,
			'IDENTIFIER' => 192
		}
	},
	{#State 99
		DEFAULT => -7
	},
	{#State 100
		DEFAULT => -13
	},
	{#State 101
		ACTIONS => {
			'CHAR' => -307,
			'OBJECT' => -307,
			'ONEWAY' => 150,
			'VALUEBASE' => -307,
			'NATIVE' => 28,
			'VOID' => -307,
			'STRUCT' => 30,
			'DOUBLE' => -307,
			'LONG' => -307,
			'STRING' => -307,
			"::" => -307,
			'WSTRING' => -307,
			'UNSIGNED' => -307,
			'SHORT' => -307,
			'TYPEDEF' => 33,
			'BOOLEAN' => -307,
			'IDENTIFIER' => -307,
			'UNION' => 35,
			'READONLY' => 161,
			'WCHAR' => -307,
			'ATTRIBUTE' => -290,
			'error' => 193,
			'CONST' => 19,
			"}" => 194,
			'EXCEPTION' => 21,
			'OCTET' => -307,
			'FLOAT' => -307,
			'ENUM' => 24,
			'ANY' => -307
		},
		GOTOS => {
			'const_dcl' => 157,
			'op_mod' => 151,
			'except_dcl' => 152,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'exports' => 195,
			'export' => 159,
			'struct_type' => 31,
			'op_header' => 160,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 162,
			'enum_header' => 18,
			'attr_dcl' => 163,
			'type_dcl' => 164,
			'union_header' => 22,
			'interface_body' => 196
		}
	},
	{#State 102
		DEFAULT => -177
	},
	{#State 103
		DEFAULT => -175
	},
	{#State 104
		DEFAULT => -205
	},
	{#State 105
		ACTIONS => {
			'PRIVATE' => 198,
			'ONEWAY' => 150,
			'FACTORY' => 202,
			'UNSIGNED' => -307,
			'SHORT' => -307,
			'WCHAR' => -307,
			'error' => 204,
			'CONST' => 19,
			"}" => 205,
			'EXCEPTION' => 21,
			'OCTET' => -307,
			'FLOAT' => -307,
			'ENUM' => 24,
			'ANY' => -307,
			'CHAR' => -307,
			'OBJECT' => -307,
			'NATIVE' => 28,
			'VALUEBASE' => -307,
			'VOID' => -307,
			'STRUCT' => 30,
			'DOUBLE' => -307,
			'LONG' => -307,
			'STRING' => -307,
			"::" => -307,
			'WSTRING' => -307,
			'BOOLEAN' => -307,
			'TYPEDEF' => 33,
			'IDENTIFIER' => -307,
			'UNION' => 35,
			'READONLY' => 161,
			'ATTRIBUTE' => -290,
			'PUBLIC' => 208
		},
		GOTOS => {
			'init_header_param' => 197,
			'const_dcl' => 157,
			'op_mod' => 151,
			'value_elements' => 206,
			'except_dcl' => 152,
			'state_member' => 199,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'state_mod' => 200,
			'value_element' => 201,
			'export' => 207,
			'init_header' => 203,
			'struct_type' => 31,
			'op_header' => 160,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 162,
			'init_dcl' => 209,
			'enum_header' => 18,
			'attr_dcl' => 163,
			'type_dcl' => 164,
			'union_header' => 22
		}
	},
	{#State 106
		DEFAULT => -232
	},
	{#State 107
		DEFAULT => -296
	},
	{#State 108
		ACTIONS => {
			'CHAR' => 78,
			'OBJECT' => 126,
			'VALUEBASE' => 127,
			'FIXED' => 110,
			'SEQUENCE' => 111,
			'STRUCT' => 30,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'UNION' => 35,
			'WCHAR' => 71,
			'error' => 210,
			"}" => 212,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ENUM' => 24,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 116,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'type_spec' => 170,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'member_list' => 211,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'member' => 173,
			'struct_type' => 131,
			'union_type' => 132,
			'sequence_type' => 133,
			'unsigned_long_int' => 92,
			'template_type_spec' => 134,
			'constr_type_spec' => 135,
			'simple_type_spec' => 136,
			'fixed_pt_type' => 137
		}
	},
	{#State 109
		DEFAULT => -185
	},
	{#State 110
		ACTIONS => {
			"<" => 214,
			'error' => 213
		}
	},
	{#State 111
		ACTIONS => {
			"<" => 216,
			'error' => 215
		}
	},
	{#State 112
		DEFAULT => -193
	},
	{#State 113
		DEFAULT => -187
	},
	{#State 114
		DEFAULT => -192
	},
	{#State 115
		DEFAULT => -190
	},
	{#State 116
		ACTIONS => {
			"::" => 178
		},
		DEFAULT => -184
	},
	{#State 117
		DEFAULT => -188
	},
	{#State 118
		ACTIONS => {
			'error' => 219,
			'IDENTIFIER' => 223
		},
		GOTOS => {
			'declarators' => 217,
			'declarator' => 218,
			'simple_declarator' => 221,
			'array_declarator' => 222,
			'complex_declarator' => 220
		}
	},
	{#State 119
		DEFAULT => -171
	},
	{#State 120
		DEFAULT => -195
	},
	{#State 121
		DEFAULT => -191
	},
	{#State 122
		DEFAULT => -182
	},
	{#State 123
		DEFAULT => -200
	},
	{#State 124
		DEFAULT => -176
	},
	{#State 125
		DEFAULT => -228
	},
	{#State 126
		DEFAULT => -229
	},
	{#State 127
		DEFAULT => -342
	},
	{#State 128
		DEFAULT => -196
	},
	{#State 129
		DEFAULT => -189
	},
	{#State 130
		DEFAULT => -186
	},
	{#State 131
		DEFAULT => -198
	},
	{#State 132
		DEFAULT => -199
	},
	{#State 133
		DEFAULT => -194
	},
	{#State 134
		DEFAULT => -183
	},
	{#State 135
		DEFAULT => -181
	},
	{#State 136
		DEFAULT => -180
	},
	{#State 137
		DEFAULT => -197
	},
	{#State 138
		DEFAULT => -242
	},
	{#State 139
		DEFAULT => -10
	},
	{#State 140
		DEFAULT => -16
	},
	{#State 141
		DEFAULT => -6
	},
	{#State 142
		DEFAULT => -12
	},
	{#State 143
		ACTIONS => {
			'error' => 224,
			'IDENTIFIER' => 225
		}
	},
	{#State 144
		DEFAULT => -83
	},
	{#State 145
		DEFAULT => -5
	},
	{#State 146
		DEFAULT => -70
	},
	{#State 147
		ACTIONS => {
			"{" => -68,
			'SUPPORTS' => 168,
			":" => 167
		},
		DEFAULT => -63,
		GOTOS => {
			'supported_interface_spec' => 169,
			'value_inheritance_spec' => 226
		}
	},
	{#State 148
		ACTIONS => {
			"}" => 227
		}
	},
	{#State 149
		ACTIONS => {
			"}" => 228
		}
	},
	{#State 150
		DEFAULT => -308
	},
	{#State 151
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'OBJECT' => 126,
			'IDENTIFIER' => 91,
			'VALUEBASE' => 127,
			'VOID' => 234,
			'WCHAR' => 71,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'OCTET' => 74,
			'FLOAT' => 76,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'wide_string_type' => 233,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 229,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 230,
			'op_type_spec' => 235,
			'base_type_spec' => 231,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'unsigned_long_int' => 92,
			'param_type_spec' => 232,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 152
		ACTIONS => {
			'error' => 237,
			";" => 236
		}
	},
	{#State 153
		DEFAULT => -306
	},
	{#State 154
		ACTIONS => {
			'ATTRIBUTE' => 238
		}
	},
	{#State 155
		ACTIONS => {
			"}" => 239
		}
	},
	{#State 156
		DEFAULT => -65
	},
	{#State 157
		ACTIONS => {
			'error' => 241,
			";" => 240
		}
	},
	{#State 158
		ACTIONS => {
			"}" => 242
		}
	},
	{#State 159
		ACTIONS => {
			'ONEWAY' => 150,
			'NATIVE' => 28,
			'STRUCT' => 30,
			'TYPEDEF' => 33,
			'UNION' => 35,
			'READONLY' => 161,
			'ATTRIBUTE' => -290,
			'CONST' => 19,
			"}" => -36,
			'EXCEPTION' => 21,
			'ENUM' => 24
		},
		DEFAULT => -307,
		GOTOS => {
			'const_dcl' => 157,
			'op_mod' => 151,
			'except_dcl' => 152,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'exports' => 243,
			'export' => 159,
			'struct_type' => 31,
			'op_header' => 160,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 162,
			'enum_header' => 18,
			'attr_dcl' => 163,
			'type_dcl' => 164,
			'union_header' => 22
		}
	},
	{#State 160
		ACTIONS => {
			'error' => 245,
			"(" => 244
		},
		GOTOS => {
			'parameter_dcls' => 246
		}
	},
	{#State 161
		DEFAULT => -289
	},
	{#State 162
		ACTIONS => {
			'error' => 248,
			";" => 247
		}
	},
	{#State 163
		ACTIONS => {
			'error' => 250,
			";" => 249
		}
	},
	{#State 164
		ACTIONS => {
			'error' => 252,
			";" => 251
		}
	},
	{#State 165
		DEFAULT => -64
	},
	{#State 166
		DEFAULT => -79
	},
	{#State 167
		ACTIONS => {
			'TRUNCATABLE' => 254
		},
		DEFAULT => -89,
		GOTOS => {
			'inheritance_mod' => 253
		}
	},
	{#State 168
		ACTIONS => {
			'error' => 256,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 255,
			'interface_names' => 258,
			'interface_name' => 257
		}
	},
	{#State 169
		DEFAULT => -87
	},
	{#State 170
		ACTIONS => {
			'IDENTIFIER' => 223
		},
		GOTOS => {
			'declarators' => 259,
			'declarator' => 218,
			'simple_declarator' => 221,
			'array_declarator' => 222,
			'complex_declarator' => 220
		}
	},
	{#State 171
		ACTIONS => {
			"}" => 260
		}
	},
	{#State 172
		ACTIONS => {
			"}" => 261
		}
	},
	{#State 173
		ACTIONS => {
			'CHAR' => 78,
			'OBJECT' => 126,
			'VALUEBASE' => 127,
			'FIXED' => 110,
			'SEQUENCE' => 111,
			'STRUCT' => 30,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'UNION' => 35,
			'WCHAR' => 71,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ENUM' => 24,
			'ANY' => 125
		},
		DEFAULT => -233,
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 116,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'type_spec' => 170,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'member_list' => 262,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'member' => 173,
			'struct_type' => 131,
			'union_type' => 132,
			'sequence_type' => 133,
			'unsigned_long_int' => 92,
			'template_type_spec' => 134,
			'constr_type_spec' => 135,
			'simple_type_spec' => 136,
			'fixed_pt_type' => 137
		}
	},
	{#State 174
		ACTIONS => {
			"}" => 263
		}
	},
	{#State 175
		ACTIONS => {
			";" => 264,
			"," => 265
		},
		DEFAULT => -265
	},
	{#State 176
		DEFAULT => -269
	},
	{#State 177
		ACTIONS => {
			"}" => 266
		}
	},
	{#State 178
		ACTIONS => {
			'error' => 267,
			'IDENTIFIER' => 268
		}
	},
	{#State 179
		DEFAULT => -221
	},
	{#State 180
		ACTIONS => {
			'LONG' => 269
		},
		DEFAULT => -222
	},
	{#State 181
		DEFAULT => -209
	},
	{#State 182
		DEFAULT => -217
	},
	{#State 183
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 279,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'primary_expr' => 289,
			'and_expr' => 290,
			'scoped_name' => 272,
			'positive_int_const' => 273,
			'wide_string_literal' => 274,
			'boolean_literal' => 276,
			'mult_expr' => 292,
			'const_exp' => 277,
			'or_expr' => 278,
			'unary_expr' => 296,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 184
		DEFAULT => -55
	},
	{#State 185
		DEFAULT => -54
	},
	{#State 186
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 301,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'primary_expr' => 289,
			'and_expr' => 290,
			'scoped_name' => 272,
			'positive_int_const' => 300,
			'wide_string_literal' => 274,
			'boolean_literal' => 276,
			'mult_expr' => 292,
			'const_exp' => 277,
			'or_expr' => 278,
			'unary_expr' => 296,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 187
		DEFAULT => -118
	},
	{#State 188
		ACTIONS => {
			'error' => 302,
			"=" => 303
		}
	},
	{#State 189
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'error' => 307,
			'LONG' => 311,
			"::" => 86,
			'ENUM' => 24,
			'UNSIGNED' => 68
		},
		GOTOS => {
			'switch_type_spec' => 308,
			'unsigned_int' => 59,
			'signed_int' => 62,
			'integer_type' => 310,
			'boolean_type' => 309,
			'unsigned_longlong_int' => 72,
			'char_type' => 304,
			'enum_type' => 306,
			'unsigned_long_int' => 92,
			'scoped_name' => 305,
			'enum_header' => 18,
			'signed_long_int' => 67,
			'unsigned_short_int' => 75,
			'signed_short_int' => 87,
			'signed_longlong_int' => 77
		}
	},
	{#State 190
		DEFAULT => -241
	},
	{#State 191
		ACTIONS => {
			"{" => -34
		},
		DEFAULT => -29
	},
	{#State 192
		ACTIONS => {
			"{" => -32,
			":" => 312
		},
		DEFAULT => -28,
		GOTOS => {
			'interface_inheritance_spec' => 313
		}
	},
	{#State 193
		ACTIONS => {
			"}" => 314
		}
	},
	{#State 194
		DEFAULT => -25
	},
	{#State 195
		DEFAULT => -35
	},
	{#State 196
		ACTIONS => {
			"}" => 315
		}
	},
	{#State 197
		ACTIONS => {
			'error' => 317,
			";" => 316
		}
	},
	{#State 198
		DEFAULT => -102
	},
	{#State 199
		DEFAULT => -96
	},
	{#State 200
		ACTIONS => {
			'CHAR' => 78,
			'OBJECT' => 126,
			'VALUEBASE' => 127,
			'FIXED' => 110,
			'SEQUENCE' => 111,
			'STRUCT' => 30,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'UNION' => 35,
			'WCHAR' => 71,
			'error' => 319,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ENUM' => 24,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 116,
			'wide_char_type' => 117,
			'type_spec' => 318,
			'signed_long_int' => 67,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'struct_type' => 131,
			'union_type' => 132,
			'sequence_type' => 133,
			'unsigned_long_int' => 92,
			'template_type_spec' => 134,
			'constr_type_spec' => 135,
			'simple_type_spec' => 136,
			'fixed_pt_type' => 137
		}
	},
	{#State 201
		ACTIONS => {
			'PRIVATE' => 198,
			'ONEWAY' => 150,
			'FACTORY' => 202,
			'CONST' => 19,
			'EXCEPTION' => 21,
			"}" => -75,
			'ENUM' => 24,
			'NATIVE' => 28,
			'STRUCT' => 30,
			'TYPEDEF' => 33,
			'UNION' => 35,
			'READONLY' => 161,
			'ATTRIBUTE' => -290,
			'PUBLIC' => 208
		},
		DEFAULT => -307,
		GOTOS => {
			'init_header_param' => 197,
			'const_dcl' => 157,
			'op_mod' => 151,
			'value_elements' => 320,
			'except_dcl' => 152,
			'state_member' => 199,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'state_mod' => 200,
			'value_element' => 201,
			'export' => 207,
			'init_header' => 203,
			'struct_type' => 31,
			'op_header' => 160,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 162,
			'init_dcl' => 209,
			'enum_header' => 18,
			'attr_dcl' => 163,
			'type_dcl' => 164,
			'union_header' => 22
		}
	},
	{#State 202
		ACTIONS => {
			'error' => 321,
			'IDENTIFIER' => 322
		}
	},
	{#State 203
		ACTIONS => {
			'error' => 324,
			"(" => 323
		}
	},
	{#State 204
		ACTIONS => {
			"}" => 325
		}
	},
	{#State 205
		DEFAULT => -72
	},
	{#State 206
		ACTIONS => {
			"}" => 326
		}
	},
	{#State 207
		DEFAULT => -95
	},
	{#State 208
		DEFAULT => -101
	},
	{#State 209
		DEFAULT => -97
	},
	{#State 210
		ACTIONS => {
			"}" => 327
		}
	},
	{#State 211
		ACTIONS => {
			"}" => 328
		}
	},
	{#State 212
		DEFAULT => -293
	},
	{#State 213
		DEFAULT => -340
	},
	{#State 214
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 330,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'primary_expr' => 289,
			'and_expr' => 290,
			'scoped_name' => 272,
			'positive_int_const' => 329,
			'wide_string_literal' => 274,
			'boolean_literal' => 276,
			'mult_expr' => 292,
			'const_exp' => 277,
			'or_expr' => 278,
			'unary_expr' => 296,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 215
		DEFAULT => -274
	},
	{#State 216
		ACTIONS => {
			'CHAR' => 78,
			'OBJECT' => 126,
			'VALUEBASE' => 127,
			'FIXED' => 110,
			'SEQUENCE' => 111,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'WCHAR' => 71,
			'error' => 331,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'wide_string_type' => 128,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 116,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 120,
			'sequence_type' => 133,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'unsigned_long_int' => 92,
			'template_type_spec' => 134,
			'unsigned_short_int' => 75,
			'simple_type_spec' => 332,
			'fixed_pt_type' => 137,
			'signed_longlong_int' => 77
		}
	},
	{#State 217
		DEFAULT => -178
	},
	{#State 218
		ACTIONS => {
			"," => 333
		},
		DEFAULT => -201
	},
	{#State 219
		DEFAULT => -179
	},
	{#State 220
		DEFAULT => -204
	},
	{#State 221
		DEFAULT => -203
	},
	{#State 222
		DEFAULT => -206
	},
	{#State 223
		ACTIONS => {
			"[" => 336
		},
		DEFAULT => -205,
		GOTOS => {
			'fixed_array_sizes' => 334,
			'fixed_array_size' => 335
		}
	},
	{#State 224
		DEFAULT => -82
	},
	{#State 225
		ACTIONS => {
			'SUPPORTS' => 168,
			":" => 167
		},
		DEFAULT => -78,
		GOTOS => {
			'supported_interface_spec' => 169,
			'value_inheritance_spec' => 337
		}
	},
	{#State 226
		DEFAULT => -69
	},
	{#State 227
		DEFAULT => -19
	},
	{#State 228
		DEFAULT => -18
	},
	{#State 229
		ACTIONS => {
			"::" => 178
		},
		DEFAULT => -336
	},
	{#State 230
		DEFAULT => -334
	},
	{#State 231
		DEFAULT => -333
	},
	{#State 232
		DEFAULT => -309
	},
	{#State 233
		DEFAULT => -335
	},
	{#State 234
		DEFAULT => -310
	},
	{#State 235
		ACTIONS => {
			'error' => 338,
			'IDENTIFIER' => 339
		}
	},
	{#State 236
		DEFAULT => -40
	},
	{#State 237
		DEFAULT => -45
	},
	{#State 238
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'OBJECT' => 126,
			'IDENTIFIER' => 91,
			'VALUEBASE' => 127,
			'WCHAR' => 71,
			'DOUBLE' => 82,
			'error' => 340,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'OCTET' => 74,
			'FLOAT' => 76,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'wide_string_type' => 233,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 229,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 230,
			'base_type_spec' => 231,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'unsigned_long_int' => 92,
			'param_type_spec' => 341,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 239
		DEFAULT => -67
	},
	{#State 240
		DEFAULT => -39
	},
	{#State 241
		DEFAULT => -44
	},
	{#State 242
		DEFAULT => -66
	},
	{#State 243
		DEFAULT => -37
	},
	{#State 244
		ACTIONS => {
			'error' => 343,
			")" => 347,
			'OUT' => 348,
			'INOUT' => 344,
			'IN' => 342
		},
		GOTOS => {
			'param_dcl' => 349,
			'param_dcls' => 346,
			'param_attribute' => 345
		}
	},
	{#State 245
		DEFAULT => -303
	},
	{#State 246
		ACTIONS => {
			'RAISES' => 353,
			'CONTEXT' => 350
		},
		DEFAULT => -299,
		GOTOS => {
			'context_expr' => 352,
			'raises_expr' => 351
		}
	},
	{#State 247
		DEFAULT => -42
	},
	{#State 248
		DEFAULT => -47
	},
	{#State 249
		DEFAULT => -41
	},
	{#State 250
		DEFAULT => -46
	},
	{#State 251
		DEFAULT => -38
	},
	{#State 252
		DEFAULT => -43
	},
	{#State 253
		ACTIONS => {
			'error' => 356,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 354,
			'value_name' => 355,
			'value_names' => 357
		}
	},
	{#State 254
		DEFAULT => -88
	},
	{#State 255
		ACTIONS => {
			"::" => 178
		},
		DEFAULT => -52
	},
	{#State 256
		DEFAULT => -93
	},
	{#State 257
		ACTIONS => {
			"," => 358
		},
		DEFAULT => -50
	},
	{#State 258
		DEFAULT => -92
	},
	{#State 259
		ACTIONS => {
			'error' => 360,
			";" => 359
		}
	},
	{#State 260
		DEFAULT => -231
	},
	{#State 261
		DEFAULT => -230
	},
	{#State 262
		DEFAULT => -234
	},
	{#State 263
		DEFAULT => -261
	},
	{#State 264
		DEFAULT => -268
	},
	{#State 265
		ACTIONS => {
			'IDENTIFIER' => 176
		},
		DEFAULT => -267,
		GOTOS => {
			'enumerators' => 361,
			'enumerator' => 175
		}
	},
	{#State 266
		DEFAULT => -260
	},
	{#State 267
		DEFAULT => -57
	},
	{#State 268
		DEFAULT => -56
	},
	{#State 269
		DEFAULT => -223
	},
	{#State 270
		DEFAULT => -159
	},
	{#State 271
		DEFAULT => -160
	},
	{#State 272
		ACTIONS => {
			"::" => 178
		},
		DEFAULT => -152
	},
	{#State 273
		ACTIONS => {
			">" => 362
		}
	},
	{#State 274
		DEFAULT => -158
	},
	{#State 275
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 364,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 292,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'const_exp' => 363,
			'and_expr' => 290,
			'or_expr' => 278,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 276
		DEFAULT => -163
	},
	{#State 277
		DEFAULT => -170
	},
	{#State 278
		ACTIONS => {
			"|" => 365
		},
		DEFAULT => -130
	},
	{#State 279
		ACTIONS => {
			">" => 366
		}
	},
	{#State 280
		ACTIONS => {
			"^" => 367
		},
		DEFAULT => -131
	},
	{#State 281
		ACTIONS => {
			"<<" => 368,
			">>" => 369
		},
		DEFAULT => -135
	},
	{#State 282
		DEFAULT => -169
	},
	{#State 283
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 283
		},
		DEFAULT => -166,
		GOTOS => {
			'wide_string_literal' => 370
		}
	},
	{#State 284
		DEFAULT => -153
	},
	{#State 285
		DEFAULT => -168
	},
	{#State 286
		ACTIONS => {
			"+" => 371,
			"-" => 372
		},
		DEFAULT => -137
	},
	{#State 287
		DEFAULT => -157
	},
	{#State 288
		DEFAULT => -162
	},
	{#State 289
		DEFAULT => -148
	},
	{#State 290
		ACTIONS => {
			"&" => 373
		},
		DEFAULT => -133
	},
	{#State 291
		DEFAULT => -156
	},
	{#State 292
		ACTIONS => {
			"%" => 375,
			"*" => 374,
			"/" => 376
		},
		DEFAULT => -140
	},
	{#State 293
		ACTIONS => {
			'STRING_LITERAL' => 293
		},
		DEFAULT => -164,
		GOTOS => {
			'string_literal' => 377
		}
	},
	{#State 294
		DEFAULT => -161
	},
	{#State 295
		DEFAULT => -150
	},
	{#State 296
		DEFAULT => -143
	},
	{#State 297
		DEFAULT => -149
	},
	{#State 298
		DEFAULT => -151
	},
	{#State 299
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'boolean_literal' => 276,
			'scoped_name' => 272,
			'primary_expr' => 378,
			'literal' => 284,
			'wide_string_literal' => 274
		}
	},
	{#State 300
		ACTIONS => {
			">" => 379
		}
	},
	{#State 301
		ACTIONS => {
			">" => 380
		}
	},
	{#State 302
		DEFAULT => -117
	},
	{#State 303
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 382,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 292,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'const_exp' => 381,
			'and_expr' => 290,
			'or_expr' => 278,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 304
		DEFAULT => -244
	},
	{#State 305
		ACTIONS => {
			"::" => 178
		},
		DEFAULT => -247
	},
	{#State 306
		DEFAULT => -246
	},
	{#State 307
		ACTIONS => {
			")" => 383
		}
	},
	{#State 308
		ACTIONS => {
			")" => 384
		}
	},
	{#State 309
		DEFAULT => -245
	},
	{#State 310
		DEFAULT => -243
	},
	{#State 311
		ACTIONS => {
			'LONG' => 182
		},
		DEFAULT => -216
	},
	{#State 312
		ACTIONS => {
			'error' => 385,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 255,
			'interface_names' => 386,
			'interface_name' => 257
		}
	},
	{#State 313
		DEFAULT => -33
	},
	{#State 314
		DEFAULT => -27
	},
	{#State 315
		DEFAULT => -26
	},
	{#State 316
		DEFAULT => -103
	},
	{#State 317
		DEFAULT => -104
	},
	{#State 318
		ACTIONS => {
			'error' => 388,
			'IDENTIFIER' => 223
		},
		GOTOS => {
			'declarators' => 387,
			'declarator' => 218,
			'simple_declarator' => 221,
			'array_declarator' => 222,
			'complex_declarator' => 220
		}
	},
	{#State 319
		ACTIONS => {
			";" => 389
		}
	},
	{#State 320
		DEFAULT => -76
	},
	{#State 321
		DEFAULT => -110
	},
	{#State 322
		DEFAULT => -109
	},
	{#State 323
		ACTIONS => {
			'error' => 394,
			")" => 395,
			'IN' => 392
		},
		GOTOS => {
			'init_param_decls' => 391,
			'init_param_attribute' => 390,
			'init_param_decl' => 393
		}
	},
	{#State 324
		DEFAULT => -108
	},
	{#State 325
		DEFAULT => -74
	},
	{#State 326
		DEFAULT => -73
	},
	{#State 327
		DEFAULT => -295
	},
	{#State 328
		DEFAULT => -294
	},
	{#State 329
		ACTIONS => {
			"," => 396
		}
	},
	{#State 330
		ACTIONS => {
			">" => 397
		}
	},
	{#State 331
		ACTIONS => {
			">" => 398
		}
	},
	{#State 332
		ACTIONS => {
			">" => 400,
			"," => 399
		}
	},
	{#State 333
		ACTIONS => {
			'IDENTIFIER' => 223
		},
		GOTOS => {
			'declarators' => 401,
			'declarator' => 218,
			'simple_declarator' => 221,
			'array_declarator' => 222,
			'complex_declarator' => 220
		}
	},
	{#State 334
		DEFAULT => -281
	},
	{#State 335
		ACTIONS => {
			"[" => 336
		},
		DEFAULT => -282,
		GOTOS => {
			'fixed_array_sizes' => 402,
			'fixed_array_size' => 335
		}
	},
	{#State 336
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 404,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'primary_expr' => 289,
			'and_expr' => 290,
			'scoped_name' => 272,
			'positive_int_const' => 403,
			'wide_string_literal' => 274,
			'boolean_literal' => 276,
			'mult_expr' => 292,
			'const_exp' => 277,
			'or_expr' => 278,
			'unary_expr' => 296,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 337
		DEFAULT => -80
	},
	{#State 338
		DEFAULT => -305
	},
	{#State 339
		DEFAULT => -304
	},
	{#State 340
		DEFAULT => -288
	},
	{#State 341
		ACTIONS => {
			'error' => 405,
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarators' => 407,
			'simple_declarator' => 406
		}
	},
	{#State 342
		DEFAULT => -319
	},
	{#State 343
		ACTIONS => {
			")" => 408
		}
	},
	{#State 344
		DEFAULT => -321
	},
	{#State 345
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'OBJECT' => 126,
			'IDENTIFIER' => 91,
			'VALUEBASE' => 127,
			'WCHAR' => 71,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'OCTET' => 74,
			'FLOAT' => 76,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'wide_string_type' => 233,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 229,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 230,
			'base_type_spec' => 231,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'unsigned_long_int' => 92,
			'param_type_spec' => 409,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 346
		ACTIONS => {
			")" => 410
		}
	},
	{#State 347
		DEFAULT => -312
	},
	{#State 348
		DEFAULT => -320
	},
	{#State 349
		ACTIONS => {
			";" => 411,
			"," => 412
		},
		DEFAULT => -314
	},
	{#State 350
		ACTIONS => {
			'error' => 414,
			"(" => 413
		}
	},
	{#State 351
		ACTIONS => {
			'CONTEXT' => 350
		},
		DEFAULT => -300,
		GOTOS => {
			'context_expr' => 415
		}
	},
	{#State 352
		DEFAULT => -302
	},
	{#State 353
		ACTIONS => {
			'error' => 417,
			"(" => 416
		}
	},
	{#State 354
		ACTIONS => {
			"::" => 178
		},
		DEFAULT => -94
	},
	{#State 355
		ACTIONS => {
			"," => 418
		},
		DEFAULT => -90
	},
	{#State 356
		DEFAULT => -86
	},
	{#State 357
		ACTIONS => {
			'SUPPORTS' => 168
		},
		DEFAULT => -84,
		GOTOS => {
			'supported_interface_spec' => 419
		}
	},
	{#State 358
		ACTIONS => {
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 255,
			'interface_names' => 420,
			'interface_name' => 257
		}
	},
	{#State 359
		DEFAULT => -235
	},
	{#State 360
		DEFAULT => -236
	},
	{#State 361
		DEFAULT => -266
	},
	{#State 362
		DEFAULT => -275
	},
	{#State 363
		ACTIONS => {
			")" => 421
		}
	},
	{#State 364
		ACTIONS => {
			")" => 422
		}
	},
	{#State 365
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 292,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'and_expr' => 290,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'xor_expr' => 423,
			'shift_expr' => 281,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 366
		DEFAULT => -277
	},
	{#State 367
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 292,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'and_expr' => 424,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'shift_expr' => 281,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 368
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 292,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 425
		}
	},
	{#State 369
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 292,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 426
		}
	},
	{#State 370
		DEFAULT => -167
	},
	{#State 371
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 427,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299
		}
	},
	{#State 372
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 428,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299
		}
	},
	{#State 373
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 292,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'shift_expr' => 429,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 374
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'unary_expr' => 430,
			'scoped_name' => 272,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299
		}
	},
	{#State 375
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'unary_expr' => 431,
			'scoped_name' => 272,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299
		}
	},
	{#State 376
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'CHARACTER_LITERAL' => 270,
			"+" => 295,
			'FIXED_PT_LITERAL' => 294,
			'WIDE_CHARACTER_LITERAL' => 271,
			"-" => 297,
			"::" => 86,
			'FALSE' => 282,
			'WIDE_STRING_LITERAL' => 283,
			'INTEGER_LITERAL' => 291,
			"~" => 298,
			"(" => 275,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'unary_expr' => 432,
			'scoped_name' => 272,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299
		}
	},
	{#State 377
		DEFAULT => -165
	},
	{#State 378
		DEFAULT => -147
	},
	{#State 379
		DEFAULT => -278
	},
	{#State 380
		DEFAULT => -280
	},
	{#State 381
		DEFAULT => -115
	},
	{#State 382
		DEFAULT => -116
	},
	{#State 383
		DEFAULT => -240
	},
	{#State 384
		ACTIONS => {
			"{" => 434,
			'error' => 433
		}
	},
	{#State 385
		DEFAULT => -49
	},
	{#State 386
		DEFAULT => -48
	},
	{#State 387
		ACTIONS => {
			";" => 435
		}
	},
	{#State 388
		ACTIONS => {
			";" => 436
		}
	},
	{#State 389
		DEFAULT => -100
	},
	{#State 390
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'OBJECT' => 126,
			'IDENTIFIER' => 91,
			'VALUEBASE' => 127,
			'WCHAR' => 71,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'OCTET' => 74,
			'FLOAT' => 76,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'wide_string_type' => 233,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 229,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 230,
			'base_type_spec' => 231,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'unsigned_long_int' => 92,
			'param_type_spec' => 437,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 391
		ACTIONS => {
			")" => 438
		}
	},
	{#State 392
		DEFAULT => -114
	},
	{#State 393
		ACTIONS => {
			"," => 439
		},
		DEFAULT => -111
	},
	{#State 394
		ACTIONS => {
			")" => 440
		}
	},
	{#State 395
		DEFAULT => -105
	},
	{#State 396
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 442,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'primary_expr' => 289,
			'and_expr' => 290,
			'scoped_name' => 272,
			'positive_int_const' => 441,
			'wide_string_literal' => 274,
			'boolean_literal' => 276,
			'mult_expr' => 292,
			'const_exp' => 277,
			'or_expr' => 278,
			'unary_expr' => 296,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 397
		DEFAULT => -339
	},
	{#State 398
		DEFAULT => -273
	},
	{#State 399
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 444,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'string_literal' => 287,
			'primary_expr' => 289,
			'and_expr' => 290,
			'scoped_name' => 272,
			'positive_int_const' => 443,
			'wide_string_literal' => 274,
			'boolean_literal' => 276,
			'mult_expr' => 292,
			'const_exp' => 277,
			'or_expr' => 278,
			'unary_expr' => 296,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 400
		DEFAULT => -272
	},
	{#State 401
		DEFAULT => -202
	},
	{#State 402
		DEFAULT => -283
	},
	{#State 403
		ACTIONS => {
			"]" => 445
		}
	},
	{#State 404
		ACTIONS => {
			"]" => 446
		}
	},
	{#State 405
		DEFAULT => -287
	},
	{#State 406
		ACTIONS => {
			"," => 447
		},
		DEFAULT => -291
	},
	{#State 407
		DEFAULT => -286
	},
	{#State 408
		DEFAULT => -313
	},
	{#State 409
		ACTIONS => {
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarator' => 448
		}
	},
	{#State 410
		DEFAULT => -311
	},
	{#State 411
		DEFAULT => -317
	},
	{#State 412
		ACTIONS => {
			'OUT' => 348,
			'INOUT' => 344,
			'IN' => 342
		},
		DEFAULT => -316,
		GOTOS => {
			'param_dcl' => 349,
			'param_dcls' => 449,
			'param_attribute' => 345
		}
	},
	{#State 413
		ACTIONS => {
			'error' => 450,
			'STRING_LITERAL' => 293
		},
		GOTOS => {
			'string_literal' => 451,
			'string_literals' => 452
		}
	},
	{#State 414
		DEFAULT => -330
	},
	{#State 415
		DEFAULT => -301
	},
	{#State 416
		ACTIONS => {
			'error' => 454,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 453,
			'exception_names' => 455,
			'exception_name' => 456
		}
	},
	{#State 417
		DEFAULT => -324
	},
	{#State 418
		ACTIONS => {
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 354,
			'value_name' => 355,
			'value_names' => 457
		}
	},
	{#State 419
		DEFAULT => -85
	},
	{#State 420
		DEFAULT => -51
	},
	{#State 421
		DEFAULT => -154
	},
	{#State 422
		DEFAULT => -155
	},
	{#State 423
		ACTIONS => {
			"^" => 367
		},
		DEFAULT => -132
	},
	{#State 424
		ACTIONS => {
			"&" => 373
		},
		DEFAULT => -134
	},
	{#State 425
		ACTIONS => {
			"+" => 371,
			"-" => 372
		},
		DEFAULT => -139
	},
	{#State 426
		ACTIONS => {
			"+" => 371,
			"-" => 372
		},
		DEFAULT => -138
	},
	{#State 427
		ACTIONS => {
			"%" => 375,
			"*" => 374,
			"/" => 376
		},
		DEFAULT => -141
	},
	{#State 428
		ACTIONS => {
			"%" => 375,
			"*" => 374,
			"/" => 376
		},
		DEFAULT => -142
	},
	{#State 429
		ACTIONS => {
			"<<" => 368,
			">>" => 369
		},
		DEFAULT => -136
	},
	{#State 430
		DEFAULT => -144
	},
	{#State 431
		DEFAULT => -146
	},
	{#State 432
		DEFAULT => -145
	},
	{#State 433
		DEFAULT => -239
	},
	{#State 434
		ACTIONS => {
			'error' => 461,
			'CASE' => 458,
			'DEFAULT' => 460
		},
		GOTOS => {
			'case_labels' => 463,
			'switch_body' => 462,
			'case' => 459,
			'case_label' => 464
		}
	},
	{#State 435
		DEFAULT => -98
	},
	{#State 436
		DEFAULT => -99
	},
	{#State 437
		ACTIONS => {
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarator' => 465
		}
	},
	{#State 438
		DEFAULT => -106
	},
	{#State 439
		ACTIONS => {
			'IN' => 392
		},
		GOTOS => {
			'init_param_decls' => 466,
			'init_param_attribute' => 390,
			'init_param_decl' => 393
		}
	},
	{#State 440
		DEFAULT => -107
	},
	{#State 441
		ACTIONS => {
			">" => 467
		}
	},
	{#State 442
		ACTIONS => {
			">" => 468
		}
	},
	{#State 443
		ACTIONS => {
			">" => 469
		}
	},
	{#State 444
		ACTIONS => {
			">" => 470
		}
	},
	{#State 445
		DEFAULT => -284
	},
	{#State 446
		DEFAULT => -285
	},
	{#State 447
		ACTIONS => {
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarators' => 471,
			'simple_declarator' => 406
		}
	},
	{#State 448
		DEFAULT => -318
	},
	{#State 449
		DEFAULT => -315
	},
	{#State 450
		ACTIONS => {
			")" => 472
		}
	},
	{#State 451
		ACTIONS => {
			"," => 473
		},
		DEFAULT => -331
	},
	{#State 452
		ACTIONS => {
			")" => 474
		}
	},
	{#State 453
		ACTIONS => {
			"::" => 178
		},
		DEFAULT => -327
	},
	{#State 454
		ACTIONS => {
			")" => 475
		}
	},
	{#State 455
		ACTIONS => {
			")" => 476
		}
	},
	{#State 456
		ACTIONS => {
			"," => 477
		},
		DEFAULT => -325
	},
	{#State 457
		DEFAULT => -91
	},
	{#State 458
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 288,
			'CHARACTER_LITERAL' => 270,
			'WIDE_CHARACTER_LITERAL' => 271,
			"::" => 86,
			'INTEGER_LITERAL' => 291,
			"(" => 275,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 293,
			'FIXED_PT_LITERAL' => 294,
			"+" => 295,
			'error' => 479,
			"-" => 297,
			'WIDE_STRING_LITERAL' => 283,
			'FALSE' => 282,
			"~" => 298,
			'TRUE' => 285
		},
		GOTOS => {
			'mult_expr' => 292,
			'string_literal' => 287,
			'boolean_literal' => 276,
			'primary_expr' => 289,
			'const_exp' => 478,
			'and_expr' => 290,
			'or_expr' => 278,
			'unary_expr' => 296,
			'scoped_name' => 272,
			'xor_expr' => 280,
			'shift_expr' => 281,
			'wide_string_literal' => 274,
			'literal' => 284,
			'unary_operator' => 299,
			'add_expr' => 286
		}
	},
	{#State 459
		ACTIONS => {
			'CASE' => 458,
			'DEFAULT' => 460
		},
		DEFAULT => -248,
		GOTOS => {
			'case_labels' => 463,
			'switch_body' => 480,
			'case' => 459,
			'case_label' => 464
		}
	},
	{#State 460
		ACTIONS => {
			'error' => 481,
			":" => 482
		}
	},
	{#State 461
		ACTIONS => {
			"}" => 483
		}
	},
	{#State 462
		ACTIONS => {
			"}" => 484
		}
	},
	{#State 463
		ACTIONS => {
			'CHAR' => 78,
			'OBJECT' => 126,
			'VALUEBASE' => 127,
			'FIXED' => 110,
			'SEQUENCE' => 111,
			'STRUCT' => 30,
			'DOUBLE' => 82,
			'LONG' => 83,
			'STRING' => 84,
			"::" => 86,
			'WSTRING' => 88,
			'UNSIGNED' => 68,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'UNION' => 35,
			'WCHAR' => 71,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ENUM' => 24,
			'ANY' => 125
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 116,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'type_spec' => 485,
			'string_type' => 120,
			'struct_header' => 11,
			'element_spec' => 486,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'struct_type' => 131,
			'union_type' => 132,
			'sequence_type' => 133,
			'unsigned_long_int' => 92,
			'template_type_spec' => 134,
			'constr_type_spec' => 135,
			'simple_type_spec' => 136,
			'fixed_pt_type' => 137
		}
	},
	{#State 464
		ACTIONS => {
			'CASE' => 458,
			'DEFAULT' => 460
		},
		DEFAULT => -252,
		GOTOS => {
			'case_labels' => 487,
			'case_label' => 464
		}
	},
	{#State 465
		DEFAULT => -113
	},
	{#State 466
		DEFAULT => -112
	},
	{#State 467
		DEFAULT => -337
	},
	{#State 468
		DEFAULT => -338
	},
	{#State 469
		DEFAULT => -270
	},
	{#State 470
		DEFAULT => -271
	},
	{#State 471
		DEFAULT => -292
	},
	{#State 472
		DEFAULT => -329
	},
	{#State 473
		ACTIONS => {
			'STRING_LITERAL' => 293
		},
		GOTOS => {
			'string_literal' => 451,
			'string_literals' => 488
		}
	},
	{#State 474
		DEFAULT => -328
	},
	{#State 475
		DEFAULT => -323
	},
	{#State 476
		DEFAULT => -322
	},
	{#State 477
		ACTIONS => {
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 453,
			'exception_names' => 489,
			'exception_name' => 456
		}
	},
	{#State 478
		ACTIONS => {
			'error' => 490,
			":" => 491
		}
	},
	{#State 479
		DEFAULT => -256
	},
	{#State 480
		DEFAULT => -249
	},
	{#State 481
		DEFAULT => -258
	},
	{#State 482
		DEFAULT => -257
	},
	{#State 483
		DEFAULT => -238
	},
	{#State 484
		DEFAULT => -237
	},
	{#State 485
		ACTIONS => {
			'IDENTIFIER' => 223
		},
		GOTOS => {
			'declarator' => 492,
			'simple_declarator' => 221,
			'array_declarator' => 222,
			'complex_declarator' => 220
		}
	},
	{#State 486
		ACTIONS => {
			'error' => 494,
			";" => 493
		}
	},
	{#State 487
		DEFAULT => -253
	},
	{#State 488
		DEFAULT => -332
	},
	{#State 489
		DEFAULT => -326
	},
	{#State 490
		DEFAULT => -255
	},
	{#State 491
		DEFAULT => -254
	},
	{#State 492
		DEFAULT => -259
	},
	{#State 493
		DEFAULT => -250
	},
	{#State 494
		DEFAULT => -251
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
		 'definition', 2,
sub
#line 111 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 117 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 123 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 129 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'definition', 2,
sub
#line 135 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 17
		 'definition', 2,
sub
#line 141 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 18
		 'module', 4,
sub
#line 151 "parser23.yp"
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
#line 158 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'module', 2,
sub
#line 164 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'module_header', 2,
sub
#line 173 "parser23.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 22
		 'module_header', 2,
sub
#line 179 "parser23.yp"
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
#line 196 "parser23.yp"
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
#line 204 "parser23.yp"
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
#line 212 "parser23.yp"
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
#line 223 "parser23.yp"
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
	[#Rule 29
		 'forward_dcl', 3,
sub
#line 235 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 30
		 'interface_mod', 1, undef
	],
	[#Rule 31
		 'interface_mod', 0, undef
	],
	[#Rule 32
		 'interface_header', 3,
sub
#line 251 "parser23.yp"
{
			if (defined $_[1] and $_[1] eq 'abstract') {
				new AbstractInterface($_[0],
						'idf'					=>	$_[3]
				);
			} else {
				new RegularInterface($_[0],
						'idf'					=>	$_[3]
				);
			}
		}
	],
	[#Rule 33
		 'interface_header', 4,
sub
#line 263 "parser23.yp"
{
			my $inheritance = new InheritanceSpec($_[0],
					'list_interface'		=>	$_[4]
			);
			if (defined $_[1] and $_[1] eq 'abstract') {
				new AbstractInterface($_[0],
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
	[#Rule 34
		 'interface_header', 3,
sub
#line 280 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 35
		 'interface_body', 1, undef
	],
	[#Rule 36
		 'exports', 1,
sub
#line 294 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 37
		 'exports', 2,
sub
#line 298 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
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
		 'export', 2,
sub
#line 317 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 44
		 'export', 2,
sub
#line 323 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 45
		 'export', 2,
sub
#line 329 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 46
		 'export', 2,
sub
#line 335 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 47
		 'export', 2,
sub
#line 341 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 48
		 'interface_inheritance_spec', 2,
sub
#line 351 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 49
		 'interface_inheritance_spec', 2,
sub
#line 355 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 50
		 'interface_names', 1,
sub
#line 363 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 51
		 'interface_names', 3,
sub
#line 367 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 52
		 'interface_name', 1,
sub
#line 376 "parser23.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 53
		 'scoped_name', 1, undef
	],
	[#Rule 54
		 'scoped_name', 2,
sub
#line 386 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 55
		 'scoped_name', 2,
sub
#line 390 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 56
		 'scoped_name', 3,
sub
#line 396 "parser23.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 57
		 'scoped_name', 3,
sub
#line 400 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
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
#line 422 "parser23.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 63
		 'value_forward_dcl', 3,
sub
#line 428 "parser23.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 64
		 'value_box_dcl', 3,
sub
#line 438 "parser23.yp"
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
#line 449 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 66
		 'value_abs_dcl', 4,
sub
#line 457 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 67
		 'value_abs_dcl', 4,
sub
#line 465 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 68
		 'value_abs_header', 3,
sub
#line 475 "parser23.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 69
		 'value_abs_header', 4,
sub
#line 481 "parser23.yp"
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
#line 488 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 71
		 'value_abs_header', 2,
sub
#line 493 "parser23.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 72
		 'value_dcl', 3,
sub
#line 502 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 73
		 'value_dcl', 4,
sub
#line 510 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 74
		 'value_dcl', 4,
sub
#line 518 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 75
		 'value_elements', 1,
sub
#line 528 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 76
		 'value_elements', 2,
sub
#line 532 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 77
		 'value_header', 2,
sub
#line 541 "parser23.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 78
		 'value_header', 3,
sub
#line 547 "parser23.yp"
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
#line 554 "parser23.yp"
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
#line 561 "parser23.yp"
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
#line 569 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 82
		 'value_header', 3,
sub
#line 574 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 83
		 'value_header', 2,
sub
#line 579 "parser23.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 84
		 'value_inheritance_spec', 3,
sub
#line 588 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3]
			);
		}
	],
	[#Rule 85
		 'value_inheritance_spec', 4,
sub
#line 595 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 86
		 'value_inheritance_spec', 3,
sub
#line 603 "parser23.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 87
		 'value_inheritance_spec', 1,
sub
#line 608 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 88
		 'inheritance_mod', 1, undef
	],
	[#Rule 89
		 'inheritance_mod', 0, undef
	],
	[#Rule 90
		 'value_names', 1,
sub
#line 624 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 91
		 'value_names', 3,
sub
#line 628 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 92
		 'supported_interface_spec', 2,
sub
#line 636 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 93
		 'supported_interface_spec', 2,
sub
#line 640 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 94
		 'value_name', 1,
sub
#line 649 "parser23.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 95
		 'value_element', 1, undef
	],
	[#Rule 96
		 'value_element', 1, undef
	],
	[#Rule 97
		 'value_element', 1, undef
	],
	[#Rule 98
		 'state_member', 4,
sub
#line 667 "parser23.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 99
		 'state_member', 4,
sub
#line 675 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 100
		 'state_member', 3,
sub
#line 680 "parser23.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 101
		 'state_mod', 1, undef
	],
	[#Rule 102
		 'state_mod', 1, undef
	],
	[#Rule 103
		 'init_dcl', 2, undef
	],
	[#Rule 104
		 'init_dcl', 2,
sub
#line 698 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 105
		 'init_header_param', 3,
sub
#line 707 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 106
		 'init_header_param', 4,
sub
#line 713 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 107
		 'init_header_param', 4,
sub
#line 721 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 108
		 'init_header_param', 2,
sub
#line 728 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 109
		 'init_header', 2,
sub
#line 738 "parser23.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 110
		 'init_header', 2,
sub
#line 744 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 111
		 'init_param_decls', 1,
sub
#line 753 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 112
		 'init_param_decls', 3,
sub
#line 757 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 113
		 'init_param_decl', 3,
sub
#line 766 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 114
		 'init_param_attribute', 1, undef
	],
	[#Rule 115
		 'const_dcl', 5,
sub
#line 784 "parser23.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 116
		 'const_dcl', 5,
sub
#line 792 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 117
		 'const_dcl', 4,
sub
#line 797 "parser23.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 118
		 'const_dcl', 3,
sub
#line 802 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'const_dcl', 2,
sub
#line 807 "parser23.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 120
		 'const_type', 1, undef
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
		 'const_type', 1,
sub
#line 832 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 129
		 'const_type', 1, undef
	],
	[#Rule 130
		 'const_exp', 1, undef
	],
	[#Rule 131
		 'or_expr', 1, undef
	],
	[#Rule 132
		 'or_expr', 3,
sub
#line 850 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 133
		 'xor_expr', 1, undef
	],
	[#Rule 134
		 'xor_expr', 3,
sub
#line 860 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 135
		 'and_expr', 1, undef
	],
	[#Rule 136
		 'and_expr', 3,
sub
#line 870 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 137
		 'shift_expr', 1, undef
	],
	[#Rule 138
		 'shift_expr', 3,
sub
#line 880 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 139
		 'shift_expr', 3,
sub
#line 884 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 140
		 'add_expr', 1, undef
	],
	[#Rule 141
		 'add_expr', 3,
sub
#line 894 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 142
		 'add_expr', 3,
sub
#line 898 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 143
		 'mult_expr', 1, undef
	],
	[#Rule 144
		 'mult_expr', 3,
sub
#line 908 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 145
		 'mult_expr', 3,
sub
#line 912 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 146
		 'mult_expr', 3,
sub
#line 916 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'unary_expr', 2,
sub
#line 924 "parser23.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 148
		 'unary_expr', 1, undef
	],
	[#Rule 149
		 'unary_operator', 1, undef
	],
	[#Rule 150
		 'unary_operator', 1, undef
	],
	[#Rule 151
		 'unary_operator', 1, undef
	],
	[#Rule 152
		 'primary_expr', 1,
sub
#line 944 "parser23.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 153
		 'primary_expr', 1,
sub
#line 950 "parser23.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 154
		 'primary_expr', 3,
sub
#line 954 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 155
		 'primary_expr', 3,
sub
#line 958 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 156
		 'literal', 1,
sub
#line 967 "parser23.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 157
		 'literal', 1,
sub
#line 974 "parser23.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 158
		 'literal', 1,
sub
#line 980 "parser23.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 159
		 'literal', 1,
sub
#line 986 "parser23.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 992 "parser23.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 998 "parser23.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1005 "parser23.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 163
		 'literal', 1, undef
	],
	[#Rule 164
		 'string_literal', 1, undef
	],
	[#Rule 165
		 'string_literal', 2,
sub
#line 1019 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 166
		 'wide_string_literal', 1, undef
	],
	[#Rule 167
		 'wide_string_literal', 2,
sub
#line 1028 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 168
		 'boolean_literal', 1,
sub
#line 1036 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 169
		 'boolean_literal', 1,
sub
#line 1042 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 170
		 'positive_int_const', 1,
sub
#line 1052 "parser23.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 171
		 'type_dcl', 2,
sub
#line 1062 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 172
		 'type_dcl', 1, undef
	],
	[#Rule 173
		 'type_dcl', 1, undef
	],
	[#Rule 174
		 'type_dcl', 1, undef
	],
	[#Rule 175
		 'type_dcl', 2,
sub
#line 1072 "parser23.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 176
		 'type_dcl', 2,
sub
#line 1079 "parser23.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 177
		 'type_dcl', 2,
sub
#line 1084 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'type_declarator', 2,
sub
#line 1093 "parser23.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 179
		 'type_declarator', 2,
sub
#line 1100 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 180
		 'type_spec', 1, undef
	],
	[#Rule 181
		 'type_spec', 1, undef
	],
	[#Rule 182
		 'simple_type_spec', 1, undef
	],
	[#Rule 183
		 'simple_type_spec', 1, undef
	],
	[#Rule 184
		 'simple_type_spec', 1,
sub
#line 1121 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
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
		 'template_type_spec', 1, undef
	],
	[#Rule 195
		 'template_type_spec', 1, undef
	],
	[#Rule 196
		 'template_type_spec', 1, undef
	],
	[#Rule 197
		 'template_type_spec', 1, undef
	],
	[#Rule 198
		 'constr_type_spec', 1, undef
	],
	[#Rule 199
		 'constr_type_spec', 1, undef
	],
	[#Rule 200
		 'constr_type_spec', 1, undef
	],
	[#Rule 201
		 'declarators', 1,
sub
#line 1173 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 202
		 'declarators', 3,
sub
#line 1177 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 203
		 'declarator', 1,
sub
#line 1186 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 204
		 'declarator', 1, undef
	],
	[#Rule 205
		 'simple_declarator', 1, undef
	],
	[#Rule 206
		 'complex_declarator', 1, undef
	],
	[#Rule 207
		 'floating_pt_type', 1,
sub
#line 1208 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 208
		 'floating_pt_type', 1,
sub
#line 1214 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 209
		 'floating_pt_type', 2,
sub
#line 1220 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 210
		 'integer_type', 1, undef
	],
	[#Rule 211
		 'integer_type', 1, undef
	],
	[#Rule 212
		 'signed_int', 1, undef
	],
	[#Rule 213
		 'signed_int', 1, undef
	],
	[#Rule 214
		 'signed_int', 1, undef
	],
	[#Rule 215
		 'signed_short_int', 1,
sub
#line 1248 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 216
		 'signed_long_int', 1,
sub
#line 1258 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 217
		 'signed_longlong_int', 2,
sub
#line 1268 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 218
		 'unsigned_int', 1, undef
	],
	[#Rule 219
		 'unsigned_int', 1, undef
	],
	[#Rule 220
		 'unsigned_int', 1, undef
	],
	[#Rule 221
		 'unsigned_short_int', 2,
sub
#line 1288 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 222
		 'unsigned_long_int', 2,
sub
#line 1298 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 223
		 'unsigned_longlong_int', 3,
sub
#line 1308 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 224
		 'char_type', 1,
sub
#line 1318 "parser23.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 225
		 'wide_char_type', 1,
sub
#line 1328 "parser23.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 226
		 'boolean_type', 1,
sub
#line 1338 "parser23.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 227
		 'octet_type', 1,
sub
#line 1348 "parser23.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 228
		 'any_type', 1,
sub
#line 1358 "parser23.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 229
		 'object_type', 1,
sub
#line 1368 "parser23.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'struct_type', 4,
sub
#line 1378 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 231
		 'struct_type', 4,
sub
#line 1385 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 232
		 'struct_header', 2,
sub
#line 1394 "parser23.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 233
		 'member_list', 1,
sub
#line 1404 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 234
		 'member_list', 2,
sub
#line 1408 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 235
		 'member', 3,
sub
#line 1417 "parser23.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 236
		 'member', 3,
sub
#line 1424 "parser23.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 237
		 'union_type', 8,
sub
#line 1437 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 238
		 'union_type', 8,
sub
#line 1445 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 239
		 'union_type', 6,
sub
#line 1451 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 240
		 'union_type', 5,
sub
#line 1457 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 241
		 'union_type', 3,
sub
#line 1463 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'union_header', 2,
sub
#line 1472 "parser23.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 243
		 'switch_type_spec', 1, undef
	],
	[#Rule 244
		 'switch_type_spec', 1, undef
	],
	[#Rule 245
		 'switch_type_spec', 1, undef
	],
	[#Rule 246
		 'switch_type_spec', 1, undef
	],
	[#Rule 247
		 'switch_type_spec', 1,
sub
#line 1490 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 248
		 'switch_body', 1,
sub
#line 1498 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 249
		 'switch_body', 2,
sub
#line 1502 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 250
		 'case', 3,
sub
#line 1511 "parser23.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 251
		 'case', 3,
sub
#line 1518 "parser23.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 252
		 'case_labels', 1,
sub
#line 1530 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 253
		 'case_labels', 2,
sub
#line 1534 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 254
		 'case_label', 3,
sub
#line 1543 "parser23.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 255
		 'case_label', 3,
sub
#line 1547 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 256
		 'case_label', 2,
sub
#line 1553 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 257
		 'case_label', 2,
sub
#line 1558 "parser23.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 258
		 'case_label', 2,
sub
#line 1562 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 259
		 'element_spec', 2,
sub
#line 1572 "parser23.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 260
		 'enum_type', 4,
sub
#line 1583 "parser23.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 261
		 'enum_type', 4,
sub
#line 1589 "parser23.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 262
		 'enum_type', 2,
sub
#line 1594 "parser23.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 263
		 'enum_header', 2,
sub
#line 1602 "parser23.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 264
		 'enum_header', 2,
sub
#line 1608 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 265
		 'enumerators', 1,
sub
#line 1616 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 266
		 'enumerators', 3,
sub
#line 1620 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 267
		 'enumerators', 2,
sub
#line 1625 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 268
		 'enumerators', 2,
sub
#line 1630 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 269
		 'enumerator', 1,
sub
#line 1639 "parser23.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 270
		 'sequence_type', 6,
sub
#line 1649 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 271
		 'sequence_type', 6,
sub
#line 1657 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 272
		 'sequence_type', 4,
sub
#line 1662 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 273
		 'sequence_type', 4,
sub
#line 1669 "parser23.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 274
		 'sequence_type', 2,
sub
#line 1674 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 275
		 'string_type', 4,
sub
#line 1683 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 276
		 'string_type', 1,
sub
#line 1690 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 277
		 'string_type', 4,
sub
#line 1696 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'wide_string_type', 4,
sub
#line 1705 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 279
		 'wide_string_type', 1,
sub
#line 1712 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 280
		 'wide_string_type', 4,
sub
#line 1718 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 281
		 'array_declarator', 2,
sub
#line 1727 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 282
		 'fixed_array_sizes', 1,
sub
#line 1735 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 283
		 'fixed_array_sizes', 2,
sub
#line 1739 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 284
		 'fixed_array_size', 3,
sub
#line 1748 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 285
		 'fixed_array_size', 3,
sub
#line 1752 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 286
		 'attr_dcl', 4,
sub
#line 1761 "parser23.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 287
		 'attr_dcl', 4,
sub
#line 1769 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 288
		 'attr_dcl', 3,
sub
#line 1774 "parser23.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 289
		 'attr_mod', 1, undef
	],
	[#Rule 290
		 'attr_mod', 0, undef
	],
	[#Rule 291
		 'simple_declarators', 1,
sub
#line 1789 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 292
		 'simple_declarators', 3,
sub
#line 1793 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 293
		 'except_dcl', 3,
sub
#line 1802 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 294
		 'except_dcl', 4,
sub
#line 1807 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 295
		 'except_dcl', 4,
sub
#line 1814 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 296
		 'except_dcl', 2,
sub
#line 1820 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 297
		 'exception_header', 2,
sub
#line 1829 "parser23.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 298
		 'exception_header', 2,
sub
#line 1835 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 299
		 'op_dcl', 2,
sub
#line 1844 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 300
		 'op_dcl', 3,
sub
#line 1852 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 301
		 'op_dcl', 4,
sub
#line 1861 "parser23.yp"
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
	[#Rule 302
		 'op_dcl', 3,
sub
#line 1871 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 303
		 'op_dcl', 2,
sub
#line 1880 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 304
		 'op_header', 3,
sub
#line 1890 "parser23.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 305
		 'op_header', 3,
sub
#line 1898 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 306
		 'op_mod', 1, undef
	],
	[#Rule 307
		 'op_mod', 0, undef
	],
	[#Rule 308
		 'op_attribute', 1, undef
	],
	[#Rule 309
		 'op_type_spec', 1, undef
	],
	[#Rule 310
		 'op_type_spec', 1,
sub
#line 1922 "parser23.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 311
		 'parameter_dcls', 3,
sub
#line 1932 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 312
		 'parameter_dcls', 2,
sub
#line 1936 "parser23.yp"
{
			undef;
		}
	],
	[#Rule 313
		 'parameter_dcls', 3,
sub
#line 1940 "parser23.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 314
		 'param_dcls', 1,
sub
#line 1948 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 315
		 'param_dcls', 3,
sub
#line 1952 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 316
		 'param_dcls', 2,
sub
#line 1957 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 317
		 'param_dcls', 2,
sub
#line 1962 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 318
		 'param_dcl', 3,
sub
#line 1971 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 319
		 'param_attribute', 1, undef
	],
	[#Rule 320
		 'param_attribute', 1, undef
	],
	[#Rule 321
		 'param_attribute', 1, undef
	],
	[#Rule 322
		 'raises_expr', 4,
sub
#line 1993 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 323
		 'raises_expr', 4,
sub
#line 1997 "parser23.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 324
		 'raises_expr', 2,
sub
#line 2002 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 325
		 'exception_names', 1,
sub
#line 2010 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 326
		 'exception_names', 3,
sub
#line 2014 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 327
		 'exception_name', 1,
sub
#line 2022 "parser23.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 328
		 'context_expr', 4,
sub
#line 2030 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 329
		 'context_expr', 4,
sub
#line 2034 "parser23.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 330
		 'context_expr', 2,
sub
#line 2039 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 331
		 'string_literals', 1,
sub
#line 2047 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 332
		 'string_literals', 3,
sub
#line 2051 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 333
		 'param_type_spec', 1, undef
	],
	[#Rule 334
		 'param_type_spec', 1, undef
	],
	[#Rule 335
		 'param_type_spec', 1, undef
	],
	[#Rule 336
		 'param_type_spec', 1,
sub
#line 2066 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 337
		 'fixed_pt_type', 6,
sub
#line 2074 "parser23.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 338
		 'fixed_pt_type', 6,
sub
#line 2082 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 339
		 'fixed_pt_type', 4,
sub
#line 2087 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 340
		 'fixed_pt_type', 2,
sub
#line 2092 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 341
		 'fixed_pt_const_type', 1,
sub
#line 2101 "parser23.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 342
		 'value_base_type', 1,
sub
#line 2111 "parser23.yp"
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

#line 2118 "parser23.yp"


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
