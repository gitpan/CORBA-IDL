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
			'NATIVE' => 28,
			'ABSTRACT' => 2,
			'STRUCT' => 30,
			'VALUETYPE' => 9,
			'TYPEDEF' => 33,
			'MODULE' => 12,
			'IDENTIFIER' => 35,
			'UNION' => 36,
			'error' => 17,
			'CONST' => 19,
			'EXCEPTION' => 21,
			'CUSTOM' => 39,
			'ENUM' => 24,
			'INTERFACE' => -32
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
			'module' => 37,
			'enum_header' => 18,
			'value_abs_dcl' => 20,
			'type_dcl' => 38,
			'union_header' => 22,
			'definitions' => 23,
			'definition' => 40,
			'interface_mod' => 25
		}
	},
	{#State 1
		DEFAULT => -62
	},
	{#State 2
		ACTIONS => {
			'error' => 42,
			'VALUETYPE' => 41,
			'INTERFACE' => -31
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 44,
			";" => 43
		}
	},
	{#State 4
		ACTIONS => {
			'' => 45
		}
	},
	{#State 5
		ACTIONS => {
			"{" => 47,
			'error' => 46
		}
	},
	{#State 6
		ACTIONS => {
			'error' => 49,
			";" => 48
		}
	},
	{#State 7
		DEFAULT => -61
	},
	{#State 8
		ACTIONS => {
			"{" => 50
		}
	},
	{#State 9
		ACTIONS => {
			'error' => 51,
			'IDENTIFIER' => 52
		}
	},
	{#State 10
		DEFAULT => -59
	},
	{#State 11
		ACTIONS => {
			"{" => 53
		}
	},
	{#State 12
		ACTIONS => {
			'error' => 54,
			'IDENTIFIER' => 55
		}
	},
	{#State 13
		DEFAULT => -24
	},
	{#State 14
		ACTIONS => {
			'error' => 57,
			";" => 56
		}
	},
	{#State 15
		DEFAULT => -175
	},
	{#State 16
		DEFAULT => -25
	},
	{#State 17
		DEFAULT => -3
	},
	{#State 18
		ACTIONS => {
			"{" => 59,
			'error' => 58
		}
	},
	{#State 19
		ACTIONS => {
			'CHAR' => 79,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'FIXED' => 62,
			'WCHAR' => 72,
			'DOUBLE' => 83,
			'error' => 74,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'OCTET' => 75,
			'FLOAT' => 77,
			'WSTRING' => 89,
			'UNSIGNED' => 69
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 61,
			'signed_int' => 63,
			'wide_string_type' => 80,
			'integer_type' => 82,
			'boolean_type' => 81,
			'char_type' => 64,
			'octet_type' => 65,
			'scoped_name' => 66,
			'fixed_pt_const_type' => 86,
			'wide_char_type' => 67,
			'signed_long_int' => 68,
			'signed_short_int' => 88,
			'const_type' => 90,
			'string_type' => 70,
			'unsigned_longlong_int' => 73,
			'unsigned_long_int' => 93,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78
		}
	},
	{#State 20
		DEFAULT => -60
	},
	{#State 21
		ACTIONS => {
			'error' => 94,
			'IDENTIFIER' => 95
		}
	},
	{#State 22
		ACTIONS => {
			'SWITCH' => 96
		}
	},
	{#State 23
		DEFAULT => -1
	},
	{#State 24
		ACTIONS => {
			'error' => 97,
			'IDENTIFIER' => 98
		}
	},
	{#State 25
		ACTIONS => {
			'INTERFACE' => 99
		}
	},
	{#State 26
		ACTIONS => {
			'error' => 101,
			";" => 100
		}
	},
	{#State 27
		ACTIONS => {
			"{" => 102
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 103,
			'IDENTIFIER' => 105
		},
		GOTOS => {
			'simple_declarator' => 104
		}
	},
	{#State 29
		ACTIONS => {
			"{" => 106
		}
	},
	{#State 30
		ACTIONS => {
			'IDENTIFIER' => 107
		}
	},
	{#State 31
		DEFAULT => -173
	},
	{#State 32
		ACTIONS => {
			"{" => 109,
			'error' => 108
		}
	},
	{#State 33
		ACTIONS => {
			'CHAR' => 79,
			'OBJECT' => 127,
			'VALUEBASE' => 128,
			'FIXED' => 111,
			'SEQUENCE' => 112,
			'STRUCT' => 30,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'UNION' => 36,
			'WCHAR' => 72,
			'error' => 125,
			'FLOAT' => 77,
			'OCTET' => 75,
			'ENUM' => 24,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'wide_char_type' => 118,
			'type_spec' => 119,
			'signed_long_int' => 68,
			'type_declarator' => 120,
			'string_type' => 121,
			'struct_header' => 11,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'base_type_spec' => 123,
			'enum_type' => 124,
			'enum_header' => 18,
			'union_header' => 22,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78,
			'wide_string_type' => 129,
			'boolean_type' => 130,
			'integer_type' => 131,
			'signed_short_int' => 88,
			'struct_type' => 132,
			'union_type' => 133,
			'sequence_type' => 134,
			'unsigned_long_int' => 93,
			'template_type_spec' => 135,
			'constr_type_spec' => 136,
			'simple_type_spec' => 137,
			'fixed_pt_type' => 138
		}
	},
	{#State 34
		DEFAULT => -174
	},
	{#State 35
		ACTIONS => {
			'error' => 139
		}
	},
	{#State 36
		ACTIONS => {
			'IDENTIFIER' => 140
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
			";" => 143
		}
	},
	{#State 39
		ACTIONS => {
			'error' => 146,
			'VALUETYPE' => 145
		}
	},
	{#State 40
		ACTIONS => {
			'NATIVE' => 28,
			'ABSTRACT' => 2,
			'STRUCT' => 30,
			'VALUETYPE' => 9,
			'TYPEDEF' => 33,
			'MODULE' => 12,
			'IDENTIFIER' => 35,
			'UNION' => 36,
			'CONST' => 19,
			'EXCEPTION' => 21,
			'CUSTOM' => 39,
			'ENUM' => 24,
			'INTERFACE' => -32
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
			'module' => 37,
			'enum_header' => 18,
			'value_abs_dcl' => 20,
			'type_dcl' => 38,
			'union_header' => 22,
			'definitions' => 147,
			'definition' => 40,
			'interface_mod' => 25
		}
	},
	{#State 41
		ACTIONS => {
			'error' => 148,
			'IDENTIFIER' => 149
		}
	},
	{#State 42
		DEFAULT => -72
	},
	{#State 43
		DEFAULT => -8
	},
	{#State 44
		DEFAULT => -14
	},
	{#State 45
		DEFAULT => 0
	},
	{#State 46
		DEFAULT => -21
	},
	{#State 47
		ACTIONS => {
			'TYPEDEF' => 33,
			'IDENTIFIER' => 35,
			'NATIVE' => 28,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 36,
			'STRUCT' => 30,
			'error' => 150,
			'CONST' => 19,
			'CUSTOM' => 39,
			'EXCEPTION' => 21,
			'VALUETYPE' => 9,
			'ENUM' => 24,
			'INTERFACE' => -32
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
			'module' => 37,
			'enum_header' => 18,
			'value_abs_dcl' => 20,
			'type_dcl' => 38,
			'union_header' => 22,
			'definitions' => 151,
			'definition' => 40,
			'interface_mod' => 25
		}
	},
	{#State 48
		DEFAULT => -9
	},
	{#State 49
		DEFAULT => -15
	},
	{#State 50
		ACTIONS => {
			'CHAR' => -308,
			'OBJECT' => -308,
			'ONEWAY' => 152,
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
			'UNION' => 36,
			'READONLY' => 163,
			'WCHAR' => -308,
			'ATTRIBUTE' => -291,
			'error' => 157,
			'CONST' => 19,
			"}" => 158,
			'EXCEPTION' => 21,
			'OCTET' => -308,
			'FLOAT' => -308,
			'ENUM' => 24,
			'ANY' => -308
		},
		GOTOS => {
			'const_dcl' => 159,
			'op_mod' => 153,
			'except_dcl' => 154,
			'op_attribute' => 155,
			'attr_mod' => 156,
			'exports' => 160,
			'export' => 161,
			'struct_type' => 31,
			'op_header' => 162,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 164,
			'enum_header' => 18,
			'attr_dcl' => 165,
			'type_dcl' => 166,
			'union_header' => 22
		}
	},
	{#State 51
		DEFAULT => -82
	},
	{#State 52
		ACTIONS => {
			'CHAR' => 79,
			'OBJECT' => 127,
			'VALUEBASE' => 128,
			'FIXED' => 111,
			'SEQUENCE' => 112,
			'STRUCT' => 30,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			":" => 169,
			'UNION' => 36,
			'WCHAR' => 72,
			"{" => -78,
			'SUPPORTS' => 170,
			'FLOAT' => 77,
			'OCTET' => 75,
			'ENUM' => 24,
			'ANY' => 126
		},
		DEFAULT => -63,
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'wide_char_type' => 118,
			'type_spec' => 167,
			'signed_long_int' => 68,
			'string_type' => 121,
			'struct_header' => 11,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'base_type_spec' => 123,
			'enum_type' => 124,
			'enum_header' => 18,
			'union_header' => 22,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78,
			'wide_string_type' => 129,
			'boolean_type' => 130,
			'integer_type' => 131,
			'signed_short_int' => 88,
			'value_inheritance_spec' => 168,
			'struct_type' => 132,
			'union_type' => 133,
			'sequence_type' => 134,
			'unsigned_long_int' => 93,
			'template_type_spec' => 135,
			'constr_type_spec' => 136,
			'simple_type_spec' => 137,
			'fixed_pt_type' => 138,
			'supported_interface_spec' => 171
		}
	},
	{#State 53
		ACTIONS => {
			'CHAR' => 79,
			'OBJECT' => 127,
			'VALUEBASE' => 128,
			'FIXED' => 111,
			'SEQUENCE' => 112,
			'STRUCT' => 30,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'UNION' => 36,
			'WCHAR' => 72,
			'error' => 173,
			'FLOAT' => 77,
			'OCTET' => 75,
			'ENUM' => 24,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'type_spec' => 172,
			'string_type' => 121,
			'struct_header' => 11,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'base_type_spec' => 123,
			'enum_type' => 124,
			'enum_header' => 18,
			'member_list' => 174,
			'union_header' => 22,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78,
			'wide_string_type' => 129,
			'boolean_type' => 130,
			'integer_type' => 131,
			'signed_short_int' => 88,
			'member' => 175,
			'struct_type' => 132,
			'union_type' => 133,
			'sequence_type' => 134,
			'unsigned_long_int' => 93,
			'template_type_spec' => 135,
			'constr_type_spec' => 136,
			'simple_type_spec' => 137,
			'fixed_pt_type' => 138
		}
	},
	{#State 54
		DEFAULT => -23
	},
	{#State 55
		DEFAULT => -22
	},
	{#State 56
		DEFAULT => -11
	},
	{#State 57
		DEFAULT => -17
	},
	{#State 58
		DEFAULT => -263
	},
	{#State 59
		ACTIONS => {
			'error' => 176,
			'IDENTIFIER' => 178
		},
		GOTOS => {
			'enumerators' => 179,
			'enumerator' => 177
		}
	},
	{#State 60
		DEFAULT => -212
	},
	{#State 61
		DEFAULT => -125
	},
	{#State 62
		DEFAULT => -342
	},
	{#State 63
		DEFAULT => -211
	},
	{#State 64
		DEFAULT => -122
	},
	{#State 65
		DEFAULT => -130
	},
	{#State 66
		ACTIONS => {
			"::" => 180
		},
		DEFAULT => -129
	},
	{#State 67
		DEFAULT => -123
	},
	{#State 68
		DEFAULT => -214
	},
	{#State 69
		ACTIONS => {
			'SHORT' => 181,
			'LONG' => 182
		}
	},
	{#State 70
		DEFAULT => -126
	},
	{#State 71
		DEFAULT => -216
	},
	{#State 72
		DEFAULT => -226
	},
	{#State 73
		DEFAULT => -221
	},
	{#State 74
		DEFAULT => -120
	},
	{#State 75
		DEFAULT => -228
	},
	{#State 76
		DEFAULT => -219
	},
	{#State 77
		DEFAULT => -208
	},
	{#State 78
		DEFAULT => -215
	},
	{#State 79
		DEFAULT => -225
	},
	{#State 80
		DEFAULT => -127
	},
	{#State 81
		DEFAULT => -124
	},
	{#State 82
		DEFAULT => -121
	},
	{#State 83
		DEFAULT => -209
	},
	{#State 84
		ACTIONS => {
			'DOUBLE' => 183,
			'LONG' => 184
		},
		DEFAULT => -217
	},
	{#State 85
		ACTIONS => {
			"<" => 185
		},
		DEFAULT => -277
	},
	{#State 86
		DEFAULT => -128
	},
	{#State 87
		ACTIONS => {
			'error' => 186,
			'IDENTIFIER' => 187
		}
	},
	{#State 88
		DEFAULT => -213
	},
	{#State 89
		ACTIONS => {
			"<" => 188
		},
		DEFAULT => -280
	},
	{#State 90
		ACTIONS => {
			'error' => 189,
			'IDENTIFIER' => 190
		}
	},
	{#State 91
		DEFAULT => -227
	},
	{#State 92
		DEFAULT => -54
	},
	{#State 93
		DEFAULT => -220
	},
	{#State 94
		DEFAULT => -299
	},
	{#State 95
		DEFAULT => -298
	},
	{#State 96
		ACTIONS => {
			'error' => 192,
			"(" => 191
		}
	},
	{#State 97
		DEFAULT => -265
	},
	{#State 98
		DEFAULT => -264
	},
	{#State 99
		ACTIONS => {
			'error' => 193,
			'IDENTIFIER' => 194
		}
	},
	{#State 100
		DEFAULT => -7
	},
	{#State 101
		DEFAULT => -13
	},
	{#State 102
		ACTIONS => {
			'CHAR' => -308,
			'OBJECT' => -308,
			'ONEWAY' => 152,
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
			'UNION' => 36,
			'READONLY' => 163,
			'WCHAR' => -308,
			'ATTRIBUTE' => -291,
			'error' => 195,
			'CONST' => 19,
			"}" => 196,
			'EXCEPTION' => 21,
			'OCTET' => -308,
			'FLOAT' => -308,
			'ENUM' => 24,
			'ANY' => -308
		},
		GOTOS => {
			'const_dcl' => 159,
			'op_mod' => 153,
			'except_dcl' => 154,
			'op_attribute' => 155,
			'attr_mod' => 156,
			'exports' => 197,
			'export' => 161,
			'struct_type' => 31,
			'op_header' => 162,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 164,
			'enum_header' => 18,
			'attr_dcl' => 165,
			'type_dcl' => 166,
			'union_header' => 22,
			'interface_body' => 198
		}
	},
	{#State 103
		DEFAULT => -178
	},
	{#State 104
		DEFAULT => -176
	},
	{#State 105
		DEFAULT => -206
	},
	{#State 106
		ACTIONS => {
			'PRIVATE' => 200,
			'ONEWAY' => 152,
			'FACTORY' => 204,
			'UNSIGNED' => -308,
			'SHORT' => -308,
			'WCHAR' => -308,
			'error' => 206,
			'CONST' => 19,
			"}" => 207,
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
			'UNION' => 36,
			'READONLY' => 163,
			'ATTRIBUTE' => -291,
			'PUBLIC' => 210
		},
		GOTOS => {
			'init_header_param' => 199,
			'const_dcl' => 159,
			'op_mod' => 153,
			'value_elements' => 208,
			'except_dcl' => 154,
			'state_member' => 201,
			'op_attribute' => 155,
			'attr_mod' => 156,
			'state_mod' => 202,
			'value_element' => 203,
			'export' => 209,
			'init_header' => 205,
			'struct_type' => 31,
			'op_header' => 162,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 164,
			'init_dcl' => 211,
			'enum_header' => 18,
			'attr_dcl' => 165,
			'type_dcl' => 166,
			'union_header' => 22
		}
	},
	{#State 107
		DEFAULT => -233
	},
	{#State 108
		DEFAULT => -297
	},
	{#State 109
		ACTIONS => {
			'CHAR' => 79,
			'OBJECT' => 127,
			'VALUEBASE' => 128,
			'FIXED' => 111,
			'SEQUENCE' => 112,
			'STRUCT' => 30,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'UNION' => 36,
			'WCHAR' => 72,
			'error' => 212,
			"}" => 214,
			'FLOAT' => 77,
			'OCTET' => 75,
			'ENUM' => 24,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'type_spec' => 172,
			'string_type' => 121,
			'struct_header' => 11,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'base_type_spec' => 123,
			'enum_type' => 124,
			'enum_header' => 18,
			'member_list' => 213,
			'union_header' => 22,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78,
			'wide_string_type' => 129,
			'boolean_type' => 130,
			'integer_type' => 131,
			'signed_short_int' => 88,
			'member' => 175,
			'struct_type' => 132,
			'union_type' => 133,
			'sequence_type' => 134,
			'unsigned_long_int' => 93,
			'template_type_spec' => 135,
			'constr_type_spec' => 136,
			'simple_type_spec' => 137,
			'fixed_pt_type' => 138
		}
	},
	{#State 110
		DEFAULT => -186
	},
	{#State 111
		ACTIONS => {
			"<" => 216,
			'error' => 215
		}
	},
	{#State 112
		ACTIONS => {
			"<" => 218,
			'error' => 217
		}
	},
	{#State 113
		DEFAULT => -194
	},
	{#State 114
		DEFAULT => -188
	},
	{#State 115
		DEFAULT => -193
	},
	{#State 116
		DEFAULT => -191
	},
	{#State 117
		ACTIONS => {
			"::" => 180
		},
		DEFAULT => -185
	},
	{#State 118
		DEFAULT => -189
	},
	{#State 119
		ACTIONS => {
			'error' => 221,
			'IDENTIFIER' => 225
		},
		GOTOS => {
			'declarators' => 219,
			'declarator' => 220,
			'simple_declarator' => 223,
			'array_declarator' => 224,
			'complex_declarator' => 222
		}
	},
	{#State 120
		DEFAULT => -172
	},
	{#State 121
		DEFAULT => -196
	},
	{#State 122
		DEFAULT => -192
	},
	{#State 123
		DEFAULT => -183
	},
	{#State 124
		DEFAULT => -201
	},
	{#State 125
		DEFAULT => -177
	},
	{#State 126
		DEFAULT => -229
	},
	{#State 127
		DEFAULT => -230
	},
	{#State 128
		DEFAULT => -343
	},
	{#State 129
		DEFAULT => -197
	},
	{#State 130
		DEFAULT => -190
	},
	{#State 131
		DEFAULT => -187
	},
	{#State 132
		DEFAULT => -199
	},
	{#State 133
		DEFAULT => -200
	},
	{#State 134
		DEFAULT => -195
	},
	{#State 135
		DEFAULT => -184
	},
	{#State 136
		DEFAULT => -182
	},
	{#State 137
		DEFAULT => -181
	},
	{#State 138
		DEFAULT => -198
	},
	{#State 139
		ACTIONS => {
			";" => 226
		}
	},
	{#State 140
		DEFAULT => -243
	},
	{#State 141
		DEFAULT => -10
	},
	{#State 142
		DEFAULT => -16
	},
	{#State 143
		DEFAULT => -6
	},
	{#State 144
		DEFAULT => -12
	},
	{#State 145
		ACTIONS => {
			'error' => 227,
			'IDENTIFIER' => 228
		}
	},
	{#State 146
		DEFAULT => -84
	},
	{#State 147
		DEFAULT => -5
	},
	{#State 148
		DEFAULT => -71
	},
	{#State 149
		ACTIONS => {
			"{" => -69,
			'SUPPORTS' => 170,
			":" => 169
		},
		DEFAULT => -64,
		GOTOS => {
			'supported_interface_spec' => 171,
			'value_inheritance_spec' => 229
		}
	},
	{#State 150
		ACTIONS => {
			"}" => 230
		}
	},
	{#State 151
		ACTIONS => {
			"}" => 231
		}
	},
	{#State 152
		DEFAULT => -309
	},
	{#State 153
		ACTIONS => {
			'CHAR' => 79,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'OBJECT' => 127,
			'IDENTIFIER' => 92,
			'VALUEBASE' => 128,
			'VOID' => 237,
			'WCHAR' => 72,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'OCTET' => 75,
			'FLOAT' => 77,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'wide_string_type' => 236,
			'integer_type' => 131,
			'boolean_type' => 130,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 232,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'signed_short_int' => 88,
			'string_type' => 233,
			'op_type_spec' => 238,
			'base_type_spec' => 234,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'unsigned_long_int' => 93,
			'param_type_spec' => 235,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78
		}
	},
	{#State 154
		ACTIONS => {
			'error' => 240,
			";" => 239
		}
	},
	{#State 155
		DEFAULT => -307
	},
	{#State 156
		ACTIONS => {
			'ATTRIBUTE' => 241
		}
	},
	{#State 157
		ACTIONS => {
			"}" => 242
		}
	},
	{#State 158
		DEFAULT => -66
	},
	{#State 159
		ACTIONS => {
			'error' => 244,
			";" => 243
		}
	},
	{#State 160
		ACTIONS => {
			"}" => 245
		}
	},
	{#State 161
		ACTIONS => {
			'ONEWAY' => 152,
			'NATIVE' => 28,
			'STRUCT' => 30,
			'TYPEDEF' => 33,
			'UNION' => 36,
			'READONLY' => 163,
			'ATTRIBUTE' => -291,
			'CONST' => 19,
			"}" => -37,
			'EXCEPTION' => 21,
			'ENUM' => 24
		},
		DEFAULT => -308,
		GOTOS => {
			'const_dcl' => 159,
			'op_mod' => 153,
			'except_dcl' => 154,
			'op_attribute' => 155,
			'attr_mod' => 156,
			'exports' => 246,
			'export' => 161,
			'struct_type' => 31,
			'op_header' => 162,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 164,
			'enum_header' => 18,
			'attr_dcl' => 165,
			'type_dcl' => 166,
			'union_header' => 22
		}
	},
	{#State 162
		ACTIONS => {
			'error' => 248,
			"(" => 247
		},
		GOTOS => {
			'parameter_dcls' => 249
		}
	},
	{#State 163
		DEFAULT => -290
	},
	{#State 164
		ACTIONS => {
			'error' => 251,
			";" => 250
		}
	},
	{#State 165
		ACTIONS => {
			'error' => 253,
			";" => 252
		}
	},
	{#State 166
		ACTIONS => {
			'error' => 255,
			";" => 254
		}
	},
	{#State 167
		DEFAULT => -65
	},
	{#State 168
		DEFAULT => -80
	},
	{#State 169
		ACTIONS => {
			'TRUNCATABLE' => 257
		},
		DEFAULT => -90,
		GOTOS => {
			'inheritance_mod' => 256
		}
	},
	{#State 170
		ACTIONS => {
			'error' => 259,
			'IDENTIFIER' => 92,
			"::" => 87
		},
		GOTOS => {
			'scoped_name' => 258,
			'interface_names' => 261,
			'interface_name' => 260
		}
	},
	{#State 171
		DEFAULT => -88
	},
	{#State 172
		ACTIONS => {
			'IDENTIFIER' => 225
		},
		GOTOS => {
			'declarators' => 262,
			'declarator' => 220,
			'simple_declarator' => 223,
			'array_declarator' => 224,
			'complex_declarator' => 222
		}
	},
	{#State 173
		ACTIONS => {
			"}" => 263
		}
	},
	{#State 174
		ACTIONS => {
			"}" => 264
		}
	},
	{#State 175
		ACTIONS => {
			'CHAR' => 79,
			'OBJECT' => 127,
			'VALUEBASE' => 128,
			'FIXED' => 111,
			'SEQUENCE' => 112,
			'STRUCT' => 30,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'UNION' => 36,
			'WCHAR' => 72,
			'FLOAT' => 77,
			'OCTET' => 75,
			'ENUM' => 24,
			'ANY' => 126
		},
		DEFAULT => -234,
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'type_spec' => 172,
			'string_type' => 121,
			'struct_header' => 11,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'base_type_spec' => 123,
			'enum_type' => 124,
			'enum_header' => 18,
			'member_list' => 265,
			'union_header' => 22,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78,
			'wide_string_type' => 129,
			'boolean_type' => 130,
			'integer_type' => 131,
			'signed_short_int' => 88,
			'member' => 175,
			'struct_type' => 132,
			'union_type' => 133,
			'sequence_type' => 134,
			'unsigned_long_int' => 93,
			'template_type_spec' => 135,
			'constr_type_spec' => 136,
			'simple_type_spec' => 137,
			'fixed_pt_type' => 138
		}
	},
	{#State 176
		ACTIONS => {
			"}" => 266
		}
	},
	{#State 177
		ACTIONS => {
			";" => 267,
			"," => 268
		},
		DEFAULT => -266
	},
	{#State 178
		DEFAULT => -270
	},
	{#State 179
		ACTIONS => {
			"}" => 269
		}
	},
	{#State 180
		ACTIONS => {
			'error' => 270,
			'IDENTIFIER' => 271
		}
	},
	{#State 181
		DEFAULT => -222
	},
	{#State 182
		ACTIONS => {
			'LONG' => 272
		},
		DEFAULT => -223
	},
	{#State 183
		DEFAULT => -210
	},
	{#State 184
		DEFAULT => -218
	},
	{#State 185
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 282,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'primary_expr' => 292,
			'and_expr' => 293,
			'scoped_name' => 275,
			'positive_int_const' => 276,
			'wide_string_literal' => 277,
			'boolean_literal' => 279,
			'mult_expr' => 295,
			'const_exp' => 280,
			'or_expr' => 281,
			'unary_expr' => 299,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 186
		DEFAULT => -56
	},
	{#State 187
		DEFAULT => -55
	},
	{#State 188
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 304,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'primary_expr' => 292,
			'and_expr' => 293,
			'scoped_name' => 275,
			'positive_int_const' => 303,
			'wide_string_literal' => 277,
			'boolean_literal' => 279,
			'mult_expr' => 295,
			'const_exp' => 280,
			'or_expr' => 281,
			'unary_expr' => 299,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 189
		DEFAULT => -119
	},
	{#State 190
		ACTIONS => {
			'error' => 305,
			"=" => 306
		}
	},
	{#State 191
		ACTIONS => {
			'CHAR' => 79,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'error' => 310,
			'LONG' => 314,
			"::" => 87,
			'ENUM' => 24,
			'UNSIGNED' => 69
		},
		GOTOS => {
			'switch_type_spec' => 311,
			'unsigned_int' => 60,
			'signed_int' => 63,
			'integer_type' => 313,
			'boolean_type' => 312,
			'unsigned_longlong_int' => 73,
			'char_type' => 307,
			'enum_type' => 309,
			'unsigned_long_int' => 93,
			'scoped_name' => 308,
			'enum_header' => 18,
			'signed_long_int' => 68,
			'unsigned_short_int' => 76,
			'signed_short_int' => 88,
			'signed_longlong_int' => 78
		}
	},
	{#State 192
		DEFAULT => -242
	},
	{#State 193
		ACTIONS => {
			"{" => -35
		},
		DEFAULT => -30
	},
	{#State 194
		ACTIONS => {
			"{" => -33,
			":" => 315
		},
		DEFAULT => -29,
		GOTOS => {
			'interface_inheritance_spec' => 316
		}
	},
	{#State 195
		ACTIONS => {
			"}" => 317
		}
	},
	{#State 196
		DEFAULT => -26
	},
	{#State 197
		DEFAULT => -36
	},
	{#State 198
		ACTIONS => {
			"}" => 318
		}
	},
	{#State 199
		ACTIONS => {
			'error' => 320,
			";" => 319
		}
	},
	{#State 200
		DEFAULT => -103
	},
	{#State 201
		DEFAULT => -97
	},
	{#State 202
		ACTIONS => {
			'CHAR' => 79,
			'OBJECT' => 127,
			'VALUEBASE' => 128,
			'FIXED' => 111,
			'SEQUENCE' => 112,
			'STRUCT' => 30,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'UNION' => 36,
			'WCHAR' => 72,
			'error' => 322,
			'FLOAT' => 77,
			'OCTET' => 75,
			'ENUM' => 24,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'wide_char_type' => 118,
			'type_spec' => 321,
			'signed_long_int' => 68,
			'string_type' => 121,
			'struct_header' => 11,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'base_type_spec' => 123,
			'enum_type' => 124,
			'enum_header' => 18,
			'union_header' => 22,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78,
			'wide_string_type' => 129,
			'boolean_type' => 130,
			'integer_type' => 131,
			'signed_short_int' => 88,
			'struct_type' => 132,
			'union_type' => 133,
			'sequence_type' => 134,
			'unsigned_long_int' => 93,
			'template_type_spec' => 135,
			'constr_type_spec' => 136,
			'simple_type_spec' => 137,
			'fixed_pt_type' => 138
		}
	},
	{#State 203
		ACTIONS => {
			'PRIVATE' => 200,
			'ONEWAY' => 152,
			'FACTORY' => 204,
			'CONST' => 19,
			'EXCEPTION' => 21,
			"}" => -76,
			'ENUM' => 24,
			'NATIVE' => 28,
			'STRUCT' => 30,
			'TYPEDEF' => 33,
			'UNION' => 36,
			'READONLY' => 163,
			'ATTRIBUTE' => -291,
			'PUBLIC' => 210
		},
		DEFAULT => -308,
		GOTOS => {
			'init_header_param' => 199,
			'const_dcl' => 159,
			'op_mod' => 153,
			'value_elements' => 323,
			'except_dcl' => 154,
			'state_member' => 201,
			'op_attribute' => 155,
			'attr_mod' => 156,
			'state_mod' => 202,
			'value_element' => 203,
			'export' => 209,
			'init_header' => 205,
			'struct_type' => 31,
			'op_header' => 162,
			'exception_header' => 32,
			'union_type' => 34,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 164,
			'init_dcl' => 211,
			'enum_header' => 18,
			'attr_dcl' => 165,
			'type_dcl' => 166,
			'union_header' => 22
		}
	},
	{#State 204
		ACTIONS => {
			'error' => 324,
			'IDENTIFIER' => 325
		}
	},
	{#State 205
		ACTIONS => {
			'error' => 327,
			"(" => 326
		}
	},
	{#State 206
		ACTIONS => {
			"}" => 328
		}
	},
	{#State 207
		DEFAULT => -73
	},
	{#State 208
		ACTIONS => {
			"}" => 329
		}
	},
	{#State 209
		DEFAULT => -96
	},
	{#State 210
		DEFAULT => -102
	},
	{#State 211
		DEFAULT => -98
	},
	{#State 212
		ACTIONS => {
			"}" => 330
		}
	},
	{#State 213
		ACTIONS => {
			"}" => 331
		}
	},
	{#State 214
		DEFAULT => -294
	},
	{#State 215
		DEFAULT => -341
	},
	{#State 216
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 333,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'primary_expr' => 292,
			'and_expr' => 293,
			'scoped_name' => 275,
			'positive_int_const' => 332,
			'wide_string_literal' => 277,
			'boolean_literal' => 279,
			'mult_expr' => 295,
			'const_exp' => 280,
			'or_expr' => 281,
			'unary_expr' => 299,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 217
		DEFAULT => -275
	},
	{#State 218
		ACTIONS => {
			'CHAR' => 79,
			'OBJECT' => 127,
			'VALUEBASE' => 128,
			'FIXED' => 111,
			'SEQUENCE' => 112,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'WCHAR' => 72,
			'error' => 334,
			'FLOAT' => 77,
			'OCTET' => 75,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'wide_string_type' => 129,
			'integer_type' => 131,
			'boolean_type' => 130,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'signed_short_int' => 88,
			'string_type' => 121,
			'sequence_type' => 134,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'base_type_spec' => 123,
			'unsigned_long_int' => 93,
			'template_type_spec' => 135,
			'unsigned_short_int' => 76,
			'simple_type_spec' => 335,
			'fixed_pt_type' => 138,
			'signed_longlong_int' => 78
		}
	},
	{#State 219
		DEFAULT => -179
	},
	{#State 220
		ACTIONS => {
			"," => 336
		},
		DEFAULT => -202
	},
	{#State 221
		DEFAULT => -180
	},
	{#State 222
		DEFAULT => -205
	},
	{#State 223
		DEFAULT => -204
	},
	{#State 224
		DEFAULT => -207
	},
	{#State 225
		ACTIONS => {
			"[" => 339
		},
		DEFAULT => -206,
		GOTOS => {
			'fixed_array_sizes' => 337,
			'fixed_array_size' => 338
		}
	},
	{#State 226
		DEFAULT => -18
	},
	{#State 227
		DEFAULT => -83
	},
	{#State 228
		ACTIONS => {
			'SUPPORTS' => 170,
			":" => 169
		},
		DEFAULT => -79,
		GOTOS => {
			'supported_interface_spec' => 171,
			'value_inheritance_spec' => 340
		}
	},
	{#State 229
		DEFAULT => -70
	},
	{#State 230
		DEFAULT => -20
	},
	{#State 231
		DEFAULT => -19
	},
	{#State 232
		ACTIONS => {
			"::" => 180
		},
		DEFAULT => -337
	},
	{#State 233
		DEFAULT => -335
	},
	{#State 234
		DEFAULT => -334
	},
	{#State 235
		DEFAULT => -310
	},
	{#State 236
		DEFAULT => -336
	},
	{#State 237
		DEFAULT => -311
	},
	{#State 238
		ACTIONS => {
			'error' => 341,
			'IDENTIFIER' => 342
		}
	},
	{#State 239
		DEFAULT => -41
	},
	{#State 240
		DEFAULT => -46
	},
	{#State 241
		ACTIONS => {
			'CHAR' => 79,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'OBJECT' => 127,
			'IDENTIFIER' => 92,
			'VALUEBASE' => 128,
			'WCHAR' => 72,
			'DOUBLE' => 83,
			'error' => 343,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'OCTET' => 75,
			'FLOAT' => 77,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'wide_string_type' => 236,
			'integer_type' => 131,
			'boolean_type' => 130,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 232,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'signed_short_int' => 88,
			'string_type' => 233,
			'base_type_spec' => 234,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'unsigned_long_int' => 93,
			'param_type_spec' => 344,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78
		}
	},
	{#State 242
		DEFAULT => -68
	},
	{#State 243
		DEFAULT => -40
	},
	{#State 244
		DEFAULT => -45
	},
	{#State 245
		DEFAULT => -67
	},
	{#State 246
		DEFAULT => -38
	},
	{#State 247
		ACTIONS => {
			'error' => 346,
			")" => 350,
			'OUT' => 351,
			'INOUT' => 347,
			'IN' => 345
		},
		GOTOS => {
			'param_dcl' => 352,
			'param_dcls' => 349,
			'param_attribute' => 348
		}
	},
	{#State 248
		DEFAULT => -304
	},
	{#State 249
		ACTIONS => {
			'RAISES' => 356,
			'CONTEXT' => 353
		},
		DEFAULT => -300,
		GOTOS => {
			'context_expr' => 355,
			'raises_expr' => 354
		}
	},
	{#State 250
		DEFAULT => -43
	},
	{#State 251
		DEFAULT => -48
	},
	{#State 252
		DEFAULT => -42
	},
	{#State 253
		DEFAULT => -47
	},
	{#State 254
		DEFAULT => -39
	},
	{#State 255
		DEFAULT => -44
	},
	{#State 256
		ACTIONS => {
			'error' => 359,
			'IDENTIFIER' => 92,
			"::" => 87
		},
		GOTOS => {
			'scoped_name' => 357,
			'value_name' => 358,
			'value_names' => 360
		}
	},
	{#State 257
		DEFAULT => -89
	},
	{#State 258
		ACTIONS => {
			"::" => 180
		},
		DEFAULT => -53
	},
	{#State 259
		DEFAULT => -94
	},
	{#State 260
		ACTIONS => {
			"," => 361
		},
		DEFAULT => -51
	},
	{#State 261
		DEFAULT => -93
	},
	{#State 262
		ACTIONS => {
			'error' => 363,
			";" => 362
		}
	},
	{#State 263
		DEFAULT => -232
	},
	{#State 264
		DEFAULT => -231
	},
	{#State 265
		DEFAULT => -235
	},
	{#State 266
		DEFAULT => -262
	},
	{#State 267
		DEFAULT => -269
	},
	{#State 268
		ACTIONS => {
			'IDENTIFIER' => 178
		},
		DEFAULT => -268,
		GOTOS => {
			'enumerators' => 364,
			'enumerator' => 177
		}
	},
	{#State 269
		DEFAULT => -261
	},
	{#State 270
		DEFAULT => -58
	},
	{#State 271
		DEFAULT => -57
	},
	{#State 272
		DEFAULT => -224
	},
	{#State 273
		DEFAULT => -160
	},
	{#State 274
		DEFAULT => -161
	},
	{#State 275
		ACTIONS => {
			"::" => 180
		},
		DEFAULT => -153
	},
	{#State 276
		ACTIONS => {
			">" => 365
		}
	},
	{#State 277
		DEFAULT => -159
	},
	{#State 278
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 367,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 295,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'const_exp' => 366,
			'and_expr' => 293,
			'or_expr' => 281,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 279
		DEFAULT => -164
	},
	{#State 280
		DEFAULT => -171
	},
	{#State 281
		ACTIONS => {
			"|" => 368
		},
		DEFAULT => -131
	},
	{#State 282
		ACTIONS => {
			">" => 369
		}
	},
	{#State 283
		ACTIONS => {
			"^" => 370
		},
		DEFAULT => -132
	},
	{#State 284
		ACTIONS => {
			"<<" => 371,
			">>" => 372
		},
		DEFAULT => -136
	},
	{#State 285
		DEFAULT => -170
	},
	{#State 286
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 286
		},
		DEFAULT => -167,
		GOTOS => {
			'wide_string_literal' => 373
		}
	},
	{#State 287
		DEFAULT => -154
	},
	{#State 288
		DEFAULT => -169
	},
	{#State 289
		ACTIONS => {
			"+" => 374,
			"-" => 375
		},
		DEFAULT => -138
	},
	{#State 290
		DEFAULT => -158
	},
	{#State 291
		DEFAULT => -163
	},
	{#State 292
		DEFAULT => -149
	},
	{#State 293
		ACTIONS => {
			"&" => 376
		},
		DEFAULT => -134
	},
	{#State 294
		DEFAULT => -157
	},
	{#State 295
		ACTIONS => {
			"%" => 378,
			"*" => 377,
			"/" => 379
		},
		DEFAULT => -141
	},
	{#State 296
		ACTIONS => {
			'STRING_LITERAL' => 296
		},
		DEFAULT => -165,
		GOTOS => {
			'string_literal' => 380
		}
	},
	{#State 297
		DEFAULT => -162
	},
	{#State 298
		DEFAULT => -151
	},
	{#State 299
		DEFAULT => -144
	},
	{#State 300
		DEFAULT => -150
	},
	{#State 301
		DEFAULT => -152
	},
	{#State 302
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'boolean_literal' => 279,
			'scoped_name' => 275,
			'primary_expr' => 381,
			'literal' => 287,
			'wide_string_literal' => 277
		}
	},
	{#State 303
		ACTIONS => {
			">" => 382
		}
	},
	{#State 304
		ACTIONS => {
			">" => 383
		}
	},
	{#State 305
		DEFAULT => -118
	},
	{#State 306
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 385,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 295,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'const_exp' => 384,
			'and_expr' => 293,
			'or_expr' => 281,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 307
		DEFAULT => -245
	},
	{#State 308
		ACTIONS => {
			"::" => 180
		},
		DEFAULT => -248
	},
	{#State 309
		DEFAULT => -247
	},
	{#State 310
		ACTIONS => {
			")" => 386
		}
	},
	{#State 311
		ACTIONS => {
			")" => 387
		}
	},
	{#State 312
		DEFAULT => -246
	},
	{#State 313
		DEFAULT => -244
	},
	{#State 314
		ACTIONS => {
			'LONG' => 184
		},
		DEFAULT => -217
	},
	{#State 315
		ACTIONS => {
			'error' => 388,
			'IDENTIFIER' => 92,
			"::" => 87
		},
		GOTOS => {
			'scoped_name' => 258,
			'interface_names' => 389,
			'interface_name' => 260
		}
	},
	{#State 316
		DEFAULT => -34
	},
	{#State 317
		DEFAULT => -28
	},
	{#State 318
		DEFAULT => -27
	},
	{#State 319
		DEFAULT => -104
	},
	{#State 320
		DEFAULT => -105
	},
	{#State 321
		ACTIONS => {
			'error' => 391,
			'IDENTIFIER' => 225
		},
		GOTOS => {
			'declarators' => 390,
			'declarator' => 220,
			'simple_declarator' => 223,
			'array_declarator' => 224,
			'complex_declarator' => 222
		}
	},
	{#State 322
		ACTIONS => {
			";" => 392
		}
	},
	{#State 323
		DEFAULT => -77
	},
	{#State 324
		DEFAULT => -111
	},
	{#State 325
		DEFAULT => -110
	},
	{#State 326
		ACTIONS => {
			'error' => 397,
			")" => 398,
			'IN' => 395
		},
		GOTOS => {
			'init_param_decls' => 394,
			'init_param_attribute' => 393,
			'init_param_decl' => 396
		}
	},
	{#State 327
		DEFAULT => -109
	},
	{#State 328
		DEFAULT => -75
	},
	{#State 329
		DEFAULT => -74
	},
	{#State 330
		DEFAULT => -296
	},
	{#State 331
		DEFAULT => -295
	},
	{#State 332
		ACTIONS => {
			"," => 399
		}
	},
	{#State 333
		ACTIONS => {
			">" => 400
		}
	},
	{#State 334
		ACTIONS => {
			">" => 401
		}
	},
	{#State 335
		ACTIONS => {
			">" => 403,
			"," => 402
		}
	},
	{#State 336
		ACTIONS => {
			'IDENTIFIER' => 225
		},
		GOTOS => {
			'declarators' => 404,
			'declarator' => 220,
			'simple_declarator' => 223,
			'array_declarator' => 224,
			'complex_declarator' => 222
		}
	},
	{#State 337
		DEFAULT => -282
	},
	{#State 338
		ACTIONS => {
			"[" => 339
		},
		DEFAULT => -283,
		GOTOS => {
			'fixed_array_sizes' => 405,
			'fixed_array_size' => 338
		}
	},
	{#State 339
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 407,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'primary_expr' => 292,
			'and_expr' => 293,
			'scoped_name' => 275,
			'positive_int_const' => 406,
			'wide_string_literal' => 277,
			'boolean_literal' => 279,
			'mult_expr' => 295,
			'const_exp' => 280,
			'or_expr' => 281,
			'unary_expr' => 299,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 340
		DEFAULT => -81
	},
	{#State 341
		DEFAULT => -306
	},
	{#State 342
		DEFAULT => -305
	},
	{#State 343
		DEFAULT => -289
	},
	{#State 344
		ACTIONS => {
			'error' => 408,
			'IDENTIFIER' => 105
		},
		GOTOS => {
			'simple_declarators' => 410,
			'simple_declarator' => 409
		}
	},
	{#State 345
		DEFAULT => -320
	},
	{#State 346
		ACTIONS => {
			")" => 411
		}
	},
	{#State 347
		DEFAULT => -322
	},
	{#State 348
		ACTIONS => {
			'CHAR' => 79,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'OBJECT' => 127,
			'IDENTIFIER' => 92,
			'VALUEBASE' => 128,
			'WCHAR' => 72,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'OCTET' => 75,
			'FLOAT' => 77,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'wide_string_type' => 236,
			'integer_type' => 131,
			'boolean_type' => 130,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 232,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'signed_short_int' => 88,
			'string_type' => 233,
			'base_type_spec' => 234,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'unsigned_long_int' => 93,
			'param_type_spec' => 412,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78
		}
	},
	{#State 349
		ACTIONS => {
			")" => 413
		}
	},
	{#State 350
		DEFAULT => -313
	},
	{#State 351
		DEFAULT => -321
	},
	{#State 352
		ACTIONS => {
			";" => 414,
			"," => 415
		},
		DEFAULT => -315
	},
	{#State 353
		ACTIONS => {
			'error' => 417,
			"(" => 416
		}
	},
	{#State 354
		ACTIONS => {
			'CONTEXT' => 353
		},
		DEFAULT => -301,
		GOTOS => {
			'context_expr' => 418
		}
	},
	{#State 355
		DEFAULT => -303
	},
	{#State 356
		ACTIONS => {
			'error' => 420,
			"(" => 419
		}
	},
	{#State 357
		ACTIONS => {
			"::" => 180
		},
		DEFAULT => -95
	},
	{#State 358
		ACTIONS => {
			"," => 421
		},
		DEFAULT => -91
	},
	{#State 359
		DEFAULT => -87
	},
	{#State 360
		ACTIONS => {
			'SUPPORTS' => 170
		},
		DEFAULT => -85,
		GOTOS => {
			'supported_interface_spec' => 422
		}
	},
	{#State 361
		ACTIONS => {
			'IDENTIFIER' => 92,
			"::" => 87
		},
		GOTOS => {
			'scoped_name' => 258,
			'interface_names' => 423,
			'interface_name' => 260
		}
	},
	{#State 362
		DEFAULT => -236
	},
	{#State 363
		DEFAULT => -237
	},
	{#State 364
		DEFAULT => -267
	},
	{#State 365
		DEFAULT => -276
	},
	{#State 366
		ACTIONS => {
			")" => 424
		}
	},
	{#State 367
		ACTIONS => {
			")" => 425
		}
	},
	{#State 368
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 295,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'and_expr' => 293,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'xor_expr' => 426,
			'shift_expr' => 284,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 369
		DEFAULT => -278
	},
	{#State 370
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 295,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'and_expr' => 427,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'shift_expr' => 284,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 371
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 295,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 428
		}
	},
	{#State 372
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 295,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 429
		}
	},
	{#State 373
		DEFAULT => -168
	},
	{#State 374
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302
		}
	},
	{#State 375
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 431,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302
		}
	},
	{#State 376
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 295,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'shift_expr' => 432,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 377
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'unary_expr' => 433,
			'scoped_name' => 275,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302
		}
	},
	{#State 378
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'unary_expr' => 434,
			'scoped_name' => 275,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302
		}
	},
	{#State 379
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'CHARACTER_LITERAL' => 273,
			"+" => 298,
			'FIXED_PT_LITERAL' => 297,
			'WIDE_CHARACTER_LITERAL' => 274,
			"-" => 300,
			"::" => 87,
			'FALSE' => 285,
			'WIDE_STRING_LITERAL' => 286,
			'INTEGER_LITERAL' => 294,
			"~" => 301,
			"(" => 278,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'unary_expr' => 435,
			'scoped_name' => 275,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302
		}
	},
	{#State 380
		DEFAULT => -166
	},
	{#State 381
		DEFAULT => -148
	},
	{#State 382
		DEFAULT => -279
	},
	{#State 383
		DEFAULT => -281
	},
	{#State 384
		DEFAULT => -116
	},
	{#State 385
		DEFAULT => -117
	},
	{#State 386
		DEFAULT => -241
	},
	{#State 387
		ACTIONS => {
			"{" => 437,
			'error' => 436
		}
	},
	{#State 388
		DEFAULT => -50
	},
	{#State 389
		DEFAULT => -49
	},
	{#State 390
		ACTIONS => {
			";" => 438
		}
	},
	{#State 391
		ACTIONS => {
			";" => 439
		}
	},
	{#State 392
		DEFAULT => -101
	},
	{#State 393
		ACTIONS => {
			'CHAR' => 79,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'OBJECT' => 127,
			'IDENTIFIER' => 92,
			'VALUEBASE' => 128,
			'WCHAR' => 72,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'OCTET' => 75,
			'FLOAT' => 77,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'wide_string_type' => 236,
			'integer_type' => 131,
			'boolean_type' => 130,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 232,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'signed_short_int' => 88,
			'string_type' => 233,
			'base_type_spec' => 234,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'unsigned_long_int' => 93,
			'param_type_spec' => 440,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78
		}
	},
	{#State 394
		ACTIONS => {
			")" => 441
		}
	},
	{#State 395
		DEFAULT => -115
	},
	{#State 396
		ACTIONS => {
			"," => 442
		},
		DEFAULT => -112
	},
	{#State 397
		ACTIONS => {
			")" => 443
		}
	},
	{#State 398
		DEFAULT => -106
	},
	{#State 399
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 445,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'primary_expr' => 292,
			'and_expr' => 293,
			'scoped_name' => 275,
			'positive_int_const' => 444,
			'wide_string_literal' => 277,
			'boolean_literal' => 279,
			'mult_expr' => 295,
			'const_exp' => 280,
			'or_expr' => 281,
			'unary_expr' => 299,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 400
		DEFAULT => -340
	},
	{#State 401
		DEFAULT => -274
	},
	{#State 402
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 447,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'string_literal' => 290,
			'primary_expr' => 292,
			'and_expr' => 293,
			'scoped_name' => 275,
			'positive_int_const' => 446,
			'wide_string_literal' => 277,
			'boolean_literal' => 279,
			'mult_expr' => 295,
			'const_exp' => 280,
			'or_expr' => 281,
			'unary_expr' => 299,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
		}
	},
	{#State 403
		DEFAULT => -273
	},
	{#State 404
		DEFAULT => -203
	},
	{#State 405
		DEFAULT => -284
	},
	{#State 406
		ACTIONS => {
			"]" => 448
		}
	},
	{#State 407
		ACTIONS => {
			"]" => 449
		}
	},
	{#State 408
		DEFAULT => -288
	},
	{#State 409
		ACTIONS => {
			"," => 450
		},
		DEFAULT => -292
	},
	{#State 410
		DEFAULT => -287
	},
	{#State 411
		DEFAULT => -314
	},
	{#State 412
		ACTIONS => {
			'IDENTIFIER' => 105
		},
		GOTOS => {
			'simple_declarator' => 451
		}
	},
	{#State 413
		DEFAULT => -312
	},
	{#State 414
		DEFAULT => -318
	},
	{#State 415
		ACTIONS => {
			'OUT' => 351,
			'INOUT' => 347,
			'IN' => 345
		},
		DEFAULT => -317,
		GOTOS => {
			'param_dcl' => 352,
			'param_dcls' => 452,
			'param_attribute' => 348
		}
	},
	{#State 416
		ACTIONS => {
			'error' => 453,
			'STRING_LITERAL' => 296
		},
		GOTOS => {
			'string_literal' => 454,
			'string_literals' => 455
		}
	},
	{#State 417
		DEFAULT => -331
	},
	{#State 418
		DEFAULT => -302
	},
	{#State 419
		ACTIONS => {
			'error' => 457,
			'IDENTIFIER' => 92,
			"::" => 87
		},
		GOTOS => {
			'scoped_name' => 456,
			'exception_names' => 458,
			'exception_name' => 459
		}
	},
	{#State 420
		DEFAULT => -325
	},
	{#State 421
		ACTIONS => {
			'IDENTIFIER' => 92,
			"::" => 87
		},
		GOTOS => {
			'scoped_name' => 357,
			'value_name' => 358,
			'value_names' => 460
		}
	},
	{#State 422
		DEFAULT => -86
	},
	{#State 423
		DEFAULT => -52
	},
	{#State 424
		DEFAULT => -155
	},
	{#State 425
		DEFAULT => -156
	},
	{#State 426
		ACTIONS => {
			"^" => 370
		},
		DEFAULT => -133
	},
	{#State 427
		ACTIONS => {
			"&" => 376
		},
		DEFAULT => -135
	},
	{#State 428
		ACTIONS => {
			"+" => 374,
			"-" => 375
		},
		DEFAULT => -140
	},
	{#State 429
		ACTIONS => {
			"+" => 374,
			"-" => 375
		},
		DEFAULT => -139
	},
	{#State 430
		ACTIONS => {
			"%" => 378,
			"*" => 377,
			"/" => 379
		},
		DEFAULT => -142
	},
	{#State 431
		ACTIONS => {
			"%" => 378,
			"*" => 377,
			"/" => 379
		},
		DEFAULT => -143
	},
	{#State 432
		ACTIONS => {
			"<<" => 371,
			">>" => 372
		},
		DEFAULT => -137
	},
	{#State 433
		DEFAULT => -145
	},
	{#State 434
		DEFAULT => -147
	},
	{#State 435
		DEFAULT => -146
	},
	{#State 436
		DEFAULT => -240
	},
	{#State 437
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
	{#State 438
		DEFAULT => -99
	},
	{#State 439
		DEFAULT => -100
	},
	{#State 440
		ACTIONS => {
			'IDENTIFIER' => 105
		},
		GOTOS => {
			'simple_declarator' => 468
		}
	},
	{#State 441
		DEFAULT => -107
	},
	{#State 442
		ACTIONS => {
			'IN' => 395
		},
		GOTOS => {
			'init_param_decls' => 469,
			'init_param_attribute' => 393,
			'init_param_decl' => 396
		}
	},
	{#State 443
		DEFAULT => -108
	},
	{#State 444
		ACTIONS => {
			">" => 470
		}
	},
	{#State 445
		ACTIONS => {
			">" => 471
		}
	},
	{#State 446
		ACTIONS => {
			">" => 472
		}
	},
	{#State 447
		ACTIONS => {
			">" => 473
		}
	},
	{#State 448
		DEFAULT => -285
	},
	{#State 449
		DEFAULT => -286
	},
	{#State 450
		ACTIONS => {
			'IDENTIFIER' => 105
		},
		GOTOS => {
			'simple_declarators' => 474,
			'simple_declarator' => 409
		}
	},
	{#State 451
		DEFAULT => -319
	},
	{#State 452
		DEFAULT => -316
	},
	{#State 453
		ACTIONS => {
			")" => 475
		}
	},
	{#State 454
		ACTIONS => {
			"," => 476
		},
		DEFAULT => -332
	},
	{#State 455
		ACTIONS => {
			")" => 477
		}
	},
	{#State 456
		ACTIONS => {
			"::" => 180
		},
		DEFAULT => -328
	},
	{#State 457
		ACTIONS => {
			")" => 478
		}
	},
	{#State 458
		ACTIONS => {
			")" => 479
		}
	},
	{#State 459
		ACTIONS => {
			"," => 480
		},
		DEFAULT => -326
	},
	{#State 460
		DEFAULT => -92
	},
	{#State 461
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 291,
			'CHARACTER_LITERAL' => 273,
			'WIDE_CHARACTER_LITERAL' => 274,
			"::" => 87,
			'INTEGER_LITERAL' => 294,
			"(" => 278,
			'IDENTIFIER' => 92,
			'STRING_LITERAL' => 296,
			'FIXED_PT_LITERAL' => 297,
			"+" => 298,
			'error' => 482,
			"-" => 300,
			'WIDE_STRING_LITERAL' => 286,
			'FALSE' => 285,
			"~" => 301,
			'TRUE' => 288
		},
		GOTOS => {
			'mult_expr' => 295,
			'string_literal' => 290,
			'boolean_literal' => 279,
			'primary_expr' => 292,
			'const_exp' => 481,
			'and_expr' => 293,
			'or_expr' => 281,
			'unary_expr' => 299,
			'scoped_name' => 275,
			'xor_expr' => 283,
			'shift_expr' => 284,
			'wide_string_literal' => 277,
			'literal' => 287,
			'unary_operator' => 302,
			'add_expr' => 289
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
			'switch_body' => 483,
			'case' => 462,
			'case_label' => 467
		}
	},
	{#State 463
		ACTIONS => {
			'error' => 484,
			":" => 485
		}
	},
	{#State 464
		ACTIONS => {
			"}" => 486
		}
	},
	{#State 465
		ACTIONS => {
			"}" => 487
		}
	},
	{#State 466
		ACTIONS => {
			'CHAR' => 79,
			'OBJECT' => 127,
			'VALUEBASE' => 128,
			'FIXED' => 111,
			'SEQUENCE' => 112,
			'STRUCT' => 30,
			'DOUBLE' => 83,
			'LONG' => 84,
			'STRING' => 85,
			"::" => 87,
			'WSTRING' => 89,
			'UNSIGNED' => 69,
			'SHORT' => 71,
			'BOOLEAN' => 91,
			'IDENTIFIER' => 92,
			'UNION' => 36,
			'WCHAR' => 72,
			'FLOAT' => 77,
			'OCTET' => 75,
			'ENUM' => 24,
			'ANY' => 126
		},
		GOTOS => {
			'unsigned_int' => 60,
			'floating_pt_type' => 110,
			'signed_int' => 63,
			'char_type' => 114,
			'value_base_type' => 113,
			'object_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'wide_char_type' => 118,
			'signed_long_int' => 68,
			'type_spec' => 488,
			'string_type' => 121,
			'struct_header' => 11,
			'element_spec' => 489,
			'unsigned_longlong_int' => 73,
			'any_type' => 122,
			'base_type_spec' => 123,
			'enum_type' => 124,
			'enum_header' => 18,
			'union_header' => 22,
			'unsigned_short_int' => 76,
			'signed_longlong_int' => 78,
			'wide_string_type' => 129,
			'boolean_type' => 130,
			'integer_type' => 131,
			'signed_short_int' => 88,
			'struct_type' => 132,
			'union_type' => 133,
			'sequence_type' => 134,
			'unsigned_long_int' => 93,
			'template_type_spec' => 135,
			'constr_type_spec' => 136,
			'simple_type_spec' => 137,
			'fixed_pt_type' => 138
		}
	},
	{#State 467
		ACTIONS => {
			'CASE' => 461,
			'DEFAULT' => 463
		},
		DEFAULT => -253,
		GOTOS => {
			'case_labels' => 490,
			'case_label' => 467
		}
	},
	{#State 468
		DEFAULT => -114
	},
	{#State 469
		DEFAULT => -113
	},
	{#State 470
		DEFAULT => -338
	},
	{#State 471
		DEFAULT => -339
	},
	{#State 472
		DEFAULT => -271
	},
	{#State 473
		DEFAULT => -272
	},
	{#State 474
		DEFAULT => -293
	},
	{#State 475
		DEFAULT => -330
	},
	{#State 476
		ACTIONS => {
			'STRING_LITERAL' => 296
		},
		GOTOS => {
			'string_literal' => 454,
			'string_literals' => 491
		}
	},
	{#State 477
		DEFAULT => -329
	},
	{#State 478
		DEFAULT => -324
	},
	{#State 479
		DEFAULT => -323
	},
	{#State 480
		ACTIONS => {
			'IDENTIFIER' => 92,
			"::" => 87
		},
		GOTOS => {
			'scoped_name' => 456,
			'exception_names' => 492,
			'exception_name' => 459
		}
	},
	{#State 481
		ACTIONS => {
			'error' => 493,
			":" => 494
		}
	},
	{#State 482
		DEFAULT => -257
	},
	{#State 483
		DEFAULT => -250
	},
	{#State 484
		DEFAULT => -259
	},
	{#State 485
		DEFAULT => -258
	},
	{#State 486
		DEFAULT => -239
	},
	{#State 487
		DEFAULT => -238
	},
	{#State 488
		ACTIONS => {
			'IDENTIFIER' => 225
		},
		GOTOS => {
			'declarator' => 495,
			'simple_declarator' => 223,
			'array_declarator' => 224,
			'complex_declarator' => 222
		}
	},
	{#State 489
		ACTIONS => {
			'error' => 497,
			";" => 496
		}
	},
	{#State 490
		DEFAULT => -254
	},
	{#State 491
		DEFAULT => -333
	},
	{#State 492
		DEFAULT => -327
	},
	{#State 493
		DEFAULT => -256
	},
	{#State 494
		DEFAULT => -255
	},
	{#State 495
		DEFAULT => -260
	},
	{#State 496
		DEFAULT => -251
	},
	{#State 497
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
		 'definition', 3,
sub
#line 147 "parser23.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 19
		 'module', 4,
sub
#line 160 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 20
		 'module', 4,
sub
#line 167 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'module', 2,
sub
#line 173 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 22
		 'module_header', 2,
sub
#line 182 "parser23.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 23
		 'module_header', 2,
sub
#line 188 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 24
		 'interface', 1, undef
	],
	[#Rule 25
		 'interface', 1, undef
	],
	[#Rule 26
		 'interface_dcl', 3,
sub
#line 205 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 27
		 'interface_dcl', 4,
sub
#line 213 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 28
		 'interface_dcl', 4,
sub
#line 221 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 29
		 'forward_dcl', 3,
sub
#line 232 "parser23.yp"
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
	[#Rule 30
		 'forward_dcl', 3,
sub
#line 244 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
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
#line 260 "parser23.yp"
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
	[#Rule 34
		 'interface_header', 4,
sub
#line 272 "parser23.yp"
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
	[#Rule 35
		 'interface_header', 3,
sub
#line 289 "parser23.yp"
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
#line 303 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 38
		 'exports', 2,
sub
#line 307 "parser23.yp"
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
#line 326 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 45
		 'export', 2,
sub
#line 332 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 46
		 'export', 2,
sub
#line 338 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 47
		 'export', 2,
sub
#line 344 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 48
		 'export', 2,
sub
#line 350 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 49
		 'interface_inheritance_spec', 2,
sub
#line 360 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 50
		 'interface_inheritance_spec', 2,
sub
#line 364 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 51
		 'interface_names', 1,
sub
#line 372 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 52
		 'interface_names', 3,
sub
#line 376 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 53
		 'interface_name', 1,
sub
#line 385 "parser23.yp"
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
#line 395 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 56
		 'scoped_name', 2,
sub
#line 399 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 57
		 'scoped_name', 3,
sub
#line 405 "parser23.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 58
		 'scoped_name', 3,
sub
#line 409 "parser23.yp"
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
#line 431 "parser23.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 64
		 'value_forward_dcl', 3,
sub
#line 437 "parser23.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 65
		 'value_box_dcl', 3,
sub
#line 447 "parser23.yp"
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
#line 458 "parser23.yp"
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
#line 466 "parser23.yp"
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
#line 474 "parser23.yp"
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
#line 484 "parser23.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 70
		 'value_abs_header', 4,
sub
#line 490 "parser23.yp"
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
#line 497 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 72
		 'value_abs_header', 2,
sub
#line 502 "parser23.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 73
		 'value_dcl', 3,
sub
#line 511 "parser23.yp"
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
#line 519 "parser23.yp"
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
#line 527 "parser23.yp"
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
#line 537 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 77
		 'value_elements', 2,
sub
#line 541 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 78
		 'value_header', 2,
sub
#line 550 "parser23.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 79
		 'value_header', 3,
sub
#line 556 "parser23.yp"
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
#line 563 "parser23.yp"
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
#line 570 "parser23.yp"
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
#line 578 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 83
		 'value_header', 3,
sub
#line 583 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 84
		 'value_header', 2,
sub
#line 588 "parser23.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 85
		 'value_inheritance_spec', 3,
sub
#line 597 "parser23.yp"
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
#line 604 "parser23.yp"
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
#line 612 "parser23.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 88
		 'value_inheritance_spec', 1,
sub
#line 617 "parser23.yp"
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
#line 633 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 92
		 'value_names', 3,
sub
#line 637 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 93
		 'supported_interface_spec', 2,
sub
#line 645 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 94
		 'supported_interface_spec', 2,
sub
#line 649 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 95
		 'value_name', 1,
sub
#line 658 "parser23.yp"
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
#line 676 "parser23.yp"
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
#line 684 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 101
		 'state_member', 3,
sub
#line 689 "parser23.yp"
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
#line 707 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 106
		 'init_header_param', 3,
sub
#line 716 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 107
		 'init_header_param', 4,
sub
#line 722 "parser23.yp"
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
#line 730 "parser23.yp"
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
#line 737 "parser23.yp"
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
#line 747 "parser23.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 111
		 'init_header', 2,
sub
#line 753 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'init_param_decls', 1,
sub
#line 762 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 113
		 'init_param_decls', 3,
sub
#line 766 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 114
		 'init_param_decl', 3,
sub
#line 775 "parser23.yp"
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
#line 793 "parser23.yp"
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
#line 801 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 118
		 'const_dcl', 4,
sub
#line 806 "parser23.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'const_dcl', 3,
sub
#line 811 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 120
		 'const_dcl', 2,
sub
#line 816 "parser23.yp"
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
#line 841 "parser23.yp"
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
#line 859 "parser23.yp"
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
#line 869 "parser23.yp"
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
#line 879 "parser23.yp"
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
#line 889 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 140
		 'shift_expr', 3,
sub
#line 893 "parser23.yp"
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
#line 903 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 143
		 'add_expr', 3,
sub
#line 907 "parser23.yp"
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
#line 917 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 146
		 'mult_expr', 3,
sub
#line 921 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'mult_expr', 3,
sub
#line 925 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 148
		 'unary_expr', 2,
sub
#line 933 "parser23.yp"
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
#line 953 "parser23.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 154
		 'primary_expr', 1,
sub
#line 959 "parser23.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 155
		 'primary_expr', 3,
sub
#line 963 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 156
		 'primary_expr', 3,
sub
#line 967 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 157
		 'literal', 1,
sub
#line 976 "parser23.yp"
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
#line 983 "parser23.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 159
		 'literal', 1,
sub
#line 989 "parser23.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 995 "parser23.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 1001 "parser23.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1007 "parser23.yp"
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
#line 1014 "parser23.yp"
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
#line 1028 "parser23.yp"
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
#line 1037 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 169
		 'boolean_literal', 1,
sub
#line 1045 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 170
		 'boolean_literal', 1,
sub
#line 1051 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 171
		 'positive_int_const', 1,
sub
#line 1061 "parser23.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 172
		 'type_dcl', 2,
sub
#line 1071 "parser23.yp"
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
#line 1081 "parser23.yp"
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
#line 1088 "parser23.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'type_dcl', 2,
sub
#line 1093 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 179
		 'type_declarator', 2,
sub
#line 1102 "parser23.yp"
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
#line 1109 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
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
#line 1130 "parser23.yp"
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
#line 1182 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 203
		 'declarators', 3,
sub
#line 1186 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 204
		 'declarator', 1,
sub
#line 1195 "parser23.yp"
{
			[$_[1]];
		}
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
#line 1217 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 209
		 'floating_pt_type', 1,
sub
#line 1223 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 210
		 'floating_pt_type', 2,
sub
#line 1229 "parser23.yp"
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
#line 1257 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 217
		 'signed_long_int', 1,
sub
#line 1267 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 218
		 'signed_longlong_int', 2,
sub
#line 1277 "parser23.yp"
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
#line 1297 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 223
		 'unsigned_long_int', 2,
sub
#line 1307 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 224
		 'unsigned_longlong_int', 3,
sub
#line 1317 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 225
		 'char_type', 1,
sub
#line 1327 "parser23.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 226
		 'wide_char_type', 1,
sub
#line 1337 "parser23.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 227
		 'boolean_type', 1,
sub
#line 1347 "parser23.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 228
		 'octet_type', 1,
sub
#line 1357 "parser23.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 229
		 'any_type', 1,
sub
#line 1367 "parser23.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'object_type', 1,
sub
#line 1377 "parser23.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 231
		 'struct_type', 4,
sub
#line 1387 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 232
		 'struct_type', 4,
sub
#line 1394 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'struct_header', 2,
sub
#line 1403 "parser23.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 234
		 'member_list', 1,
sub
#line 1413 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 235
		 'member_list', 2,
sub
#line 1417 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 236
		 'member', 3,
sub
#line 1426 "parser23.yp"
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
#line 1433 "parser23.yp"
{
			$_[0]->Error("';' expected.\n");
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
#line 1446 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 239
		 'union_type', 8,
sub
#line 1454 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 240
		 'union_type', 6,
sub
#line 1460 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 241
		 'union_type', 5,
sub
#line 1466 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'union_type', 3,
sub
#line 1472 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'union_header', 2,
sub
#line 1481 "parser23.yp"
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
#line 1499 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 249
		 'switch_body', 1,
sub
#line 1507 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 250
		 'switch_body', 2,
sub
#line 1511 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 251
		 'case', 3,
sub
#line 1520 "parser23.yp"
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
#line 1527 "parser23.yp"
{
			$_[0]->Error("';' expected.\n");
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
#line 1539 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 254
		 'case_labels', 2,
sub
#line 1543 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 255
		 'case_label', 3,
sub
#line 1552 "parser23.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 256
		 'case_label', 3,
sub
#line 1556 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 257
		 'case_label', 2,
sub
#line 1562 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 258
		 'case_label', 2,
sub
#line 1567 "parser23.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 259
		 'case_label', 2,
sub
#line 1571 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 260
		 'element_spec', 2,
sub
#line 1581 "parser23.yp"
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
#line 1592 "parser23.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 262
		 'enum_type', 4,
sub
#line 1598 "parser23.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 263
		 'enum_type', 2,
sub
#line 1603 "parser23.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 264
		 'enum_header', 2,
sub
#line 1611 "parser23.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 265
		 'enum_header', 2,
sub
#line 1617 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'enumerators', 1,
sub
#line 1625 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 267
		 'enumerators', 3,
sub
#line 1629 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 268
		 'enumerators', 2,
sub
#line 1634 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 269
		 'enumerators', 2,
sub
#line 1639 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 270
		 'enumerator', 1,
sub
#line 1648 "parser23.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 271
		 'sequence_type', 6,
sub
#line 1658 "parser23.yp"
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
#line 1666 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 273
		 'sequence_type', 4,
sub
#line 1671 "parser23.yp"
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
#line 1678 "parser23.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 275
		 'sequence_type', 2,
sub
#line 1683 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 276
		 'string_type', 4,
sub
#line 1692 "parser23.yp"
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
#line 1699 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 278
		 'string_type', 4,
sub
#line 1705 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'wide_string_type', 4,
sub
#line 1714 "parser23.yp"
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
#line 1721 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 281
		 'wide_string_type', 4,
sub
#line 1727 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 282
		 'array_declarator', 2,
sub
#line 1736 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 283
		 'fixed_array_sizes', 1,
sub
#line 1744 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 284
		 'fixed_array_sizes', 2,
sub
#line 1748 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 285
		 'fixed_array_size', 3,
sub
#line 1757 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 286
		 'fixed_array_size', 3,
sub
#line 1761 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 287
		 'attr_dcl', 4,
sub
#line 1770 "parser23.yp"
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
#line 1778 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 289
		 'attr_dcl', 3,
sub
#line 1783 "parser23.yp"
{
			$_[0]->Error("type expected.\n");
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
#line 1798 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 293
		 'simple_declarators', 3,
sub
#line 1802 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 294
		 'except_dcl', 3,
sub
#line 1811 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 295
		 'except_dcl', 4,
sub
#line 1816 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 296
		 'except_dcl', 4,
sub
#line 1823 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 297
		 'except_dcl', 2,
sub
#line 1829 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 298
		 'exception_header', 2,
sub
#line 1838 "parser23.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 299
		 'exception_header', 2,
sub
#line 1844 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 300
		 'op_dcl', 2,
sub
#line 1853 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 301
		 'op_dcl', 3,
sub
#line 1861 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 302
		 'op_dcl', 4,
sub
#line 1870 "parser23.yp"
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
	[#Rule 303
		 'op_dcl', 3,
sub
#line 1880 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 304
		 'op_dcl', 2,
sub
#line 1889 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 305
		 'op_header', 3,
sub
#line 1899 "parser23.yp"
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
#line 1907 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
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
#line 1931 "parser23.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 312
		 'parameter_dcls', 3,
sub
#line 1941 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 313
		 'parameter_dcls', 2,
sub
#line 1945 "parser23.yp"
{
			undef;
		}
	],
	[#Rule 314
		 'parameter_dcls', 3,
sub
#line 1949 "parser23.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 315
		 'param_dcls', 1,
sub
#line 1957 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 316
		 'param_dcls', 3,
sub
#line 1961 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 317
		 'param_dcls', 2,
sub
#line 1966 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 318
		 'param_dcls', 2,
sub
#line 1971 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 319
		 'param_dcl', 3,
sub
#line 1980 "parser23.yp"
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
#line 2002 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 324
		 'raises_expr', 4,
sub
#line 2006 "parser23.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 325
		 'raises_expr', 2,
sub
#line 2011 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 326
		 'exception_names', 1,
sub
#line 2019 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 327
		 'exception_names', 3,
sub
#line 2023 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 328
		 'exception_name', 1,
sub
#line 2031 "parser23.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 329
		 'context_expr', 4,
sub
#line 2039 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 330
		 'context_expr', 4,
sub
#line 2043 "parser23.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 331
		 'context_expr', 2,
sub
#line 2048 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 332
		 'string_literals', 1,
sub
#line 2056 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 333
		 'string_literals', 3,
sub
#line 2060 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
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
#line 2075 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 338
		 'fixed_pt_type', 6,
sub
#line 2083 "parser23.yp"
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
#line 2091 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 340
		 'fixed_pt_type', 4,
sub
#line 2096 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 341
		 'fixed_pt_type', 2,
sub
#line 2101 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 342
		 'fixed_pt_const_type', 1,
sub
#line 2110 "parser23.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 343
		 'value_base_type', 1,
sub
#line 2120 "parser23.yp"
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

#line 2127 "parser23.yp"


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
