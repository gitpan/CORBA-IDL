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
			'NATIVE' => 29,
			'ABSTRACT' => 2,
			'STRUCT' => 31,
			'VALUETYPE' => 9,
			'TYPEDEF' => 34,
			'MODULE' => 12,
			'IDENTIFIER' => 36,
			'UNION' => 37,
			'error' => 18,
			'CONST' => 20,
			'EXCEPTION' => 22,
			'CUSTOM' => 40,
			'ENUM' => 25,
			'INTERFACE' => -32
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
			'value_dcl' => 10,
			'struct_type' => 32,
			'union_type' => 35,
			'exception_header' => 33,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'module' => 38,
			'enum_header' => 19,
			'value_abs_dcl' => 21,
			'type_dcl' => 39,
			'union_header' => 23,
			'definitions' => 24,
			'definition' => 41,
			'interface_mod' => 26
		}
	},
	{#State 1
		DEFAULT => -65
	},
	{#State 2
		ACTIONS => {
			'error' => 43,
			'VALUETYPE' => 42,
			'INTERFACE' => -31
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
		DEFAULT => -64
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
		DEFAULT => -62
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
		DEFAULT => -24
	},
	{#State 14
		ACTIONS => {
			'error' => 58,
			";" => 57
		}
	},
	{#State 15
		ACTIONS => {
			'CHAR' => 85,
			'OBJECT' => 86,
			'VALUEBASE' => 87,
			'FIXED' => 61,
			'SEQUENCE' => 63,
			'STRUCT' => 31,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'UNION' => 37,
			'WCHAR' => 75,
			'FLOAT' => 82,
			'OCTET' => 80,
			'ENUM' => 25,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'wide_char_type' => 69,
			'type_spec' => 71,
			'signed_long_int' => 70,
			'string_type' => 73,
			'struct_header' => 11,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'base_type_spec' => 78,
			'enum_type' => 79,
			'enum_header' => 19,
			'union_header' => 23,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83,
			'wide_string_type' => 88,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 95,
			'struct_type' => 97,
			'union_type' => 99,
			'sequence_type' => 101,
			'unsigned_long_int' => 102,
			'template_type_spec' => 103,
			'constr_type_spec' => 104,
			'simple_type_spec' => 105,
			'fixed_pt_type' => 106
		}
	},
	{#State 16
		DEFAULT => -179
	},
	{#State 17
		DEFAULT => -25
	},
	{#State 18
		DEFAULT => -3
	},
	{#State 19
		ACTIONS => {
			"{" => 108,
			'error' => 107
		}
	},
	{#State 20
		ACTIONS => {
			'CHAR' => 85,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'FIXED' => 110,
			'WCHAR' => 75,
			'DOUBLE' => 91,
			'error' => 116,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'OCTET' => 80,
			'FLOAT' => 82,
			'WSTRING' => 96,
			'UNSIGNED' => 72
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 109,
			'signed_int' => 62,
			'wide_string_type' => 117,
			'integer_type' => 119,
			'boolean_type' => 118,
			'char_type' => 111,
			'octet_type' => 112,
			'scoped_name' => 113,
			'fixed_pt_const_type' => 120,
			'wide_char_type' => 114,
			'signed_long_int' => 70,
			'signed_short_int' => 95,
			'const_type' => 121,
			'string_type' => 115,
			'unsigned_longlong_int' => 76,
			'unsigned_long_int' => 102,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83
		}
	},
	{#State 21
		DEFAULT => -63
	},
	{#State 22
		ACTIONS => {
			'error' => 122,
			'IDENTIFIER' => 123
		}
	},
	{#State 23
		ACTIONS => {
			'SWITCH' => 124
		}
	},
	{#State 24
		DEFAULT => -1
	},
	{#State 25
		ACTIONS => {
			'error' => 125,
			'IDENTIFIER' => 126
		}
	},
	{#State 26
		ACTIONS => {
			'INTERFACE' => 127
		}
	},
	{#State 27
		ACTIONS => {
			'error' => 129,
			";" => 128
		}
	},
	{#State 28
		ACTIONS => {
			"{" => 130
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 131,
			'IDENTIFIER' => 133
		},
		GOTOS => {
			'simple_declarator' => 132
		}
	},
	{#State 30
		ACTIONS => {
			"{" => 134
		}
	},
	{#State 31
		ACTIONS => {
			'IDENTIFIER' => 135
		}
	},
	{#State 32
		DEFAULT => -177
	},
	{#State 33
		ACTIONS => {
			"{" => 137,
			'error' => 136
		}
	},
	{#State 34
		ACTIONS => {
			'CHAR' => 85,
			'OBJECT' => 86,
			'VALUEBASE' => 87,
			'FIXED' => 61,
			'SEQUENCE' => 63,
			'STRUCT' => 31,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'UNION' => 37,
			'WCHAR' => 75,
			'error' => 140,
			'FLOAT' => 82,
			'OCTET' => 80,
			'ENUM' => 25,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'wide_char_type' => 69,
			'type_spec' => 138,
			'signed_long_int' => 70,
			'type_declarator' => 139,
			'string_type' => 73,
			'struct_header' => 11,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'base_type_spec' => 78,
			'enum_type' => 79,
			'enum_header' => 19,
			'union_header' => 23,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83,
			'wide_string_type' => 88,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 95,
			'struct_type' => 97,
			'union_type' => 99,
			'sequence_type' => 101,
			'unsigned_long_int' => 102,
			'template_type_spec' => 103,
			'constr_type_spec' => 104,
			'simple_type_spec' => 105,
			'fixed_pt_type' => 106
		}
	},
	{#State 35
		DEFAULT => -178
	},
	{#State 36
		ACTIONS => {
			'error' => 141
		}
	},
	{#State 37
		ACTIONS => {
			'IDENTIFIER' => 142
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
			";" => 145
		}
	},
	{#State 40
		ACTIONS => {
			'error' => 148,
			'VALUETYPE' => 147
		}
	},
	{#State 41
		ACTIONS => {
			'NATIVE' => 29,
			'ABSTRACT' => 2,
			'STRUCT' => 31,
			'VALUETYPE' => 9,
			'TYPEDEF' => 34,
			'MODULE' => 12,
			'IDENTIFIER' => 36,
			'UNION' => 37,
			'CONST' => 20,
			'EXCEPTION' => 22,
			'CUSTOM' => 40,
			'ENUM' => 25,
			'INTERFACE' => -32
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
			'value_dcl' => 10,
			'struct_type' => 32,
			'union_type' => 35,
			'exception_header' => 33,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'module' => 38,
			'enum_header' => 19,
			'value_abs_dcl' => 21,
			'type_dcl' => 39,
			'definitions' => 149,
			'union_header' => 23,
			'definition' => 41,
			'interface_mod' => 26
		}
	},
	{#State 42
		ACTIONS => {
			'error' => 150,
			'IDENTIFIER' => 151
		}
	},
	{#State 43
		DEFAULT => -76
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
		DEFAULT => -21
	},
	{#State 48
		ACTIONS => {
			'TYPEDEF' => 34,
			'IDENTIFIER' => 36,
			'NATIVE' => 29,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 37,
			'STRUCT' => 31,
			'error' => 152,
			'CONST' => 20,
			'CUSTOM' => 40,
			'EXCEPTION' => 22,
			'VALUETYPE' => 9,
			'ENUM' => 25,
			'INTERFACE' => -32
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
			'value_dcl' => 10,
			'struct_type' => 32,
			'union_type' => 35,
			'exception_header' => 33,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'module' => 38,
			'enum_header' => 19,
			'value_abs_dcl' => 21,
			'type_dcl' => 39,
			'definitions' => 153,
			'union_header' => 23,
			'definition' => 41,
			'interface_mod' => 26
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
			'PRIVATE' => 155,
			'ONEWAY' => 156,
			'FACTORY' => 163,
			'UNSIGNED' => -312,
			'SHORT' => -312,
			'WCHAR' => -312,
			'error' => 165,
			'CONST' => 20,
			"}" => 166,
			'EXCEPTION' => 22,
			'OCTET' => -312,
			'FLOAT' => -312,
			'ENUM' => 25,
			'ANY' => -312,
			'CHAR' => -312,
			'OBJECT' => -312,
			'NATIVE' => 29,
			'VALUEBASE' => -312,
			'VOID' => -312,
			'STRUCT' => 31,
			'DOUBLE' => -312,
			'LONG' => -312,
			'STRING' => -312,
			"::" => -312,
			'WSTRING' => -312,
			'BOOLEAN' => -312,
			'TYPEDEF' => 34,
			'IDENTIFIER' => -312,
			'UNION' => 37,
			'READONLY' => 172,
			'ATTRIBUTE' => -295,
			'PUBLIC' => 173
		},
		GOTOS => {
			'init_header_param' => 154,
			'const_dcl' => 167,
			'op_mod' => 157,
			'state_member' => 159,
			'except_dcl' => 158,
			'op_attribute' => 160,
			'attr_mod' => 161,
			'state_mod' => 162,
			'exports' => 168,
			'_export' => 169,
			'export' => 170,
			'init_header' => 164,
			'struct_type' => 32,
			'op_header' => 171,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 174,
			'init_dcl' => 175,
			'enum_header' => 19,
			'attr_dcl' => 176,
			'type_dcl' => 177,
			'union_header' => 23
		}
	},
	{#State 52
		DEFAULT => -86
	},
	{#State 53
		ACTIONS => {
			":" => 179,
			";" => -66,
			"{" => -82,
			'error' => -66,
			'SUPPORTS' => 180
		},
		DEFAULT => -69,
		GOTOS => {
			'supported_interface_spec' => 181,
			'value_inheritance_spec' => 178
		}
	},
	{#State 54
		ACTIONS => {
			'CHAR' => 85,
			'OBJECT' => 86,
			'VALUEBASE' => 87,
			'FIXED' => 61,
			'SEQUENCE' => 63,
			'STRUCT' => 31,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'UNION' => 37,
			'WCHAR' => 75,
			'error' => 183,
			'FLOAT' => 82,
			'OCTET' => 80,
			'ENUM' => 25,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'type_spec' => 182,
			'string_type' => 73,
			'struct_header' => 11,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'base_type_spec' => 78,
			'enum_type' => 79,
			'enum_header' => 19,
			'member_list' => 184,
			'union_header' => 23,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83,
			'wide_string_type' => 88,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 95,
			'member' => 185,
			'struct_type' => 97,
			'union_type' => 99,
			'sequence_type' => 101,
			'unsigned_long_int' => 102,
			'template_type_spec' => 103,
			'constr_type_spec' => 104,
			'simple_type_spec' => 105,
			'fixed_pt_type' => 106
		}
	},
	{#State 55
		DEFAULT => -23
	},
	{#State 56
		DEFAULT => -22
	},
	{#State 57
		DEFAULT => -11
	},
	{#State 58
		DEFAULT => -17
	},
	{#State 59
		DEFAULT => -216
	},
	{#State 60
		DEFAULT => -190
	},
	{#State 61
		ACTIONS => {
			"<" => 187,
			'error' => 186
		}
	},
	{#State 62
		DEFAULT => -215
	},
	{#State 63
		ACTIONS => {
			"<" => 189,
			'error' => 188
		}
	},
	{#State 64
		DEFAULT => -198
	},
	{#State 65
		DEFAULT => -192
	},
	{#State 66
		DEFAULT => -197
	},
	{#State 67
		DEFAULT => -195
	},
	{#State 68
		ACTIONS => {
			"::" => 190
		},
		DEFAULT => -189
	},
	{#State 69
		DEFAULT => -193
	},
	{#State 70
		DEFAULT => -218
	},
	{#State 71
		DEFAULT => -68
	},
	{#State 72
		ACTIONS => {
			'SHORT' => 191,
			'LONG' => 192
		}
	},
	{#State 73
		DEFAULT => -200
	},
	{#State 74
		DEFAULT => -220
	},
	{#State 75
		DEFAULT => -230
	},
	{#State 76
		DEFAULT => -225
	},
	{#State 77
		DEFAULT => -196
	},
	{#State 78
		DEFAULT => -187
	},
	{#State 79
		DEFAULT => -205
	},
	{#State 80
		DEFAULT => -232
	},
	{#State 81
		DEFAULT => -223
	},
	{#State 82
		DEFAULT => -212
	},
	{#State 83
		DEFAULT => -219
	},
	{#State 84
		DEFAULT => -233
	},
	{#State 85
		DEFAULT => -229
	},
	{#State 86
		DEFAULT => -234
	},
	{#State 87
		DEFAULT => -347
	},
	{#State 88
		DEFAULT => -201
	},
	{#State 89
		DEFAULT => -194
	},
	{#State 90
		DEFAULT => -191
	},
	{#State 91
		DEFAULT => -213
	},
	{#State 92
		ACTIONS => {
			'DOUBLE' => 193,
			'LONG' => 194
		},
		DEFAULT => -221
	},
	{#State 93
		ACTIONS => {
			"<" => 195
		},
		DEFAULT => -281
	},
	{#State 94
		ACTIONS => {
			'error' => 196,
			'IDENTIFIER' => 197
		}
	},
	{#State 95
		DEFAULT => -217
	},
	{#State 96
		ACTIONS => {
			"<" => 198
		},
		DEFAULT => -284
	},
	{#State 97
		DEFAULT => -203
	},
	{#State 98
		DEFAULT => -231
	},
	{#State 99
		DEFAULT => -204
	},
	{#State 100
		DEFAULT => -57
	},
	{#State 101
		DEFAULT => -199
	},
	{#State 102
		DEFAULT => -224
	},
	{#State 103
		DEFAULT => -188
	},
	{#State 104
		DEFAULT => -186
	},
	{#State 105
		DEFAULT => -185
	},
	{#State 106
		DEFAULT => -202
	},
	{#State 107
		DEFAULT => -267
	},
	{#State 108
		ACTIONS => {
			'error' => 199,
			'IDENTIFIER' => 201
		},
		GOTOS => {
			'enumerators' => 202,
			'enumerator' => 200
		}
	},
	{#State 109
		DEFAULT => -129
	},
	{#State 110
		DEFAULT => -346
	},
	{#State 111
		DEFAULT => -126
	},
	{#State 112
		DEFAULT => -134
	},
	{#State 113
		ACTIONS => {
			"::" => 190
		},
		DEFAULT => -133
	},
	{#State 114
		DEFAULT => -127
	},
	{#State 115
		DEFAULT => -130
	},
	{#State 116
		DEFAULT => -124
	},
	{#State 117
		DEFAULT => -131
	},
	{#State 118
		DEFAULT => -128
	},
	{#State 119
		DEFAULT => -125
	},
	{#State 120
		DEFAULT => -132
	},
	{#State 121
		ACTIONS => {
			'error' => 203,
			'IDENTIFIER' => 204
		}
	},
	{#State 122
		DEFAULT => -303
	},
	{#State 123
		DEFAULT => -302
	},
	{#State 124
		ACTIONS => {
			'error' => 206,
			"(" => 205
		}
	},
	{#State 125
		DEFAULT => -269
	},
	{#State 126
		DEFAULT => -268
	},
	{#State 127
		ACTIONS => {
			'error' => 207,
			'IDENTIFIER' => 208
		}
	},
	{#State 128
		DEFAULT => -7
	},
	{#State 129
		DEFAULT => -13
	},
	{#State 130
		ACTIONS => {
			'PRIVATE' => 155,
			'ONEWAY' => 156,
			'FACTORY' => 163,
			'UNSIGNED' => -312,
			'SHORT' => -312,
			'WCHAR' => -312,
			'error' => 209,
			'CONST' => 20,
			"}" => 210,
			'EXCEPTION' => 22,
			'OCTET' => -312,
			'FLOAT' => -312,
			'ENUM' => 25,
			'ANY' => -312,
			'CHAR' => -312,
			'OBJECT' => -312,
			'NATIVE' => 29,
			'VALUEBASE' => -312,
			'VOID' => -312,
			'STRUCT' => 31,
			'DOUBLE' => -312,
			'LONG' => -312,
			'STRING' => -312,
			"::" => -312,
			'WSTRING' => -312,
			'BOOLEAN' => -312,
			'TYPEDEF' => 34,
			'IDENTIFIER' => -312,
			'UNION' => 37,
			'READONLY' => 172,
			'ATTRIBUTE' => -295,
			'PUBLIC' => 173
		},
		GOTOS => {
			'init_header_param' => 154,
			'const_dcl' => 167,
			'op_mod' => 157,
			'state_member' => 159,
			'except_dcl' => 158,
			'op_attribute' => 160,
			'attr_mod' => 161,
			'state_mod' => 162,
			'exports' => 211,
			'_export' => 169,
			'export' => 170,
			'init_header' => 164,
			'struct_type' => 32,
			'op_header' => 171,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 174,
			'init_dcl' => 175,
			'enum_header' => 19,
			'attr_dcl' => 176,
			'type_dcl' => 177,
			'union_header' => 23,
			'interface_body' => 212
		}
	},
	{#State 131
		DEFAULT => -182
	},
	{#State 132
		DEFAULT => -180
	},
	{#State 133
		DEFAULT => -210
	},
	{#State 134
		ACTIONS => {
			'PRIVATE' => 155,
			'ONEWAY' => 156,
			'FACTORY' => 163,
			'UNSIGNED' => -312,
			'SHORT' => -312,
			'WCHAR' => -312,
			'error' => 215,
			'CONST' => 20,
			"}" => 216,
			'EXCEPTION' => 22,
			'OCTET' => -312,
			'FLOAT' => -312,
			'ENUM' => 25,
			'ANY' => -312,
			'CHAR' => -312,
			'OBJECT' => -312,
			'NATIVE' => 29,
			'VALUEBASE' => -312,
			'VOID' => -312,
			'STRUCT' => 31,
			'DOUBLE' => -312,
			'LONG' => -312,
			'STRING' => -312,
			"::" => -312,
			'WSTRING' => -312,
			'BOOLEAN' => -312,
			'TYPEDEF' => 34,
			'IDENTIFIER' => -312,
			'UNION' => 37,
			'READONLY' => 172,
			'ATTRIBUTE' => -295,
			'PUBLIC' => 173
		},
		GOTOS => {
			'init_header_param' => 154,
			'const_dcl' => 167,
			'op_mod' => 157,
			'value_elements' => 217,
			'except_dcl' => 158,
			'state_member' => 213,
			'op_attribute' => 160,
			'attr_mod' => 161,
			'state_mod' => 162,
			'value_element' => 214,
			'export' => 218,
			'init_header' => 164,
			'struct_type' => 32,
			'op_header' => 171,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 174,
			'init_dcl' => 219,
			'enum_header' => 19,
			'attr_dcl' => 176,
			'type_dcl' => 177,
			'union_header' => 23
		}
	},
	{#State 135
		DEFAULT => -237
	},
	{#State 136
		DEFAULT => -301
	},
	{#State 137
		ACTIONS => {
			'CHAR' => 85,
			'OBJECT' => 86,
			'VALUEBASE' => 87,
			'FIXED' => 61,
			'SEQUENCE' => 63,
			'STRUCT' => 31,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'UNION' => 37,
			'WCHAR' => 75,
			'error' => 220,
			"}" => 222,
			'FLOAT' => 82,
			'OCTET' => 80,
			'ENUM' => 25,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'type_spec' => 182,
			'string_type' => 73,
			'struct_header' => 11,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'base_type_spec' => 78,
			'enum_type' => 79,
			'enum_header' => 19,
			'member_list' => 221,
			'union_header' => 23,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83,
			'wide_string_type' => 88,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 95,
			'member' => 185,
			'struct_type' => 97,
			'union_type' => 99,
			'sequence_type' => 101,
			'unsigned_long_int' => 102,
			'template_type_spec' => 103,
			'constr_type_spec' => 104,
			'simple_type_spec' => 105,
			'fixed_pt_type' => 106
		}
	},
	{#State 138
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
	{#State 139
		DEFAULT => -176
	},
	{#State 140
		DEFAULT => -181
	},
	{#State 141
		ACTIONS => {
			";" => 230
		}
	},
	{#State 142
		DEFAULT => -247
	},
	{#State 143
		DEFAULT => -10
	},
	{#State 144
		DEFAULT => -16
	},
	{#State 145
		DEFAULT => -6
	},
	{#State 146
		DEFAULT => -12
	},
	{#State 147
		ACTIONS => {
			'error' => 231,
			'IDENTIFIER' => 232
		}
	},
	{#State 148
		DEFAULT => -88
	},
	{#State 149
		DEFAULT => -5
	},
	{#State 150
		DEFAULT => -75
	},
	{#State 151
		ACTIONS => {
			"{" => -73,
			'SUPPORTS' => 180,
			":" => 179
		},
		DEFAULT => -67,
		GOTOS => {
			'supported_interface_spec' => 181,
			'value_inheritance_spec' => 233
		}
	},
	{#State 152
		ACTIONS => {
			"}" => 234
		}
	},
	{#State 153
		ACTIONS => {
			"}" => 235
		}
	},
	{#State 154
		ACTIONS => {
			'error' => 237,
			";" => 236
		}
	},
	{#State 155
		DEFAULT => -107
	},
	{#State 156
		DEFAULT => -313
	},
	{#State 157
		ACTIONS => {
			'CHAR' => 85,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'OBJECT' => 86,
			'IDENTIFIER' => 100,
			'VALUEBASE' => 87,
			'VOID' => 243,
			'WCHAR' => 75,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'OCTET' => 80,
			'FLOAT' => 82,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 242,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 238,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'signed_short_int' => 95,
			'string_type' => 239,
			'op_type_spec' => 244,
			'base_type_spec' => 240,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'unsigned_long_int' => 102,
			'param_type_spec' => 241,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83
		}
	},
	{#State 158
		ACTIONS => {
			'error' => 246,
			";" => 245
		}
	},
	{#State 159
		DEFAULT => -40
	},
	{#State 160
		DEFAULT => -311
	},
	{#State 161
		ACTIONS => {
			'ATTRIBUTE' => 247
		}
	},
	{#State 162
		ACTIONS => {
			'CHAR' => 85,
			'OBJECT' => 86,
			'VALUEBASE' => 87,
			'FIXED' => 61,
			'SEQUENCE' => 63,
			'STRUCT' => 31,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'UNION' => 37,
			'WCHAR' => 75,
			'error' => 249,
			'FLOAT' => 82,
			'OCTET' => 80,
			'ENUM' => 25,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'wide_char_type' => 69,
			'type_spec' => 248,
			'signed_long_int' => 70,
			'string_type' => 73,
			'struct_header' => 11,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'base_type_spec' => 78,
			'enum_type' => 79,
			'enum_header' => 19,
			'union_header' => 23,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83,
			'wide_string_type' => 88,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 95,
			'struct_type' => 97,
			'union_type' => 99,
			'sequence_type' => 101,
			'unsigned_long_int' => 102,
			'template_type_spec' => 103,
			'constr_type_spec' => 104,
			'simple_type_spec' => 105,
			'fixed_pt_type' => 106
		}
	},
	{#State 163
		ACTIONS => {
			'error' => 250,
			'IDENTIFIER' => 251
		}
	},
	{#State 164
		ACTIONS => {
			'error' => 253,
			"(" => 252
		}
	},
	{#State 165
		ACTIONS => {
			"}" => 254
		}
	},
	{#State 166
		DEFAULT => -70
	},
	{#State 167
		ACTIONS => {
			'error' => 256,
			";" => 255
		}
	},
	{#State 168
		ACTIONS => {
			"}" => 257
		}
	},
	{#State 169
		ACTIONS => {
			'PRIVATE' => 155,
			'ONEWAY' => 156,
			'FACTORY' => 163,
			'CONST' => 20,
			'EXCEPTION' => 22,
			"}" => -37,
			'ENUM' => 25,
			'NATIVE' => 29,
			'STRUCT' => 31,
			'TYPEDEF' => 34,
			'UNION' => 37,
			'READONLY' => 172,
			'ATTRIBUTE' => -295,
			'PUBLIC' => 173
		},
		DEFAULT => -312,
		GOTOS => {
			'init_header_param' => 154,
			'const_dcl' => 167,
			'op_mod' => 157,
			'state_member' => 159,
			'except_dcl' => 158,
			'op_attribute' => 160,
			'attr_mod' => 161,
			'state_mod' => 162,
			'exports' => 258,
			'_export' => 169,
			'export' => 170,
			'init_header' => 164,
			'struct_type' => 32,
			'op_header' => 171,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 174,
			'init_dcl' => 175,
			'enum_header' => 19,
			'attr_dcl' => 176,
			'type_dcl' => 177,
			'union_header' => 23
		}
	},
	{#State 170
		DEFAULT => -39
	},
	{#State 171
		ACTIONS => {
			'error' => 260,
			"(" => 259
		},
		GOTOS => {
			'parameter_dcls' => 261
		}
	},
	{#State 172
		DEFAULT => -294
	},
	{#State 173
		DEFAULT => -106
	},
	{#State 174
		ACTIONS => {
			'error' => 263,
			";" => 262
		}
	},
	{#State 175
		DEFAULT => -41
	},
	{#State 176
		ACTIONS => {
			'error' => 265,
			";" => 264
		}
	},
	{#State 177
		ACTIONS => {
			'error' => 267,
			";" => 266
		}
	},
	{#State 178
		DEFAULT => -84
	},
	{#State 179
		ACTIONS => {
			'TRUNCATABLE' => 269
		},
		DEFAULT => -94,
		GOTOS => {
			'inheritance_mod' => 268
		}
	},
	{#State 180
		ACTIONS => {
			'error' => 271,
			'IDENTIFIER' => 100,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 270,
			'interface_names' => 273,
			'interface_name' => 272
		}
	},
	{#State 181
		DEFAULT => -92
	},
	{#State 182
		ACTIONS => {
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarators' => 274,
			'declarator' => 224,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 183
		ACTIONS => {
			"}" => 275
		}
	},
	{#State 184
		ACTIONS => {
			"}" => 276
		}
	},
	{#State 185
		ACTIONS => {
			'CHAR' => 85,
			'OBJECT' => 86,
			'VALUEBASE' => 87,
			'FIXED' => 61,
			'SEQUENCE' => 63,
			'STRUCT' => 31,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'UNION' => 37,
			'WCHAR' => 75,
			'FLOAT' => 82,
			'OCTET' => 80,
			'ENUM' => 25,
			'ANY' => 84
		},
		DEFAULT => -238,
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'type_spec' => 182,
			'string_type' => 73,
			'struct_header' => 11,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'base_type_spec' => 78,
			'enum_type' => 79,
			'enum_header' => 19,
			'member_list' => 277,
			'union_header' => 23,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83,
			'wide_string_type' => 88,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 95,
			'member' => 185,
			'struct_type' => 97,
			'union_type' => 99,
			'sequence_type' => 101,
			'unsigned_long_int' => 102,
			'template_type_spec' => 103,
			'constr_type_spec' => 104,
			'simple_type_spec' => 105,
			'fixed_pt_type' => 106
		}
	},
	{#State 186
		DEFAULT => -345
	},
	{#State 187
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
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
	{#State 188
		DEFAULT => -279
	},
	{#State 189
		ACTIONS => {
			'CHAR' => 85,
			'OBJECT' => 86,
			'VALUEBASE' => 87,
			'FIXED' => 61,
			'SEQUENCE' => 63,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'WCHAR' => 75,
			'error' => 308,
			'FLOAT' => 82,
			'OCTET' => 80,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 88,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'signed_short_int' => 95,
			'string_type' => 73,
			'sequence_type' => 101,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'base_type_spec' => 78,
			'unsigned_long_int' => 102,
			'template_type_spec' => 103,
			'unsigned_short_int' => 81,
			'simple_type_spec' => 309,
			'fixed_pt_type' => 106,
			'signed_longlong_int' => 83
		}
	},
	{#State 190
		ACTIONS => {
			'error' => 310,
			'IDENTIFIER' => 311
		}
	},
	{#State 191
		DEFAULT => -226
	},
	{#State 192
		ACTIONS => {
			'LONG' => 312
		},
		DEFAULT => -227
	},
	{#State 193
		DEFAULT => -214
	},
	{#State 194
		DEFAULT => -222
	},
	{#State 195
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 314,
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
			'positive_int_const' => 313,
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
	{#State 196
		DEFAULT => -59
	},
	{#State 197
		DEFAULT => -58
	},
	{#State 198
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 316,
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
			'positive_int_const' => 315,
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
	{#State 199
		ACTIONS => {
			"}" => 317
		}
	},
	{#State 200
		ACTIONS => {
			";" => 318,
			"," => 319
		},
		DEFAULT => -270
	},
	{#State 201
		DEFAULT => -274
	},
	{#State 202
		ACTIONS => {
			"}" => 320
		}
	},
	{#State 203
		DEFAULT => -123
	},
	{#State 204
		ACTIONS => {
			'error' => 321,
			"=" => 322
		}
	},
	{#State 205
		ACTIONS => {
			'CHAR' => 85,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'error' => 326,
			'LONG' => 330,
			"::" => 94,
			'ENUM' => 25,
			'UNSIGNED' => 72
		},
		GOTOS => {
			'switch_type_spec' => 327,
			'unsigned_int' => 59,
			'signed_int' => 62,
			'integer_type' => 329,
			'boolean_type' => 328,
			'unsigned_longlong_int' => 76,
			'char_type' => 323,
			'enum_type' => 325,
			'unsigned_long_int' => 102,
			'scoped_name' => 324,
			'enum_header' => 19,
			'signed_long_int' => 70,
			'unsigned_short_int' => 81,
			'signed_short_int' => 95,
			'signed_longlong_int' => 83
		}
	},
	{#State 206
		DEFAULT => -246
	},
	{#State 207
		ACTIONS => {
			"{" => -35
		},
		DEFAULT => -30
	},
	{#State 208
		ACTIONS => {
			"{" => -33,
			":" => 331
		},
		DEFAULT => -29,
		GOTOS => {
			'interface_inheritance_spec' => 332
		}
	},
	{#State 209
		ACTIONS => {
			"}" => 333
		}
	},
	{#State 210
		DEFAULT => -26
	},
	{#State 211
		DEFAULT => -36
	},
	{#State 212
		ACTIONS => {
			"}" => 334
		}
	},
	{#State 213
		DEFAULT => -101
	},
	{#State 214
		ACTIONS => {
			'PRIVATE' => 155,
			'ONEWAY' => 156,
			'FACTORY' => 163,
			'CONST' => 20,
			'EXCEPTION' => 22,
			"}" => -80,
			'ENUM' => 25,
			'NATIVE' => 29,
			'STRUCT' => 31,
			'TYPEDEF' => 34,
			'UNION' => 37,
			'READONLY' => 172,
			'ATTRIBUTE' => -295,
			'PUBLIC' => 173
		},
		DEFAULT => -312,
		GOTOS => {
			'init_header_param' => 154,
			'const_dcl' => 167,
			'op_mod' => 157,
			'value_elements' => 335,
			'except_dcl' => 158,
			'state_member' => 213,
			'op_attribute' => 160,
			'attr_mod' => 161,
			'state_mod' => 162,
			'value_element' => 214,
			'export' => 218,
			'init_header' => 164,
			'struct_type' => 32,
			'op_header' => 171,
			'exception_header' => 33,
			'union_type' => 35,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 174,
			'init_dcl' => 219,
			'enum_header' => 19,
			'attr_dcl' => 176,
			'type_dcl' => 177,
			'union_header' => 23
		}
	},
	{#State 215
		ACTIONS => {
			"}" => 336
		}
	},
	{#State 216
		DEFAULT => -77
	},
	{#State 217
		ACTIONS => {
			"}" => 337
		}
	},
	{#State 218
		DEFAULT => -100
	},
	{#State 219
		DEFAULT => -102
	},
	{#State 220
		ACTIONS => {
			"}" => 338
		}
	},
	{#State 221
		ACTIONS => {
			"}" => 339
		}
	},
	{#State 222
		DEFAULT => -298
	},
	{#State 223
		DEFAULT => -183
	},
	{#State 224
		ACTIONS => {
			"," => 340
		},
		DEFAULT => -206
	},
	{#State 225
		DEFAULT => -184
	},
	{#State 226
		DEFAULT => -209
	},
	{#State 227
		DEFAULT => -208
	},
	{#State 228
		DEFAULT => -211
	},
	{#State 229
		ACTIONS => {
			"[" => 343
		},
		DEFAULT => -210,
		GOTOS => {
			'fixed_array_sizes' => 341,
			'fixed_array_size' => 342
		}
	},
	{#State 230
		DEFAULT => -18
	},
	{#State 231
		DEFAULT => -87
	},
	{#State 232
		ACTIONS => {
			'SUPPORTS' => 180,
			":" => 179
		},
		DEFAULT => -83,
		GOTOS => {
			'supported_interface_spec' => 181,
			'value_inheritance_spec' => 344
		}
	},
	{#State 233
		DEFAULT => -74
	},
	{#State 234
		DEFAULT => -20
	},
	{#State 235
		DEFAULT => -19
	},
	{#State 236
		DEFAULT => -108
	},
	{#State 237
		DEFAULT => -109
	},
	{#State 238
		ACTIONS => {
			"::" => 190
		},
		DEFAULT => -341
	},
	{#State 239
		DEFAULT => -339
	},
	{#State 240
		DEFAULT => -338
	},
	{#State 241
		DEFAULT => -314
	},
	{#State 242
		DEFAULT => -340
	},
	{#State 243
		DEFAULT => -315
	},
	{#State 244
		ACTIONS => {
			'error' => 345,
			'IDENTIFIER' => 346
		}
	},
	{#State 245
		DEFAULT => -44
	},
	{#State 246
		DEFAULT => -49
	},
	{#State 247
		ACTIONS => {
			'CHAR' => 85,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'OBJECT' => 86,
			'IDENTIFIER' => 100,
			'VALUEBASE' => 87,
			'WCHAR' => 75,
			'DOUBLE' => 91,
			'error' => 347,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'OCTET' => 80,
			'FLOAT' => 82,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 242,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 238,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'signed_short_int' => 95,
			'string_type' => 239,
			'base_type_spec' => 240,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'unsigned_long_int' => 102,
			'param_type_spec' => 348,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83
		}
	},
	{#State 248
		ACTIONS => {
			'error' => 350,
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarators' => 349,
			'declarator' => 224,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 249
		ACTIONS => {
			";" => 351
		}
	},
	{#State 250
		DEFAULT => -115
	},
	{#State 251
		DEFAULT => -114
	},
	{#State 252
		ACTIONS => {
			'error' => 356,
			")" => 357,
			'IN' => 354
		},
		GOTOS => {
			'init_param_decls' => 353,
			'init_param_attribute' => 352,
			'init_param_decl' => 355
		}
	},
	{#State 253
		DEFAULT => -113
	},
	{#State 254
		DEFAULT => -72
	},
	{#State 255
		DEFAULT => -43
	},
	{#State 256
		DEFAULT => -48
	},
	{#State 257
		DEFAULT => -71
	},
	{#State 258
		DEFAULT => -38
	},
	{#State 259
		ACTIONS => {
			'error' => 359,
			")" => 363,
			'OUT' => 364,
			'INOUT' => 360,
			'IN' => 358
		},
		GOTOS => {
			'param_dcl' => 365,
			'param_dcls' => 362,
			'param_attribute' => 361
		}
	},
	{#State 260
		DEFAULT => -308
	},
	{#State 261
		ACTIONS => {
			'RAISES' => 369,
			'CONTEXT' => 366
		},
		DEFAULT => -304,
		GOTOS => {
			'context_expr' => 368,
			'raises_expr' => 367
		}
	},
	{#State 262
		DEFAULT => -46
	},
	{#State 263
		DEFAULT => -51
	},
	{#State 264
		DEFAULT => -45
	},
	{#State 265
		DEFAULT => -50
	},
	{#State 266
		DEFAULT => -42
	},
	{#State 267
		DEFAULT => -47
	},
	{#State 268
		ACTIONS => {
			'error' => 372,
			'IDENTIFIER' => 100,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 370,
			'value_name' => 371,
			'value_names' => 373
		}
	},
	{#State 269
		DEFAULT => -93
	},
	{#State 270
		ACTIONS => {
			"::" => 190
		},
		DEFAULT => -56
	},
	{#State 271
		DEFAULT => -98
	},
	{#State 272
		ACTIONS => {
			"," => 374
		},
		DEFAULT => -54
	},
	{#State 273
		DEFAULT => -97
	},
	{#State 274
		ACTIONS => {
			'error' => 376,
			";" => 375
		}
	},
	{#State 275
		DEFAULT => -236
	},
	{#State 276
		DEFAULT => -235
	},
	{#State 277
		DEFAULT => -239
	},
	{#State 278
		DEFAULT => -164
	},
	{#State 279
		DEFAULT => -165
	},
	{#State 280
		ACTIONS => {
			"::" => 190
		},
		DEFAULT => -157
	},
	{#State 281
		ACTIONS => {
			"," => 377
		}
	},
	{#State 282
		DEFAULT => -163
	},
	{#State 283
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 379,
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
			'const_exp' => 378,
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
		DEFAULT => -168
	},
	{#State 285
		DEFAULT => -175
	},
	{#State 286
		ACTIONS => {
			"|" => 380
		},
		DEFAULT => -135
	},
	{#State 287
		ACTIONS => {
			">" => 381
		}
	},
	{#State 288
		ACTIONS => {
			"^" => 382
		},
		DEFAULT => -136
	},
	{#State 289
		ACTIONS => {
			"<<" => 383,
			">>" => 384
		},
		DEFAULT => -140
	},
	{#State 290
		DEFAULT => -174
	},
	{#State 291
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 291
		},
		DEFAULT => -171,
		GOTOS => {
			'wide_string_literal' => 385
		}
	},
	{#State 292
		DEFAULT => -158
	},
	{#State 293
		DEFAULT => -173
	},
	{#State 294
		ACTIONS => {
			"+" => 386,
			"-" => 387
		},
		DEFAULT => -142
	},
	{#State 295
		DEFAULT => -162
	},
	{#State 296
		DEFAULT => -167
	},
	{#State 297
		DEFAULT => -153
	},
	{#State 298
		ACTIONS => {
			"&" => 388
		},
		DEFAULT => -138
	},
	{#State 299
		DEFAULT => -161
	},
	{#State 300
		ACTIONS => {
			"%" => 390,
			"*" => 389,
			"/" => 391
		},
		DEFAULT => -145
	},
	{#State 301
		ACTIONS => {
			'STRING_LITERAL' => 301
		},
		DEFAULT => -169,
		GOTOS => {
			'string_literal' => 392
		}
	},
	{#State 302
		DEFAULT => -166
	},
	{#State 303
		DEFAULT => -155
	},
	{#State 304
		DEFAULT => -148
	},
	{#State 305
		DEFAULT => -154
	},
	{#State 306
		DEFAULT => -156
	},
	{#State 307
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
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
			'primary_expr' => 393,
			'literal' => 292,
			'wide_string_literal' => 282
		}
	},
	{#State 308
		ACTIONS => {
			">" => 394
		}
	},
	{#State 309
		ACTIONS => {
			">" => 396,
			"," => 395
		}
	},
	{#State 310
		DEFAULT => -61
	},
	{#State 311
		DEFAULT => -60
	},
	{#State 312
		DEFAULT => -228
	},
	{#State 313
		ACTIONS => {
			">" => 397
		}
	},
	{#State 314
		ACTIONS => {
			">" => 398
		}
	},
	{#State 315
		ACTIONS => {
			">" => 399
		}
	},
	{#State 316
		ACTIONS => {
			">" => 400
		}
	},
	{#State 317
		DEFAULT => -266
	},
	{#State 318
		DEFAULT => -273
	},
	{#State 319
		ACTIONS => {
			'IDENTIFIER' => 201
		},
		DEFAULT => -272,
		GOTOS => {
			'enumerators' => 401,
			'enumerator' => 200
		}
	},
	{#State 320
		DEFAULT => -265
	},
	{#State 321
		DEFAULT => -122
	},
	{#State 322
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 403,
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
			'const_exp' => 402,
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
	{#State 323
		DEFAULT => -249
	},
	{#State 324
		ACTIONS => {
			"::" => 190
		},
		DEFAULT => -252
	},
	{#State 325
		DEFAULT => -251
	},
	{#State 326
		ACTIONS => {
			")" => 404
		}
	},
	{#State 327
		ACTIONS => {
			")" => 405
		}
	},
	{#State 328
		DEFAULT => -250
	},
	{#State 329
		DEFAULT => -248
	},
	{#State 330
		ACTIONS => {
			'LONG' => 194
		},
		DEFAULT => -221
	},
	{#State 331
		ACTIONS => {
			'error' => 406,
			'IDENTIFIER' => 100,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 270,
			'interface_names' => 407,
			'interface_name' => 272
		}
	},
	{#State 332
		DEFAULT => -34
	},
	{#State 333
		DEFAULT => -28
	},
	{#State 334
		DEFAULT => -27
	},
	{#State 335
		DEFAULT => -81
	},
	{#State 336
		DEFAULT => -79
	},
	{#State 337
		DEFAULT => -78
	},
	{#State 338
		DEFAULT => -300
	},
	{#State 339
		DEFAULT => -299
	},
	{#State 340
		ACTIONS => {
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarators' => 408,
			'declarator' => 224,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 341
		DEFAULT => -286
	},
	{#State 342
		ACTIONS => {
			"[" => 343
		},
		DEFAULT => -287,
		GOTOS => {
			'fixed_array_sizes' => 409,
			'fixed_array_size' => 342
		}
	},
	{#State 343
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 411,
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
			'positive_int_const' => 410,
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
	{#State 344
		DEFAULT => -85
	},
	{#State 345
		DEFAULT => -310
	},
	{#State 346
		DEFAULT => -309
	},
	{#State 347
		DEFAULT => -293
	},
	{#State 348
		ACTIONS => {
			'error' => 412,
			'IDENTIFIER' => 133
		},
		GOTOS => {
			'simple_declarators' => 414,
			'simple_declarator' => 413
		}
	},
	{#State 349
		ACTIONS => {
			";" => 415
		}
	},
	{#State 350
		ACTIONS => {
			";" => 416
		}
	},
	{#State 351
		DEFAULT => -105
	},
	{#State 352
		ACTIONS => {
			'CHAR' => 85,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'OBJECT' => 86,
			'IDENTIFIER' => 100,
			'VALUEBASE' => 87,
			'WCHAR' => 75,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'OCTET' => 80,
			'FLOAT' => 82,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 242,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 238,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'signed_short_int' => 95,
			'string_type' => 239,
			'base_type_spec' => 240,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'unsigned_long_int' => 102,
			'param_type_spec' => 417,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83
		}
	},
	{#State 353
		ACTIONS => {
			")" => 418
		}
	},
	{#State 354
		DEFAULT => -119
	},
	{#State 355
		ACTIONS => {
			"," => 419
		},
		DEFAULT => -116
	},
	{#State 356
		ACTIONS => {
			")" => 420
		}
	},
	{#State 357
		DEFAULT => -110
	},
	{#State 358
		DEFAULT => -324
	},
	{#State 359
		ACTIONS => {
			")" => 421
		}
	},
	{#State 360
		DEFAULT => -326
	},
	{#State 361
		ACTIONS => {
			'CHAR' => 85,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'OBJECT' => 86,
			'IDENTIFIER' => 100,
			'VALUEBASE' => 87,
			'WCHAR' => 75,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'OCTET' => 80,
			'FLOAT' => 82,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'wide_string_type' => 242,
			'integer_type' => 90,
			'boolean_type' => 89,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 238,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'signed_short_int' => 95,
			'string_type' => 239,
			'base_type_spec' => 240,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'unsigned_long_int' => 102,
			'param_type_spec' => 422,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83
		}
	},
	{#State 362
		ACTIONS => {
			")" => 423
		}
	},
	{#State 363
		DEFAULT => -317
	},
	{#State 364
		DEFAULT => -325
	},
	{#State 365
		ACTIONS => {
			";" => 424,
			"," => 425
		},
		DEFAULT => -319
	},
	{#State 366
		ACTIONS => {
			'error' => 427,
			"(" => 426
		}
	},
	{#State 367
		ACTIONS => {
			'CONTEXT' => 366
		},
		DEFAULT => -305,
		GOTOS => {
			'context_expr' => 428
		}
	},
	{#State 368
		DEFAULT => -307
	},
	{#State 369
		ACTIONS => {
			'error' => 430,
			"(" => 429
		}
	},
	{#State 370
		ACTIONS => {
			"::" => 190
		},
		DEFAULT => -99
	},
	{#State 371
		ACTIONS => {
			"," => 431
		},
		DEFAULT => -95
	},
	{#State 372
		DEFAULT => -91
	},
	{#State 373
		ACTIONS => {
			'SUPPORTS' => 180
		},
		DEFAULT => -89,
		GOTOS => {
			'supported_interface_spec' => 432
		}
	},
	{#State 374
		ACTIONS => {
			'IDENTIFIER' => 100,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 270,
			'interface_names' => 433,
			'interface_name' => 272
		}
	},
	{#State 375
		DEFAULT => -240
	},
	{#State 376
		DEFAULT => -241
	},
	{#State 377
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 435,
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
			'positive_int_const' => 434,
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
	{#State 378
		ACTIONS => {
			")" => 436
		}
	},
	{#State 379
		ACTIONS => {
			")" => 437
		}
	},
	{#State 380
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
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
			'xor_expr' => 438,
			'shift_expr' => 289,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 381
		DEFAULT => -344
	},
	{#State 382
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
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
			'and_expr' => 439,
			'unary_expr' => 304,
			'scoped_name' => 280,
			'shift_expr' => 289,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 383
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
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
			'add_expr' => 440
		}
	},
	{#State 384
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
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
			'add_expr' => 441
		}
	},
	{#State 385
		DEFAULT => -172
	},
	{#State 386
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 442,
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
	{#State 387
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
			'FALSE' => 290,
			'WIDE_STRING_LITERAL' => 291,
			'INTEGER_LITERAL' => 299,
			"~" => 306,
			"(" => 283,
			'TRUE' => 293
		},
		GOTOS => {
			'mult_expr' => 443,
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
	{#State 388
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
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
			'shift_expr' => 444,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307,
			'add_expr' => 294
		}
	},
	{#State 389
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
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
			'unary_expr' => 445,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307
		}
	},
	{#State 390
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
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
			'unary_expr' => 446,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307
		}
	},
	{#State 391
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'CHARACTER_LITERAL' => 278,
			"+" => 303,
			'FIXED_PT_LITERAL' => 302,
			'WIDE_CHARACTER_LITERAL' => 279,
			"-" => 305,
			"::" => 94,
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
			'unary_expr' => 447,
			'scoped_name' => 280,
			'wide_string_literal' => 282,
			'literal' => 292,
			'unary_operator' => 307
		}
	},
	{#State 392
		DEFAULT => -170
	},
	{#State 393
		DEFAULT => -152
	},
	{#State 394
		DEFAULT => -278
	},
	{#State 395
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 449,
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
			'positive_int_const' => 448,
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
	{#State 396
		DEFAULT => -277
	},
	{#State 397
		DEFAULT => -280
	},
	{#State 398
		DEFAULT => -282
	},
	{#State 399
		DEFAULT => -283
	},
	{#State 400
		DEFAULT => -285
	},
	{#State 401
		DEFAULT => -271
	},
	{#State 402
		DEFAULT => -120
	},
	{#State 403
		DEFAULT => -121
	},
	{#State 404
		DEFAULT => -245
	},
	{#State 405
		ACTIONS => {
			"{" => 451,
			'error' => 450
		}
	},
	{#State 406
		DEFAULT => -53
	},
	{#State 407
		DEFAULT => -52
	},
	{#State 408
		DEFAULT => -207
	},
	{#State 409
		DEFAULT => -288
	},
	{#State 410
		ACTIONS => {
			"]" => 452
		}
	},
	{#State 411
		ACTIONS => {
			"]" => 453
		}
	},
	{#State 412
		DEFAULT => -292
	},
	{#State 413
		ACTIONS => {
			"," => 454
		},
		DEFAULT => -296
	},
	{#State 414
		DEFAULT => -291
	},
	{#State 415
		DEFAULT => -103
	},
	{#State 416
		DEFAULT => -104
	},
	{#State 417
		ACTIONS => {
			'IDENTIFIER' => 133
		},
		GOTOS => {
			'simple_declarator' => 455
		}
	},
	{#State 418
		DEFAULT => -111
	},
	{#State 419
		ACTIONS => {
			'IN' => 354
		},
		GOTOS => {
			'init_param_decls' => 456,
			'init_param_attribute' => 352,
			'init_param_decl' => 355
		}
	},
	{#State 420
		DEFAULT => -112
	},
	{#State 421
		DEFAULT => -318
	},
	{#State 422
		ACTIONS => {
			'IDENTIFIER' => 133
		},
		GOTOS => {
			'simple_declarator' => 457
		}
	},
	{#State 423
		DEFAULT => -316
	},
	{#State 424
		DEFAULT => -322
	},
	{#State 425
		ACTIONS => {
			'OUT' => 364,
			'INOUT' => 360,
			'IN' => 358
		},
		DEFAULT => -321,
		GOTOS => {
			'param_dcl' => 365,
			'param_dcls' => 458,
			'param_attribute' => 361
		}
	},
	{#State 426
		ACTIONS => {
			'error' => 459,
			'STRING_LITERAL' => 301
		},
		GOTOS => {
			'string_literal' => 460,
			'string_literals' => 461
		}
	},
	{#State 427
		DEFAULT => -335
	},
	{#State 428
		DEFAULT => -306
	},
	{#State 429
		ACTIONS => {
			'error' => 463,
			'IDENTIFIER' => 100,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 462,
			'exception_names' => 464,
			'exception_name' => 465
		}
	},
	{#State 430
		DEFAULT => -329
	},
	{#State 431
		ACTIONS => {
			'IDENTIFIER' => 100,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 370,
			'value_name' => 371,
			'value_names' => 466
		}
	},
	{#State 432
		DEFAULT => -90
	},
	{#State 433
		DEFAULT => -55
	},
	{#State 434
		ACTIONS => {
			">" => 467
		}
	},
	{#State 435
		ACTIONS => {
			">" => 468
		}
	},
	{#State 436
		DEFAULT => -159
	},
	{#State 437
		DEFAULT => -160
	},
	{#State 438
		ACTIONS => {
			"^" => 382
		},
		DEFAULT => -137
	},
	{#State 439
		ACTIONS => {
			"&" => 388
		},
		DEFAULT => -139
	},
	{#State 440
		ACTIONS => {
			"+" => 386,
			"-" => 387
		},
		DEFAULT => -144
	},
	{#State 441
		ACTIONS => {
			"+" => 386,
			"-" => 387
		},
		DEFAULT => -143
	},
	{#State 442
		ACTIONS => {
			"%" => 390,
			"*" => 389,
			"/" => 391
		},
		DEFAULT => -146
	},
	{#State 443
		ACTIONS => {
			"%" => 390,
			"*" => 389,
			"/" => 391
		},
		DEFAULT => -147
	},
	{#State 444
		ACTIONS => {
			"<<" => 383,
			">>" => 384
		},
		DEFAULT => -141
	},
	{#State 445
		DEFAULT => -149
	},
	{#State 446
		DEFAULT => -151
	},
	{#State 447
		DEFAULT => -150
	},
	{#State 448
		ACTIONS => {
			">" => 469
		}
	},
	{#State 449
		ACTIONS => {
			">" => 470
		}
	},
	{#State 450
		DEFAULT => -244
	},
	{#State 451
		ACTIONS => {
			'error' => 474,
			'CASE' => 471,
			'DEFAULT' => 473
		},
		GOTOS => {
			'case_labels' => 476,
			'switch_body' => 475,
			'case' => 472,
			'case_label' => 477
		}
	},
	{#State 452
		DEFAULT => -289
	},
	{#State 453
		DEFAULT => -290
	},
	{#State 454
		ACTIONS => {
			'IDENTIFIER' => 133
		},
		GOTOS => {
			'simple_declarators' => 478,
			'simple_declarator' => 413
		}
	},
	{#State 455
		DEFAULT => -118
	},
	{#State 456
		DEFAULT => -117
	},
	{#State 457
		DEFAULT => -323
	},
	{#State 458
		DEFAULT => -320
	},
	{#State 459
		ACTIONS => {
			")" => 479
		}
	},
	{#State 460
		ACTIONS => {
			"," => 480
		},
		DEFAULT => -336
	},
	{#State 461
		ACTIONS => {
			")" => 481
		}
	},
	{#State 462
		ACTIONS => {
			"::" => 190
		},
		DEFAULT => -332
	},
	{#State 463
		ACTIONS => {
			")" => 482
		}
	},
	{#State 464
		ACTIONS => {
			")" => 483
		}
	},
	{#State 465
		ACTIONS => {
			"," => 484
		},
		DEFAULT => -330
	},
	{#State 466
		DEFAULT => -96
	},
	{#State 467
		DEFAULT => -342
	},
	{#State 468
		DEFAULT => -343
	},
	{#State 469
		DEFAULT => -275
	},
	{#State 470
		DEFAULT => -276
	},
	{#State 471
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 296,
			'CHARACTER_LITERAL' => 278,
			'WIDE_CHARACTER_LITERAL' => 279,
			"::" => 94,
			'INTEGER_LITERAL' => 299,
			"(" => 283,
			'IDENTIFIER' => 100,
			'STRING_LITERAL' => 301,
			'FIXED_PT_LITERAL' => 302,
			"+" => 303,
			'error' => 486,
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
			'const_exp' => 485,
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
	{#State 472
		ACTIONS => {
			'CASE' => 471,
			'DEFAULT' => 473
		},
		DEFAULT => -253,
		GOTOS => {
			'case_labels' => 476,
			'switch_body' => 487,
			'case' => 472,
			'case_label' => 477
		}
	},
	{#State 473
		ACTIONS => {
			'error' => 488,
			":" => 489
		}
	},
	{#State 474
		ACTIONS => {
			"}" => 490
		}
	},
	{#State 475
		ACTIONS => {
			"}" => 491
		}
	},
	{#State 476
		ACTIONS => {
			'CHAR' => 85,
			'OBJECT' => 86,
			'VALUEBASE' => 87,
			'FIXED' => 61,
			'SEQUENCE' => 63,
			'STRUCT' => 31,
			'DOUBLE' => 91,
			'LONG' => 92,
			'STRING' => 93,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 72,
			'SHORT' => 74,
			'BOOLEAN' => 98,
			'IDENTIFIER' => 100,
			'UNION' => 37,
			'WCHAR' => 75,
			'FLOAT' => 82,
			'OCTET' => 80,
			'ENUM' => 25,
			'ANY' => 84
		},
		GOTOS => {
			'unsigned_int' => 59,
			'floating_pt_type' => 60,
			'signed_int' => 62,
			'char_type' => 65,
			'value_base_type' => 64,
			'object_type' => 66,
			'octet_type' => 67,
			'scoped_name' => 68,
			'wide_char_type' => 69,
			'signed_long_int' => 70,
			'type_spec' => 492,
			'string_type' => 73,
			'struct_header' => 11,
			'element_spec' => 493,
			'unsigned_longlong_int' => 76,
			'any_type' => 77,
			'base_type_spec' => 78,
			'enum_type' => 79,
			'enum_header' => 19,
			'union_header' => 23,
			'unsigned_short_int' => 81,
			'signed_longlong_int' => 83,
			'wide_string_type' => 88,
			'boolean_type' => 89,
			'integer_type' => 90,
			'signed_short_int' => 95,
			'struct_type' => 97,
			'union_type' => 99,
			'sequence_type' => 101,
			'unsigned_long_int' => 102,
			'template_type_spec' => 103,
			'constr_type_spec' => 104,
			'simple_type_spec' => 105,
			'fixed_pt_type' => 106
		}
	},
	{#State 477
		ACTIONS => {
			'CASE' => 471,
			'DEFAULT' => 473
		},
		DEFAULT => -257,
		GOTOS => {
			'case_labels' => 494,
			'case_label' => 477
		}
	},
	{#State 478
		DEFAULT => -297
	},
	{#State 479
		DEFAULT => -334
	},
	{#State 480
		ACTIONS => {
			'STRING_LITERAL' => 301
		},
		GOTOS => {
			'string_literal' => 460,
			'string_literals' => 495
		}
	},
	{#State 481
		DEFAULT => -333
	},
	{#State 482
		DEFAULT => -328
	},
	{#State 483
		DEFAULT => -327
	},
	{#State 484
		ACTIONS => {
			'IDENTIFIER' => 100,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 462,
			'exception_names' => 496,
			'exception_name' => 465
		}
	},
	{#State 485
		ACTIONS => {
			'error' => 497,
			":" => 498
		}
	},
	{#State 486
		DEFAULT => -261
	},
	{#State 487
		DEFAULT => -254
	},
	{#State 488
		DEFAULT => -263
	},
	{#State 489
		DEFAULT => -262
	},
	{#State 490
		DEFAULT => -243
	},
	{#State 491
		DEFAULT => -242
	},
	{#State 492
		ACTIONS => {
			'IDENTIFIER' => 229
		},
		GOTOS => {
			'declarator' => 499,
			'simple_declarator' => 227,
			'array_declarator' => 228,
			'complex_declarator' => 226
		}
	},
	{#State 493
		ACTIONS => {
			'error' => 501,
			";" => 500
		}
	},
	{#State 494
		DEFAULT => -258
	},
	{#State 495
		DEFAULT => -337
	},
	{#State 496
		DEFAULT => -331
	},
	{#State 497
		DEFAULT => -260
	},
	{#State 498
		DEFAULT => -259
	},
	{#State 499
		DEFAULT => -264
	},
	{#State 500
		DEFAULT => -255
	},
	{#State 501
		DEFAULT => -256
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
		 '_export', 1, undef
	],
	[#Rule 40
		 '_export', 1,
sub
#line 318 "parser23.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 41
		 '_export', 1,
sub
#line 323 "parser23.yp"
{
			$_[0]->Error("initializer unexpected.\n");
			$_[1];						#default action
		}
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
		 'export', 2, undef
	],
	[#Rule 46
		 'export', 2, undef
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
		 'export', 2,
sub
#line 347 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 49
		 'export', 2,
sub
#line 353 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 50
		 'export', 2,
sub
#line 359 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 51
		 'export', 2,
sub
#line 365 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 52
		 'interface_inheritance_spec', 2,
sub
#line 375 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 53
		 'interface_inheritance_spec', 2,
sub
#line 379 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 54
		 'interface_names', 1,
sub
#line 387 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 55
		 'interface_names', 3,
sub
#line 391 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 56
		 'interface_name', 1,
sub
#line 400 "parser23.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 57
		 'scoped_name', 1, undef
	],
	[#Rule 58
		 'scoped_name', 2,
sub
#line 410 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 59
		 'scoped_name', 2,
sub
#line 414 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 60
		 'scoped_name', 3,
sub
#line 420 "parser23.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 61
		 'scoped_name', 3,
sub
#line 424 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 62
		 'value', 1, undef
	],
	[#Rule 63
		 'value', 1, undef
	],
	[#Rule 64
		 'value', 1, undef
	],
	[#Rule 65
		 'value', 1, undef
	],
	[#Rule 66
		 'value_forward_dcl', 2,
sub
#line 446 "parser23.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 67
		 'value_forward_dcl', 3,
sub
#line 452 "parser23.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 68
		 'value_box_dcl', 2,
sub
#line 462 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 69
		 'value_box_header', 2,
sub
#line 473 "parser23.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 70
		 'value_abs_dcl', 3,
sub
#line 483 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 71
		 'value_abs_dcl', 4,
sub
#line 491 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 72
		 'value_abs_dcl', 4,
sub
#line 499 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 73
		 'value_abs_header', 3,
sub
#line 509 "parser23.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 74
		 'value_abs_header', 4,
sub
#line 515 "parser23.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 75
		 'value_abs_header', 3,
sub
#line 522 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 76
		 'value_abs_header', 2,
sub
#line 527 "parser23.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 77
		 'value_dcl', 3,
sub
#line 536 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 78
		 'value_dcl', 4,
sub
#line 544 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 79
		 'value_dcl', 4,
sub
#line 552 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 80
		 'value_elements', 1,
sub
#line 562 "parser23.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 81
		 'value_elements', 2,
sub
#line 566 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 82
		 'value_header', 2,
sub
#line 575 "parser23.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 83
		 'value_header', 3,
sub
#line 581 "parser23.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 84
		 'value_header', 3,
sub
#line 588 "parser23.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 85
		 'value_header', 4,
sub
#line 595 "parser23.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 86
		 'value_header', 2,
sub
#line 603 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 87
		 'value_header', 3,
sub
#line 608 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 88
		 'value_header', 2,
sub
#line 613 "parser23.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 89
		 'value_inheritance_spec', 3,
sub
#line 622 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3]
			);
		}
	],
	[#Rule 90
		 'value_inheritance_spec', 4,
sub
#line 629 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 91
		 'value_inheritance_spec', 3,
sub
#line 637 "parser23.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 92
		 'value_inheritance_spec', 1,
sub
#line 642 "parser23.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 93
		 'inheritance_mod', 1, undef
	],
	[#Rule 94
		 'inheritance_mod', 0, undef
	],
	[#Rule 95
		 'value_names', 1,
sub
#line 658 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 96
		 'value_names', 3,
sub
#line 662 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 97
		 'supported_interface_spec', 2,
sub
#line 670 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 98
		 'supported_interface_spec', 2,
sub
#line 674 "parser23.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 99
		 'value_name', 1,
sub
#line 683 "parser23.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 100
		 'value_element', 1, undef
	],
	[#Rule 101
		 'value_element', 1, undef
	],
	[#Rule 102
		 'value_element', 1, undef
	],
	[#Rule 103
		 'state_member', 4,
sub
#line 701 "parser23.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 104
		 'state_member', 4,
sub
#line 709 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 105
		 'state_member', 3,
sub
#line 714 "parser23.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 106
		 'state_mod', 1, undef
	],
	[#Rule 107
		 'state_mod', 1, undef
	],
	[#Rule 108
		 'init_dcl', 2, undef
	],
	[#Rule 109
		 'init_dcl', 2,
sub
#line 732 "parser23.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 110
		 'init_header_param', 3,
sub
#line 741 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 111
		 'init_header_param', 4,
sub
#line 747 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 112
		 'init_header_param', 4,
sub
#line 755 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 113
		 'init_header_param', 2,
sub
#line 762 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 114
		 'init_header', 2,
sub
#line 772 "parser23.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 115
		 'init_header', 2,
sub
#line 778 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 116
		 'init_param_decls', 1,
sub
#line 787 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 117
		 'init_param_decls', 3,
sub
#line 791 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 118
		 'init_param_decl', 3,
sub
#line 800 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 119
		 'init_param_attribute', 1, undef
	],
	[#Rule 120
		 'const_dcl', 5,
sub
#line 818 "parser23.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 121
		 'const_dcl', 5,
sub
#line 826 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 122
		 'const_dcl', 4,
sub
#line 831 "parser23.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 123
		 'const_dcl', 3,
sub
#line 836 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 124
		 'const_dcl', 2,
sub
#line 841 "parser23.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
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
		 'const_type', 1, undef
	],
	[#Rule 131
		 'const_type', 1, undef
	],
	[#Rule 132
		 'const_type', 1, undef
	],
	[#Rule 133
		 'const_type', 1,
sub
#line 866 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 134
		 'const_type', 1, undef
	],
	[#Rule 135
		 'const_exp', 1, undef
	],
	[#Rule 136
		 'or_expr', 1, undef
	],
	[#Rule 137
		 'or_expr', 3,
sub
#line 884 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 138
		 'xor_expr', 1, undef
	],
	[#Rule 139
		 'xor_expr', 3,
sub
#line 894 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 140
		 'and_expr', 1, undef
	],
	[#Rule 141
		 'and_expr', 3,
sub
#line 904 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 142
		 'shift_expr', 1, undef
	],
	[#Rule 143
		 'shift_expr', 3,
sub
#line 914 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 144
		 'shift_expr', 3,
sub
#line 918 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 145
		 'add_expr', 1, undef
	],
	[#Rule 146
		 'add_expr', 3,
sub
#line 928 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'add_expr', 3,
sub
#line 932 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 148
		 'mult_expr', 1, undef
	],
	[#Rule 149
		 'mult_expr', 3,
sub
#line 942 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 150
		 'mult_expr', 3,
sub
#line 946 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 151
		 'mult_expr', 3,
sub
#line 950 "parser23.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 152
		 'unary_expr', 2,
sub
#line 958 "parser23.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 153
		 'unary_expr', 1, undef
	],
	[#Rule 154
		 'unary_operator', 1, undef
	],
	[#Rule 155
		 'unary_operator', 1, undef
	],
	[#Rule 156
		 'unary_operator', 1, undef
	],
	[#Rule 157
		 'primary_expr', 1,
sub
#line 978 "parser23.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 158
		 'primary_expr', 1,
sub
#line 984 "parser23.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 159
		 'primary_expr', 3,
sub
#line 988 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 160
		 'primary_expr', 3,
sub
#line 992 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 1001 "parser23.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1008 "parser23.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'literal', 1,
sub
#line 1014 "parser23.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'literal', 1,
sub
#line 1020 "parser23.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'literal', 1,
sub
#line 1026 "parser23.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 166
		 'literal', 1,
sub
#line 1032 "parser23.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 167
		 'literal', 1,
sub
#line 1039 "parser23.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 168
		 'literal', 1, undef
	],
	[#Rule 169
		 'string_literal', 1, undef
	],
	[#Rule 170
		 'string_literal', 2,
sub
#line 1053 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 171
		 'wide_string_literal', 1, undef
	],
	[#Rule 172
		 'wide_string_literal', 2,
sub
#line 1062 "parser23.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 173
		 'boolean_literal', 1,
sub
#line 1070 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 174
		 'boolean_literal', 1,
sub
#line 1076 "parser23.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 175
		 'positive_int_const', 1,
sub
#line 1086 "parser23.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 176
		 'type_dcl', 2,
sub
#line 1096 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 177
		 'type_dcl', 1, undef
	],
	[#Rule 178
		 'type_dcl', 1, undef
	],
	[#Rule 179
		 'type_dcl', 1, undef
	],
	[#Rule 180
		 'type_dcl', 2,
sub
#line 1106 "parser23.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 181
		 'type_dcl', 2,
sub
#line 1113 "parser23.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 182
		 'type_dcl', 2,
sub
#line 1118 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 183
		 'type_declarator', 2,
sub
#line 1127 "parser23.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 184
		 'type_declarator', 2,
sub
#line 1134 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 185
		 'type_spec', 1, undef
	],
	[#Rule 186
		 'type_spec', 1, undef
	],
	[#Rule 187
		 'simple_type_spec', 1, undef
	],
	[#Rule 188
		 'simple_type_spec', 1, undef
	],
	[#Rule 189
		 'simple_type_spec', 1,
sub
#line 1155 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
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
		 'base_type_spec', 1, undef
	],
	[#Rule 198
		 'base_type_spec', 1, undef
	],
	[#Rule 199
		 'template_type_spec', 1, undef
	],
	[#Rule 200
		 'template_type_spec', 1, undef
	],
	[#Rule 201
		 'template_type_spec', 1, undef
	],
	[#Rule 202
		 'template_type_spec', 1, undef
	],
	[#Rule 203
		 'constr_type_spec', 1, undef
	],
	[#Rule 204
		 'constr_type_spec', 1, undef
	],
	[#Rule 205
		 'constr_type_spec', 1, undef
	],
	[#Rule 206
		 'declarators', 1,
sub
#line 1207 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 207
		 'declarators', 3,
sub
#line 1211 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 208
		 'declarator', 1,
sub
#line 1220 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 209
		 'declarator', 1, undef
	],
	[#Rule 210
		 'simple_declarator', 1, undef
	],
	[#Rule 211
		 'complex_declarator', 1, undef
	],
	[#Rule 212
		 'floating_pt_type', 1,
sub
#line 1242 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 213
		 'floating_pt_type', 1,
sub
#line 1248 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 214
		 'floating_pt_type', 2,
sub
#line 1254 "parser23.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 215
		 'integer_type', 1, undef
	],
	[#Rule 216
		 'integer_type', 1, undef
	],
	[#Rule 217
		 'signed_int', 1, undef
	],
	[#Rule 218
		 'signed_int', 1, undef
	],
	[#Rule 219
		 'signed_int', 1, undef
	],
	[#Rule 220
		 'signed_short_int', 1,
sub
#line 1282 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 221
		 'signed_long_int', 1,
sub
#line 1292 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 222
		 'signed_longlong_int', 2,
sub
#line 1302 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 223
		 'unsigned_int', 1, undef
	],
	[#Rule 224
		 'unsigned_int', 1, undef
	],
	[#Rule 225
		 'unsigned_int', 1, undef
	],
	[#Rule 226
		 'unsigned_short_int', 2,
sub
#line 1322 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 227
		 'unsigned_long_int', 2,
sub
#line 1332 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 228
		 'unsigned_longlong_int', 3,
sub
#line 1342 "parser23.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 229
		 'char_type', 1,
sub
#line 1352 "parser23.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'wide_char_type', 1,
sub
#line 1362 "parser23.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 231
		 'boolean_type', 1,
sub
#line 1372 "parser23.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 232
		 'octet_type', 1,
sub
#line 1382 "parser23.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 233
		 'any_type', 1,
sub
#line 1392 "parser23.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 234
		 'object_type', 1,
sub
#line 1402 "parser23.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 235
		 'struct_type', 4,
sub
#line 1412 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 236
		 'struct_type', 4,
sub
#line 1419 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 237
		 'struct_header', 2,
sub
#line 1428 "parser23.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 238
		 'member_list', 1,
sub
#line 1438 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 239
		 'member_list', 2,
sub
#line 1442 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 240
		 'member', 3,
sub
#line 1451 "parser23.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 241
		 'member', 3,
sub
#line 1458 "parser23.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 242
		 'union_type', 8,
sub
#line 1471 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 243
		 'union_type', 8,
sub
#line 1479 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 244
		 'union_type', 6,
sub
#line 1485 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 245
		 'union_type', 5,
sub
#line 1491 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 246
		 'union_type', 3,
sub
#line 1497 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 247
		 'union_header', 2,
sub
#line 1506 "parser23.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 248
		 'switch_type_spec', 1, undef
	],
	[#Rule 249
		 'switch_type_spec', 1, undef
	],
	[#Rule 250
		 'switch_type_spec', 1, undef
	],
	[#Rule 251
		 'switch_type_spec', 1, undef
	],
	[#Rule 252
		 'switch_type_spec', 1,
sub
#line 1524 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 253
		 'switch_body', 1,
sub
#line 1532 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 254
		 'switch_body', 2,
sub
#line 1536 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 255
		 'case', 3,
sub
#line 1545 "parser23.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 256
		 'case', 3,
sub
#line 1552 "parser23.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 257
		 'case_labels', 1,
sub
#line 1564 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 258
		 'case_labels', 2,
sub
#line 1568 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 259
		 'case_label', 3,
sub
#line 1577 "parser23.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 260
		 'case_label', 3,
sub
#line 1581 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 261
		 'case_label', 2,
sub
#line 1587 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 262
		 'case_label', 2,
sub
#line 1592 "parser23.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 263
		 'case_label', 2,
sub
#line 1596 "parser23.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 264
		 'element_spec', 2,
sub
#line 1606 "parser23.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 265
		 'enum_type', 4,
sub
#line 1617 "parser23.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 266
		 'enum_type', 4,
sub
#line 1623 "parser23.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'enum_type', 2,
sub
#line 1628 "parser23.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'enum_header', 2,
sub
#line 1636 "parser23.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 269
		 'enum_header', 2,
sub
#line 1642 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 270
		 'enumerators', 1,
sub
#line 1650 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 271
		 'enumerators', 3,
sub
#line 1654 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 272
		 'enumerators', 2,
sub
#line 1659 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 273
		 'enumerators', 2,
sub
#line 1664 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 274
		 'enumerator', 1,
sub
#line 1673 "parser23.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 275
		 'sequence_type', 6,
sub
#line 1683 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 276
		 'sequence_type', 6,
sub
#line 1691 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'sequence_type', 4,
sub
#line 1696 "parser23.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 278
		 'sequence_type', 4,
sub
#line 1703 "parser23.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'sequence_type', 2,
sub
#line 1708 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 280
		 'string_type', 4,
sub
#line 1717 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 281
		 'string_type', 1,
sub
#line 1724 "parser23.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 282
		 'string_type', 4,
sub
#line 1730 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 283
		 'wide_string_type', 4,
sub
#line 1739 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 284
		 'wide_string_type', 1,
sub
#line 1746 "parser23.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 285
		 'wide_string_type', 4,
sub
#line 1752 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 286
		 'array_declarator', 2,
sub
#line 1761 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 287
		 'fixed_array_sizes', 1,
sub
#line 1769 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 288
		 'fixed_array_sizes', 2,
sub
#line 1773 "parser23.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 289
		 'fixed_array_size', 3,
sub
#line 1782 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 290
		 'fixed_array_size', 3,
sub
#line 1786 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 291
		 'attr_dcl', 4,
sub
#line 1795 "parser23.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 292
		 'attr_dcl', 4,
sub
#line 1803 "parser23.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 293
		 'attr_dcl', 3,
sub
#line 1808 "parser23.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 294
		 'attr_mod', 1, undef
	],
	[#Rule 295
		 'attr_mod', 0, undef
	],
	[#Rule 296
		 'simple_declarators', 1,
sub
#line 1823 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 297
		 'simple_declarators', 3,
sub
#line 1827 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 298
		 'except_dcl', 3,
sub
#line 1836 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 299
		 'except_dcl', 4,
sub
#line 1841 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 300
		 'except_dcl', 4,
sub
#line 1848 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 301
		 'except_dcl', 2,
sub
#line 1854 "parser23.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 302
		 'exception_header', 2,
sub
#line 1863 "parser23.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 303
		 'exception_header', 2,
sub
#line 1869 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 304
		 'op_dcl', 2,
sub
#line 1878 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 305
		 'op_dcl', 3,
sub
#line 1886 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 306
		 'op_dcl', 4,
sub
#line 1895 "parser23.yp"
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
	[#Rule 307
		 'op_dcl', 3,
sub
#line 1905 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 308
		 'op_dcl', 2,
sub
#line 1914 "parser23.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 309
		 'op_header', 3,
sub
#line 1924 "parser23.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 310
		 'op_header', 3,
sub
#line 1932 "parser23.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 311
		 'op_mod', 1, undef
	],
	[#Rule 312
		 'op_mod', 0, undef
	],
	[#Rule 313
		 'op_attribute', 1, undef
	],
	[#Rule 314
		 'op_type_spec', 1, undef
	],
	[#Rule 315
		 'op_type_spec', 1,
sub
#line 1956 "parser23.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 316
		 'parameter_dcls', 3,
sub
#line 1966 "parser23.yp"
{
			$_[2];
		}
	],
	[#Rule 317
		 'parameter_dcls', 2,
sub
#line 1970 "parser23.yp"
{
			undef;
		}
	],
	[#Rule 318
		 'parameter_dcls', 3,
sub
#line 1974 "parser23.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 319
		 'param_dcls', 1,
sub
#line 1982 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 320
		 'param_dcls', 3,
sub
#line 1986 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 321
		 'param_dcls', 2,
sub
#line 1991 "parser23.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 322
		 'param_dcls', 2,
sub
#line 1996 "parser23.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 323
		 'param_dcl', 3,
sub
#line 2005 "parser23.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 324
		 'param_attribute', 1, undef
	],
	[#Rule 325
		 'param_attribute', 1, undef
	],
	[#Rule 326
		 'param_attribute', 1, undef
	],
	[#Rule 327
		 'raises_expr', 4,
sub
#line 2027 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 328
		 'raises_expr', 4,
sub
#line 2031 "parser23.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 329
		 'raises_expr', 2,
sub
#line 2036 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 330
		 'exception_names', 1,
sub
#line 2044 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 331
		 'exception_names', 3,
sub
#line 2048 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 332
		 'exception_name', 1,
sub
#line 2056 "parser23.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 333
		 'context_expr', 4,
sub
#line 2064 "parser23.yp"
{
			$_[3];
		}
	],
	[#Rule 334
		 'context_expr', 4,
sub
#line 2068 "parser23.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 335
		 'context_expr', 2,
sub
#line 2073 "parser23.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 336
		 'string_literals', 1,
sub
#line 2081 "parser23.yp"
{
			[$_[1]];
		}
	],
	[#Rule 337
		 'string_literals', 3,
sub
#line 2085 "parser23.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 338
		 'param_type_spec', 1, undef
	],
	[#Rule 339
		 'param_type_spec', 1, undef
	],
	[#Rule 340
		 'param_type_spec', 1, undef
	],
	[#Rule 341
		 'param_type_spec', 1,
sub
#line 2100 "parser23.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 342
		 'fixed_pt_type', 6,
sub
#line 2108 "parser23.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 343
		 'fixed_pt_type', 6,
sub
#line 2116 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 344
		 'fixed_pt_type', 4,
sub
#line 2121 "parser23.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 345
		 'fixed_pt_type', 2,
sub
#line 2126 "parser23.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 346
		 'fixed_pt_const_type', 1,
sub
#line 2135 "parser23.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 347
		 'value_base_type', 1,
sub
#line 2145 "parser23.yp"
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

#line 2152 "parser23.yp"


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
