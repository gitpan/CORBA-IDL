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
			'IDENTIFIER' => 37,
			'UNION' => 38,
			'error' => 17,
			'LOCAL' => 20,
			'CONST' => 21,
			'EXCEPTION' => 23,
			'CUSTOM' => 41,
			'ENUM' => 26,
			'INTERFACE' => -33
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
			'module' => 39,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'value_abs_dcl' => 22,
			'type_dcl' => 40,
			'union_header' => 24,
			'definitions' => 25,
			'definition' => 42,
			'interface_mod' => 27
		}
	},
	{#State 1
		DEFAULT => -63
	},
	{#State 2
		ACTIONS => {
			'error' => 44,
			'VALUETYPE' => 43,
			'INTERFACE' => -31
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 46,
			";" => 45
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
			'error' => 51,
			";" => 50
		}
	},
	{#State 7
		DEFAULT => -62
	},
	{#State 8
		ACTIONS => {
			"{" => 52
		}
	},
	{#State 9
		ACTIONS => {
			'error' => 53,
			'IDENTIFIER' => 54
		}
	},
	{#State 10
		DEFAULT => -60
	},
	{#State 11
		ACTIONS => {
			"{" => 55
		}
	},
	{#State 12
		ACTIONS => {
			'error' => 56,
			'IDENTIFIER' => 57
		}
	},
	{#State 13
		DEFAULT => -24
	},
	{#State 14
		ACTIONS => {
			'error' => 59,
			";" => 58
		}
	},
	{#State 15
		DEFAULT => -176
	},
	{#State 16
		DEFAULT => -25
	},
	{#State 17
		DEFAULT => -3
	},
	{#State 18
		ACTIONS => {
			"{" => 61,
			'error' => 60
		}
	},
	{#State 19
		DEFAULT => -178
	},
	{#State 20
		DEFAULT => -32
	},
	{#State 21
		ACTIONS => {
			'CHAR' => 81,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'FIXED' => 64,
			'WCHAR' => 74,
			'DOUBLE' => 85,
			'error' => 76,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'OCTET' => 77,
			'FLOAT' => 79,
			'WSTRING' => 91,
			'UNSIGNED' => 71
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 63,
			'signed_int' => 65,
			'wide_string_type' => 82,
			'integer_type' => 84,
			'boolean_type' => 83,
			'char_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'fixed_pt_const_type' => 88,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'signed_short_int' => 90,
			'const_type' => 92,
			'string_type' => 72,
			'unsigned_longlong_int' => 75,
			'unsigned_long_int' => 95,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80
		}
	},
	{#State 22
		DEFAULT => -61
	},
	{#State 23
		ACTIONS => {
			'error' => 96,
			'IDENTIFIER' => 97
		}
	},
	{#State 24
		ACTIONS => {
			'SWITCH' => 98
		}
	},
	{#State 25
		DEFAULT => -1
	},
	{#State 26
		ACTIONS => {
			'error' => 99,
			'IDENTIFIER' => 100
		}
	},
	{#State 27
		ACTIONS => {
			'INTERFACE' => 101
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 103,
			";" => 102
		}
	},
	{#State 29
		ACTIONS => {
			"{" => 104
		}
	},
	{#State 30
		ACTIONS => {
			'error' => 105,
			'IDENTIFIER' => 107
		},
		GOTOS => {
			'simple_declarator' => 106
		}
	},
	{#State 31
		ACTIONS => {
			"{" => 108
		}
	},
	{#State 32
		ACTIONS => {
			'error' => 109,
			'IDENTIFIER' => 110
		}
	},
	{#State 33
		DEFAULT => -174
	},
	{#State 34
		ACTIONS => {
			"{" => 112,
			'error' => 111
		}
	},
	{#State 35
		ACTIONS => {
			'CHAR' => 81,
			'OBJECT' => 130,
			'VALUEBASE' => 131,
			'FIXED' => 114,
			'SEQUENCE' => 115,
			'STRUCT' => 135,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'UNION' => 138,
			'WCHAR' => 74,
			'error' => 128,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 26,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 120,
			'wide_char_type' => 121,
			'type_spec' => 122,
			'signed_long_int' => 70,
			'type_declarator' => 123,
			'string_type' => 124,
			'struct_header' => 11,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'base_type_spec' => 126,
			'enum_type' => 127,
			'enum_header' => 18,
			'union_header' => 24,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 132,
			'boolean_type' => 133,
			'integer_type' => 134,
			'signed_short_int' => 90,
			'struct_type' => 136,
			'union_type' => 137,
			'sequence_type' => 139,
			'unsigned_long_int' => 95,
			'template_type_spec' => 140,
			'constr_type_spec' => 141,
			'simple_type_spec' => 142,
			'fixed_pt_type' => 143
		}
	},
	{#State 36
		DEFAULT => -175
	},
	{#State 37
		ACTIONS => {
			'error' => 144
		}
	},
	{#State 38
		ACTIONS => {
			'error' => 145,
			'IDENTIFIER' => 146
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
			";" => 149
		}
	},
	{#State 41
		ACTIONS => {
			'error' => 152,
			'VALUETYPE' => 151
		}
	},
	{#State 42
		ACTIONS => {
			'TYPEDEF' => 35,
			'IDENTIFIER' => 37,
			'NATIVE' => 30,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 38,
			'STRUCT' => 32,
			'LOCAL' => 20,
			'CONST' => 21,
			'EXCEPTION' => 23,
			'CUSTOM' => 41,
			'VALUETYPE' => 9,
			'ENUM' => 26,
			'INTERFACE' => -33
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
			'module' => 39,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'value_abs_dcl' => 22,
			'type_dcl' => 40,
			'definitions' => 153,
			'union_header' => 24,
			'definition' => 42,
			'interface_mod' => 27
		}
	},
	{#State 43
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 155
		}
	},
	{#State 44
		DEFAULT => -73
	},
	{#State 45
		DEFAULT => -8
	},
	{#State 46
		DEFAULT => -14
	},
	{#State 47
		DEFAULT => 0
	},
	{#State 48
		DEFAULT => -21
	},
	{#State 49
		ACTIONS => {
			'NATIVE' => 30,
			'ABSTRACT' => 2,
			'STRUCT' => 32,
			'VALUETYPE' => 9,
			'TYPEDEF' => 35,
			'MODULE' => 12,
			'IDENTIFIER' => 37,
			'UNION' => 38,
			'error' => 156,
			'LOCAL' => 20,
			'CONST' => 21,
			'EXCEPTION' => 23,
			'CUSTOM' => 41,
			'ENUM' => 26,
			'INTERFACE' => -33
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
			'module' => 39,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'value_abs_dcl' => 22,
			'type_dcl' => 40,
			'definitions' => 157,
			'union_header' => 24,
			'definition' => 42,
			'interface_mod' => 27
		}
	},
	{#State 50
		DEFAULT => -9
	},
	{#State 51
		DEFAULT => -15
	},
	{#State 52
		ACTIONS => {
			'CHAR' => -310,
			'OBJECT' => -310,
			'ONEWAY' => 158,
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
			'UNION' => 38,
			'READONLY' => 169,
			'WCHAR' => -310,
			'ATTRIBUTE' => -293,
			'error' => 163,
			'CONST' => 21,
			"}" => 164,
			'EXCEPTION' => 23,
			'OCTET' => -310,
			'FLOAT' => -310,
			'ENUM' => 26,
			'ANY' => -310
		},
		GOTOS => {
			'const_dcl' => 165,
			'op_mod' => 159,
			'except_dcl' => 160,
			'op_attribute' => 161,
			'attr_mod' => 162,
			'exports' => 166,
			'export' => 167,
			'struct_type' => 33,
			'op_header' => 168,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 170,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'attr_dcl' => 171,
			'type_dcl' => 172,
			'union_header' => 24
		}
	},
	{#State 53
		DEFAULT => -83
	},
	{#State 54
		ACTIONS => {
			'CHAR' => 81,
			'OBJECT' => 130,
			'VALUEBASE' => 131,
			'FIXED' => 114,
			'SEQUENCE' => 115,
			'STRUCT' => 135,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			":" => 175,
			'UNION' => 138,
			'WCHAR' => 74,
			"{" => -79,
			'SUPPORTS' => 176,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 26,
			'ANY' => 129
		},
		DEFAULT => -64,
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 120,
			'wide_char_type' => 121,
			'type_spec' => 173,
			'signed_long_int' => 70,
			'string_type' => 124,
			'struct_header' => 11,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'base_type_spec' => 126,
			'enum_type' => 127,
			'enum_header' => 18,
			'union_header' => 24,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 132,
			'boolean_type' => 133,
			'integer_type' => 134,
			'signed_short_int' => 90,
			'value_inheritance_spec' => 174,
			'struct_type' => 136,
			'union_type' => 137,
			'sequence_type' => 139,
			'unsigned_long_int' => 95,
			'template_type_spec' => 140,
			'constr_type_spec' => 141,
			'simple_type_spec' => 142,
			'fixed_pt_type' => 143,
			'supported_interface_spec' => 177
		}
	},
	{#State 55
		ACTIONS => {
			'CHAR' => 81,
			'OBJECT' => 130,
			'VALUEBASE' => 131,
			'FIXED' => 114,
			'SEQUENCE' => 115,
			'STRUCT' => 135,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'UNION' => 138,
			'WCHAR' => 74,
			'error' => 179,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 26,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 120,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'type_spec' => 178,
			'string_type' => 124,
			'struct_header' => 11,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'base_type_spec' => 126,
			'enum_type' => 127,
			'enum_header' => 18,
			'member_list' => 180,
			'union_header' => 24,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 132,
			'boolean_type' => 133,
			'integer_type' => 134,
			'signed_short_int' => 90,
			'member' => 181,
			'struct_type' => 136,
			'union_type' => 137,
			'sequence_type' => 139,
			'unsigned_long_int' => 95,
			'template_type_spec' => 140,
			'constr_type_spec' => 141,
			'simple_type_spec' => 142,
			'fixed_pt_type' => 143
		}
	},
	{#State 56
		DEFAULT => -23
	},
	{#State 57
		DEFAULT => -22
	},
	{#State 58
		DEFAULT => -11
	},
	{#State 59
		DEFAULT => -17
	},
	{#State 60
		DEFAULT => -265
	},
	{#State 61
		ACTIONS => {
			'error' => 182,
			'IDENTIFIER' => 184
		},
		GOTOS => {
			'enumerators' => 185,
			'enumerator' => 183
		}
	},
	{#State 62
		DEFAULT => -214
	},
	{#State 63
		DEFAULT => -126
	},
	{#State 64
		DEFAULT => -344
	},
	{#State 65
		DEFAULT => -213
	},
	{#State 66
		DEFAULT => -123
	},
	{#State 67
		DEFAULT => -131
	},
	{#State 68
		ACTIONS => {
			"::" => 186
		},
		DEFAULT => -130
	},
	{#State 69
		DEFAULT => -124
	},
	{#State 70
		DEFAULT => -216
	},
	{#State 71
		ACTIONS => {
			'SHORT' => 187,
			'LONG' => 188
		}
	},
	{#State 72
		DEFAULT => -127
	},
	{#State 73
		DEFAULT => -218
	},
	{#State 74
		DEFAULT => -228
	},
	{#State 75
		DEFAULT => -223
	},
	{#State 76
		DEFAULT => -121
	},
	{#State 77
		DEFAULT => -230
	},
	{#State 78
		DEFAULT => -221
	},
	{#State 79
		DEFAULT => -210
	},
	{#State 80
		DEFAULT => -217
	},
	{#State 81
		DEFAULT => -227
	},
	{#State 82
		DEFAULT => -128
	},
	{#State 83
		DEFAULT => -125
	},
	{#State 84
		DEFAULT => -122
	},
	{#State 85
		DEFAULT => -211
	},
	{#State 86
		ACTIONS => {
			'DOUBLE' => 189,
			'LONG' => 190
		},
		DEFAULT => -219
	},
	{#State 87
		ACTIONS => {
			"<" => 191
		},
		DEFAULT => -279
	},
	{#State 88
		DEFAULT => -129
	},
	{#State 89
		ACTIONS => {
			'error' => 192,
			'IDENTIFIER' => 193
		}
	},
	{#State 90
		DEFAULT => -215
	},
	{#State 91
		ACTIONS => {
			"<" => 194
		},
		DEFAULT => -282
	},
	{#State 92
		ACTIONS => {
			'error' => 195,
			'IDENTIFIER' => 196
		}
	},
	{#State 93
		DEFAULT => -229
	},
	{#State 94
		DEFAULT => -55
	},
	{#State 95
		DEFAULT => -222
	},
	{#State 96
		DEFAULT => -301
	},
	{#State 97
		DEFAULT => -300
	},
	{#State 98
		ACTIONS => {
			'error' => 198,
			"(" => 197
		}
	},
	{#State 99
		DEFAULT => -267
	},
	{#State 100
		DEFAULT => -266
	},
	{#State 101
		ACTIONS => {
			'error' => 199,
			'IDENTIFIER' => 200
		}
	},
	{#State 102
		DEFAULT => -7
	},
	{#State 103
		DEFAULT => -13
	},
	{#State 104
		ACTIONS => {
			'CHAR' => -310,
			'OBJECT' => -310,
			'ONEWAY' => 158,
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
			'UNION' => 38,
			'READONLY' => 169,
			'WCHAR' => -310,
			'ATTRIBUTE' => -293,
			'error' => 201,
			'CONST' => 21,
			"}" => 202,
			'EXCEPTION' => 23,
			'OCTET' => -310,
			'FLOAT' => -310,
			'ENUM' => 26,
			'ANY' => -310
		},
		GOTOS => {
			'const_dcl' => 165,
			'op_mod' => 159,
			'except_dcl' => 160,
			'op_attribute' => 161,
			'attr_mod' => 162,
			'exports' => 203,
			'export' => 167,
			'struct_type' => 33,
			'op_header' => 168,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 170,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'attr_dcl' => 171,
			'type_dcl' => 172,
			'union_header' => 24,
			'interface_body' => 204
		}
	},
	{#State 105
		DEFAULT => -180
	},
	{#State 106
		DEFAULT => -177
	},
	{#State 107
		DEFAULT => -208
	},
	{#State 108
		ACTIONS => {
			'PRIVATE' => 206,
			'ONEWAY' => 158,
			'FACTORY' => 210,
			'UNSIGNED' => -310,
			'SHORT' => -310,
			'WCHAR' => -310,
			'error' => 212,
			'CONST' => 21,
			"}" => 213,
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
			'UNION' => 38,
			'READONLY' => 169,
			'ATTRIBUTE' => -293,
			'PUBLIC' => 216
		},
		GOTOS => {
			'init_header_param' => 205,
			'const_dcl' => 165,
			'op_mod' => 159,
			'value_elements' => 214,
			'except_dcl' => 160,
			'state_member' => 207,
			'op_attribute' => 161,
			'attr_mod' => 162,
			'state_mod' => 208,
			'value_element' => 209,
			'export' => 215,
			'init_header' => 211,
			'struct_type' => 33,
			'op_header' => 168,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 170,
			'init_dcl' => 217,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 171,
			'type_dcl' => 172,
			'union_header' => 24
		}
	},
	{#State 109
		DEFAULT => -347
	},
	{#State 110
		ACTIONS => {
			"{" => -235
		},
		DEFAULT => -346
	},
	{#State 111
		DEFAULT => -299
	},
	{#State 112
		ACTIONS => {
			'CHAR' => 81,
			'OBJECT' => 130,
			'VALUEBASE' => 131,
			'FIXED' => 114,
			'SEQUENCE' => 115,
			'STRUCT' => 135,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'UNION' => 138,
			'WCHAR' => 74,
			'error' => 218,
			"}" => 220,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 26,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 120,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'type_spec' => 178,
			'string_type' => 124,
			'struct_header' => 11,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'base_type_spec' => 126,
			'enum_type' => 127,
			'enum_header' => 18,
			'member_list' => 219,
			'union_header' => 24,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 132,
			'boolean_type' => 133,
			'integer_type' => 134,
			'signed_short_int' => 90,
			'member' => 181,
			'struct_type' => 136,
			'union_type' => 137,
			'sequence_type' => 139,
			'unsigned_long_int' => 95,
			'template_type_spec' => 140,
			'constr_type_spec' => 141,
			'simple_type_spec' => 142,
			'fixed_pt_type' => 143
		}
	},
	{#State 113
		DEFAULT => -188
	},
	{#State 114
		ACTIONS => {
			"<" => 222,
			'error' => 221
		}
	},
	{#State 115
		ACTIONS => {
			"<" => 224,
			'error' => 223
		}
	},
	{#State 116
		DEFAULT => -196
	},
	{#State 117
		DEFAULT => -190
	},
	{#State 118
		DEFAULT => -195
	},
	{#State 119
		DEFAULT => -193
	},
	{#State 120
		ACTIONS => {
			"::" => 186
		},
		DEFAULT => -187
	},
	{#State 121
		DEFAULT => -191
	},
	{#State 122
		ACTIONS => {
			'error' => 227,
			'IDENTIFIER' => 231
		},
		GOTOS => {
			'declarators' => 225,
			'declarator' => 226,
			'simple_declarator' => 229,
			'array_declarator' => 230,
			'complex_declarator' => 228
		}
	},
	{#State 123
		DEFAULT => -173
	},
	{#State 124
		DEFAULT => -198
	},
	{#State 125
		DEFAULT => -194
	},
	{#State 126
		DEFAULT => -185
	},
	{#State 127
		DEFAULT => -203
	},
	{#State 128
		DEFAULT => -179
	},
	{#State 129
		DEFAULT => -231
	},
	{#State 130
		DEFAULT => -232
	},
	{#State 131
		DEFAULT => -345
	},
	{#State 132
		DEFAULT => -199
	},
	{#State 133
		DEFAULT => -192
	},
	{#State 134
		DEFAULT => -189
	},
	{#State 135
		ACTIONS => {
			'IDENTIFIER' => 232
		}
	},
	{#State 136
		DEFAULT => -201
	},
	{#State 137
		DEFAULT => -202
	},
	{#State 138
		ACTIONS => {
			'IDENTIFIER' => 233
		}
	},
	{#State 139
		DEFAULT => -197
	},
	{#State 140
		DEFAULT => -186
	},
	{#State 141
		DEFAULT => -184
	},
	{#State 142
		DEFAULT => -183
	},
	{#State 143
		DEFAULT => -200
	},
	{#State 144
		ACTIONS => {
			";" => 234
		}
	},
	{#State 145
		DEFAULT => -349
	},
	{#State 146
		ACTIONS => {
			'SWITCH' => -245
		},
		DEFAULT => -348
	},
	{#State 147
		DEFAULT => -10
	},
	{#State 148
		DEFAULT => -16
	},
	{#State 149
		DEFAULT => -6
	},
	{#State 150
		DEFAULT => -12
	},
	{#State 151
		ACTIONS => {
			'error' => 235,
			'IDENTIFIER' => 236
		}
	},
	{#State 152
		DEFAULT => -85
	},
	{#State 153
		DEFAULT => -5
	},
	{#State 154
		DEFAULT => -72
	},
	{#State 155
		ACTIONS => {
			"{" => -70,
			'SUPPORTS' => 176,
			":" => 175
		},
		DEFAULT => -65,
		GOTOS => {
			'supported_interface_spec' => 177,
			'value_inheritance_spec' => 237
		}
	},
	{#State 156
		ACTIONS => {
			"}" => 238
		}
	},
	{#State 157
		ACTIONS => {
			"}" => 239
		}
	},
	{#State 158
		DEFAULT => -311
	},
	{#State 159
		ACTIONS => {
			'CHAR' => 81,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'OBJECT' => 130,
			'IDENTIFIER' => 94,
			'VALUEBASE' => 131,
			'VOID' => 245,
			'WCHAR' => 74,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'OCTET' => 77,
			'FLOAT' => 79,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'wide_string_type' => 244,
			'integer_type' => 134,
			'boolean_type' => 133,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 240,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'signed_short_int' => 90,
			'string_type' => 241,
			'op_type_spec' => 246,
			'base_type_spec' => 242,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'unsigned_long_int' => 95,
			'param_type_spec' => 243,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80
		}
	},
	{#State 160
		ACTIONS => {
			'error' => 248,
			";" => 247
		}
	},
	{#State 161
		DEFAULT => -309
	},
	{#State 162
		ACTIONS => {
			'ATTRIBUTE' => 249
		}
	},
	{#State 163
		ACTIONS => {
			"}" => 250
		}
	},
	{#State 164
		DEFAULT => -67
	},
	{#State 165
		ACTIONS => {
			'error' => 252,
			";" => 251
		}
	},
	{#State 166
		ACTIONS => {
			"}" => 253
		}
	},
	{#State 167
		ACTIONS => {
			'ONEWAY' => 158,
			'NATIVE' => 30,
			'STRUCT' => 32,
			'TYPEDEF' => 35,
			'UNION' => 38,
			'READONLY' => 169,
			'ATTRIBUTE' => -293,
			'CONST' => 21,
			"}" => -38,
			'EXCEPTION' => 23,
			'ENUM' => 26
		},
		DEFAULT => -310,
		GOTOS => {
			'const_dcl' => 165,
			'op_mod' => 159,
			'except_dcl' => 160,
			'op_attribute' => 161,
			'attr_mod' => 162,
			'exports' => 254,
			'export' => 167,
			'struct_type' => 33,
			'op_header' => 168,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 170,
			'constr_forward_decl' => 19,
			'enum_header' => 18,
			'attr_dcl' => 171,
			'type_dcl' => 172,
			'union_header' => 24
		}
	},
	{#State 168
		ACTIONS => {
			'error' => 256,
			"(" => 255
		},
		GOTOS => {
			'parameter_dcls' => 257
		}
	},
	{#State 169
		DEFAULT => -292
	},
	{#State 170
		ACTIONS => {
			'error' => 259,
			";" => 258
		}
	},
	{#State 171
		ACTIONS => {
			'error' => 261,
			";" => 260
		}
	},
	{#State 172
		ACTIONS => {
			'error' => 263,
			";" => 262
		}
	},
	{#State 173
		DEFAULT => -66
	},
	{#State 174
		DEFAULT => -81
	},
	{#State 175
		ACTIONS => {
			'TRUNCATABLE' => 265
		},
		DEFAULT => -91,
		GOTOS => {
			'inheritance_mod' => 264
		}
	},
	{#State 176
		ACTIONS => {
			'error' => 267,
			'IDENTIFIER' => 94,
			"::" => 89
		},
		GOTOS => {
			'scoped_name' => 266,
			'interface_names' => 269,
			'interface_name' => 268
		}
	},
	{#State 177
		DEFAULT => -89
	},
	{#State 178
		ACTIONS => {
			'IDENTIFIER' => 231
		},
		GOTOS => {
			'declarators' => 270,
			'declarator' => 226,
			'simple_declarator' => 229,
			'array_declarator' => 230,
			'complex_declarator' => 228
		}
	},
	{#State 179
		ACTIONS => {
			"}" => 271
		}
	},
	{#State 180
		ACTIONS => {
			"}" => 272
		}
	},
	{#State 181
		ACTIONS => {
			'CHAR' => 81,
			'OBJECT' => 130,
			'VALUEBASE' => 131,
			'FIXED' => 114,
			'SEQUENCE' => 115,
			'STRUCT' => 135,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'UNION' => 138,
			'WCHAR' => 74,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 26,
			'ANY' => 129
		},
		DEFAULT => -236,
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 120,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'type_spec' => 178,
			'string_type' => 124,
			'struct_header' => 11,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'base_type_spec' => 126,
			'enum_type' => 127,
			'enum_header' => 18,
			'member_list' => 273,
			'union_header' => 24,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 132,
			'boolean_type' => 133,
			'integer_type' => 134,
			'signed_short_int' => 90,
			'member' => 181,
			'struct_type' => 136,
			'union_type' => 137,
			'sequence_type' => 139,
			'unsigned_long_int' => 95,
			'template_type_spec' => 140,
			'constr_type_spec' => 141,
			'simple_type_spec' => 142,
			'fixed_pt_type' => 143
		}
	},
	{#State 182
		ACTIONS => {
			"}" => 274
		}
	},
	{#State 183
		ACTIONS => {
			";" => 275,
			"," => 276
		},
		DEFAULT => -268
	},
	{#State 184
		DEFAULT => -272
	},
	{#State 185
		ACTIONS => {
			"}" => 277
		}
	},
	{#State 186
		ACTIONS => {
			'error' => 278,
			'IDENTIFIER' => 279
		}
	},
	{#State 187
		DEFAULT => -224
	},
	{#State 188
		ACTIONS => {
			'LONG' => 280
		},
		DEFAULT => -225
	},
	{#State 189
		DEFAULT => -212
	},
	{#State 190
		DEFAULT => -220
	},
	{#State 191
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 290,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'primary_expr' => 300,
			'and_expr' => 301,
			'scoped_name' => 283,
			'positive_int_const' => 284,
			'wide_string_literal' => 285,
			'boolean_literal' => 287,
			'mult_expr' => 303,
			'const_exp' => 288,
			'or_expr' => 289,
			'unary_expr' => 307,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 192
		DEFAULT => -57
	},
	{#State 193
		DEFAULT => -56
	},
	{#State 194
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 312,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'primary_expr' => 300,
			'and_expr' => 301,
			'scoped_name' => 283,
			'positive_int_const' => 311,
			'wide_string_literal' => 285,
			'boolean_literal' => 287,
			'mult_expr' => 303,
			'const_exp' => 288,
			'or_expr' => 289,
			'unary_expr' => 307,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 195
		DEFAULT => -120
	},
	{#State 196
		ACTIONS => {
			'error' => 313,
			"=" => 314
		}
	},
	{#State 197
		ACTIONS => {
			'CHAR' => 81,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'error' => 318,
			'LONG' => 322,
			"::" => 89,
			'ENUM' => 26,
			'UNSIGNED' => 71
		},
		GOTOS => {
			'switch_type_spec' => 319,
			'unsigned_int' => 62,
			'signed_int' => 65,
			'integer_type' => 321,
			'boolean_type' => 320,
			'unsigned_longlong_int' => 75,
			'char_type' => 315,
			'enum_type' => 317,
			'unsigned_long_int' => 95,
			'scoped_name' => 316,
			'enum_header' => 18,
			'signed_long_int' => 70,
			'unsigned_short_int' => 78,
			'signed_short_int' => 90,
			'signed_longlong_int' => 80
		}
	},
	{#State 198
		DEFAULT => -244
	},
	{#State 199
		ACTIONS => {
			"{" => -36
		},
		DEFAULT => -30
	},
	{#State 200
		ACTIONS => {
			"{" => -34,
			":" => 323
		},
		DEFAULT => -29,
		GOTOS => {
			'interface_inheritance_spec' => 324
		}
	},
	{#State 201
		ACTIONS => {
			"}" => 325
		}
	},
	{#State 202
		DEFAULT => -26
	},
	{#State 203
		DEFAULT => -37
	},
	{#State 204
		ACTIONS => {
			"}" => 326
		}
	},
	{#State 205
		ACTIONS => {
			'error' => 328,
			";" => 327
		}
	},
	{#State 206
		DEFAULT => -104
	},
	{#State 207
		DEFAULT => -98
	},
	{#State 208
		ACTIONS => {
			'CHAR' => 81,
			'OBJECT' => 130,
			'VALUEBASE' => 131,
			'FIXED' => 114,
			'SEQUENCE' => 115,
			'STRUCT' => 135,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'UNION' => 138,
			'WCHAR' => 74,
			'error' => 330,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 26,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 120,
			'wide_char_type' => 121,
			'type_spec' => 329,
			'signed_long_int' => 70,
			'string_type' => 124,
			'struct_header' => 11,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'base_type_spec' => 126,
			'enum_type' => 127,
			'enum_header' => 18,
			'union_header' => 24,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 132,
			'boolean_type' => 133,
			'integer_type' => 134,
			'signed_short_int' => 90,
			'struct_type' => 136,
			'union_type' => 137,
			'sequence_type' => 139,
			'unsigned_long_int' => 95,
			'template_type_spec' => 140,
			'constr_type_spec' => 141,
			'simple_type_spec' => 142,
			'fixed_pt_type' => 143
		}
	},
	{#State 209
		ACTIONS => {
			'PRIVATE' => 206,
			'ONEWAY' => 158,
			'FACTORY' => 210,
			'CONST' => 21,
			'EXCEPTION' => 23,
			"}" => -77,
			'ENUM' => 26,
			'NATIVE' => 30,
			'STRUCT' => 32,
			'TYPEDEF' => 35,
			'UNION' => 38,
			'READONLY' => 169,
			'ATTRIBUTE' => -293,
			'PUBLIC' => 216
		},
		DEFAULT => -310,
		GOTOS => {
			'init_header_param' => 205,
			'const_dcl' => 165,
			'op_mod' => 159,
			'value_elements' => 331,
			'except_dcl' => 160,
			'state_member' => 207,
			'op_attribute' => 161,
			'attr_mod' => 162,
			'state_mod' => 208,
			'value_element' => 209,
			'export' => 215,
			'init_header' => 211,
			'struct_type' => 33,
			'op_header' => 168,
			'exception_header' => 34,
			'union_type' => 36,
			'struct_header' => 11,
			'enum_type' => 15,
			'op_dcl' => 170,
			'init_dcl' => 217,
			'enum_header' => 18,
			'constr_forward_decl' => 19,
			'attr_dcl' => 171,
			'type_dcl' => 172,
			'union_header' => 24
		}
	},
	{#State 210
		ACTIONS => {
			'error' => 332,
			'IDENTIFIER' => 333
		}
	},
	{#State 211
		ACTIONS => {
			'error' => 335,
			"(" => 334
		}
	},
	{#State 212
		ACTIONS => {
			"}" => 336
		}
	},
	{#State 213
		DEFAULT => -74
	},
	{#State 214
		ACTIONS => {
			"}" => 337
		}
	},
	{#State 215
		DEFAULT => -97
	},
	{#State 216
		DEFAULT => -103
	},
	{#State 217
		DEFAULT => -99
	},
	{#State 218
		ACTIONS => {
			"}" => 338
		}
	},
	{#State 219
		ACTIONS => {
			"}" => 339
		}
	},
	{#State 220
		DEFAULT => -296
	},
	{#State 221
		DEFAULT => -343
	},
	{#State 222
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 341,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'primary_expr' => 300,
			'and_expr' => 301,
			'scoped_name' => 283,
			'positive_int_const' => 340,
			'wide_string_literal' => 285,
			'boolean_literal' => 287,
			'mult_expr' => 303,
			'const_exp' => 288,
			'or_expr' => 289,
			'unary_expr' => 307,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 223
		DEFAULT => -277
	},
	{#State 224
		ACTIONS => {
			'CHAR' => 81,
			'OBJECT' => 130,
			'VALUEBASE' => 131,
			'FIXED' => 114,
			'SEQUENCE' => 115,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'WCHAR' => 74,
			'error' => 342,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'wide_string_type' => 132,
			'integer_type' => 134,
			'boolean_type' => 133,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 120,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'signed_short_int' => 90,
			'string_type' => 124,
			'sequence_type' => 139,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'base_type_spec' => 126,
			'unsigned_long_int' => 95,
			'template_type_spec' => 140,
			'unsigned_short_int' => 78,
			'simple_type_spec' => 343,
			'fixed_pt_type' => 143,
			'signed_longlong_int' => 80
		}
	},
	{#State 225
		DEFAULT => -181
	},
	{#State 226
		ACTIONS => {
			"," => 344
		},
		DEFAULT => -204
	},
	{#State 227
		DEFAULT => -182
	},
	{#State 228
		DEFAULT => -207
	},
	{#State 229
		DEFAULT => -206
	},
	{#State 230
		DEFAULT => -209
	},
	{#State 231
		ACTIONS => {
			"[" => 347
		},
		DEFAULT => -208,
		GOTOS => {
			'fixed_array_sizes' => 345,
			'fixed_array_size' => 346
		}
	},
	{#State 232
		DEFAULT => -235
	},
	{#State 233
		DEFAULT => -245
	},
	{#State 234
		DEFAULT => -18
	},
	{#State 235
		DEFAULT => -84
	},
	{#State 236
		ACTIONS => {
			'SUPPORTS' => 176,
			":" => 175
		},
		DEFAULT => -80,
		GOTOS => {
			'supported_interface_spec' => 177,
			'value_inheritance_spec' => 348
		}
	},
	{#State 237
		DEFAULT => -71
	},
	{#State 238
		DEFAULT => -20
	},
	{#State 239
		DEFAULT => -19
	},
	{#State 240
		ACTIONS => {
			"::" => 186
		},
		DEFAULT => -339
	},
	{#State 241
		DEFAULT => -337
	},
	{#State 242
		DEFAULT => -336
	},
	{#State 243
		DEFAULT => -312
	},
	{#State 244
		DEFAULT => -338
	},
	{#State 245
		DEFAULT => -313
	},
	{#State 246
		ACTIONS => {
			'error' => 349,
			'IDENTIFIER' => 350
		}
	},
	{#State 247
		DEFAULT => -42
	},
	{#State 248
		DEFAULT => -47
	},
	{#State 249
		ACTIONS => {
			'CHAR' => 81,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'OBJECT' => 130,
			'IDENTIFIER' => 94,
			'VALUEBASE' => 131,
			'WCHAR' => 74,
			'DOUBLE' => 85,
			'error' => 351,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'OCTET' => 77,
			'FLOAT' => 79,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'wide_string_type' => 244,
			'integer_type' => 134,
			'boolean_type' => 133,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 240,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'signed_short_int' => 90,
			'string_type' => 241,
			'base_type_spec' => 242,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'unsigned_long_int' => 95,
			'param_type_spec' => 352,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80
		}
	},
	{#State 250
		DEFAULT => -69
	},
	{#State 251
		DEFAULT => -41
	},
	{#State 252
		DEFAULT => -46
	},
	{#State 253
		DEFAULT => -68
	},
	{#State 254
		DEFAULT => -39
	},
	{#State 255
		ACTIONS => {
			'error' => 354,
			")" => 358,
			'OUT' => 359,
			'INOUT' => 355,
			'IN' => 353
		},
		GOTOS => {
			'param_dcl' => 360,
			'param_dcls' => 357,
			'param_attribute' => 356
		}
	},
	{#State 256
		DEFAULT => -306
	},
	{#State 257
		ACTIONS => {
			'RAISES' => 364,
			'CONTEXT' => 361
		},
		DEFAULT => -302,
		GOTOS => {
			'context_expr' => 363,
			'raises_expr' => 362
		}
	},
	{#State 258
		DEFAULT => -44
	},
	{#State 259
		DEFAULT => -49
	},
	{#State 260
		DEFAULT => -43
	},
	{#State 261
		DEFAULT => -48
	},
	{#State 262
		DEFAULT => -40
	},
	{#State 263
		DEFAULT => -45
	},
	{#State 264
		ACTIONS => {
			'error' => 367,
			'IDENTIFIER' => 94,
			"::" => 89
		},
		GOTOS => {
			'scoped_name' => 365,
			'value_name' => 366,
			'value_names' => 368
		}
	},
	{#State 265
		DEFAULT => -90
	},
	{#State 266
		ACTIONS => {
			"::" => 186
		},
		DEFAULT => -54
	},
	{#State 267
		DEFAULT => -95
	},
	{#State 268
		ACTIONS => {
			"," => 369
		},
		DEFAULT => -52
	},
	{#State 269
		DEFAULT => -94
	},
	{#State 270
		ACTIONS => {
			'error' => 371,
			";" => 370
		}
	},
	{#State 271
		DEFAULT => -234
	},
	{#State 272
		DEFAULT => -233
	},
	{#State 273
		DEFAULT => -237
	},
	{#State 274
		DEFAULT => -264
	},
	{#State 275
		DEFAULT => -271
	},
	{#State 276
		ACTIONS => {
			'IDENTIFIER' => 184
		},
		DEFAULT => -270,
		GOTOS => {
			'enumerators' => 372,
			'enumerator' => 183
		}
	},
	{#State 277
		DEFAULT => -263
	},
	{#State 278
		DEFAULT => -59
	},
	{#State 279
		DEFAULT => -58
	},
	{#State 280
		DEFAULT => -226
	},
	{#State 281
		DEFAULT => -161
	},
	{#State 282
		DEFAULT => -162
	},
	{#State 283
		ACTIONS => {
			"::" => 186
		},
		DEFAULT => -154
	},
	{#State 284
		ACTIONS => {
			">" => 373
		}
	},
	{#State 285
		DEFAULT => -160
	},
	{#State 286
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 375,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 303,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'const_exp' => 374,
			'and_expr' => 301,
			'or_expr' => 289,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 287
		DEFAULT => -165
	},
	{#State 288
		DEFAULT => -172
	},
	{#State 289
		ACTIONS => {
			"|" => 376
		},
		DEFAULT => -132
	},
	{#State 290
		ACTIONS => {
			">" => 377
		}
	},
	{#State 291
		ACTIONS => {
			"^" => 378
		},
		DEFAULT => -133
	},
	{#State 292
		ACTIONS => {
			"<<" => 379,
			">>" => 380
		},
		DEFAULT => -137
	},
	{#State 293
		DEFAULT => -171
	},
	{#State 294
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 294
		},
		DEFAULT => -168,
		GOTOS => {
			'wide_string_literal' => 381
		}
	},
	{#State 295
		DEFAULT => -155
	},
	{#State 296
		DEFAULT => -170
	},
	{#State 297
		ACTIONS => {
			"+" => 382,
			"-" => 383
		},
		DEFAULT => -139
	},
	{#State 298
		DEFAULT => -159
	},
	{#State 299
		DEFAULT => -164
	},
	{#State 300
		DEFAULT => -150
	},
	{#State 301
		ACTIONS => {
			"&" => 384
		},
		DEFAULT => -135
	},
	{#State 302
		DEFAULT => -158
	},
	{#State 303
		ACTIONS => {
			"%" => 386,
			"*" => 385,
			"/" => 387
		},
		DEFAULT => -142
	},
	{#State 304
		ACTIONS => {
			'STRING_LITERAL' => 304
		},
		DEFAULT => -166,
		GOTOS => {
			'string_literal' => 388
		}
	},
	{#State 305
		DEFAULT => -163
	},
	{#State 306
		DEFAULT => -152
	},
	{#State 307
		DEFAULT => -145
	},
	{#State 308
		DEFAULT => -151
	},
	{#State 309
		DEFAULT => -153
	},
	{#State 310
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'boolean_literal' => 287,
			'scoped_name' => 283,
			'primary_expr' => 389,
			'literal' => 295,
			'wide_string_literal' => 285
		}
	},
	{#State 311
		ACTIONS => {
			">" => 390
		}
	},
	{#State 312
		ACTIONS => {
			">" => 391
		}
	},
	{#State 313
		DEFAULT => -119
	},
	{#State 314
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 393,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 303,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'const_exp' => 392,
			'and_expr' => 301,
			'or_expr' => 289,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 315
		DEFAULT => -247
	},
	{#State 316
		ACTIONS => {
			"::" => 186
		},
		DEFAULT => -250
	},
	{#State 317
		DEFAULT => -249
	},
	{#State 318
		ACTIONS => {
			")" => 394
		}
	},
	{#State 319
		ACTIONS => {
			")" => 395
		}
	},
	{#State 320
		DEFAULT => -248
	},
	{#State 321
		DEFAULT => -246
	},
	{#State 322
		ACTIONS => {
			'LONG' => 190
		},
		DEFAULT => -219
	},
	{#State 323
		ACTIONS => {
			'error' => 396,
			'IDENTIFIER' => 94,
			"::" => 89
		},
		GOTOS => {
			'scoped_name' => 266,
			'interface_names' => 397,
			'interface_name' => 268
		}
	},
	{#State 324
		DEFAULT => -35
	},
	{#State 325
		DEFAULT => -28
	},
	{#State 326
		DEFAULT => -27
	},
	{#State 327
		DEFAULT => -105
	},
	{#State 328
		DEFAULT => -106
	},
	{#State 329
		ACTIONS => {
			'error' => 399,
			'IDENTIFIER' => 231
		},
		GOTOS => {
			'declarators' => 398,
			'declarator' => 226,
			'simple_declarator' => 229,
			'array_declarator' => 230,
			'complex_declarator' => 228
		}
	},
	{#State 330
		ACTIONS => {
			";" => 400
		}
	},
	{#State 331
		DEFAULT => -78
	},
	{#State 332
		DEFAULT => -112
	},
	{#State 333
		DEFAULT => -111
	},
	{#State 334
		ACTIONS => {
			'error' => 405,
			")" => 406,
			'IN' => 403
		},
		GOTOS => {
			'init_param_decls' => 402,
			'init_param_attribute' => 401,
			'init_param_decl' => 404
		}
	},
	{#State 335
		DEFAULT => -110
	},
	{#State 336
		DEFAULT => -76
	},
	{#State 337
		DEFAULT => -75
	},
	{#State 338
		DEFAULT => -298
	},
	{#State 339
		DEFAULT => -297
	},
	{#State 340
		ACTIONS => {
			"," => 407
		}
	},
	{#State 341
		ACTIONS => {
			">" => 408
		}
	},
	{#State 342
		ACTIONS => {
			">" => 409
		}
	},
	{#State 343
		ACTIONS => {
			">" => 411,
			"," => 410
		}
	},
	{#State 344
		ACTIONS => {
			'IDENTIFIER' => 231
		},
		GOTOS => {
			'declarators' => 412,
			'declarator' => 226,
			'simple_declarator' => 229,
			'array_declarator' => 230,
			'complex_declarator' => 228
		}
	},
	{#State 345
		DEFAULT => -284
	},
	{#State 346
		ACTIONS => {
			"[" => 347
		},
		DEFAULT => -285,
		GOTOS => {
			'fixed_array_sizes' => 413,
			'fixed_array_size' => 346
		}
	},
	{#State 347
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 415,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'primary_expr' => 300,
			'and_expr' => 301,
			'scoped_name' => 283,
			'positive_int_const' => 414,
			'wide_string_literal' => 285,
			'boolean_literal' => 287,
			'mult_expr' => 303,
			'const_exp' => 288,
			'or_expr' => 289,
			'unary_expr' => 307,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 348
		DEFAULT => -82
	},
	{#State 349
		DEFAULT => -308
	},
	{#State 350
		DEFAULT => -307
	},
	{#State 351
		DEFAULT => -291
	},
	{#State 352
		ACTIONS => {
			'error' => 416,
			'IDENTIFIER' => 107
		},
		GOTOS => {
			'simple_declarators' => 418,
			'simple_declarator' => 417
		}
	},
	{#State 353
		DEFAULT => -322
	},
	{#State 354
		ACTIONS => {
			")" => 419
		}
	},
	{#State 355
		DEFAULT => -324
	},
	{#State 356
		ACTIONS => {
			'CHAR' => 81,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'OBJECT' => 130,
			'IDENTIFIER' => 94,
			'VALUEBASE' => 131,
			'WCHAR' => 74,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'OCTET' => 77,
			'FLOAT' => 79,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'wide_string_type' => 244,
			'integer_type' => 134,
			'boolean_type' => 133,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 240,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'signed_short_int' => 90,
			'string_type' => 241,
			'base_type_spec' => 242,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'unsigned_long_int' => 95,
			'param_type_spec' => 420,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80
		}
	},
	{#State 357
		ACTIONS => {
			")" => 421
		}
	},
	{#State 358
		DEFAULT => -315
	},
	{#State 359
		DEFAULT => -323
	},
	{#State 360
		ACTIONS => {
			";" => 422,
			"," => 423
		},
		DEFAULT => -317
	},
	{#State 361
		ACTIONS => {
			'error' => 425,
			"(" => 424
		}
	},
	{#State 362
		ACTIONS => {
			'CONTEXT' => 361
		},
		DEFAULT => -303,
		GOTOS => {
			'context_expr' => 426
		}
	},
	{#State 363
		DEFAULT => -305
	},
	{#State 364
		ACTIONS => {
			'error' => 428,
			"(" => 427
		}
	},
	{#State 365
		ACTIONS => {
			"::" => 186
		},
		DEFAULT => -96
	},
	{#State 366
		ACTIONS => {
			"," => 429
		},
		DEFAULT => -92
	},
	{#State 367
		DEFAULT => -88
	},
	{#State 368
		ACTIONS => {
			'SUPPORTS' => 176
		},
		DEFAULT => -86,
		GOTOS => {
			'supported_interface_spec' => 430
		}
	},
	{#State 369
		ACTIONS => {
			'IDENTIFIER' => 94,
			"::" => 89
		},
		GOTOS => {
			'scoped_name' => 266,
			'interface_names' => 431,
			'interface_name' => 268
		}
	},
	{#State 370
		DEFAULT => -238
	},
	{#State 371
		DEFAULT => -239
	},
	{#State 372
		DEFAULT => -269
	},
	{#State 373
		DEFAULT => -278
	},
	{#State 374
		ACTIONS => {
			")" => 432
		}
	},
	{#State 375
		ACTIONS => {
			")" => 433
		}
	},
	{#State 376
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 303,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'and_expr' => 301,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'xor_expr' => 434,
			'shift_expr' => 292,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 377
		DEFAULT => -280
	},
	{#State 378
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 303,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'and_expr' => 435,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'shift_expr' => 292,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 379
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 303,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 436
		}
	},
	{#State 380
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 303,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 437
		}
	},
	{#State 381
		DEFAULT => -169
	},
	{#State 382
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 438,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310
		}
	},
	{#State 383
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 439,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310
		}
	},
	{#State 384
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 303,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'shift_expr' => 440,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 385
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'unary_expr' => 441,
			'scoped_name' => 283,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310
		}
	},
	{#State 386
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'unary_expr' => 442,
			'scoped_name' => 283,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310
		}
	},
	{#State 387
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'CHARACTER_LITERAL' => 281,
			"+" => 306,
			'FIXED_PT_LITERAL' => 305,
			'WIDE_CHARACTER_LITERAL' => 282,
			"-" => 308,
			"::" => 89,
			'FALSE' => 293,
			'WIDE_STRING_LITERAL' => 294,
			'INTEGER_LITERAL' => 302,
			"~" => 309,
			"(" => 286,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'unary_expr' => 443,
			'scoped_name' => 283,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310
		}
	},
	{#State 388
		DEFAULT => -167
	},
	{#State 389
		DEFAULT => -149
	},
	{#State 390
		DEFAULT => -281
	},
	{#State 391
		DEFAULT => -283
	},
	{#State 392
		DEFAULT => -117
	},
	{#State 393
		DEFAULT => -118
	},
	{#State 394
		DEFAULT => -243
	},
	{#State 395
		ACTIONS => {
			"{" => 445,
			'error' => 444
		}
	},
	{#State 396
		DEFAULT => -51
	},
	{#State 397
		DEFAULT => -50
	},
	{#State 398
		ACTIONS => {
			";" => 446
		}
	},
	{#State 399
		ACTIONS => {
			";" => 447
		}
	},
	{#State 400
		DEFAULT => -102
	},
	{#State 401
		ACTIONS => {
			'CHAR' => 81,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'OBJECT' => 130,
			'IDENTIFIER' => 94,
			'VALUEBASE' => 131,
			'WCHAR' => 74,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'OCTET' => 77,
			'FLOAT' => 79,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'wide_string_type' => 244,
			'integer_type' => 134,
			'boolean_type' => 133,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 240,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'signed_short_int' => 90,
			'string_type' => 241,
			'base_type_spec' => 242,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'unsigned_long_int' => 95,
			'param_type_spec' => 448,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80
		}
	},
	{#State 402
		ACTIONS => {
			")" => 449
		}
	},
	{#State 403
		DEFAULT => -116
	},
	{#State 404
		ACTIONS => {
			"," => 450
		},
		DEFAULT => -113
	},
	{#State 405
		ACTIONS => {
			")" => 451
		}
	},
	{#State 406
		DEFAULT => -107
	},
	{#State 407
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 453,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'primary_expr' => 300,
			'and_expr' => 301,
			'scoped_name' => 283,
			'positive_int_const' => 452,
			'wide_string_literal' => 285,
			'boolean_literal' => 287,
			'mult_expr' => 303,
			'const_exp' => 288,
			'or_expr' => 289,
			'unary_expr' => 307,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 408
		DEFAULT => -342
	},
	{#State 409
		DEFAULT => -276
	},
	{#State 410
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 455,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'string_literal' => 298,
			'primary_expr' => 300,
			'and_expr' => 301,
			'scoped_name' => 283,
			'positive_int_const' => 454,
			'wide_string_literal' => 285,
			'boolean_literal' => 287,
			'mult_expr' => 303,
			'const_exp' => 288,
			'or_expr' => 289,
			'unary_expr' => 307,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
		}
	},
	{#State 411
		DEFAULT => -275
	},
	{#State 412
		DEFAULT => -205
	},
	{#State 413
		DEFAULT => -286
	},
	{#State 414
		ACTIONS => {
			"]" => 456
		}
	},
	{#State 415
		ACTIONS => {
			"]" => 457
		}
	},
	{#State 416
		DEFAULT => -290
	},
	{#State 417
		ACTIONS => {
			"," => 458
		},
		DEFAULT => -294
	},
	{#State 418
		DEFAULT => -289
	},
	{#State 419
		DEFAULT => -316
	},
	{#State 420
		ACTIONS => {
			'IDENTIFIER' => 107
		},
		GOTOS => {
			'simple_declarator' => 459
		}
	},
	{#State 421
		DEFAULT => -314
	},
	{#State 422
		DEFAULT => -320
	},
	{#State 423
		ACTIONS => {
			'OUT' => 359,
			'INOUT' => 355,
			'IN' => 353
		},
		DEFAULT => -319,
		GOTOS => {
			'param_dcl' => 360,
			'param_dcls' => 460,
			'param_attribute' => 356
		}
	},
	{#State 424
		ACTIONS => {
			'error' => 461,
			'STRING_LITERAL' => 304
		},
		GOTOS => {
			'string_literal' => 462,
			'string_literals' => 463
		}
	},
	{#State 425
		DEFAULT => -333
	},
	{#State 426
		DEFAULT => -304
	},
	{#State 427
		ACTIONS => {
			'error' => 465,
			'IDENTIFIER' => 94,
			"::" => 89
		},
		GOTOS => {
			'scoped_name' => 464,
			'exception_names' => 466,
			'exception_name' => 467
		}
	},
	{#State 428
		DEFAULT => -327
	},
	{#State 429
		ACTIONS => {
			'IDENTIFIER' => 94,
			"::" => 89
		},
		GOTOS => {
			'scoped_name' => 365,
			'value_name' => 366,
			'value_names' => 468
		}
	},
	{#State 430
		DEFAULT => -87
	},
	{#State 431
		DEFAULT => -53
	},
	{#State 432
		DEFAULT => -156
	},
	{#State 433
		DEFAULT => -157
	},
	{#State 434
		ACTIONS => {
			"^" => 378
		},
		DEFAULT => -134
	},
	{#State 435
		ACTIONS => {
			"&" => 384
		},
		DEFAULT => -136
	},
	{#State 436
		ACTIONS => {
			"+" => 382,
			"-" => 383
		},
		DEFAULT => -141
	},
	{#State 437
		ACTIONS => {
			"+" => 382,
			"-" => 383
		},
		DEFAULT => -140
	},
	{#State 438
		ACTIONS => {
			"%" => 386,
			"*" => 385,
			"/" => 387
		},
		DEFAULT => -143
	},
	{#State 439
		ACTIONS => {
			"%" => 386,
			"*" => 385,
			"/" => 387
		},
		DEFAULT => -144
	},
	{#State 440
		ACTIONS => {
			"<<" => 379,
			">>" => 380
		},
		DEFAULT => -138
	},
	{#State 441
		DEFAULT => -146
	},
	{#State 442
		DEFAULT => -148
	},
	{#State 443
		DEFAULT => -147
	},
	{#State 444
		DEFAULT => -242
	},
	{#State 445
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
	{#State 446
		DEFAULT => -100
	},
	{#State 447
		DEFAULT => -101
	},
	{#State 448
		ACTIONS => {
			'IDENTIFIER' => 107
		},
		GOTOS => {
			'simple_declarator' => 476
		}
	},
	{#State 449
		DEFAULT => -108
	},
	{#State 450
		ACTIONS => {
			'IN' => 403
		},
		GOTOS => {
			'init_param_decls' => 477,
			'init_param_attribute' => 401,
			'init_param_decl' => 404
		}
	},
	{#State 451
		DEFAULT => -109
	},
	{#State 452
		ACTIONS => {
			">" => 478
		}
	},
	{#State 453
		ACTIONS => {
			">" => 479
		}
	},
	{#State 454
		ACTIONS => {
			">" => 480
		}
	},
	{#State 455
		ACTIONS => {
			">" => 481
		}
	},
	{#State 456
		DEFAULT => -287
	},
	{#State 457
		DEFAULT => -288
	},
	{#State 458
		ACTIONS => {
			'IDENTIFIER' => 107
		},
		GOTOS => {
			'simple_declarators' => 482,
			'simple_declarator' => 417
		}
	},
	{#State 459
		DEFAULT => -321
	},
	{#State 460
		DEFAULT => -318
	},
	{#State 461
		ACTIONS => {
			")" => 483
		}
	},
	{#State 462
		ACTIONS => {
			"," => 484
		},
		DEFAULT => -334
	},
	{#State 463
		ACTIONS => {
			")" => 485
		}
	},
	{#State 464
		ACTIONS => {
			"::" => 186
		},
		DEFAULT => -330
	},
	{#State 465
		ACTIONS => {
			")" => 486
		}
	},
	{#State 466
		ACTIONS => {
			")" => 487
		}
	},
	{#State 467
		ACTIONS => {
			"," => 488
		},
		DEFAULT => -328
	},
	{#State 468
		DEFAULT => -93
	},
	{#State 469
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 299,
			'CHARACTER_LITERAL' => 281,
			'WIDE_CHARACTER_LITERAL' => 282,
			"::" => 89,
			'INTEGER_LITERAL' => 302,
			"(" => 286,
			'IDENTIFIER' => 94,
			'STRING_LITERAL' => 304,
			'FIXED_PT_LITERAL' => 305,
			"+" => 306,
			'error' => 490,
			"-" => 308,
			'WIDE_STRING_LITERAL' => 294,
			'FALSE' => 293,
			"~" => 309,
			'TRUE' => 296
		},
		GOTOS => {
			'mult_expr' => 303,
			'string_literal' => 298,
			'boolean_literal' => 287,
			'primary_expr' => 300,
			'const_exp' => 489,
			'and_expr' => 301,
			'or_expr' => 289,
			'unary_expr' => 307,
			'scoped_name' => 283,
			'xor_expr' => 291,
			'shift_expr' => 292,
			'wide_string_literal' => 285,
			'literal' => 295,
			'unary_operator' => 310,
			'add_expr' => 297
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
			'switch_body' => 491,
			'case' => 470,
			'case_label' => 475
		}
	},
	{#State 471
		ACTIONS => {
			'error' => 492,
			":" => 493
		}
	},
	{#State 472
		ACTIONS => {
			"}" => 494
		}
	},
	{#State 473
		ACTIONS => {
			"}" => 495
		}
	},
	{#State 474
		ACTIONS => {
			'CHAR' => 81,
			'OBJECT' => 130,
			'VALUEBASE' => 131,
			'FIXED' => 114,
			'SEQUENCE' => 115,
			'STRUCT' => 135,
			'DOUBLE' => 85,
			'LONG' => 86,
			'STRING' => 87,
			"::" => 89,
			'WSTRING' => 91,
			'UNSIGNED' => 71,
			'SHORT' => 73,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 94,
			'UNION' => 138,
			'WCHAR' => 74,
			'FLOAT' => 79,
			'OCTET' => 77,
			'ENUM' => 26,
			'ANY' => 129
		},
		GOTOS => {
			'unsigned_int' => 62,
			'floating_pt_type' => 113,
			'signed_int' => 65,
			'char_type' => 117,
			'value_base_type' => 116,
			'object_type' => 118,
			'octet_type' => 119,
			'scoped_name' => 120,
			'wide_char_type' => 121,
			'signed_long_int' => 70,
			'type_spec' => 496,
			'string_type' => 124,
			'struct_header' => 11,
			'element_spec' => 497,
			'unsigned_longlong_int' => 75,
			'any_type' => 125,
			'base_type_spec' => 126,
			'enum_type' => 127,
			'enum_header' => 18,
			'union_header' => 24,
			'unsigned_short_int' => 78,
			'signed_longlong_int' => 80,
			'wide_string_type' => 132,
			'boolean_type' => 133,
			'integer_type' => 134,
			'signed_short_int' => 90,
			'struct_type' => 136,
			'union_type' => 137,
			'sequence_type' => 139,
			'unsigned_long_int' => 95,
			'template_type_spec' => 140,
			'constr_type_spec' => 141,
			'simple_type_spec' => 142,
			'fixed_pt_type' => 143
		}
	},
	{#State 475
		ACTIONS => {
			'CASE' => 469,
			'DEFAULT' => 471
		},
		DEFAULT => -255,
		GOTOS => {
			'case_labels' => 498,
			'case_label' => 475
		}
	},
	{#State 476
		DEFAULT => -115
	},
	{#State 477
		DEFAULT => -114
	},
	{#State 478
		DEFAULT => -340
	},
	{#State 479
		DEFAULT => -341
	},
	{#State 480
		DEFAULT => -273
	},
	{#State 481
		DEFAULT => -274
	},
	{#State 482
		DEFAULT => -295
	},
	{#State 483
		DEFAULT => -332
	},
	{#State 484
		ACTIONS => {
			'STRING_LITERAL' => 304
		},
		GOTOS => {
			'string_literal' => 462,
			'string_literals' => 499
		}
	},
	{#State 485
		DEFAULT => -331
	},
	{#State 486
		DEFAULT => -326
	},
	{#State 487
		DEFAULT => -325
	},
	{#State 488
		ACTIONS => {
			'IDENTIFIER' => 94,
			"::" => 89
		},
		GOTOS => {
			'scoped_name' => 464,
			'exception_names' => 500,
			'exception_name' => 467
		}
	},
	{#State 489
		ACTIONS => {
			'error' => 501,
			":" => 502
		}
	},
	{#State 490
		DEFAULT => -259
	},
	{#State 491
		DEFAULT => -252
	},
	{#State 492
		DEFAULT => -261
	},
	{#State 493
		DEFAULT => -260
	},
	{#State 494
		DEFAULT => -241
	},
	{#State 495
		DEFAULT => -240
	},
	{#State 496
		ACTIONS => {
			'IDENTIFIER' => 231
		},
		GOTOS => {
			'declarator' => 503,
			'simple_declarator' => 229,
			'array_declarator' => 230,
			'complex_declarator' => 228
		}
	},
	{#State 497
		ACTIONS => {
			'error' => 505,
			";" => 504
		}
	},
	{#State 498
		DEFAULT => -256
	},
	{#State 499
		DEFAULT => -335
	},
	{#State 500
		DEFAULT => -329
	},
	{#State 501
		DEFAULT => -258
	},
	{#State 502
		DEFAULT => -257
	},
	{#State 503
		DEFAULT => -262
	},
	{#State 504
		DEFAULT => -253
	},
	{#State 505
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
		 'definition', 3,
sub
#line 148 "parser24.yp"
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
#line 161 "parser24.yp"
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
#line 168 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'module', 2,
sub
#line 174 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 22
		 'module_header', 2,
sub
#line 183 "parser24.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 23
		 'module_header', 2,
sub
#line 189 "parser24.yp"
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
#line 206 "parser24.yp"
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
#line 214 "parser24.yp"
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
#line 222 "parser24.yp"
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
#line 233 "parser24.yp"
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
	[#Rule 30
		 'forward_dcl', 3,
sub
#line 249 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 31
		 'interface_mod', 1, undef
	],
	[#Rule 32
		 'interface_mod', 1, undef
	],
	[#Rule 33
		 'interface_mod', 0, undef
	],
	[#Rule 34
		 'interface_header', 3,
sub
#line 267 "parser24.yp"
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
	[#Rule 35
		 'interface_header', 4,
sub
#line 283 "parser24.yp"
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
	[#Rule 36
		 'interface_header', 3,
sub
#line 305 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 37
		 'interface_body', 1, undef
	],
	[#Rule 38
		 'exports', 1,
sub
#line 319 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 39
		 'exports', 2,
sub
#line 323 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
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
		 'export', 2, undef
	],
	[#Rule 45
		 'export', 2,
sub
#line 342 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 46
		 'export', 2,
sub
#line 348 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 47
		 'export', 2,
sub
#line 354 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 48
		 'export', 2,
sub
#line 360 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 49
		 'export', 2,
sub
#line 366 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 50
		 'interface_inheritance_spec', 2,
sub
#line 376 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 51
		 'interface_inheritance_spec', 2,
sub
#line 380 "parser24.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 52
		 'interface_names', 1,
sub
#line 388 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 53
		 'interface_names', 3,
sub
#line 392 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 54
		 'interface_name', 1,
sub
#line 401 "parser24.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 55
		 'scoped_name', 1, undef
	],
	[#Rule 56
		 'scoped_name', 2,
sub
#line 411 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 57
		 'scoped_name', 2,
sub
#line 415 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 58
		 'scoped_name', 3,
sub
#line 421 "parser24.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 59
		 'scoped_name', 3,
sub
#line 425 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
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
		 'value', 1, undef
	],
	[#Rule 64
		 'value_forward_dcl', 2,
sub
#line 447 "parser24.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 65
		 'value_forward_dcl', 3,
sub
#line 453 "parser24.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 66
		 'value_box_dcl', 3,
sub
#line 463 "parser24.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 67
		 'value_abs_dcl', 3,
sub
#line 474 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 68
		 'value_abs_dcl', 4,
sub
#line 482 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 69
		 'value_abs_dcl', 4,
sub
#line 490 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 70
		 'value_abs_header', 3,
sub
#line 500 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 71
		 'value_abs_header', 4,
sub
#line 506 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 72
		 'value_abs_header', 3,
sub
#line 513 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 73
		 'value_abs_header', 2,
sub
#line 518 "parser24.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 74
		 'value_dcl', 3,
sub
#line 527 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 75
		 'value_dcl', 4,
sub
#line 535 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 76
		 'value_dcl', 4,
sub
#line 543 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 77
		 'value_elements', 1,
sub
#line 553 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 78
		 'value_elements', 2,
sub
#line 557 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 79
		 'value_header', 2,
sub
#line 566 "parser24.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 80
		 'value_header', 3,
sub
#line 572 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 81
		 'value_header', 3,
sub
#line 579 "parser24.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 82
		 'value_header', 4,
sub
#line 586 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 83
		 'value_header', 2,
sub
#line 594 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 84
		 'value_header', 3,
sub
#line 599 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 85
		 'value_header', 2,
sub
#line 604 "parser24.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 86
		 'value_inheritance_spec', 3,
sub
#line 613 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3]
			);
		}
	],
	[#Rule 87
		 'value_inheritance_spec', 4,
sub
#line 620 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 88
		 'value_inheritance_spec', 3,
sub
#line 628 "parser24.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 89
		 'value_inheritance_spec', 1,
sub
#line 633 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 90
		 'inheritance_mod', 1, undef
	],
	[#Rule 91
		 'inheritance_mod', 0, undef
	],
	[#Rule 92
		 'value_names', 1,
sub
#line 649 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 93
		 'value_names', 3,
sub
#line 653 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 94
		 'supported_interface_spec', 2,
sub
#line 661 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 95
		 'supported_interface_spec', 2,
sub
#line 665 "parser24.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 96
		 'value_name', 1,
sub
#line 674 "parser24.yp"
{
			Value->Lookup($_[0],$_[1]);
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
#line 692 "parser24.yp"
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
#line 700 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 102
		 'state_member', 3,
sub
#line 705 "parser24.yp"
{
			$_[0]->Error("type_spec expected.\n");
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
		 'init_dcl', 2, undef
	],
	[#Rule 106
		 'init_dcl', 2,
sub
#line 723 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 107
		 'init_header_param', 3,
sub
#line 733 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 108
		 'init_header_param', 4,
sub
#line 739 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 109
		 'init_header_param', 4,
sub
#line 747 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 110
		 'init_header_param', 2,
sub
#line 754 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 111
		 'init_header', 2,
sub
#line 764 "parser24.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 112
		 'init_header', 2,
sub
#line 770 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 113
		 'init_param_decls', 1,
sub
#line 779 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 114
		 'init_param_decls', 3,
sub
#line 783 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 115
		 'init_param_decl', 3,
sub
#line 792 "parser24.yp"
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
#line 810 "parser24.yp"
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
#line 818 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'const_dcl', 4,
sub
#line 823 "parser24.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 120
		 'const_dcl', 3,
sub
#line 828 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 121
		 'const_dcl', 2,
sub
#line 833 "parser24.yp"
{
			$_[0]->Error("const_type expected.\n");
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
#line 858 "parser24.yp"
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
#line 876 "parser24.yp"
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
#line 886 "parser24.yp"
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
#line 896 "parser24.yp"
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
#line 906 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 141
		 'shift_expr', 3,
sub
#line 910 "parser24.yp"
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
#line 920 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 144
		 'add_expr', 3,
sub
#line 924 "parser24.yp"
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
#line 934 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'mult_expr', 3,
sub
#line 938 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 148
		 'mult_expr', 3,
sub
#line 942 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 149
		 'unary_expr', 2,
sub
#line 950 "parser24.yp"
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
#line 970 "parser24.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 155
		 'primary_expr', 1,
sub
#line 976 "parser24.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 156
		 'primary_expr', 3,
sub
#line 980 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 157
		 'primary_expr', 3,
sub
#line 984 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 158
		 'literal', 1,
sub
#line 993 "parser24.yp"
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
#line 1000 "parser24.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 1006 "parser24.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 1012 "parser24.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1018 "parser24.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'literal', 1,
sub
#line 1024 "parser24.yp"
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
#line 1031 "parser24.yp"
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
#line 1045 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 168
		 'wide_string_literal', 1, undef
	],
	[#Rule 169
		 'wide_string_literal', 2,
sub
#line 1054 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 170
		 'boolean_literal', 1,
sub
#line 1062 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 171
		 'boolean_literal', 1,
sub
#line 1068 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 172
		 'positive_int_const', 1,
sub
#line 1078 "parser24.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 173
		 'type_dcl', 2,
sub
#line 1088 "parser24.yp"
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
#line 1098 "parser24.yp"
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
#line 1107 "parser24.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 180
		 'type_dcl', 2,
sub
#line 1112 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 181
		 'type_declarator', 2,
sub
#line 1121 "parser24.yp"
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
#line 1128 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
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
#line 1149 "parser24.yp"
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
#line 1201 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 205
		 'declarators', 3,
sub
#line 1205 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 206
		 'declarator', 1,
sub
#line 1214 "parser24.yp"
{
			[$_[1]];
		}
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
#line 1236 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 211
		 'floating_pt_type', 1,
sub
#line 1242 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 212
		 'floating_pt_type', 2,
sub
#line 1248 "parser24.yp"
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
#line 1276 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 219
		 'signed_long_int', 1,
sub
#line 1286 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 220
		 'signed_longlong_int', 2,
sub
#line 1296 "parser24.yp"
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
#line 1316 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 225
		 'unsigned_long_int', 2,
sub
#line 1326 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 226
		 'unsigned_longlong_int', 3,
sub
#line 1336 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 227
		 'char_type', 1,
sub
#line 1346 "parser24.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 228
		 'wide_char_type', 1,
sub
#line 1356 "parser24.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 229
		 'boolean_type', 1,
sub
#line 1366 "parser24.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'octet_type', 1,
sub
#line 1376 "parser24.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 231
		 'any_type', 1,
sub
#line 1386 "parser24.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 232
		 'object_type', 1,
sub
#line 1396 "parser24.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 233
		 'struct_type', 4,
sub
#line 1406 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 234
		 'struct_type', 4,
sub
#line 1413 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 235
		 'struct_header', 2,
sub
#line 1422 "parser24.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 236
		 'member_list', 1,
sub
#line 1432 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 237
		 'member_list', 2,
sub
#line 1436 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 238
		 'member', 3,
sub
#line 1445 "parser24.yp"
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
#line 1452 "parser24.yp"
{
			$_[0]->Error("';' expected.\n");
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
#line 1465 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 241
		 'union_type', 8,
sub
#line 1473 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'union_type', 6,
sub
#line 1479 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'union_type', 5,
sub
#line 1485 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 244
		 'union_type', 3,
sub
#line 1491 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 245
		 'union_header', 2,
sub
#line 1500 "parser24.yp"
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
#line 1518 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 251
		 'switch_body', 1,
sub
#line 1526 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 252
		 'switch_body', 2,
sub
#line 1530 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 253
		 'case', 3,
sub
#line 1539 "parser24.yp"
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
#line 1546 "parser24.yp"
{
			$_[0]->Error("';' expected.\n");
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
#line 1558 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 256
		 'case_labels', 2,
sub
#line 1562 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 257
		 'case_label', 3,
sub
#line 1571 "parser24.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 258
		 'case_label', 3,
sub
#line 1575 "parser24.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 259
		 'case_label', 2,
sub
#line 1581 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 260
		 'case_label', 2,
sub
#line 1586 "parser24.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 261
		 'case_label', 2,
sub
#line 1590 "parser24.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 262
		 'element_spec', 2,
sub
#line 1600 "parser24.yp"
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
#line 1611 "parser24.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 264
		 'enum_type', 4,
sub
#line 1617 "parser24.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 265
		 'enum_type', 2,
sub
#line 1622 "parser24.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'enum_header', 2,
sub
#line 1630 "parser24.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 267
		 'enum_header', 2,
sub
#line 1636 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'enumerators', 1,
sub
#line 1644 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 269
		 'enumerators', 3,
sub
#line 1648 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 270
		 'enumerators', 2,
sub
#line 1653 "parser24.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 271
		 'enumerators', 2,
sub
#line 1658 "parser24.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 272
		 'enumerator', 1,
sub
#line 1667 "parser24.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 273
		 'sequence_type', 6,
sub
#line 1677 "parser24.yp"
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
#line 1685 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 275
		 'sequence_type', 4,
sub
#line 1690 "parser24.yp"
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
#line 1697 "parser24.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'sequence_type', 2,
sub
#line 1702 "parser24.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'string_type', 4,
sub
#line 1711 "parser24.yp"
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
#line 1718 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 280
		 'string_type', 4,
sub
#line 1724 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 281
		 'wide_string_type', 4,
sub
#line 1733 "parser24.yp"
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
#line 1740 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 283
		 'wide_string_type', 4,
sub
#line 1746 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 284
		 'array_declarator', 2,
sub
#line 1755 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 285
		 'fixed_array_sizes', 1,
sub
#line 1763 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 286
		 'fixed_array_sizes', 2,
sub
#line 1767 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 287
		 'fixed_array_size', 3,
sub
#line 1776 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 288
		 'fixed_array_size', 3,
sub
#line 1780 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 289
		 'attr_dcl', 4,
sub
#line 1789 "parser24.yp"
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
#line 1797 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 291
		 'attr_dcl', 3,
sub
#line 1802 "parser24.yp"
{
			$_[0]->Error("type expected.\n");
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
#line 1817 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 295
		 'simple_declarators', 3,
sub
#line 1821 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 296
		 'except_dcl', 3,
sub
#line 1830 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 297
		 'except_dcl', 4,
sub
#line 1835 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 298
		 'except_dcl', 4,
sub
#line 1842 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 299
		 'except_dcl', 2,
sub
#line 1848 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 300
		 'exception_header', 2,
sub
#line 1857 "parser24.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 301
		 'exception_header', 2,
sub
#line 1863 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 302
		 'op_dcl', 2,
sub
#line 1872 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 303
		 'op_dcl', 3,
sub
#line 1880 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 304
		 'op_dcl', 4,
sub
#line 1889 "parser24.yp"
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
	[#Rule 305
		 'op_dcl', 3,
sub
#line 1899 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 306
		 'op_dcl', 2,
sub
#line 1908 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 307
		 'op_header', 3,
sub
#line 1918 "parser24.yp"
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
#line 1926 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
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
#line 1950 "parser24.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 314
		 'parameter_dcls', 3,
sub
#line 1960 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 315
		 'parameter_dcls', 2,
sub
#line 1964 "parser24.yp"
{
			undef;
		}
	],
	[#Rule 316
		 'parameter_dcls', 3,
sub
#line 1968 "parser24.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 317
		 'param_dcls', 1,
sub
#line 1976 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 318
		 'param_dcls', 3,
sub
#line 1980 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 319
		 'param_dcls', 2,
sub
#line 1985 "parser24.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 320
		 'param_dcls', 2,
sub
#line 1990 "parser24.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 321
		 'param_dcl', 3,
sub
#line 1999 "parser24.yp"
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
#line 2021 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 326
		 'raises_expr', 4,
sub
#line 2025 "parser24.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 327
		 'raises_expr', 2,
sub
#line 2030 "parser24.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 328
		 'exception_names', 1,
sub
#line 2038 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 329
		 'exception_names', 3,
sub
#line 2042 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 330
		 'exception_name', 1,
sub
#line 2050 "parser24.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 331
		 'context_expr', 4,
sub
#line 2058 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 332
		 'context_expr', 4,
sub
#line 2062 "parser24.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 333
		 'context_expr', 2,
sub
#line 2067 "parser24.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 334
		 'string_literals', 1,
sub
#line 2075 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 335
		 'string_literals', 3,
sub
#line 2079 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
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
#line 2094 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 340
		 'fixed_pt_type', 6,
sub
#line 2102 "parser24.yp"
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
#line 2110 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 342
		 'fixed_pt_type', 4,
sub
#line 2115 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 343
		 'fixed_pt_type', 2,
sub
#line 2120 "parser24.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 344
		 'fixed_pt_const_type', 1,
sub
#line 2129 "parser24.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 345
		 'value_base_type', 1,
sub
#line 2139 "parser24.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 346
		 'constr_forward_decl', 2,
sub
#line 2149 "parser24.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 347
		 'constr_forward_decl', 2,
sub
#line 2155 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 348
		 'constr_forward_decl', 2,
sub
#line 2160 "parser24.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 349
		 'constr_forward_decl', 2,
sub
#line 2166 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 2172 "parser24.yp"


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
