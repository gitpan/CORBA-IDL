####################################################################
#
#    This file was generated using Parse::Yapp version 1.02.
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
# (c) Copyright 1998-1999 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.02';
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

    my($self)=$class->SUPER::new( yyversion => '1.02',
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
		DEFAULT => -60
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
		DEFAULT => -59
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
		DEFAULT => -57
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
		DEFAULT => -58
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
		DEFAULT => -173
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
		DEFAULT => -174
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
		DEFAULT => -70
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
			'CHAR' => -308,
			'OBJECT' => -308,
			'ONEWAY' => 150,
			'VALUEBASE' => -308,
			'NATIVE' => 28,
			'VOID' => -308,
			'STRUCT' => 30,
			'DOUBLE' => -308,
			'LONG' => -308,
			'STRING' => -308,
			"::" => -308,
			'WSTRING' => -308,
			'UNSIGNED' => -308,
			'SHORT' => -308,
			'TYPEDEF' => 33,
			'BOOLEAN' => -308,
			'IDENTIFIER' => -308,
			'UNION' => 35,
			'READONLY' => 161,
			'WCHAR' => -308,
			'ATTRIBUTE' => -291,
			'error' => 155,
			'CONST' => 19,
			"}" => 156,
			'EXCEPTION' => 21,
			'OCTET' => -308,
			'FLOAT' => -308,
			'ENUM' => 24,
			'ANY' => -308
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
		DEFAULT => -80
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
			"{" => -76,
			'SUPPORTS' => 168,
			'FLOAT' => 76,
			'OCTET' => 74,
			'ENUM' => 24,
			'ANY' => 125
		},
		DEFAULT => -61,
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
			'fixed_pt_type' => 137
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
			'error' => 170,
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
			'type_spec' => 169,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'member_list' => 171,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'member' => 172,
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
		DEFAULT => -263
	},
	{#State 58
		ACTIONS => {
			'error' => 173,
			'IDENTIFIER' => 175
		},
		GOTOS => {
			'enumerators' => 176,
			'enumerator' => 174
		}
	},
	{#State 59
		DEFAULT => -212
	},
	{#State 60
		DEFAULT => -125
	},
	{#State 61
		DEFAULT => -342
	},
	{#State 62
		DEFAULT => -211
	},
	{#State 63
		DEFAULT => -122
	},
	{#State 64
		DEFAULT => -130
	},
	{#State 65
		ACTIONS => {
			"::" => 177
		},
		DEFAULT => -129
	},
	{#State 66
		DEFAULT => -123
	},
	{#State 67
		DEFAULT => -214
	},
	{#State 68
		ACTIONS => {
			'SHORT' => 178,
			'LONG' => 179
		}
	},
	{#State 69
		DEFAULT => -126
	},
	{#State 70
		DEFAULT => -216
	},
	{#State 71
		DEFAULT => -226
	},
	{#State 72
		DEFAULT => -221
	},
	{#State 73
		DEFAULT => -120
	},
	{#State 74
		DEFAULT => -228
	},
	{#State 75
		DEFAULT => -219
	},
	{#State 76
		DEFAULT => -208
	},
	{#State 77
		DEFAULT => -215
	},
	{#State 78
		DEFAULT => -225
	},
	{#State 79
		DEFAULT => -127
	},
	{#State 80
		DEFAULT => -124
	},
	{#State 81
		DEFAULT => -121
	},
	{#State 82
		DEFAULT => -209
	},
	{#State 83
		ACTIONS => {
			'DOUBLE' => 180,
			'LONG' => 181
		},
		DEFAULT => -217
	},
	{#State 84
		ACTIONS => {
			"<" => 182
		},
		DEFAULT => -277
	},
	{#State 85
		DEFAULT => -128
	},
	{#State 86
		ACTIONS => {
			'error' => 183,
			'IDENTIFIER' => 184
		}
	},
	{#State 87
		DEFAULT => -213
	},
	{#State 88
		ACTIONS => {
			"<" => 185
		},
		DEFAULT => -280
	},
	{#State 89
		ACTIONS => {
			'error' => 186,
			'IDENTIFIER' => 187
		}
	},
	{#State 90
		DEFAULT => -227
	},
	{#State 91
		DEFAULT => -52
	},
	{#State 92
		DEFAULT => -220
	},
	{#State 93
		DEFAULT => -299
	},
	{#State 94
		DEFAULT => -298
	},
	{#State 95
		ACTIONS => {
			'error' => 189,
			"(" => 188
		}
	},
	{#State 96
		DEFAULT => -265
	},
	{#State 97
		DEFAULT => -264
	},
	{#State 98
		ACTIONS => {
			'error' => 190,
			'IDENTIFIER' => 191
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
			'CHAR' => -308,
			'OBJECT' => -308,
			'ONEWAY' => 150,
			'VALUEBASE' => -308,
			'NATIVE' => 28,
			'VOID' => -308,
			'STRUCT' => 30,
			'DOUBLE' => -308,
			'LONG' => -308,
			'STRING' => -308,
			"::" => -308,
			'WSTRING' => -308,
			'UNSIGNED' => -308,
			'SHORT' => -308,
			'TYPEDEF' => 33,
			'BOOLEAN' => -308,
			'IDENTIFIER' => -308,
			'UNION' => 35,
			'READONLY' => 161,
			'WCHAR' => -308,
			'ATTRIBUTE' => -291,
			'error' => 192,
			'CONST' => 19,
			"}" => 193,
			'EXCEPTION' => 21,
			'OCTET' => -308,
			'FLOAT' => -308,
			'ENUM' => 24,
			'ANY' => -308
		},
		GOTOS => {
			'const_dcl' => 157,
			'op_mod' => 151,
			'except_dcl' => 152,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'exports' => 194,
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
			'interface_body' => 195
		}
	},
	{#State 102
		DEFAULT => -178
	},
	{#State 103
		DEFAULT => -176
	},
	{#State 104
		DEFAULT => -206
	},
	{#State 105
		ACTIONS => {
			'PRIVATE' => 196,
			'ONEWAY' => 150,
			'FACTORY' => 200,
			'UNSIGNED' => -308,
			'SHORT' => -308,
			'WCHAR' => -308,
			'error' => 202,
			'CONST' => 19,
			"}" => 203,
			'EXCEPTION' => 21,
			'OCTET' => -308,
			'FLOAT' => -308,
			'ENUM' => 24,
			'ANY' => -308,
			'CHAR' => -308,
			'OBJECT' => -308,
			'NATIVE' => 28,
			'VALUEBASE' => -308,
			'VOID' => -308,
			'STRUCT' => 30,
			'DOUBLE' => -308,
			'LONG' => -308,
			'STRING' => -308,
			"::" => -308,
			'WSTRING' => -308,
			'BOOLEAN' => -308,
			'TYPEDEF' => 33,
			'IDENTIFIER' => -308,
			'UNION' => 35,
			'READONLY' => 161,
			'ATTRIBUTE' => -291,
			'PUBLIC' => 206
		},
		GOTOS => {
			'const_dcl' => 157,
			'op_mod' => 151,
			'value_elements' => 204,
			'except_dcl' => 152,
			'state_member' => 197,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'state_mod' => 198,
			'value_element' => 199,
			'export' => 205,
			'init_header' => 201,
			'struct_type' => 31,
			'op_header' => 160,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 162,
			'init_dcl' => 207,
			'enum_header' => 18,
			'attr_dcl' => 163,
			'type_dcl' => 164,
			'union_header' => 22
		}
	},
	{#State 106
		DEFAULT => -233
	},
	{#State 107
		DEFAULT => -297
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
			'error' => 208,
			"}" => 210,
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
			'type_spec' => 169,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'member_list' => 209,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'member' => 172,
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
		DEFAULT => -186
	},
	{#State 110
		ACTIONS => {
			"<" => 212,
			'error' => 211
		}
	},
	{#State 111
		ACTIONS => {
			"<" => 214,
			'error' => 213
		}
	},
	{#State 112
		DEFAULT => -194
	},
	{#State 113
		DEFAULT => -188
	},
	{#State 114
		DEFAULT => -193
	},
	{#State 115
		DEFAULT => -191
	},
	{#State 116
		ACTIONS => {
			"::" => 177
		},
		DEFAULT => -185
	},
	{#State 117
		DEFAULT => -189
	},
	{#State 118
		ACTIONS => {
			'error' => 217,
			'IDENTIFIER' => 221
		},
		GOTOS => {
			'declarators' => 215,
			'declarator' => 216,
			'simple_declarator' => 219,
			'array_declarator' => 220,
			'complex_declarator' => 218
		}
	},
	{#State 119
		DEFAULT => -172
	},
	{#State 120
		DEFAULT => -196
	},
	{#State 121
		DEFAULT => -192
	},
	{#State 122
		DEFAULT => -183
	},
	{#State 123
		DEFAULT => -201
	},
	{#State 124
		DEFAULT => -177
	},
	{#State 125
		DEFAULT => -229
	},
	{#State 126
		DEFAULT => -230
	},
	{#State 127
		DEFAULT => -343
	},
	{#State 128
		DEFAULT => -197
	},
	{#State 129
		DEFAULT => -190
	},
	{#State 130
		DEFAULT => -187
	},
	{#State 131
		DEFAULT => -199
	},
	{#State 132
		DEFAULT => -200
	},
	{#State 133
		DEFAULT => -195
	},
	{#State 134
		DEFAULT => -184
	},
	{#State 135
		DEFAULT => -182
	},
	{#State 136
		DEFAULT => -181
	},
	{#State 137
		DEFAULT => -198
	},
	{#State 138
		DEFAULT => -243
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
			'error' => 222,
			'IDENTIFIER' => 223
		}
	},
	{#State 144
		DEFAULT => -82
	},
	{#State 145
		DEFAULT => -5
	},
	{#State 146
		DEFAULT => -69
	},
	{#State 147
		ACTIONS => {
			"{" => -67,
			'SUPPORTS' => 168,
			":" => 167
		},
		DEFAULT => -62,
		GOTOS => {
			'value_inheritance_spec' => 224
		}
	},
	{#State 148
		ACTIONS => {
			"}" => 225
		}
	},
	{#State 149
		ACTIONS => {
			"}" => 226
		}
	},
	{#State 150
		DEFAULT => -309
	},
	{#State 151
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'OBJECT' => 126,
			'IDENTIFIER' => 91,
			'VALUEBASE' => 127,
			'VOID' => 232,
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
			'wide_string_type' => 231,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 227,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 228,
			'op_type_spec' => 233,
			'base_type_spec' => 229,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'unsigned_long_int' => 92,
			'param_type_spec' => 230,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 152
		ACTIONS => {
			'error' => 235,
			";" => 234
		}
	},
	{#State 153
		DEFAULT => -307
	},
	{#State 154
		ACTIONS => {
			'ATTRIBUTE' => 236
		}
	},
	{#State 155
		ACTIONS => {
			"}" => 237
		}
	},
	{#State 156
		DEFAULT => -64
	},
	{#State 157
		ACTIONS => {
			'error' => 239,
			";" => 238
		}
	},
	{#State 158
		ACTIONS => {
			"}" => 240
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
			'ATTRIBUTE' => -291,
			'CONST' => 19,
			"}" => -35,
			'EXCEPTION' => 21,
			'ENUM' => 24
		},
		DEFAULT => -308,
		GOTOS => {
			'const_dcl' => 157,
			'op_mod' => 151,
			'except_dcl' => 152,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'exports' => 241,
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
			'error' => 243,
			"(" => 242
		},
		GOTOS => {
			'parameter_dcls' => 244
		}
	},
	{#State 161
		DEFAULT => -290
	},
	{#State 162
		ACTIONS => {
			'error' => 246,
			";" => 245
		}
	},
	{#State 163
		ACTIONS => {
			'error' => 248,
			";" => 247
		}
	},
	{#State 164
		ACTIONS => {
			'error' => 250,
			";" => 249
		}
	},
	{#State 165
		DEFAULT => -63
	},
	{#State 166
		DEFAULT => -78
	},
	{#State 167
		ACTIONS => {
			'error' => 253,
			'IDENTIFIER' => 91,
			"::" => 86,
			'TRUNCATABLE' => 254
		},
		GOTOS => {
			'scoped_name' => 251,
			'value_name' => 252,
			'value_names' => 255
		}
	},
	{#State 168
		ACTIONS => {
			'error' => 257,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 256,
			'interface_names' => 259,
			'interface_name' => 258
		}
	},
	{#State 169
		ACTIONS => {
			'IDENTIFIER' => 221
		},
		GOTOS => {
			'declarators' => 260,
			'declarator' => 216,
			'simple_declarator' => 219,
			'array_declarator' => 220,
			'complex_declarator' => 218
		}
	},
	{#State 170
		ACTIONS => {
			"}" => 261
		}
	},
	{#State 171
		ACTIONS => {
			"}" => 262
		}
	},
	{#State 172
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
		DEFAULT => -234,
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
			'type_spec' => 169,
			'string_type' => 120,
			'struct_header' => 11,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'base_type_spec' => 122,
			'enum_type' => 123,
			'enum_header' => 18,
			'member_list' => 263,
			'union_header' => 22,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77,
			'wide_string_type' => 128,
			'boolean_type' => 129,
			'integer_type' => 130,
			'signed_short_int' => 87,
			'member' => 172,
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
	{#State 173
		ACTIONS => {
			"}" => 264
		}
	},
	{#State 174
		ACTIONS => {
			";" => 265,
			"," => 266
		},
		DEFAULT => -266
	},
	{#State 175
		DEFAULT => -270
	},
	{#State 176
		ACTIONS => {
			"}" => 267
		}
	},
	{#State 177
		ACTIONS => {
			'error' => 268,
			'IDENTIFIER' => 269
		}
	},
	{#State 178
		DEFAULT => -222
	},
	{#State 179
		ACTIONS => {
			'LONG' => 270
		},
		DEFAULT => -223
	},
	{#State 180
		DEFAULT => -210
	},
	{#State 181
		DEFAULT => -218
	},
	{#State 182
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 280,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'primary_expr' => 290,
			'and_expr' => 291,
			'scoped_name' => 273,
			'positive_int_const' => 274,
			'wide_string_literal' => 275,
			'boolean_literal' => 277,
			'mult_expr' => 293,
			'const_exp' => 278,
			'or_expr' => 279,
			'unary_expr' => 297,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 183
		DEFAULT => -54
	},
	{#State 184
		DEFAULT => -53
	},
	{#State 185
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 302,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'primary_expr' => 290,
			'and_expr' => 291,
			'scoped_name' => 273,
			'positive_int_const' => 301,
			'wide_string_literal' => 275,
			'boolean_literal' => 277,
			'mult_expr' => 293,
			'const_exp' => 278,
			'or_expr' => 279,
			'unary_expr' => 297,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 186
		DEFAULT => -119
	},
	{#State 187
		ACTIONS => {
			'error' => 303,
			"=" => 304
		}
	},
	{#State 188
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'IDENTIFIER' => 91,
			'error' => 308,
			'LONG' => 312,
			"::" => 86,
			'ENUM' => 24,
			'UNSIGNED' => 68
		},
		GOTOS => {
			'switch_type_spec' => 309,
			'unsigned_int' => 59,
			'signed_int' => 62,
			'integer_type' => 311,
			'boolean_type' => 310,
			'unsigned_longlong_int' => 72,
			'char_type' => 305,
			'enum_type' => 307,
			'unsigned_long_int' => 92,
			'scoped_name' => 306,
			'enum_header' => 18,
			'signed_long_int' => 67,
			'unsigned_short_int' => 75,
			'signed_short_int' => 87,
			'signed_longlong_int' => 77
		}
	},
	{#State 189
		DEFAULT => -242
	},
	{#State 190
		DEFAULT => -29
	},
	{#State 191
		ACTIONS => {
			"{" => -32,
			":" => 313
		},
		DEFAULT => -28,
		GOTOS => {
			'interface_inheritance_spec' => 314
		}
	},
	{#State 192
		ACTIONS => {
			"}" => 315
		}
	},
	{#State 193
		DEFAULT => -25
	},
	{#State 194
		DEFAULT => -34
	},
	{#State 195
		ACTIONS => {
			"}" => 316
		}
	},
	{#State 196
		DEFAULT => -103
	},
	{#State 197
		DEFAULT => -97
	},
	{#State 198
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
			'error' => 318,
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
			'type_spec' => 317,
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
	{#State 199
		ACTIONS => {
			'PRIVATE' => 196,
			'ONEWAY' => 150,
			'FACTORY' => 200,
			'CONST' => 19,
			'EXCEPTION' => 21,
			"}" => -74,
			'ENUM' => 24,
			'NATIVE' => 28,
			'STRUCT' => 30,
			'TYPEDEF' => 33,
			'UNION' => 35,
			'READONLY' => 161,
			'ATTRIBUTE' => -291,
			'PUBLIC' => 206
		},
		DEFAULT => -308,
		GOTOS => {
			'const_dcl' => 157,
			'op_mod' => 151,
			'value_elements' => 319,
			'except_dcl' => 152,
			'state_member' => 197,
			'op_attribute' => 153,
			'attr_mod' => 154,
			'state_mod' => 198,
			'value_element' => 199,
			'export' => 205,
			'init_header' => 201,
			'struct_type' => 31,
			'op_header' => 160,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 162,
			'init_dcl' => 207,
			'enum_header' => 18,
			'attr_dcl' => 163,
			'type_dcl' => 164,
			'union_header' => 22
		}
	},
	{#State 200
		ACTIONS => {
			'error' => 320,
			'IDENTIFIER' => 321
		}
	},
	{#State 201
		ACTIONS => {
			'error' => 323,
			"(" => 322
		}
	},
	{#State 202
		ACTIONS => {
			"}" => 324
		}
	},
	{#State 203
		DEFAULT => -71
	},
	{#State 204
		ACTIONS => {
			"}" => 325
		}
	},
	{#State 205
		DEFAULT => -96
	},
	{#State 206
		DEFAULT => -102
	},
	{#State 207
		DEFAULT => -98
	},
	{#State 208
		ACTIONS => {
			"}" => 326
		}
	},
	{#State 209
		ACTIONS => {
			"}" => 327
		}
	},
	{#State 210
		DEFAULT => -294
	},
	{#State 211
		DEFAULT => -341
	},
	{#State 212
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 329,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'primary_expr' => 290,
			'and_expr' => 291,
			'scoped_name' => 273,
			'positive_int_const' => 328,
			'wide_string_literal' => 275,
			'boolean_literal' => 277,
			'mult_expr' => 293,
			'const_exp' => 278,
			'or_expr' => 279,
			'unary_expr' => 297,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 213
		DEFAULT => -275
	},
	{#State 214
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
			'error' => 330,
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
			'simple_type_spec' => 331,
			'fixed_pt_type' => 137,
			'signed_longlong_int' => 77
		}
	},
	{#State 215
		DEFAULT => -179
	},
	{#State 216
		ACTIONS => {
			"," => 332
		},
		DEFAULT => -202
	},
	{#State 217
		DEFAULT => -180
	},
	{#State 218
		DEFAULT => -205
	},
	{#State 219
		DEFAULT => -204
	},
	{#State 220
		DEFAULT => -207
	},
	{#State 221
		ACTIONS => {
			"[" => 335
		},
		DEFAULT => -206,
		GOTOS => {
			'fixed_array_sizes' => 333,
			'fixed_array_size' => 334
		}
	},
	{#State 222
		DEFAULT => -81
	},
	{#State 223
		ACTIONS => {
			'SUPPORTS' => 168,
			":" => 167
		},
		DEFAULT => -77,
		GOTOS => {
			'value_inheritance_spec' => 336
		}
	},
	{#State 224
		DEFAULT => -68
	},
	{#State 225
		DEFAULT => -19
	},
	{#State 226
		DEFAULT => -18
	},
	{#State 227
		ACTIONS => {
			"::" => 177
		},
		DEFAULT => -337
	},
	{#State 228
		DEFAULT => -335
	},
	{#State 229
		DEFAULT => -334
	},
	{#State 230
		DEFAULT => -310
	},
	{#State 231
		DEFAULT => -336
	},
	{#State 232
		DEFAULT => -311
	},
	{#State 233
		ACTIONS => {
			'error' => 337,
			'IDENTIFIER' => 338
		}
	},
	{#State 234
		DEFAULT => -39
	},
	{#State 235
		DEFAULT => -44
	},
	{#State 236
		ACTIONS => {
			'CHAR' => 78,
			'SHORT' => 70,
			'BOOLEAN' => 90,
			'OBJECT' => 126,
			'IDENTIFIER' => 91,
			'VALUEBASE' => 127,
			'WCHAR' => 71,
			'DOUBLE' => 82,
			'error' => 339,
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
			'wide_string_type' => 231,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 227,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 228,
			'base_type_spec' => 229,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'unsigned_long_int' => 92,
			'param_type_spec' => 340,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 237
		DEFAULT => -66
	},
	{#State 238
		DEFAULT => -38
	},
	{#State 239
		DEFAULT => -43
	},
	{#State 240
		DEFAULT => -65
	},
	{#State 241
		DEFAULT => -36
	},
	{#State 242
		ACTIONS => {
			'error' => 342,
			")" => 346,
			'OUT' => 347,
			'INOUT' => 343,
			'IN' => 341
		},
		GOTOS => {
			'param_dcl' => 348,
			'param_dcls' => 345,
			'param_attribute' => 344
		}
	},
	{#State 243
		DEFAULT => -304
	},
	{#State 244
		ACTIONS => {
			'RAISES' => 352,
			'CONTEXT' => 349
		},
		DEFAULT => -300,
		GOTOS => {
			'context_expr' => 351,
			'raises_expr' => 350
		}
	},
	{#State 245
		DEFAULT => -41
	},
	{#State 246
		DEFAULT => -46
	},
	{#State 247
		DEFAULT => -40
	},
	{#State 248
		DEFAULT => -45
	},
	{#State 249
		DEFAULT => -37
	},
	{#State 250
		DEFAULT => -42
	},
	{#State 251
		ACTIONS => {
			"::" => 177
		},
		DEFAULT => -95
	},
	{#State 252
		ACTIONS => {
			"," => 353
		},
		DEFAULT => -93
	},
	{#State 253
		DEFAULT => -90
	},
	{#State 254
		ACTIONS => {
			'error' => 354,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 251,
			'value_name' => 252,
			'value_names' => 355
		}
	},
	{#State 255
		ACTIONS => {
			'SUPPORTS' => 356
		},
		DEFAULT => -83
	},
	{#State 256
		ACTIONS => {
			"::" => 177
		},
		DEFAULT => -51
	},
	{#State 257
		DEFAULT => -92
	},
	{#State 258
		ACTIONS => {
			"," => 357
		},
		DEFAULT => -49
	},
	{#State 259
		DEFAULT => -91
	},
	{#State 260
		ACTIONS => {
			'error' => 359,
			";" => 358
		}
	},
	{#State 261
		DEFAULT => -232
	},
	{#State 262
		DEFAULT => -231
	},
	{#State 263
		DEFAULT => -235
	},
	{#State 264
		DEFAULT => -262
	},
	{#State 265
		DEFAULT => -269
	},
	{#State 266
		ACTIONS => {
			'IDENTIFIER' => 175
		},
		DEFAULT => -268,
		GOTOS => {
			'enumerators' => 360,
			'enumerator' => 174
		}
	},
	{#State 267
		DEFAULT => -261
	},
	{#State 268
		DEFAULT => -56
	},
	{#State 269
		DEFAULT => -55
	},
	{#State 270
		DEFAULT => -224
	},
	{#State 271
		DEFAULT => -160
	},
	{#State 272
		DEFAULT => -161
	},
	{#State 273
		ACTIONS => {
			"::" => 177
		},
		DEFAULT => -153
	},
	{#State 274
		ACTIONS => {
			">" => 361
		}
	},
	{#State 275
		DEFAULT => -159
	},
	{#State 276
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 363,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 293,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'const_exp' => 362,
			'and_expr' => 291,
			'or_expr' => 279,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 277
		DEFAULT => -164
	},
	{#State 278
		DEFAULT => -171
	},
	{#State 279
		ACTIONS => {
			"|" => 364
		},
		DEFAULT => -131
	},
	{#State 280
		ACTIONS => {
			">" => 365
		}
	},
	{#State 281
		ACTIONS => {
			"^" => 366
		},
		DEFAULT => -132
	},
	{#State 282
		ACTIONS => {
			"<<" => 367,
			">>" => 368
		},
		DEFAULT => -136
	},
	{#State 283
		DEFAULT => -170
	},
	{#State 284
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 284
		},
		DEFAULT => -167,
		GOTOS => {
			'wide_string_literal' => 369
		}
	},
	{#State 285
		DEFAULT => -154
	},
	{#State 286
		DEFAULT => -169
	},
	{#State 287
		ACTIONS => {
			"+" => 370,
			"-" => 371
		},
		DEFAULT => -138
	},
	{#State 288
		DEFAULT => -158
	},
	{#State 289
		DEFAULT => -163
	},
	{#State 290
		DEFAULT => -149
	},
	{#State 291
		ACTIONS => {
			"&" => 372
		},
		DEFAULT => -134
	},
	{#State 292
		DEFAULT => -157
	},
	{#State 293
		ACTIONS => {
			"%" => 374,
			"*" => 373,
			"/" => 375
		},
		DEFAULT => -141
	},
	{#State 294
		ACTIONS => {
			'STRING_LITERAL' => 294
		},
		DEFAULT => -165,
		GOTOS => {
			'string_literal' => 376
		}
	},
	{#State 295
		DEFAULT => -162
	},
	{#State 296
		DEFAULT => -151
	},
	{#State 297
		DEFAULT => -144
	},
	{#State 298
		DEFAULT => -150
	},
	{#State 299
		DEFAULT => -152
	},
	{#State 300
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'boolean_literal' => 277,
			'scoped_name' => 273,
			'primary_expr' => 377,
			'literal' => 285,
			'wide_string_literal' => 275
		}
	},
	{#State 301
		ACTIONS => {
			">" => 378
		}
	},
	{#State 302
		ACTIONS => {
			">" => 379
		}
	},
	{#State 303
		DEFAULT => -118
	},
	{#State 304
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 381,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 293,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'const_exp' => 380,
			'and_expr' => 291,
			'or_expr' => 279,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 305
		DEFAULT => -245
	},
	{#State 306
		ACTIONS => {
			"::" => 177
		},
		DEFAULT => -248
	},
	{#State 307
		DEFAULT => -247
	},
	{#State 308
		ACTIONS => {
			")" => 382
		}
	},
	{#State 309
		ACTIONS => {
			")" => 383
		}
	},
	{#State 310
		DEFAULT => -246
	},
	{#State 311
		DEFAULT => -244
	},
	{#State 312
		ACTIONS => {
			'LONG' => 181
		},
		DEFAULT => -217
	},
	{#State 313
		ACTIONS => {
			'error' => 384,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 256,
			'interface_names' => 385,
			'interface_name' => 258
		}
	},
	{#State 314
		DEFAULT => -33
	},
	{#State 315
		DEFAULT => -27
	},
	{#State 316
		DEFAULT => -26
	},
	{#State 317
		ACTIONS => {
			'error' => 387,
			'IDENTIFIER' => 221
		},
		GOTOS => {
			'declarators' => 386,
			'declarator' => 216,
			'simple_declarator' => 219,
			'array_declarator' => 220,
			'complex_declarator' => 218
		}
	},
	{#State 318
		ACTIONS => {
			";" => 388
		}
	},
	{#State 319
		DEFAULT => -75
	},
	{#State 320
		DEFAULT => -111
	},
	{#State 321
		DEFAULT => -110
	},
	{#State 322
		ACTIONS => {
			'error' => 393,
			")" => 394,
			'IN' => 391
		},
		GOTOS => {
			'init_param_decls' => 390,
			'init_param_attribute' => 389,
			'init_param_decl' => 392
		}
	},
	{#State 323
		DEFAULT => -109
	},
	{#State 324
		DEFAULT => -73
	},
	{#State 325
		DEFAULT => -72
	},
	{#State 326
		DEFAULT => -296
	},
	{#State 327
		DEFAULT => -295
	},
	{#State 328
		ACTIONS => {
			"," => 395
		}
	},
	{#State 329
		ACTIONS => {
			">" => 396
		}
	},
	{#State 330
		ACTIONS => {
			">" => 397
		}
	},
	{#State 331
		ACTIONS => {
			">" => 399,
			"," => 398
		}
	},
	{#State 332
		ACTIONS => {
			'IDENTIFIER' => 221
		},
		GOTOS => {
			'declarators' => 400,
			'declarator' => 216,
			'simple_declarator' => 219,
			'array_declarator' => 220,
			'complex_declarator' => 218
		}
	},
	{#State 333
		DEFAULT => -282
	},
	{#State 334
		ACTIONS => {
			"[" => 335
		},
		DEFAULT => -283,
		GOTOS => {
			'fixed_array_sizes' => 401,
			'fixed_array_size' => 334
		}
	},
	{#State 335
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 403,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'primary_expr' => 290,
			'and_expr' => 291,
			'scoped_name' => 273,
			'positive_int_const' => 402,
			'wide_string_literal' => 275,
			'boolean_literal' => 277,
			'mult_expr' => 293,
			'const_exp' => 278,
			'or_expr' => 279,
			'unary_expr' => 297,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 336
		DEFAULT => -79
	},
	{#State 337
		DEFAULT => -306
	},
	{#State 338
		DEFAULT => -305
	},
	{#State 339
		DEFAULT => -289
	},
	{#State 340
		ACTIONS => {
			'error' => 404,
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarators' => 406,
			'simple_declarator' => 405
		}
	},
	{#State 341
		DEFAULT => -320
	},
	{#State 342
		ACTIONS => {
			")" => 407
		}
	},
	{#State 343
		DEFAULT => -322
	},
	{#State 344
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
			'wide_string_type' => 231,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 227,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 228,
			'base_type_spec' => 229,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'unsigned_long_int' => 92,
			'param_type_spec' => 408,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 345
		ACTIONS => {
			")" => 409
		}
	},
	{#State 346
		DEFAULT => -313
	},
	{#State 347
		DEFAULT => -321
	},
	{#State 348
		ACTIONS => {
			";" => 410,
			"," => 411
		},
		DEFAULT => -315
	},
	{#State 349
		ACTIONS => {
			'error' => 413,
			"(" => 412
		}
	},
	{#State 350
		ACTIONS => {
			'CONTEXT' => 349
		},
		DEFAULT => -301,
		GOTOS => {
			'context_expr' => 414
		}
	},
	{#State 351
		DEFAULT => -303
	},
	{#State 352
		ACTIONS => {
			'error' => 416,
			"(" => 415
		}
	},
	{#State 353
		ACTIONS => {
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 251,
			'value_name' => 252,
			'value_names' => 417
		}
	},
	{#State 354
		DEFAULT => -89
	},
	{#State 355
		ACTIONS => {
			'SUPPORTS' => 418
		},
		DEFAULT => -84
	},
	{#State 356
		ACTIONS => {
			'error' => 419,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 256,
			'interface_names' => 420,
			'interface_name' => 258
		}
	},
	{#State 357
		ACTIONS => {
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 256,
			'interface_names' => 421,
			'interface_name' => 258
		}
	},
	{#State 358
		DEFAULT => -236
	},
	{#State 359
		DEFAULT => -237
	},
	{#State 360
		DEFAULT => -267
	},
	{#State 361
		DEFAULT => -276
	},
	{#State 362
		ACTIONS => {
			")" => 422
		}
	},
	{#State 363
		ACTIONS => {
			")" => 423
		}
	},
	{#State 364
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 293,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'and_expr' => 291,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'xor_expr' => 424,
			'shift_expr' => 282,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 365
		DEFAULT => -278
	},
	{#State 366
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 293,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'and_expr' => 425,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'shift_expr' => 282,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 367
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 293,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 426
		}
	},
	{#State 368
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 293,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 427
		}
	},
	{#State 369
		DEFAULT => -168
	},
	{#State 370
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 428,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300
		}
	},
	{#State 371
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 429,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300
		}
	},
	{#State 372
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 293,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'shift_expr' => 430,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 373
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'unary_expr' => 431,
			'scoped_name' => 273,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300
		}
	},
	{#State 374
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'unary_expr' => 432,
			'scoped_name' => 273,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300
		}
	},
	{#State 375
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'CHARACTER_LITERAL' => 271,
			"+" => 296,
			'FIXED_PT_LITERAL' => 295,
			'WIDE_CHARACTER_LITERAL' => 272,
			"-" => 298,
			"::" => 86,
			'FALSE' => 283,
			'WIDE_STRING_LITERAL' => 284,
			'INTEGER_LITERAL' => 292,
			"~" => 299,
			"(" => 276,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'unary_expr' => 433,
			'scoped_name' => 273,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300
		}
	},
	{#State 376
		DEFAULT => -166
	},
	{#State 377
		DEFAULT => -148
	},
	{#State 378
		DEFAULT => -279
	},
	{#State 379
		DEFAULT => -281
	},
	{#State 380
		DEFAULT => -116
	},
	{#State 381
		DEFAULT => -117
	},
	{#State 382
		DEFAULT => -241
	},
	{#State 383
		ACTIONS => {
			"{" => 435,
			'error' => 434
		}
	},
	{#State 384
		DEFAULT => -48
	},
	{#State 385
		DEFAULT => -47
	},
	{#State 386
		ACTIONS => {
			";" => 436
		}
	},
	{#State 387
		ACTIONS => {
			";" => 437
		}
	},
	{#State 388
		DEFAULT => -101
	},
	{#State 389
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
			'wide_string_type' => 231,
			'integer_type' => 130,
			'boolean_type' => 129,
			'char_type' => 113,
			'value_base_type' => 112,
			'object_type' => 114,
			'octet_type' => 115,
			'scoped_name' => 227,
			'wide_char_type' => 117,
			'signed_long_int' => 67,
			'signed_short_int' => 87,
			'string_type' => 228,
			'base_type_spec' => 229,
			'unsigned_longlong_int' => 72,
			'any_type' => 121,
			'unsigned_long_int' => 92,
			'param_type_spec' => 438,
			'unsigned_short_int' => 75,
			'signed_longlong_int' => 77
		}
	},
	{#State 390
		ACTIONS => {
			")" => 439
		}
	},
	{#State 391
		DEFAULT => -115
	},
	{#State 392
		ACTIONS => {
			"," => 440
		},
		DEFAULT => -112
	},
	{#State 393
		ACTIONS => {
			")" => 441
		}
	},
	{#State 394
		ACTIONS => {
			";" => 442
		}
	},
	{#State 395
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 444,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'primary_expr' => 290,
			'and_expr' => 291,
			'scoped_name' => 273,
			'positive_int_const' => 443,
			'wide_string_literal' => 275,
			'boolean_literal' => 277,
			'mult_expr' => 293,
			'const_exp' => 278,
			'or_expr' => 279,
			'unary_expr' => 297,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 396
		DEFAULT => -340
	},
	{#State 397
		DEFAULT => -274
	},
	{#State 398
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 446,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'string_literal' => 288,
			'primary_expr' => 290,
			'and_expr' => 291,
			'scoped_name' => 273,
			'positive_int_const' => 445,
			'wide_string_literal' => 275,
			'boolean_literal' => 277,
			'mult_expr' => 293,
			'const_exp' => 278,
			'or_expr' => 279,
			'unary_expr' => 297,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 399
		DEFAULT => -273
	},
	{#State 400
		DEFAULT => -203
	},
	{#State 401
		DEFAULT => -284
	},
	{#State 402
		ACTIONS => {
			"]" => 447
		}
	},
	{#State 403
		ACTIONS => {
			"]" => 448
		}
	},
	{#State 404
		DEFAULT => -288
	},
	{#State 405
		ACTIONS => {
			"," => 449
		},
		DEFAULT => -292
	},
	{#State 406
		DEFAULT => -287
	},
	{#State 407
		DEFAULT => -314
	},
	{#State 408
		ACTIONS => {
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarator' => 450
		}
	},
	{#State 409
		DEFAULT => -312
	},
	{#State 410
		DEFAULT => -318
	},
	{#State 411
		ACTIONS => {
			'OUT' => 347,
			'INOUT' => 343,
			'IN' => 341
		},
		DEFAULT => -317,
		GOTOS => {
			'param_dcl' => 348,
			'param_dcls' => 451,
			'param_attribute' => 344
		}
	},
	{#State 412
		ACTIONS => {
			'error' => 452,
			'STRING_LITERAL' => 294
		},
		GOTOS => {
			'string_literal' => 453,
			'string_literals' => 454
		}
	},
	{#State 413
		DEFAULT => -331
	},
	{#State 414
		DEFAULT => -302
	},
	{#State 415
		ACTIONS => {
			'error' => 456,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 455,
			'exception_names' => 457,
			'exception_name' => 458
		}
	},
	{#State 416
		DEFAULT => -325
	},
	{#State 417
		DEFAULT => -94
	},
	{#State 418
		ACTIONS => {
			'error' => 459,
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 256,
			'interface_names' => 460,
			'interface_name' => 258
		}
	},
	{#State 419
		DEFAULT => -87
	},
	{#State 420
		DEFAULT => -85
	},
	{#State 421
		DEFAULT => -50
	},
	{#State 422
		DEFAULT => -155
	},
	{#State 423
		DEFAULT => -156
	},
	{#State 424
		ACTIONS => {
			"^" => 366
		},
		DEFAULT => -133
	},
	{#State 425
		ACTIONS => {
			"&" => 372
		},
		DEFAULT => -135
	},
	{#State 426
		ACTIONS => {
			"+" => 370,
			"-" => 371
		},
		DEFAULT => -140
	},
	{#State 427
		ACTIONS => {
			"+" => 370,
			"-" => 371
		},
		DEFAULT => -139
	},
	{#State 428
		ACTIONS => {
			"%" => 374,
			"*" => 373,
			"/" => 375
		},
		DEFAULT => -142
	},
	{#State 429
		ACTIONS => {
			"%" => 374,
			"*" => 373,
			"/" => 375
		},
		DEFAULT => -143
	},
	{#State 430
		ACTIONS => {
			"<<" => 367,
			">>" => 368
		},
		DEFAULT => -137
	},
	{#State 431
		DEFAULT => -145
	},
	{#State 432
		DEFAULT => -147
	},
	{#State 433
		DEFAULT => -146
	},
	{#State 434
		DEFAULT => -240
	},
	{#State 435
		ACTIONS => {
			'error' => 464,
			'CASE' => 461,
			'DEFAULT' => 463
		},
		GOTOS => {
			'case_labels' => 466,
			'switch_body' => 465,
			'case' => 462,
			'case_label' => 467
		}
	},
	{#State 436
		DEFAULT => -99
	},
	{#State 437
		DEFAULT => -100
	},
	{#State 438
		ACTIONS => {
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarator' => 468
		}
	},
	{#State 439
		ACTIONS => {
			'error' => 470,
			";" => 469
		}
	},
	{#State 440
		ACTIONS => {
			'IN' => 391
		},
		GOTOS => {
			'init_param_decls' => 471,
			'init_param_attribute' => 389,
			'init_param_decl' => 392
		}
	},
	{#State 441
		ACTIONS => {
			'error' => 473,
			";" => 472
		}
	},
	{#State 442
		DEFAULT => -104
	},
	{#State 443
		ACTIONS => {
			">" => 474
		}
	},
	{#State 444
		ACTIONS => {
			">" => 475
		}
	},
	{#State 445
		ACTIONS => {
			">" => 476
		}
	},
	{#State 446
		ACTIONS => {
			">" => 477
		}
	},
	{#State 447
		DEFAULT => -285
	},
	{#State 448
		DEFAULT => -286
	},
	{#State 449
		ACTIONS => {
			'IDENTIFIER' => 104
		},
		GOTOS => {
			'simple_declarators' => 478,
			'simple_declarator' => 405
		}
	},
	{#State 450
		DEFAULT => -319
	},
	{#State 451
		DEFAULT => -316
	},
	{#State 452
		ACTIONS => {
			")" => 479
		}
	},
	{#State 453
		ACTIONS => {
			"," => 480
		},
		DEFAULT => -332
	},
	{#State 454
		ACTIONS => {
			")" => 481
		}
	},
	{#State 455
		ACTIONS => {
			"::" => 177
		},
		DEFAULT => -328
	},
	{#State 456
		ACTIONS => {
			")" => 482
		}
	},
	{#State 457
		ACTIONS => {
			")" => 483
		}
	},
	{#State 458
		ACTIONS => {
			"," => 484
		},
		DEFAULT => -326
	},
	{#State 459
		DEFAULT => -88
	},
	{#State 460
		DEFAULT => -86
	},
	{#State 461
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 289,
			'CHARACTER_LITERAL' => 271,
			'WIDE_CHARACTER_LITERAL' => 272,
			"::" => 86,
			'INTEGER_LITERAL' => 292,
			"(" => 276,
			'IDENTIFIER' => 91,
			'STRING_LITERAL' => 294,
			'FIXED_PT_LITERAL' => 295,
			"+" => 296,
			'error' => 486,
			"-" => 298,
			'WIDE_STRING_LITERAL' => 284,
			'FALSE' => 283,
			"~" => 299,
			'TRUE' => 286
		},
		GOTOS => {
			'mult_expr' => 293,
			'string_literal' => 288,
			'boolean_literal' => 277,
			'primary_expr' => 290,
			'const_exp' => 485,
			'and_expr' => 291,
			'or_expr' => 279,
			'unary_expr' => 297,
			'scoped_name' => 273,
			'xor_expr' => 281,
			'shift_expr' => 282,
			'wide_string_literal' => 275,
			'literal' => 285,
			'unary_operator' => 300,
			'add_expr' => 287
		}
	},
	{#State 462
		ACTIONS => {
			'CASE' => 461,
			'DEFAULT' => 463
		},
		DEFAULT => -249,
		GOTOS => {
			'case_labels' => 466,
			'switch_body' => 487,
			'case' => 462,
			'case_label' => 467
		}
	},
	{#State 463
		ACTIONS => {
			'error' => 488,
			":" => 489
		}
	},
	{#State 464
		ACTIONS => {
			"}" => 490
		}
	},
	{#State 465
		ACTIONS => {
			"}" => 491
		}
	},
	{#State 466
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
			'type_spec' => 492,
			'string_type' => 120,
			'struct_header' => 11,
			'element_spec' => 493,
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
	{#State 467
		ACTIONS => {
			'CASE' => 461,
			'DEFAULT' => 463
		},
		DEFAULT => -253,
		GOTOS => {
			'case_labels' => 494,
			'case_label' => 467
		}
	},
	{#State 468
		DEFAULT => -114
	},
	{#State 469
		DEFAULT => -105
	},
	{#State 470
		DEFAULT => -106
	},
	{#State 471
		DEFAULT => -113
	},
	{#State 472
		DEFAULT => -107
	},
	{#State 473
		DEFAULT => -108
	},
	{#State 474
		DEFAULT => -338
	},
	{#State 475
		DEFAULT => -339
	},
	{#State 476
		DEFAULT => -271
	},
	{#State 477
		DEFAULT => -272
	},
	{#State 478
		DEFAULT => -293
	},
	{#State 479
		DEFAULT => -330
	},
	{#State 480
		ACTIONS => {
			'STRING_LITERAL' => 294
		},
		GOTOS => {
			'string_literal' => 453,
			'string_literals' => 495
		}
	},
	{#State 481
		DEFAULT => -329
	},
	{#State 482
		DEFAULT => -324
	},
	{#State 483
		DEFAULT => -323
	},
	{#State 484
		ACTIONS => {
			'IDENTIFIER' => 91,
			"::" => 86
		},
		GOTOS => {
			'scoped_name' => 455,
			'exception_names' => 496,
			'exception_name' => 458
		}
	},
	{#State 485
		ACTIONS => {
			'error' => 497,
			":" => 498
		}
	},
	{#State 486
		DEFAULT => -257
	},
	{#State 487
		DEFAULT => -250
	},
	{#State 488
		DEFAULT => -259
	},
	{#State 489
		DEFAULT => -258
	},
	{#State 490
		DEFAULT => -239
	},
	{#State 491
		DEFAULT => -238
	},
	{#State 492
		ACTIONS => {
			'IDENTIFIER' => 221
		},
		GOTOS => {
			'declarator' => 499,
			'simple_declarator' => 219,
			'array_declarator' => 220,
			'complex_declarator' => 218
		}
	},
	{#State 493
		ACTIONS => {
			'error' => 501,
			";" => 500
		}
	},
	{#State 494
		DEFAULT => -254
	},
	{#State 495
		DEFAULT => -333
	},
	{#State 496
		DEFAULT => -327
	},
	{#State 497
		DEFAULT => -256
	},
	{#State 498
		DEFAULT => -255
	},
	{#State 499
		DEFAULT => -260
	},
	{#State 500
		DEFAULT => -251
	},
	{#State 501
		DEFAULT => -252
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
			$_[0]->Error("Empty specification\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 79 "parser23.yp"
{
			$_[0]->Error("definition declaration excepted.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 85 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 86 "parser23.yp"
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
#line 98 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 104 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 110 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 116 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'definition', 2,
sub
#line 122 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 17
		 'definition', 2,
sub
#line 128 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 18
		 'module', 4,
sub
#line 138 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->configure('list_decl' => $_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 19
		 'module', 4,
sub
#line 144 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'module', 2,
sub
#line 150 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'module_header', 2,
sub
#line 159 "parser23.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 22
		 'module_header', 2,
sub
#line 165 "parser23.yp"
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
#line 180 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[]);
		}
	],
	[#Rule 26
		 'interface_dcl', 4,
sub
#line 186 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3]);
		}
	],
	[#Rule 27
		 'interface_dcl', 4,
sub
#line 192 "parser23.yp"
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
#line 203 "parser23.yp"
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
#line 210 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
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
#line 224 "parser23.yp"
{
			new Interface($_[0],
					'modifier'				=>	$_[1],
					'idf'					=>	$_[3]
			);
		}
	],
	[#Rule 33
		 'interface_header', 4,
sub
#line 231 "parser23.yp"
{
			new Interface($_[0],
					'modifier'				=>	$_[1],
					'idf'					=>	$_[3],
					'list_inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 34
		 'interface_body', 1, undef
	],
	[#Rule 35
		 'exports', 1,
sub
#line 246 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 36
		 'exports', 2,
sub
#line 247 "parser23.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 37
		 'export', 2, undef
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
		 'export', 2,
sub
#line 258 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'export', 2,
sub
#line 264 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 44
		 'export', 2,
sub
#line 270 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 45
		 'export', 2,
sub
#line 276 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 46
		 'export', 2,
sub
#line 282 "parser23.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 47
		 'interface_inheritance_spec', 2,
sub
#line 291 "parser23.yp"
{ $_[2]; }
	],
	[#Rule 48
		 'interface_inheritance_spec', 2,
sub
#line 293 "parser23.yp"
{
			$_[0]->Error("Interface name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 49
		 'interface_names', 1,
sub
#line 300 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 50
		 'interface_names', 3,
sub
#line 301 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 51
		 'interface_name', 1,
sub
#line 307 "parser23.yp"
{
				Interface->Lookup($_[0],$_[1])
		}
	],
	[#Rule 52
		 'scoped_name', 1, undef
	],
	[#Rule 53
		 'scoped_name', 2,
sub
#line 316 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 54
		 'scoped_name', 2,
sub
#line 320 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 55
		 'scoped_name', 3,
sub
#line 326 "parser23.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 56
		 'scoped_name', 3,
sub
#line 330 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 57
		 'value', 1, undef
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
		 'value_forward_dcl', 2,
sub
#line 348 "parser23.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 62
		 'value_forward_dcl', 3,
sub
#line 354 "parser23.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 63
		 'value_box_dcl', 3,
sub
#line 364 "parser23.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
					'expr'				=>	$_[3]
			);
		}
	],
	[#Rule 64
		 'value_abs_dcl', 3,
sub
#line 375 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[])
					if (defined $_[1]);
		}
	],
	[#Rule 65
		 'value_abs_dcl', 4,
sub
#line 382 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 66
		 'value_abs_dcl', 4,
sub
#line 389 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 67
		 'value_abs_header', 3,
sub
#line 399 "parser23.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 68
		 'value_abs_header', 4,
sub
#line 405 "parser23.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 69
		 'value_abs_header', 3,
sub
#line 412 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 70
		 'value_abs_header', 2,
sub
#line 417 "parser23.yp"
{
			$_[0]->Error("'valuetype' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 71
		 'value_dcl', 3,
sub
#line 426 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[])
					if (defined $_[1]);
		}
	],
	[#Rule 72
		 'value_dcl', 4,
sub
#line 433 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 73
		 'value_dcl', 4,
sub
#line 440 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 74
		 'value_elements', 1,
sub
#line 449 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 75
		 'value_elements', 2,
sub
#line 450 "parser23.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 76
		 'value_header', 2,
sub
#line 456 "parser23.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 77
		 'value_header', 3,
sub
#line 462 "parser23.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 78
		 'value_header', 3,
sub
#line 469 "parser23.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 79
		 'value_header', 4,
sub
#line 476 "parser23.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 80
		 'value_header', 2,
sub
#line 484 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 81
		 'value_header', 3,
sub
#line 489 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 82
		 'value_header', 2,
sub
#line 494 "parser23.yp"
{
			$_[0]->Error("valuetype excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 83
		 'value_inheritance_spec', 2,
sub
#line 503 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_value'			=>	$_[2]
			);
		}
	],
	[#Rule 84
		 'value_inheritance_spec', 3,
sub
#line 509 "parser23.yp"
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
#line 516 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_value'		=>	$_[2],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 86
		 'value_inheritance_spec', 5,
sub
#line 523 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[5]
			);
		}
	],
	[#Rule 87
		 'value_inheritance_spec', 4,
sub
#line 531 "parser23.yp"
{
			$_[0]->Error("interface_name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 88
		 'value_inheritance_spec', 5,
sub
#line 536 "parser23.yp"
{
			$_[0]->Error("interface_name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 89
		 'value_inheritance_spec', 3,
sub
#line 541 "parser23.yp"
{
			$_[0]->Error("value_name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 90
		 'value_inheritance_spec', 2,
sub
#line 546 "parser23.yp"
{
			$_[0]->Error("'truncatable' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 91
		 'value_inheritance_spec', 2,
sub
#line 551 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[2]
			);
		}
	],
	[#Rule 92
		 'value_inheritance_spec', 2,
sub
#line 557 "parser23.yp"
{
			$_[0]->Error("interface_name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 93
		 'value_names', 1,
sub
#line 564 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 94
		 'value_names', 3,
sub
#line 565 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 95
		 'value_name', 1,
sub
#line 571 "parser23.yp"
{
			RegularValue->Lookup($_[0],$_[1]);
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
#line 586 "parser23.yp"
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
#line 594 "parser23.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 101
		 'state_member', 3,
sub
#line 599 "parser23.yp"
{
			$_[0]->Error("type_spec excepted.\n");
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
		 'init_dcl', 4, undef
	],
	[#Rule 105
		 'init_dcl', 5,
sub
#line 614 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 106
		 'init_dcl', 5,
sub
#line 622 "parser23.yp"
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
	[#Rule 107
		 'init_dcl', 5,
sub
#line 632 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 108
		 'init_dcl', 5,
sub
#line 639 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 109
		 'init_dcl', 2,
sub
#line 646 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 110
		 'init_header', 2,
sub
#line 656 "parser23.yp"
{
			new Factory($_[0],							# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 111
		 'init_header', 2,
sub
#line 662 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'init_param_decls', 1,
sub
#line 670 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 113
		 'init_param_decls', 3,
sub
#line 672 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 114
		 'init_param_decl', 3,
sub
#line 678 "parser23.yp"
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
#line 695 "parser23.yp"
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
#line 703 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 118
		 'const_dcl', 4,
sub
#line 708 "parser23.yp"
{
			$_[0]->Error("'=' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'const_dcl', 3,
sub
#line 713 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 120
		 'const_dcl', 2,
sub
#line 718 "parser23.yp"
{
			$_[0]->Error("const_type excepted.\n");
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
#line 735 "parser23.yp"
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
#line 750 "parser23.yp"
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
#line 759 "parser23.yp"
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
#line 768 "parser23.yp"
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
#line 777 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 140
		 'shift_expr', 3,
sub
#line 781 "parser23.yp"
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
#line 790 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 143
		 'add_expr', 3,
sub
#line 794 "parser23.yp"
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
#line 803 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 146
		 'mult_expr', 3,
sub
#line 807 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'mult_expr', 3,
sub
#line 811 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 148
		 'unary_expr', 2,
sub
#line 819 "parser23.yp"
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
#line 835 "parser23.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 154
		 'primary_expr', 1,
sub
#line 841 "parser23.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 155
		 'primary_expr', 3,
sub
#line 845 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 156
		 'primary_expr', 3,
sub
#line 849 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 157
		 'literal', 1,
sub
#line 858 "parser23.yp"
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
#line 865 "parser23.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 159
		 'literal', 1,
sub
#line 871 "parser23.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 877 "parser23.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 883 "parser23.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 889 "parser23.yp"
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
#line 896 "parser23.yp"
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
#line 907 "parser23.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 167
		 'wide_string_literal', 1, undef
	],
	[#Rule 168
		 'wide_string_literal', 2,
sub
#line 913 "parser23.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 169
		 'boolean_literal', 1,
sub
#line 919 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 170
		 'boolean_literal', 1,
sub
#line 925 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 171
		 'positive_int_const', 1,
sub
#line 935 "parser23.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 172
		 'type_dcl', 2,
sub
#line 946 "parser23.yp"
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
#line 953 "parser23.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 177
		 'type_dcl', 2,
sub
#line 960 "parser23.yp"
{
			$_[0]->Error("type_declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'type_dcl', 2,
sub
#line 965 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 179
		 'type_declarator', 2,
sub
#line 974 "parser23.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 180
		 'type_declarator', 2,
sub
#line 981 "parser23.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 181
		 'type_spec', 1, undef
	],
	[#Rule 182
		 'type_spec', 1, undef
	],
	[#Rule 183
		 'simple_type_spec', 1, undef
	],
	[#Rule 184
		 'simple_type_spec', 1, undef
	],
	[#Rule 185
		 'simple_type_spec', 1,
sub
#line 998 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
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
		 'base_type_spec', 1, undef
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
		 'template_type_spec', 1, undef
	],
	[#Rule 199
		 'constr_type_spec', 1, undef
	],
	[#Rule 200
		 'constr_type_spec', 1, undef
	],
	[#Rule 201
		 'constr_type_spec', 1, undef
	],
	[#Rule 202
		 'declarators', 1,
sub
#line 1033 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 203
		 'declarators', 3,
sub
#line 1034 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 204
		 'declarator', 1,
sub
#line 1039 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 205
		 'declarator', 1, undef
	],
	[#Rule 206
		 'simple_declarator', 1, undef
	],
	[#Rule 207
		 'complex_declarator', 1, undef
	],
	[#Rule 208
		 'floating_pt_type', 1,
sub
#line 1056 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 209
		 'floating_pt_type', 1,
sub
#line 1062 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 210
		 'floating_pt_type', 2,
sub
#line 1068 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 211
		 'integer_type', 1, undef
	],
	[#Rule 212
		 'integer_type', 1, undef
	],
	[#Rule 213
		 'signed_int', 1, undef
	],
	[#Rule 214
		 'signed_int', 1, undef
	],
	[#Rule 215
		 'signed_int', 1, undef
	],
	[#Rule 216
		 'signed_short_int', 1,
sub
#line 1091 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 217
		 'signed_long_int', 1,
sub
#line 1101 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 218
		 'signed_longlong_int', 2,
sub
#line 1111 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 219
		 'unsigned_int', 1, undef
	],
	[#Rule 220
		 'unsigned_int', 1, undef
	],
	[#Rule 221
		 'unsigned_int', 1, undef
	],
	[#Rule 222
		 'unsigned_short_int', 2,
sub
#line 1128 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 223
		 'unsigned_long_int', 2,
sub
#line 1138 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 224
		 'unsigned_longlong_int', 3,
sub
#line 1148 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 225
		 'char_type', 1,
sub
#line 1158 "parser23.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 226
		 'wide_char_type', 1,
sub
#line 1168 "parser23.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 227
		 'boolean_type', 1,
sub
#line 1178 "parser23.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 228
		 'octet_type', 1,
sub
#line 1188 "parser23.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 229
		 'any_type', 1,
sub
#line 1198 "parser23.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'object_type', 1,
sub
#line 1208 "parser23.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 231
		 'struct_type', 4,
sub
#line 1218 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 232
		 'struct_type', 4,
sub
#line 1225 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'struct_header', 2,
sub
#line 1234 "parser23.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 234
		 'member_list', 1,
sub
#line 1243 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 235
		 'member_list', 2,
sub
#line 1244 "parser23.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 236
		 'member', 3,
sub
#line 1250 "parser23.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 237
		 'member', 3,
sub
#line 1257 "parser23.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 238
		 'union_type', 8,
sub
#line 1270 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			);
		}
	],
	[#Rule 239
		 'union_type', 8,
sub
#line 1278 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 240
		 'union_type', 6,
sub
#line 1284 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 241
		 'union_type', 5,
sub
#line 1290 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'union_type', 3,
sub
#line 1296 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'union_header', 2,
sub
#line 1305 "parser23.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
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
		 'switch_type_spec', 1, undef
	],
	[#Rule 248
		 'switch_type_spec', 1,
sub
#line 1319 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 249
		 'switch_body', 1,
sub
#line 1326 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 250
		 'switch_body', 2,
sub
#line 1327 "parser23.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 251
		 'case', 3,
sub
#line 1333 "parser23.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 252
		 'case', 3,
sub
#line 1340 "parser23.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 253
		 'case_labels', 1,
sub
#line 1351 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 254
		 'case_labels', 2,
sub
#line 1352 "parser23.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 255
		 'case_label', 3,
sub
#line 1358 "parser23.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 256
		 'case_label', 3,
sub
#line 1362 "parser23.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 257
		 'case_label', 2,
sub
#line 1368 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 258
		 'case_label', 2,
sub
#line 1373 "parser23.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 259
		 'case_label', 2,
sub
#line 1377 "parser23.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 260
		 'element_spec', 2,
sub
#line 1387 "parser23.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 261
		 'enum_type', 4,
sub
#line 1398 "parser23.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 262
		 'enum_type', 4,
sub
#line 1405 "parser23.yp"
{
			$_[0]->Error("enumerator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 263
		 'enum_type', 2,
sub
#line 1410 "parser23.yp"
{
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 264
		 'enum_header', 2,
sub
#line 1418 "parser23.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 265
		 'enum_header', 2,
sub
#line 1424 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'enumerators', 1,
sub
#line 1431 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 267
		 'enumerators', 3,
sub
#line 1432 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 268
		 'enumerators', 2,
sub
#line 1434 "parser23.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 269
		 'enumerators', 2,
sub
#line 1439 "parser23.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 270
		 'enumerator', 1,
sub
#line 1448 "parser23.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 271
		 'sequence_type', 6,
sub
#line 1458 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 272
		 'sequence_type', 6,
sub
#line 1466 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 273
		 'sequence_type', 4,
sub
#line 1471 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 274
		 'sequence_type', 4,
sub
#line 1478 "parser23.yp"
{
			$_[0]->Error("simple_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 275
		 'sequence_type', 2,
sub
#line 1483 "parser23.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 276
		 'string_type', 4,
sub
#line 1492 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 277
		 'string_type', 1,
sub
#line 1499 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 278
		 'string_type', 4,
sub
#line 1505 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'wide_string_type', 4,
sub
#line 1514 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 280
		 'wide_string_type', 1,
sub
#line 1521 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 281
		 'wide_string_type', 4,
sub
#line 1527 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 282
		 'array_declarator', 2,
sub
#line 1535 "parser23.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 283
		 'fixed_array_sizes', 1,
sub
#line 1539 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 284
		 'fixed_array_sizes', 2,
sub
#line 1541 "parser23.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 285
		 'fixed_array_size', 3,
sub
#line 1546 "parser23.yp"
{ $_[2]; }
	],
	[#Rule 286
		 'fixed_array_size', 3,
sub
#line 1548 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 287
		 'attr_dcl', 4,
sub
#line 1557 "parser23.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 288
		 'attr_dcl', 4,
sub
#line 1565 "parser23.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 289
		 'attr_dcl', 3,
sub
#line 1570 "parser23.yp"
{
			$_[0]->Error("type excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 290
		 'attr_mod', 1, undef
	],
	[#Rule 291
		 'attr_mod', 0, undef
	],
	[#Rule 292
		 'simple_declarators', 1,
sub
#line 1582 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 293
		 'simple_declarators', 3,
sub
#line 1584 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 294
		 'except_dcl', 3,
sub
#line 1590 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 295
		 'except_dcl', 4,
sub
#line 1595 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 296
		 'except_dcl', 4,
sub
#line 1603 "parser23.yp"
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
	[#Rule 297
		 'except_dcl', 2,
sub
#line 1613 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 298
		 'exception_header', 2,
sub
#line 1622 "parser23.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 299
		 'exception_header', 2,
sub
#line 1628 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 300
		 'op_dcl', 2,
sub
#line 1637 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 301
		 'op_dcl', 3,
sub
#line 1646 "parser23.yp"
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
	[#Rule 302
		 'op_dcl', 4,
sub
#line 1656 "parser23.yp"
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
	[#Rule 303
		 'op_dcl', 3,
sub
#line 1667 "parser23.yp"
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
	[#Rule 304
		 'op_dcl', 2,
sub
#line 1677 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 305
		 'op_header', 3,
sub
#line 1687 "parser23.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 306
		 'op_header', 3,
sub
#line 1695 "parser23.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 307
		 'op_mod', 1, undef
	],
	[#Rule 308
		 'op_mod', 0, undef
	],
	[#Rule 309
		 'op_attribute', 1, undef
	],
	[#Rule 310
		 'op_type_spec', 1, undef
	],
	[#Rule 311
		 'op_type_spec', 1,
sub
#line 1715 "parser23.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 312
		 'parameter_dcls', 3,
sub
#line 1725 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 313
		 'parameter_dcls', 2,
sub
#line 1729 "parser23.yp"
{
			undef;
		}
	],
	[#Rule 314
		 'parameter_dcls', 3,
sub
#line 1733 "parser23.yp"
{
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 315
		 'param_dcls', 1,
sub
#line 1740 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 316
		 'param_dcls', 3,
sub
#line 1741 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 317
		 'param_dcls', 2,
sub
#line 1743 "parser23.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 318
		 'param_dcls', 2,
sub
#line 1748 "parser23.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 319
		 'param_dcl', 3,
sub
#line 1757 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
        }
	],
	[#Rule 320
		 'param_attribute', 1, undef
	],
	[#Rule 321
		 'param_attribute', 1, undef
	],
	[#Rule 322
		 'param_attribute', 1, undef
	],
	[#Rule 323
		 'raises_expr', 4,
sub
#line 1776 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 324
		 'raises_expr', 4,
sub
#line 1780 "parser23.yp"
{
			$_[0]->Error("name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 325
		 'raises_expr', 2,
sub
#line 1785 "parser23.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 326
		 'exception_names', 1,
sub
#line 1792 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 327
		 'exception_names', 3,
sub
#line 1793 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 328
		 'exception_name', 1,
sub
#line 1798 "parser23.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 329
		 'context_expr', 4,
sub
#line 1806 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 330
		 'context_expr', 4,
sub
#line 1810 "parser23.yp"
{
			$_[0]->Error("string excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 331
		 'context_expr', 2,
sub
#line 1815 "parser23.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 332
		 'string_literals', 1,
sub
#line 1822 "parser23.yp"
{ [$_[1]]; }
	],
	[#Rule 333
		 'string_literals', 3,
sub
#line 1823 "parser23.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 334
		 'param_type_spec', 1, undef
	],
	[#Rule 335
		 'param_type_spec', 1, undef
	],
	[#Rule 336
		 'param_type_spec', 1, undef
	],
	[#Rule 337
		 'param_type_spec', 1,
sub
#line 1832 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 338
		 'fixed_pt_type', 6,
sub
#line 1840 "parser23.yp"
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
#line 1848 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 340
		 'fixed_pt_type', 4,
sub
#line 1853 "parser23.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 341
		 'fixed_pt_type', 2,
sub
#line 1858 "parser23.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 342
		 'fixed_pt_const_type', 1,
sub
#line 1867 "parser23.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 343
		 'value_base_type', 1,
sub
#line 1877 "parser23.yp"
{
			new ValueBaseType($_[0]
					'value'				=>	$_[1]
			);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1884 "parser23.yp"


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
