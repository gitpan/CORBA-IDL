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
			'' => -3,
			'NATIVE' => 54,
			'ABSTRACT' => 2,
			'COMPONENT' => 55,
			'STRUCT' => 23,
			'TYPEID' => 57,
			'IMPORT' => 58,
			'TYPEPREFIX' => 59,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 60,
			'IDENTIFIER' => 62,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'error' => 46,
			'LOCAL' => 49,
			'CONST' => 13,
			'CUSTOM' => 65,
			'EXCEPTION' => 51,
			'ENUM' => 16,
			'INTERFACE' => -48
		},
		GOTOS => {
			'component_forward_dcl' => 33,
			'value_forward_dcl' => 1,
			'event' => 34,
			'except_dcl' => 35,
			'specification' => 3,
			'module_header' => 36,
			'interface' => 4,
			'value_box_dcl' => 37,
			'value_abs_header' => 6,
			'component' => 7,
			'event_dcl' => 40,
			'type_id_dcl' => 39,
			'value_dcl' => 8,
			'import' => 9,
			'struct_header' => 10,
			'interface_dcl' => 11,
			'value' => 42,
			'value_box_header' => 43,
			'enum_type' => 45,
			'forward_dcl' => 44,
			'enum_header' => 48,
			'constr_forward_decl' => 47,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 50,
			'definitions' => 15,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 52,
			'imports' => 19,
			'home_dcl' => 53,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 56,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'union_type' => 28,
			'exception_header' => 27,
			'event_header' => 61,
			'component_header' => 31,
			'module' => 63,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 66
		}
	},
	{#State 1
		DEFAULT => -85
	},
	{#State 2
		ACTIONS => {
			'error' => 69,
			'VALUETYPE' => 68,
			'EVENTTYPE' => 67,
			'INTERFACE' => -46
		}
	},
	{#State 3
		ACTIONS => {
			'' => 70
		}
	},
	{#State 4
		ACTIONS => {
			'error' => 72,
			";" => 71
		}
	},
	{#State 5
		ACTIONS => {
			'error' => 73,
			'IDENTIFIER' => 74
		}
	},
	{#State 6
		ACTIONS => {
			"{" => 75
		}
	},
	{#State 7
		ACTIONS => {
			'error' => 77,
			";" => 76
		}
	},
	{#State 8
		DEFAULT => -82
	},
	{#State 9
		ACTIONS => {
			'IMPORT' => 58
		},
		DEFAULT => -5,
		GOTOS => {
			'import' => 9,
			'imports' => 78
		}
	},
	{#State 10
		ACTIONS => {
			"{" => 79
		}
	},
	{#State 11
		DEFAULT => -39
	},
	{#State 12
		ACTIONS => {
			'error' => 81,
			";" => 80
		}
	},
	{#State 13
		ACTIONS => {
			'SHORT' => 105,
			'CHAR' => 91,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'FIXED' => 98,
			'WCHAR' => 86,
			'DOUBLE' => 110,
			'error' => 106,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'OCTET' => 88,
			'FLOAT' => 89,
			'WSTRING' => 96,
			'UNSIGNED' => 103
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 83,
			'signed_int' => 99,
			'wide_string_type' => 92,
			'integer_type' => 109,
			'boolean_type' => 108,
			'char_type' => 84,
			'scoped_name' => 100,
			'octet_type' => 85,
			'wide_char_type' => 101,
			'fixed_pt_const_type' => 93,
			'signed_long_int' => 102,
			'signed_short_int' => 95,
			'const_type' => 113,
			'string_type' => 104,
			'unsigned_longlong_int' => 87,
			'unsigned_long_int' => 115,
			'unsigned_short_int' => 107,
			'signed_longlong_int' => 90
		}
	},
	{#State 14
		DEFAULT => -83
	},
	{#State 15
		DEFAULT => -2
	},
	{#State 16
		ACTIONS => {
			'error' => 116,
			'IDENTIFIER' => 117
		}
	},
	{#State 17
		ACTIONS => {
			'INTERFACE' => 118
		}
	},
	{#State 18
		DEFAULT => -403
	},
	{#State 19
		ACTIONS => {
			'NATIVE' => 54,
			'ABSTRACT' => 2,
			'COMPONENT' => 55,
			'STRUCT' => 23,
			'TYPEID' => 57,
			'TYPEPREFIX' => 59,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 60,
			'IDENTIFIER' => 62,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 49,
			'CONST' => 13,
			'CUSTOM' => 65,
			'EXCEPTION' => 51,
			'ENUM' => 16
		},
		DEFAULT => -48,
		GOTOS => {
			'component_forward_dcl' => 33,
			'value_forward_dcl' => 1,
			'event' => 34,
			'except_dcl' => 35,
			'module_header' => 36,
			'interface' => 4,
			'value_box_dcl' => 37,
			'value_abs_header' => 6,
			'component' => 7,
			'type_id_dcl' => 39,
			'event_dcl' => 40,
			'value_dcl' => 8,
			'struct_header' => 10,
			'interface_dcl' => 11,
			'value' => 42,
			'value_box_header' => 43,
			'forward_dcl' => 44,
			'enum_type' => 45,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 50,
			'definitions' => 119,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 52,
			'home_dcl' => 53,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 56,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'exception_header' => 27,
			'union_type' => 28,
			'event_header' => 61,
			'component_header' => 31,
			'module' => 63,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 66
		}
	},
	{#State 20
		ACTIONS => {
			"{" => 120
		}
	},
	{#State 21
		ACTIONS => {
			'MANAGES' => 121
		}
	},
	{#State 22
		ACTIONS => {
			"{" => 122
		}
	},
	{#State 23
		ACTIONS => {
			'error' => 123,
			'IDENTIFIER' => 124
		}
	},
	{#State 24
		DEFAULT => -493
	},
	{#State 25
		ACTIONS => {
			"{" => 125
		}
	},
	{#State 26
		DEFAULT => -197
	},
	{#State 27
		ACTIONS => {
			'error' => 127,
			"{" => 126
		}
	},
	{#State 28
		DEFAULT => -198
	},
	{#State 29
		ACTIONS => {
			'error' => 128,
			'IDENTIFIER' => 129
		}
	},
	{#State 30
		ACTIONS => {
			'error' => 130,
			'IDENTIFIER' => 131
		}
	},
	{#State 31
		ACTIONS => {
			"{" => 132
		}
	},
	{#State 32
		ACTIONS => {
			"{" => 133
		},
		GOTOS => {
			'home_body' => 134
		}
	},
	{#State 33
		DEFAULT => -404
	},
	{#State 34
		ACTIONS => {
			'error' => 136,
			";" => 135
		}
	},
	{#State 35
		ACTIONS => {
			'error' => 138,
			";" => 137
		}
	},
	{#State 36
		ACTIONS => {
			'error' => 140,
			"{" => 139
		}
	},
	{#State 37
		DEFAULT => -84
	},
	{#State 38
		ACTIONS => {
			'error' => 141,
			'IDENTIFIER' => 142
		}
	},
	{#State 39
		ACTIONS => {
			'error' => 144,
			";" => 143
		}
	},
	{#State 40
		DEFAULT => -492
	},
	{#State 41
		ACTIONS => {
			'error' => 145,
			'IDENTIFIER' => 146
		}
	},
	{#State 42
		ACTIONS => {
			'error' => 148,
			";" => 147
		}
	},
	{#State 43
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'FIXED' => 163,
			'VALUEBASE' => 155,
			'SEQUENCE' => 150,
			'STRUCT' => 157,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'UNION' => 160,
			'WCHAR' => 86,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ENUM' => 16,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 166,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'type_spec' => 153,
			'string_type' => 168,
			'struct_header' => 10,
			'base_type_spec' => 169,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'enum_type' => 170,
			'enum_header' => 48,
			'unsigned_short_int' => 107,
			'union_header' => 50,
			'signed_longlong_int' => 90,
			'wide_string_type' => 156,
			'boolean_type' => 173,
			'integer_type' => 174,
			'signed_short_int' => 95,
			'struct_type' => 158,
			'union_type' => 159,
			'sequence_type' => 175,
			'unsigned_long_int' => 115,
			'template_type_spec' => 161,
			'constr_type_spec' => 162,
			'simple_type_spec' => 176,
			'fixed_pt_type' => 177
		}
	},
	{#State 44
		DEFAULT => -40
	},
	{#State 45
		DEFAULT => -199
	},
	{#State 46
		DEFAULT => -4
	},
	{#State 47
		DEFAULT => -201
	},
	{#State 48
		ACTIONS => {
			'error' => 179,
			"{" => 178
		}
	},
	{#State 49
		DEFAULT => -47
	},
	{#State 50
		ACTIONS => {
			'SWITCH' => 180
		}
	},
	{#State 51
		ACTIONS => {
			'error' => 181,
			'IDENTIFIER' => 182
		}
	},
	{#State 52
		ACTIONS => {
			'error' => 184,
			";" => 183
		}
	},
	{#State 53
		ACTIONS => {
			'error' => 186,
			";" => 185
		}
	},
	{#State 54
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 189
		},
		GOTOS => {
			'simple_declarator' => 188
		}
	},
	{#State 55
		ACTIONS => {
			'error' => 190,
			'IDENTIFIER' => 191
		}
	},
	{#State 56
		DEFAULT => -494
	},
	{#State 57
		ACTIONS => {
			'error' => 193,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 192
		}
	},
	{#State 58
		ACTIONS => {
			'error' => 197,
			'IDENTIFIER' => 114,
			"::" => 94,
			'STRING_LITERAL' => 198
		},
		GOTOS => {
			'scoped_name' => 196,
			'string_literal' => 194,
			'imported_scope' => 195
		}
	},
	{#State 59
		ACTIONS => {
			'error' => 201,
			'IDENTIFIER' => 114,
			"::" => 199
		},
		GOTOS => {
			'scoped_name' => 200
		}
	},
	{#State 60
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'FIXED' => 163,
			'VALUEBASE' => 155,
			'SEQUENCE' => 150,
			'STRUCT' => 157,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'UNION' => 160,
			'WCHAR' => 86,
			'error' => 204,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ENUM' => 16,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 166,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'type_spec' => 202,
			'type_declarator' => 203,
			'string_type' => 168,
			'struct_header' => 10,
			'base_type_spec' => 169,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'enum_type' => 170,
			'enum_header' => 48,
			'unsigned_short_int' => 107,
			'union_header' => 50,
			'signed_longlong_int' => 90,
			'wide_string_type' => 156,
			'boolean_type' => 173,
			'integer_type' => 174,
			'signed_short_int' => 95,
			'struct_type' => 158,
			'union_type' => 159,
			'sequence_type' => 175,
			'unsigned_long_int' => 115,
			'template_type_spec' => 161,
			'constr_type_spec' => 162,
			'simple_type_spec' => 176,
			'fixed_pt_type' => 177
		}
	},
	{#State 61
		ACTIONS => {
			"{" => 205
		}
	},
	{#State 62
		ACTIONS => {
			'error' => 206
		}
	},
	{#State 63
		ACTIONS => {
			'error' => 208,
			";" => 207
		}
	},
	{#State 64
		ACTIONS => {
			'error' => 210,
			";" => 209
		}
	},
	{#State 65
		ACTIONS => {
			'error' => 213,
			'VALUETYPE' => 212,
			'EVENTTYPE' => 211
		}
	},
	{#State 66
		ACTIONS => {
			'NATIVE' => 54,
			'ABSTRACT' => 2,
			'COMPONENT' => 55,
			'STRUCT' => 23,
			'TYPEID' => 57,
			'IMPORT' => 58,
			'TYPEPREFIX' => 59,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 60,
			'IDENTIFIER' => 62,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 49,
			'CONST' => 13,
			'CUSTOM' => 65,
			'EXCEPTION' => 51,
			'ENUM' => 16,
			'INTERFACE' => -48
		},
		DEFAULT => -7,
		GOTOS => {
			'component_forward_dcl' => 33,
			'value_forward_dcl' => 1,
			'event' => 34,
			'except_dcl' => 35,
			'module_header' => 36,
			'interface' => 4,
			'value_box_dcl' => 37,
			'value_abs_header' => 6,
			'component' => 7,
			'type_id_dcl' => 39,
			'event_dcl' => 40,
			'value_dcl' => 8,
			'import' => 9,
			'struct_header' => 10,
			'interface_dcl' => 11,
			'value' => 42,
			'value_box_header' => 43,
			'forward_dcl' => 44,
			'enum_type' => 45,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 50,
			'definitions' => 214,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 52,
			'imports' => 215,
			'home_dcl' => 53,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 56,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'exception_header' => 27,
			'union_type' => 28,
			'event_header' => 61,
			'component_header' => 31,
			'module' => 63,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 66
		}
	},
	{#State 67
		ACTIONS => {
			'error' => 216,
			'IDENTIFIER' => 217
		}
	},
	{#State 68
		ACTIONS => {
			'error' => 218,
			'IDENTIFIER' => 219
		}
	},
	{#State 69
		DEFAULT => -96
	},
	{#State 70
		DEFAULT => 0
	},
	{#State 71
		DEFAULT => -13
	},
	{#State 72
		DEFAULT => -24
	},
	{#State 73
		DEFAULT => -510
	},
	{#State 74
		ACTIONS => {
			"{" => -506,
			":" => 222,
			'SUPPORTS' => 220
		},
		DEFAULT => -495,
		GOTOS => {
			'supported_interface_spec' => 223,
			'value_inheritance_spec' => 221
		}
	},
	{#State 75
		ACTIONS => {
			'PRIVATE' => 225,
			'ONEWAY' => 226,
			'FACTORY' => 238,
			'UNSIGNED' => -330,
			'SHORT' => -330,
			'WCHAR' => -330,
			'error' => 241,
			'CONST' => 13,
			'EXCEPTION' => 51,
			"}" => 242,
			'FLOAT' => -330,
			'OCTET' => -330,
			'ENUM' => 16,
			'ANY' => -330,
			'CHAR' => -330,
			'OBJECT' => -330,
			'NATIVE' => 54,
			'VALUEBASE' => -330,
			'VOID' => -330,
			'STRUCT' => 23,
			'DOUBLE' => -330,
			'TYPEID' => 57,
			'LONG' => -330,
			'STRING' => -330,
			"::" => -330,
			'TYPEPREFIX' => 59,
			'WSTRING' => -330,
			'BOOLEAN' => -330,
			'TYPEDEF' => 60,
			'IDENTIFIER' => -330,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249,
			'PUBLIC' => 233
		},
		GOTOS => {
			'init_header_param' => 224,
			'const_dcl' => 243,
			'op_mod' => 227,
			'state_member' => 237,
			'except_dcl' => 236,
			'attr_spec' => 228,
			'op_attribute' => 229,
			'state_mod' => 230,
			'readonly_attr_spec' => 231,
			'exports' => 244,
			'_export' => 245,
			'type_id_dcl' => 239,
			'export' => 246,
			'init_header' => 240,
			'struct_type' => 26,
			'op_header' => 247,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 250,
			'enum_type' => 45,
			'init_dcl' => 234,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'type_dcl' => 251,
			'union_header' => 50
		}
	},
	{#State 76
		DEFAULT => -19
	},
	{#State 77
		DEFAULT => -30
	},
	{#State 78
		DEFAULT => -6
	},
	{#State 79
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'FIXED' => 163,
			'VALUEBASE' => 155,
			'SEQUENCE' => 150,
			'STRUCT' => 157,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'UNION' => 160,
			'WCHAR' => 86,
			'error' => 254,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ENUM' => 16,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 166,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'type_spec' => 252,
			'string_type' => 168,
			'struct_header' => 10,
			'base_type_spec' => 169,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'enum_type' => 170,
			'enum_header' => 48,
			'member_list' => 253,
			'unsigned_short_int' => 107,
			'union_header' => 50,
			'signed_longlong_int' => 90,
			'wide_string_type' => 156,
			'boolean_type' => 173,
			'integer_type' => 174,
			'signed_short_int' => 95,
			'member' => 255,
			'struct_type' => 158,
			'union_type' => 159,
			'sequence_type' => 175,
			'unsigned_long_int' => 115,
			'template_type_spec' => 161,
			'constr_type_spec' => 162,
			'simple_type_spec' => 176,
			'fixed_pt_type' => 177
		}
	},
	{#State 80
		DEFAULT => -17
	},
	{#State 81
		DEFAULT => -28
	},
	{#State 82
		DEFAULT => -237
	},
	{#State 83
		DEFAULT => -149
	},
	{#State 84
		DEFAULT => -146
	},
	{#State 85
		DEFAULT => -154
	},
	{#State 86
		DEFAULT => -251
	},
	{#State 87
		DEFAULT => -246
	},
	{#State 88
		DEFAULT => -253
	},
	{#State 89
		DEFAULT => -233
	},
	{#State 90
		DEFAULT => -240
	},
	{#State 91
		DEFAULT => -250
	},
	{#State 92
		DEFAULT => -151
	},
	{#State 93
		DEFAULT => -152
	},
	{#State 94
		ACTIONS => {
			'error' => 256,
			'IDENTIFIER' => 257
		}
	},
	{#State 95
		DEFAULT => -238
	},
	{#State 96
		ACTIONS => {
			"<" => 258
		},
		DEFAULT => -307
	},
	{#State 97
		DEFAULT => -252
	},
	{#State 98
		DEFAULT => -365
	},
	{#State 99
		DEFAULT => -236
	},
	{#State 100
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -153
	},
	{#State 101
		DEFAULT => -147
	},
	{#State 102
		DEFAULT => -239
	},
	{#State 103
		ACTIONS => {
			'SHORT' => 260,
			'LONG' => 261
		}
	},
	{#State 104
		DEFAULT => -150
	},
	{#State 105
		DEFAULT => -241
	},
	{#State 106
		DEFAULT => -144
	},
	{#State 107
		DEFAULT => -244
	},
	{#State 108
		DEFAULT => -148
	},
	{#State 109
		DEFAULT => -145
	},
	{#State 110
		DEFAULT => -234
	},
	{#State 111
		ACTIONS => {
			'DOUBLE' => 262,
			'LONG' => 263
		},
		DEFAULT => -242
	},
	{#State 112
		ACTIONS => {
			"<" => 264
		},
		DEFAULT => -304
	},
	{#State 113
		ACTIONS => {
			'error' => 265,
			'IDENTIFIER' => 266
		}
	},
	{#State 114
		DEFAULT => -77
	},
	{#State 115
		DEFAULT => -245
	},
	{#State 116
		DEFAULT => -292
	},
	{#State 117
		DEFAULT => -291
	},
	{#State 118
		ACTIONS => {
			'error' => 267,
			'IDENTIFIER' => 268
		}
	},
	{#State 119
		DEFAULT => -1
	},
	{#State 120
		ACTIONS => {
			'PRIVATE' => 225,
			'ONEWAY' => 226,
			'FACTORY' => 238,
			'UNSIGNED' => -330,
			'SHORT' => -330,
			'WCHAR' => -330,
			'error' => 269,
			'CONST' => 13,
			'EXCEPTION' => 51,
			"}" => 270,
			'FLOAT' => -330,
			'OCTET' => -330,
			'ENUM' => 16,
			'ANY' => -330,
			'CHAR' => -330,
			'OBJECT' => -330,
			'NATIVE' => 54,
			'VALUEBASE' => -330,
			'VOID' => -330,
			'STRUCT' => 23,
			'DOUBLE' => -330,
			'TYPEID' => 57,
			'LONG' => -330,
			'STRING' => -330,
			"::" => -330,
			'TYPEPREFIX' => 59,
			'WSTRING' => -330,
			'BOOLEAN' => -330,
			'TYPEDEF' => 60,
			'IDENTIFIER' => -330,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249,
			'PUBLIC' => 233
		},
		GOTOS => {
			'init_header_param' => 224,
			'const_dcl' => 243,
			'op_mod' => 227,
			'state_member' => 237,
			'except_dcl' => 236,
			'attr_spec' => 228,
			'op_attribute' => 229,
			'state_mod' => 230,
			'readonly_attr_spec' => 231,
			'exports' => 271,
			'_export' => 245,
			'type_id_dcl' => 239,
			'export' => 246,
			'init_header' => 240,
			'struct_type' => 26,
			'op_header' => 247,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 250,
			'enum_type' => 45,
			'init_dcl' => 234,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'type_dcl' => 251,
			'union_header' => 50,
			'interface_body' => 272
		}
	},
	{#State 121
		ACTIONS => {
			'error' => 274,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 273
		}
	},
	{#State 122
		ACTIONS => {
			'PRIVATE' => 225,
			'ONEWAY' => 226,
			'FACTORY' => 238,
			'UNSIGNED' => -330,
			'SHORT' => -330,
			'WCHAR' => -330,
			'error' => 278,
			'CONST' => 13,
			'EXCEPTION' => 51,
			"}" => 279,
			'FLOAT' => -330,
			'OCTET' => -330,
			'ENUM' => 16,
			'ANY' => -330,
			'CHAR' => -330,
			'OBJECT' => -330,
			'NATIVE' => 54,
			'VALUEBASE' => -330,
			'VOID' => -330,
			'STRUCT' => 23,
			'DOUBLE' => -330,
			'TYPEID' => 57,
			'LONG' => -330,
			'STRING' => -330,
			"::" => -330,
			'TYPEPREFIX' => 59,
			'WSTRING' => -330,
			'BOOLEAN' => -330,
			'TYPEDEF' => 60,
			'IDENTIFIER' => -330,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249,
			'PUBLIC' => 233
		},
		GOTOS => {
			'init_header_param' => 224,
			'const_dcl' => 243,
			'op_mod' => 227,
			'value_elements' => 280,
			'except_dcl' => 236,
			'state_member' => 277,
			'attr_spec' => 228,
			'op_attribute' => 229,
			'state_mod' => 230,
			'value_element' => 275,
			'readonly_attr_spec' => 231,
			'type_id_dcl' => 239,
			'export' => 281,
			'init_header' => 240,
			'struct_type' => 26,
			'op_header' => 247,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 250,
			'enum_type' => 45,
			'init_dcl' => 276,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'type_dcl' => 251,
			'union_header' => 50
		}
	},
	{#State 123
		ACTIONS => {
			"{" => -259
		},
		DEFAULT => -368
	},
	{#State 124
		ACTIONS => {
			"{" => -258
		},
		DEFAULT => -367
	},
	{#State 125
		ACTIONS => {
			'PRIVATE' => 225,
			'ONEWAY' => 226,
			'FACTORY' => 238,
			'UNSIGNED' => -330,
			'SHORT' => -330,
			'WCHAR' => -330,
			'error' => 282,
			'CONST' => 13,
			'EXCEPTION' => 51,
			"}" => 283,
			'FLOAT' => -330,
			'OCTET' => -330,
			'ENUM' => 16,
			'ANY' => -330,
			'CHAR' => -330,
			'OBJECT' => -330,
			'NATIVE' => 54,
			'VALUEBASE' => -330,
			'VOID' => -330,
			'STRUCT' => 23,
			'DOUBLE' => -330,
			'TYPEID' => 57,
			'LONG' => -330,
			'STRING' => -330,
			"::" => -330,
			'TYPEPREFIX' => 59,
			'WSTRING' => -330,
			'BOOLEAN' => -330,
			'TYPEDEF' => 60,
			'IDENTIFIER' => -330,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249,
			'PUBLIC' => 233
		},
		GOTOS => {
			'init_header_param' => 224,
			'const_dcl' => 243,
			'op_mod' => 227,
			'state_member' => 237,
			'except_dcl' => 236,
			'attr_spec' => 228,
			'op_attribute' => 229,
			'state_mod' => 230,
			'readonly_attr_spec' => 231,
			'exports' => 284,
			'_export' => 245,
			'type_id_dcl' => 239,
			'export' => 246,
			'init_header' => 240,
			'struct_type' => 26,
			'op_header' => 247,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 250,
			'enum_type' => 45,
			'init_dcl' => 234,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'type_dcl' => 251,
			'union_header' => 50
		}
	},
	{#State 126
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'FIXED' => 163,
			'VALUEBASE' => 155,
			'SEQUENCE' => 150,
			'STRUCT' => 157,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'UNION' => 160,
			'WCHAR' => 86,
			'error' => 286,
			"}" => 287,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ENUM' => 16,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 166,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'type_spec' => 252,
			'string_type' => 168,
			'struct_header' => 10,
			'base_type_spec' => 169,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'enum_type' => 170,
			'enum_header' => 48,
			'member_list' => 285,
			'unsigned_short_int' => 107,
			'union_header' => 50,
			'signed_longlong_int' => 90,
			'wide_string_type' => 156,
			'boolean_type' => 173,
			'integer_type' => 174,
			'signed_short_int' => 95,
			'member' => 255,
			'struct_type' => 158,
			'union_type' => 159,
			'sequence_type' => 175,
			'unsigned_long_int' => 115,
			'template_type_spec' => 161,
			'constr_type_spec' => 162,
			'simple_type_spec' => 176,
			'fixed_pt_type' => 177
		}
	},
	{#State 127
		DEFAULT => -319
	},
	{#State 128
		ACTIONS => {
			'SWITCH' => -270
		},
		DEFAULT => -370
	},
	{#State 129
		ACTIONS => {
			'SWITCH' => -269
		},
		DEFAULT => -369
	},
	{#State 130
		DEFAULT => -461
	},
	{#State 131
		ACTIONS => {
			":" => 289,
			'SUPPORTS' => 220
		},
		DEFAULT => -460,
		GOTOS => {
			'home_inheritance_spec' => 288,
			'supported_interface_spec' => 290
		}
	},
	{#State 132
		ACTIONS => {
			'error' => 301,
			'PUBLISHES' => 304,
			"}" => 302,
			'USES' => 296,
			'READONLY' => 248,
			'PROVIDES' => 303,
			'CONSUMES' => 306,
			'ATTRIBUTE' => 249,
			'EMITS' => 299
		},
		GOTOS => {
			'consumes_dcl' => 291,
			'emits_dcl' => 298,
			'attr_spec' => 228,
			'provides_dcl' => 295,
			'readonly_attr_spec' => 231,
			'component_exports' => 292,
			'attr_dcl' => 297,
			'publishes_dcl' => 293,
			'uses_dcl' => 305,
			'component_export' => 294,
			'component_body' => 300
		}
	},
	{#State 133
		ACTIONS => {
			'ONEWAY' => 226,
			'FACTORY' => 313,
			'UNSIGNED' => -330,
			'SHORT' => -330,
			'WCHAR' => -330,
			'error' => 314,
			'CONST' => 13,
			'OCTET' => -330,
			'FLOAT' => -330,
			'EXCEPTION' => 51,
			"}" => 315,
			'ENUM' => 16,
			'FINDER' => 308,
			'ANY' => -330,
			'CHAR' => -330,
			'OBJECT' => -330,
			'NATIVE' => 54,
			'VALUEBASE' => -330,
			'VOID' => -330,
			'STRUCT' => 23,
			'DOUBLE' => -330,
			'TYPEID' => 57,
			'LONG' => -330,
			'STRING' => -330,
			"::" => -330,
			'TYPEPREFIX' => 59,
			'WSTRING' => -330,
			'TYPEDEF' => 60,
			'BOOLEAN' => -330,
			'IDENTIFIER' => -330,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249
		},
		GOTOS => {
			'const_dcl' => 243,
			'op_mod' => 227,
			'except_dcl' => 236,
			'attr_spec' => 228,
			'factory_header_param' => 307,
			'home_exports' => 310,
			'home_export' => 309,
			'op_attribute' => 229,
			'readonly_attr_spec' => 231,
			'finder_dcl' => 311,
			'type_id_dcl' => 239,
			'export' => 316,
			'struct_type' => 26,
			'finder_header' => 317,
			'exception_header' => 27,
			'union_type' => 28,
			'op_header' => 247,
			'struct_header' => 10,
			'factory_dcl' => 312,
			'enum_type' => 45,
			'finder_header_param' => 318,
			'op_dcl' => 250,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'union_header' => 50,
			'type_dcl' => 251,
			'factory_header' => 319
		}
	},
	{#State 134
		DEFAULT => -453
	},
	{#State 135
		DEFAULT => -18
	},
	{#State 136
		DEFAULT => -29
	},
	{#State 137
		DEFAULT => -12
	},
	{#State 138
		DEFAULT => -23
	},
	{#State 139
		ACTIONS => {
			'NATIVE' => 54,
			'ABSTRACT' => 2,
			'COMPONENT' => 55,
			'STRUCT' => 23,
			'TYPEID' => 57,
			'TYPEPREFIX' => 59,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 60,
			'IDENTIFIER' => 62,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'error' => 321,
			'LOCAL' => 49,
			'CONST' => 13,
			'CUSTOM' => 65,
			'EXCEPTION' => 51,
			"}" => 322,
			'ENUM' => 16,
			'INTERFACE' => -48
		},
		GOTOS => {
			'component_forward_dcl' => 33,
			'value_forward_dcl' => 1,
			'event' => 34,
			'except_dcl' => 35,
			'module_header' => 36,
			'interface' => 4,
			'value_box_dcl' => 37,
			'value_abs_header' => 6,
			'component' => 7,
			'type_id_dcl' => 39,
			'event_dcl' => 40,
			'value_dcl' => 8,
			'struct_header' => 10,
			'interface_dcl' => 11,
			'value' => 42,
			'value_box_header' => 43,
			'forward_dcl' => 44,
			'enum_type' => 45,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 50,
			'definitions' => 320,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 52,
			'home_dcl' => 53,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 56,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'exception_header' => 27,
			'union_type' => 28,
			'event_header' => 61,
			'component_header' => 31,
			'module' => 63,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 66
		}
	},
	{#State 140
		ACTIONS => {
			"}" => 323
		}
	},
	{#State 141
		DEFAULT => -106
	},
	{#State 142
		ACTIONS => {
			":" => 222,
			";" => -86,
			"{" => -102,
			'error' => -86,
			'SUPPORTS' => 220
		},
		DEFAULT => -89,
		GOTOS => {
			'supported_interface_spec' => 223,
			'value_inheritance_spec' => 324
		}
	},
	{#State 143
		DEFAULT => -16
	},
	{#State 144
		DEFAULT => -27
	},
	{#State 145
		DEFAULT => -38
	},
	{#State 146
		DEFAULT => -37
	},
	{#State 147
		DEFAULT => -15
	},
	{#State 148
		DEFAULT => -26
	},
	{#State 149
		DEFAULT => -209
	},
	{#State 150
		ACTIONS => {
			'error' => 326,
			"<" => 325
		}
	},
	{#State 151
		DEFAULT => -211
	},
	{#State 152
		DEFAULT => -214
	},
	{#State 153
		DEFAULT => -88
	},
	{#State 154
		DEFAULT => -215
	},
	{#State 155
		DEFAULT => -366
	},
	{#State 156
		DEFAULT => -220
	},
	{#State 157
		ACTIONS => {
			'error' => 327,
			'IDENTIFIER' => 328
		}
	},
	{#State 158
		DEFAULT => -222
	},
	{#State 159
		DEFAULT => -223
	},
	{#State 160
		ACTIONS => {
			'error' => 329,
			'IDENTIFIER' => 330
		}
	},
	{#State 161
		DEFAULT => -207
	},
	{#State 162
		DEFAULT => -205
	},
	{#State 163
		ACTIONS => {
			'error' => 332,
			"<" => 331
		}
	},
	{#State 164
		DEFAULT => -217
	},
	{#State 165
		DEFAULT => -216
	},
	{#State 166
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -208
	},
	{#State 167
		DEFAULT => -212
	},
	{#State 168
		DEFAULT => -219
	},
	{#State 169
		DEFAULT => -206
	},
	{#State 170
		DEFAULT => -224
	},
	{#State 171
		DEFAULT => -254
	},
	{#State 172
		DEFAULT => -255
	},
	{#State 173
		DEFAULT => -213
	},
	{#State 174
		DEFAULT => -210
	},
	{#State 175
		DEFAULT => -218
	},
	{#State 176
		DEFAULT => -204
	},
	{#State 177
		DEFAULT => -221
	},
	{#State 178
		ACTIONS => {
			'error' => 335,
			'IDENTIFIER' => 336
		},
		GOTOS => {
			'enumerators' => 334,
			'enumerator' => 333
		}
	},
	{#State 179
		DEFAULT => -290
	},
	{#State 180
		ACTIONS => {
			'error' => 338,
			"(" => 337
		}
	},
	{#State 181
		DEFAULT => -321
	},
	{#State 182
		DEFAULT => -320
	},
	{#State 183
		DEFAULT => -11
	},
	{#State 184
		DEFAULT => -22
	},
	{#State 185
		DEFAULT => -20
	},
	{#State 186
		DEFAULT => -31
	},
	{#State 187
		ACTIONS => {
			";" => 339,
			"," => 340
		}
	},
	{#State 188
		DEFAULT => -200
	},
	{#State 189
		DEFAULT => -229
	},
	{#State 190
		ACTIONS => {
			"{" => -414
		},
		DEFAULT => -406
	},
	{#State 191
		ACTIONS => {
			"{" => -413,
			":" => 342,
			'SUPPORTS' => 220
		},
		DEFAULT => -405,
		GOTOS => {
			'component_inheritance_spec' => 341,
			'supported_interface_spec' => 343
		}
	},
	{#State 192
		ACTIONS => {
			'error' => 345,
			"::" => 259,
			'STRING_LITERAL' => 198
		},
		GOTOS => {
			'string_literal' => 344
		}
	},
	{#State 193
		DEFAULT => -378
	},
	{#State 194
		DEFAULT => -375
	},
	{#State 195
		ACTIONS => {
			'error' => 347,
			";" => 346
		}
	},
	{#State 196
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -374
	},
	{#State 197
		DEFAULT => -373
	},
	{#State 198
		ACTIONS => {
			'STRING_LITERAL' => 198
		},
		DEFAULT => -189,
		GOTOS => {
			'string_literal' => 348
		}
	},
	{#State 199
		ACTIONS => {
			'error' => 256,
			'IDENTIFIER' => 257,
			'STRING_LITERAL' => 198
		},
		GOTOS => {
			'string_literal' => 349
		}
	},
	{#State 200
		ACTIONS => {
			'error' => 351,
			"::" => 259,
			'STRING_LITERAL' => 198
		},
		GOTOS => {
			'string_literal' => 350
		}
	},
	{#State 201
		DEFAULT => -382
	},
	{#State 202
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 357
		},
		GOTOS => {
			'declarators' => 352,
			'declarator' => 355,
			'simple_declarator' => 356,
			'array_declarator' => 354,
			'complex_declarator' => 353
		}
	},
	{#State 203
		DEFAULT => -196
	},
	{#State 204
		DEFAULT => -202
	},
	{#State 205
		ACTIONS => {
			'PRIVATE' => 225,
			'ONEWAY' => 226,
			'FACTORY' => 238,
			'UNSIGNED' => -330,
			'SHORT' => -330,
			'WCHAR' => -330,
			'error' => 358,
			'CONST' => 13,
			'EXCEPTION' => 51,
			"}" => 359,
			'FLOAT' => -330,
			'OCTET' => -330,
			'ENUM' => 16,
			'ANY' => -330,
			'CHAR' => -330,
			'OBJECT' => -330,
			'NATIVE' => 54,
			'VALUEBASE' => -330,
			'VOID' => -330,
			'STRUCT' => 23,
			'DOUBLE' => -330,
			'TYPEID' => 57,
			'LONG' => -330,
			'STRING' => -330,
			"::" => -330,
			'TYPEPREFIX' => 59,
			'WSTRING' => -330,
			'BOOLEAN' => -330,
			'TYPEDEF' => 60,
			'IDENTIFIER' => -330,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249,
			'PUBLIC' => 233
		},
		GOTOS => {
			'init_header_param' => 224,
			'const_dcl' => 243,
			'op_mod' => 227,
			'value_elements' => 360,
			'except_dcl' => 236,
			'state_member' => 277,
			'attr_spec' => 228,
			'op_attribute' => 229,
			'state_mod' => 230,
			'value_element' => 275,
			'readonly_attr_spec' => 231,
			'type_id_dcl' => 239,
			'export' => 281,
			'init_header' => 240,
			'struct_type' => 26,
			'op_header' => 247,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 250,
			'enum_type' => 45,
			'init_dcl' => 276,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'type_dcl' => 251,
			'union_header' => 50
		}
	},
	{#State 206
		ACTIONS => {
			";" => 361
		}
	},
	{#State 207
		DEFAULT => -14
	},
	{#State 208
		DEFAULT => -25
	},
	{#State 209
		DEFAULT => -10
	},
	{#State 210
		DEFAULT => -21
	},
	{#State 211
		ACTIONS => {
			'error' => 362,
			'IDENTIFIER' => 363
		}
	},
	{#State 212
		ACTIONS => {
			'error' => 364,
			'IDENTIFIER' => 365
		}
	},
	{#State 213
		DEFAULT => -108
	},
	{#State 214
		DEFAULT => -8
	},
	{#State 215
		ACTIONS => {
			'NATIVE' => 54,
			'ABSTRACT' => 2,
			'COMPONENT' => 55,
			'STRUCT' => 23,
			'TYPEID' => 57,
			'TYPEPREFIX' => 59,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 60,
			'IDENTIFIER' => 62,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 49,
			'CONST' => 13,
			'CUSTOM' => 65,
			'EXCEPTION' => 51,
			'ENUM' => 16
		},
		DEFAULT => -48,
		GOTOS => {
			'component_forward_dcl' => 33,
			'value_forward_dcl' => 1,
			'event' => 34,
			'except_dcl' => 35,
			'module_header' => 36,
			'interface' => 4,
			'value_box_dcl' => 37,
			'value_abs_header' => 6,
			'component' => 7,
			'type_id_dcl' => 39,
			'event_dcl' => 40,
			'value_dcl' => 8,
			'struct_header' => 10,
			'interface_dcl' => 11,
			'value' => 42,
			'value_box_header' => 43,
			'forward_dcl' => 44,
			'enum_type' => 45,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 50,
			'definitions' => 366,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 52,
			'home_dcl' => 53,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 56,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'exception_header' => 27,
			'union_type' => 28,
			'event_header' => 61,
			'component_header' => 31,
			'module' => 63,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 66
		}
	},
	{#State 216
		DEFAULT => -502
	},
	{#State 217
		ACTIONS => {
			"{" => -500,
			":" => 222,
			'SUPPORTS' => 220
		},
		DEFAULT => -496,
		GOTOS => {
			'supported_interface_spec' => 223,
			'value_inheritance_spec' => 367
		}
	},
	{#State 218
		DEFAULT => -95
	},
	{#State 219
		ACTIONS => {
			"{" => -93,
			":" => 222,
			'SUPPORTS' => 220
		},
		DEFAULT => -87,
		GOTOS => {
			'supported_interface_spec' => 223,
			'value_inheritance_spec' => 368
		}
	},
	{#State 220
		ACTIONS => {
			'error' => 371,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 370,
			'interface_name' => 372,
			'interface_names' => 369
		}
	},
	{#State 221
		DEFAULT => -508
	},
	{#State 222
		ACTIONS => {
			'TRUNCATABLE' => 374
		},
		DEFAULT => -114,
		GOTOS => {
			'inheritance_mod' => 373
		}
	},
	{#State 223
		DEFAULT => -112
	},
	{#State 224
		ACTIONS => {
			'error' => 377,
			'RAISES' => 376,
			";" => 375
		},
		GOTOS => {
			'raises_expr' => 378
		}
	},
	{#State 225
		DEFAULT => -124
	},
	{#State 226
		DEFAULT => -331
	},
	{#State 227
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'VALUEBASE' => 155,
			'VOID' => 384,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'WCHAR' => 86,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'wide_string_type' => 380,
			'integer_type' => 174,
			'boolean_type' => 173,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 381,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'signed_short_int' => 95,
			'string_type' => 382,
			'op_type_spec' => 385,
			'base_type_spec' => 383,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'unsigned_long_int' => 115,
			'param_type_spec' => 379,
			'unsigned_short_int' => 107,
			'signed_longlong_int' => 90
		}
	},
	{#State 228
		DEFAULT => -315
	},
	{#State 229
		DEFAULT => -329
	},
	{#State 230
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'FIXED' => 163,
			'VALUEBASE' => 155,
			'SEQUENCE' => 150,
			'STRUCT' => 157,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'UNION' => 160,
			'WCHAR' => 86,
			'error' => 387,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ENUM' => 16,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 166,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'type_spec' => 386,
			'string_type' => 168,
			'struct_header' => 10,
			'base_type_spec' => 169,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'enum_type' => 170,
			'enum_header' => 48,
			'unsigned_short_int' => 107,
			'union_header' => 50,
			'signed_longlong_int' => 90,
			'wide_string_type' => 156,
			'boolean_type' => 173,
			'integer_type' => 174,
			'signed_short_int' => 95,
			'struct_type' => 158,
			'union_type' => 159,
			'sequence_type' => 175,
			'unsigned_long_int' => 115,
			'template_type_spec' => 161,
			'constr_type_spec' => 162,
			'simple_type_spec' => 176,
			'fixed_pt_type' => 177
		}
	},
	{#State 231
		DEFAULT => -314
	},
	{#State 232
		ACTIONS => {
			'error' => 389,
			";" => 388
		}
	},
	{#State 233
		DEFAULT => -123
	},
	{#State 234
		DEFAULT => -57
	},
	{#State 235
		ACTIONS => {
			'error' => 391,
			";" => 390
		}
	},
	{#State 236
		ACTIONS => {
			'error' => 393,
			";" => 392
		}
	},
	{#State 237
		DEFAULT => -56
	},
	{#State 238
		ACTIONS => {
			'error' => 394,
			'IDENTIFIER' => 395
		}
	},
	{#State 239
		ACTIONS => {
			'error' => 397,
			";" => 396
		}
	},
	{#State 240
		ACTIONS => {
			'error' => 399,
			"(" => 398
		}
	},
	{#State 241
		ACTIONS => {
			"}" => 400
		}
	},
	{#State 242
		DEFAULT => -90
	},
	{#State 243
		ACTIONS => {
			'error' => 402,
			";" => 401
		}
	},
	{#State 244
		ACTIONS => {
			"}" => 403
		}
	},
	{#State 245
		ACTIONS => {
			'PRIVATE' => 225,
			'ONEWAY' => 226,
			'FACTORY' => 238,
			'CONST' => 13,
			'EXCEPTION' => 51,
			"}" => -53,
			'ENUM' => 16,
			'NATIVE' => 54,
			'STRUCT' => 23,
			'TYPEID' => 57,
			'TYPEPREFIX' => 59,
			'TYPEDEF' => 60,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249,
			'PUBLIC' => 233
		},
		DEFAULT => -330,
		GOTOS => {
			'init_header_param' => 224,
			'const_dcl' => 243,
			'op_mod' => 227,
			'state_member' => 237,
			'except_dcl' => 236,
			'attr_spec' => 228,
			'op_attribute' => 229,
			'state_mod' => 230,
			'readonly_attr_spec' => 231,
			'exports' => 404,
			'_export' => 245,
			'type_id_dcl' => 239,
			'export' => 246,
			'init_header' => 240,
			'struct_type' => 26,
			'op_header' => 247,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 250,
			'enum_type' => 45,
			'init_dcl' => 234,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'type_dcl' => 251,
			'union_header' => 50
		}
	},
	{#State 246
		DEFAULT => -55
	},
	{#State 247
		ACTIONS => {
			'error' => 406,
			"(" => 405
		},
		GOTOS => {
			'parameter_dcls' => 407
		}
	},
	{#State 248
		ACTIONS => {
			'error' => 408,
			'ATTRIBUTE' => 409
		}
	},
	{#State 249
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'VALUEBASE' => 155,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'WCHAR' => 86,
			'error' => 411,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'wide_string_type' => 380,
			'integer_type' => 174,
			'boolean_type' => 173,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 381,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'signed_short_int' => 95,
			'string_type' => 382,
			'base_type_spec' => 383,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'unsigned_long_int' => 115,
			'param_type_spec' => 410,
			'unsigned_short_int' => 107,
			'signed_longlong_int' => 90
		}
	},
	{#State 250
		ACTIONS => {
			'error' => 413,
			";" => 412
		}
	},
	{#State 251
		ACTIONS => {
			'error' => 415,
			";" => 414
		}
	},
	{#State 252
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 357
		},
		GOTOS => {
			'declarators' => 416,
			'declarator' => 355,
			'simple_declarator' => 356,
			'array_declarator' => 354,
			'complex_declarator' => 353
		}
	},
	{#State 253
		ACTIONS => {
			"}" => 417
		}
	},
	{#State 254
		ACTIONS => {
			"}" => 418
		}
	},
	{#State 255
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'FIXED' => 163,
			'VALUEBASE' => 155,
			'SEQUENCE' => 150,
			'STRUCT' => 157,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'UNION' => 160,
			'WCHAR' => 86,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ENUM' => 16,
			'ANY' => 171
		},
		DEFAULT => -260,
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 166,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'type_spec' => 252,
			'string_type' => 168,
			'struct_header' => 10,
			'base_type_spec' => 169,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'enum_type' => 170,
			'enum_header' => 48,
			'member_list' => 419,
			'unsigned_short_int' => 107,
			'union_header' => 50,
			'signed_longlong_int' => 90,
			'wide_string_type' => 156,
			'boolean_type' => 173,
			'integer_type' => 174,
			'signed_short_int' => 95,
			'member' => 255,
			'struct_type' => 158,
			'union_type' => 159,
			'sequence_type' => 175,
			'unsigned_long_int' => 115,
			'template_type_spec' => 161,
			'constr_type_spec' => 162,
			'simple_type_spec' => 176,
			'fixed_pt_type' => 177
		}
	},
	{#State 256
		DEFAULT => -79
	},
	{#State 257
		DEFAULT => -78
	},
	{#State 258
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 435,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'primary_expr' => 441,
			'and_expr' => 442,
			'scoped_name' => 433,
			'positive_int_const' => 434,
			'wide_string_literal' => 421,
			'boolean_literal' => 423,
			'mult_expr' => 444,
			'const_exp' => 424,
			'or_expr' => 425,
			'unary_expr' => 446,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 259
		ACTIONS => {
			'error' => 449,
			'IDENTIFIER' => 450
		}
	},
	{#State 260
		DEFAULT => -247
	},
	{#State 261
		ACTIONS => {
			'LONG' => 451
		},
		DEFAULT => -248
	},
	{#State 262
		DEFAULT => -235
	},
	{#State 263
		DEFAULT => -243
	},
	{#State 264
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 453,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'primary_expr' => 441,
			'and_expr' => 442,
			'scoped_name' => 433,
			'positive_int_const' => 452,
			'wide_string_literal' => 421,
			'boolean_literal' => 423,
			'mult_expr' => 444,
			'const_exp' => 424,
			'or_expr' => 425,
			'unary_expr' => 446,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 265
		DEFAULT => -143
	},
	{#State 266
		ACTIONS => {
			'error' => 454,
			"=" => 455
		}
	},
	{#State 267
		ACTIONS => {
			"{" => -51
		},
		DEFAULT => -45
	},
	{#State 268
		ACTIONS => {
			"{" => -49,
			":" => 457
		},
		DEFAULT => -44,
		GOTOS => {
			'interface_inheritance_spec' => 456
		}
	},
	{#State 269
		ACTIONS => {
			"}" => 458
		}
	},
	{#State 270
		DEFAULT => -41
	},
	{#State 271
		DEFAULT => -52
	},
	{#State 272
		ACTIONS => {
			"}" => 459
		}
	},
	{#State 273
		ACTIONS => {
			"::" => 259,
			'PRIMARYKEY' => 460
		},
		DEFAULT => -455,
		GOTOS => {
			'primary_key_spec' => 461
		}
	},
	{#State 274
		DEFAULT => -456
	},
	{#State 275
		ACTIONS => {
			'PRIVATE' => 225,
			'ONEWAY' => 226,
			'FACTORY' => 238,
			'CONST' => 13,
			'EXCEPTION' => 51,
			"}" => -100,
			'ENUM' => 16,
			'NATIVE' => 54,
			'STRUCT' => 23,
			'TYPEID' => 57,
			'TYPEPREFIX' => 59,
			'TYPEDEF' => 60,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249,
			'PUBLIC' => 233
		},
		DEFAULT => -330,
		GOTOS => {
			'init_header_param' => 224,
			'const_dcl' => 243,
			'op_mod' => 227,
			'value_elements' => 462,
			'except_dcl' => 236,
			'state_member' => 277,
			'attr_spec' => 228,
			'op_attribute' => 229,
			'state_mod' => 230,
			'value_element' => 275,
			'readonly_attr_spec' => 231,
			'type_id_dcl' => 239,
			'export' => 281,
			'init_header' => 240,
			'struct_type' => 26,
			'op_header' => 247,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 250,
			'enum_type' => 45,
			'init_dcl' => 276,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'type_dcl' => 251,
			'union_header' => 50
		}
	},
	{#State 276
		DEFAULT => -120
	},
	{#State 277
		DEFAULT => -119
	},
	{#State 278
		ACTIONS => {
			"}" => 463
		}
	},
	{#State 279
		DEFAULT => -97
	},
	{#State 280
		ACTIONS => {
			"}" => 464
		}
	},
	{#State 281
		DEFAULT => -118
	},
	{#State 282
		ACTIONS => {
			"}" => 465
		}
	},
	{#State 283
		DEFAULT => -497
	},
	{#State 284
		ACTIONS => {
			"}" => 466
		}
	},
	{#State 285
		ACTIONS => {
			"}" => 467
		}
	},
	{#State 286
		ACTIONS => {
			"}" => 468
		}
	},
	{#State 287
		DEFAULT => -316
	},
	{#State 288
		ACTIONS => {
			'SUPPORTS' => 220
		},
		DEFAULT => -458,
		GOTOS => {
			'supported_interface_spec' => 469
		}
	},
	{#State 289
		ACTIONS => {
			'error' => 471,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 470
		}
	},
	{#State 290
		DEFAULT => -459
	},
	{#State 291
		ACTIONS => {
			'error' => 473,
			";" => 472
		}
	},
	{#State 292
		DEFAULT => -419
	},
	{#State 293
		ACTIONS => {
			'error' => 475,
			";" => 474
		}
	},
	{#State 294
		ACTIONS => {
			'PUBLISHES' => 304,
			'USES' => 296,
			'READONLY' => 248,
			'PROVIDES' => 303,
			'ATTRIBUTE' => 249,
			'EMITS' => 299,
			'CONSUMES' => 306
		},
		DEFAULT => -420,
		GOTOS => {
			'consumes_dcl' => 291,
			'emits_dcl' => 298,
			'attr_spec' => 228,
			'provides_dcl' => 295,
			'readonly_attr_spec' => 231,
			'component_exports' => 476,
			'attr_dcl' => 297,
			'publishes_dcl' => 293,
			'uses_dcl' => 305,
			'component_export' => 294
		}
	},
	{#State 295
		ACTIONS => {
			'error' => 478,
			";" => 477
		}
	},
	{#State 296
		ACTIONS => {
			'MULTIPLE' => 480
		},
		DEFAULT => -443,
		GOTOS => {
			'uses_mod' => 479
		}
	},
	{#State 297
		ACTIONS => {
			'error' => 482,
			";" => 481
		}
	},
	{#State 298
		ACTIONS => {
			'error' => 484,
			";" => 483
		}
	},
	{#State 299
		ACTIONS => {
			'error' => 486,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 485
		}
	},
	{#State 300
		ACTIONS => {
			"}" => 487
		}
	},
	{#State 301
		ACTIONS => {
			"}" => 488
		}
	},
	{#State 302
		DEFAULT => -407
	},
	{#State 303
		ACTIONS => {
			'error' => 491,
			'OBJECT' => 492,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 490,
			'interface_type' => 489
		}
	},
	{#State 304
		ACTIONS => {
			'error' => 494,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 493
		}
	},
	{#State 305
		ACTIONS => {
			'error' => 496,
			";" => 495
		}
	},
	{#State 306
		ACTIONS => {
			'error' => 498,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 497
		}
	},
	{#State 307
		ACTIONS => {
			'RAISES' => 376
		},
		DEFAULT => -477,
		GOTOS => {
			'raises_expr' => 499
		}
	},
	{#State 308
		ACTIONS => {
			'error' => 500,
			'IDENTIFIER' => 501
		}
	},
	{#State 309
		ACTIONS => {
			'ONEWAY' => 226,
			'FACTORY' => 313,
			'CONST' => 13,
			"}" => -469,
			'EXCEPTION' => 51,
			'ENUM' => 16,
			'FINDER' => 308,
			'NATIVE' => 54,
			'STRUCT' => 23,
			'TYPEID' => 57,
			'TYPEPREFIX' => 59,
			'TYPEDEF' => 60,
			'UNION' => 29,
			'READONLY' => 248,
			'ATTRIBUTE' => 249
		},
		DEFAULT => -330,
		GOTOS => {
			'const_dcl' => 243,
			'op_mod' => 227,
			'except_dcl' => 236,
			'attr_spec' => 228,
			'factory_header_param' => 307,
			'home_exports' => 502,
			'home_export' => 309,
			'op_attribute' => 229,
			'readonly_attr_spec' => 231,
			'finder_dcl' => 311,
			'type_id_dcl' => 239,
			'export' => 316,
			'struct_type' => 26,
			'finder_header' => 317,
			'exception_header' => 27,
			'union_type' => 28,
			'op_header' => 247,
			'struct_header' => 10,
			'factory_dcl' => 312,
			'enum_type' => 45,
			'finder_header_param' => 318,
			'op_dcl' => 250,
			'constr_forward_decl' => 47,
			'enum_header' => 48,
			'type_prefix_dcl' => 232,
			'attr_dcl' => 235,
			'union_header' => 50,
			'type_dcl' => 251,
			'factory_header' => 319
		}
	},
	{#State 310
		ACTIONS => {
			"}" => 503
		}
	},
	{#State 311
		ACTIONS => {
			'error' => 505,
			";" => 504
		}
	},
	{#State 312
		ACTIONS => {
			'error' => 507,
			";" => 506
		}
	},
	{#State 313
		ACTIONS => {
			'error' => 508,
			'IDENTIFIER' => 509
		}
	},
	{#State 314
		ACTIONS => {
			"}" => 510
		}
	},
	{#State 315
		DEFAULT => -466
	},
	{#State 316
		DEFAULT => -471
	},
	{#State 317
		ACTIONS => {
			'error' => 512,
			"(" => 511
		}
	},
	{#State 318
		ACTIONS => {
			'RAISES' => 376
		},
		DEFAULT => -485,
		GOTOS => {
			'raises_expr' => 513
		}
	},
	{#State 319
		ACTIONS => {
			'error' => 515,
			"(" => 514
		}
	},
	{#State 320
		ACTIONS => {
			"}" => 516
		}
	},
	{#State 321
		ACTIONS => {
			"}" => 517
		}
	},
	{#State 322
		DEFAULT => -35
	},
	{#State 323
		DEFAULT => -36
	},
	{#State 324
		DEFAULT => -104
	},
	{#State 325
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'FIXED' => 163,
			'VALUEBASE' => 155,
			'SEQUENCE' => 150,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'WCHAR' => 86,
			'error' => 518,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'wide_string_type' => 156,
			'integer_type' => 174,
			'boolean_type' => 173,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 166,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'signed_short_int' => 95,
			'string_type' => 168,
			'sequence_type' => 175,
			'base_type_spec' => 169,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'unsigned_long_int' => 115,
			'template_type_spec' => 161,
			'unsigned_short_int' => 107,
			'simple_type_spec' => 519,
			'fixed_pt_type' => 177,
			'signed_longlong_int' => 90
		}
	},
	{#State 326
		DEFAULT => -302
	},
	{#State 327
		DEFAULT => -259
	},
	{#State 328
		DEFAULT => -258
	},
	{#State 329
		DEFAULT => -270
	},
	{#State 330
		DEFAULT => -269
	},
	{#State 331
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 521,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'primary_expr' => 441,
			'and_expr' => 442,
			'scoped_name' => 433,
			'positive_int_const' => 520,
			'wide_string_literal' => 421,
			'boolean_literal' => 423,
			'mult_expr' => 444,
			'const_exp' => 424,
			'or_expr' => 425,
			'unary_expr' => 446,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 332
		DEFAULT => -364
	},
	{#State 333
		ACTIONS => {
			";" => 522,
			"," => 523
		},
		DEFAULT => -293
	},
	{#State 334
		ACTIONS => {
			"}" => 524
		}
	},
	{#State 335
		ACTIONS => {
			"}" => 525
		}
	},
	{#State 336
		DEFAULT => -297
	},
	{#State 337
		ACTIONS => {
			'SHORT' => 105,
			'CHAR' => 91,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'error' => 530,
			'LONG' => 533,
			"::" => 94,
			'ENUM' => 16,
			'UNSIGNED' => 103
		},
		GOTOS => {
			'switch_type_spec' => 527,
			'unsigned_int' => 82,
			'signed_int' => 99,
			'integer_type' => 532,
			'boolean_type' => 531,
			'unsigned_longlong_int' => 87,
			'char_type' => 526,
			'enum_type' => 529,
			'unsigned_long_int' => 115,
			'enum_header' => 48,
			'scoped_name' => 528,
			'unsigned_short_int' => 107,
			'signed_long_int' => 102,
			'signed_short_int' => 95,
			'signed_longlong_int' => 90
		}
	},
	{#State 338
		DEFAULT => -268
	},
	{#State 339
		DEFAULT => -231
	},
	{#State 340
		DEFAULT => -230
	},
	{#State 341
		ACTIONS => {
			'SUPPORTS' => 220
		},
		DEFAULT => -411,
		GOTOS => {
			'supported_interface_spec' => 534
		}
	},
	{#State 342
		ACTIONS => {
			'error' => 536,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 535
		}
	},
	{#State 343
		DEFAULT => -412
	},
	{#State 344
		DEFAULT => -376
	},
	{#State 345
		DEFAULT => -377
	},
	{#State 346
		DEFAULT => -371
	},
	{#State 347
		DEFAULT => -372
	},
	{#State 348
		DEFAULT => -190
	},
	{#State 349
		DEFAULT => -381
	},
	{#State 350
		DEFAULT => -379
	},
	{#State 351
		DEFAULT => -380
	},
	{#State 352
		DEFAULT => -203
	},
	{#State 353
		DEFAULT => -228
	},
	{#State 354
		DEFAULT => -232
	},
	{#State 355
		ACTIONS => {
			"," => 537
		},
		DEFAULT => -225
	},
	{#State 356
		DEFAULT => -227
	},
	{#State 357
		ACTIONS => {
			"[" => 540
		},
		DEFAULT => -229,
		GOTOS => {
			'fixed_array_sizes' => 539,
			'fixed_array_size' => 538
		}
	},
	{#State 358
		ACTIONS => {
			"}" => 541
		}
	},
	{#State 359
		DEFAULT => -503
	},
	{#State 360
		ACTIONS => {
			"}" => 542
		}
	},
	{#State 361
		DEFAULT => -32
	},
	{#State 362
		DEFAULT => -511
	},
	{#State 363
		ACTIONS => {
			":" => 222,
			'SUPPORTS' => 220
		},
		DEFAULT => -507,
		GOTOS => {
			'supported_interface_spec' => 223,
			'value_inheritance_spec' => 543
		}
	},
	{#State 364
		DEFAULT => -107
	},
	{#State 365
		ACTIONS => {
			":" => 222,
			'SUPPORTS' => 220
		},
		DEFAULT => -103,
		GOTOS => {
			'supported_interface_spec' => 223,
			'value_inheritance_spec' => 544
		}
	},
	{#State 366
		DEFAULT => -9
	},
	{#State 367
		DEFAULT => -501
	},
	{#State 368
		DEFAULT => -94
	},
	{#State 369
		DEFAULT => -415
	},
	{#State 370
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -76
	},
	{#State 371
		DEFAULT => -416
	},
	{#State 372
		ACTIONS => {
			"," => 545
		},
		DEFAULT => -74
	},
	{#State 373
		ACTIONS => {
			'error' => 548,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 547,
			'value_name' => 546,
			'value_names' => 549
		}
	},
	{#State 374
		DEFAULT => -113
	},
	{#State 375
		DEFAULT => -127
	},
	{#State 376
		ACTIONS => {
			'error' => 551,
			"(" => 550
		}
	},
	{#State 377
		DEFAULT => -128
	},
	{#State 378
		ACTIONS => {
			'error' => 553,
			";" => 552
		}
	},
	{#State 379
		DEFAULT => -332
	},
	{#State 380
		DEFAULT => -359
	},
	{#State 381
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -360
	},
	{#State 382
		DEFAULT => -358
	},
	{#State 383
		DEFAULT => -357
	},
	{#State 384
		DEFAULT => -333
	},
	{#State 385
		ACTIONS => {
			'error' => 554,
			'IDENTIFIER' => 555
		}
	},
	{#State 386
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 357
		},
		GOTOS => {
			'declarators' => 556,
			'declarator' => 355,
			'simple_declarator' => 356,
			'array_declarator' => 354,
			'complex_declarator' => 353
		}
	},
	{#State 387
		ACTIONS => {
			";" => 557
		}
	},
	{#State 388
		DEFAULT => -64
	},
	{#State 389
		DEFAULT => -71
	},
	{#State 390
		DEFAULT => -61
	},
	{#State 391
		DEFAULT => -68
	},
	{#State 392
		DEFAULT => -60
	},
	{#State 393
		DEFAULT => -67
	},
	{#State 394
		DEFAULT => -134
	},
	{#State 395
		DEFAULT => -133
	},
	{#State 396
		DEFAULT => -63
	},
	{#State 397
		DEFAULT => -70
	},
	{#State 398
		ACTIONS => {
			'error' => 563,
			")" => 559,
			'IN' => 558
		},
		GOTOS => {
			'init_param_decls' => 561,
			'init_param_attribute' => 560,
			'init_param_decl' => 562
		}
	},
	{#State 399
		DEFAULT => -132
	},
	{#State 400
		DEFAULT => -92
	},
	{#State 401
		DEFAULT => -59
	},
	{#State 402
		DEFAULT => -66
	},
	{#State 403
		DEFAULT => -91
	},
	{#State 404
		DEFAULT => -54
	},
	{#State 405
		ACTIONS => {
			'error' => 569,
			")" => 567,
			'OUT' => 568,
			'INOUT' => 565,
			'IN' => 564
		},
		GOTOS => {
			'param_dcl' => 571,
			'param_dcls' => 570,
			'param_attribute' => 566
		}
	},
	{#State 406
		DEFAULT => -326
	},
	{#State 407
		ACTIONS => {
			'CONTEXT' => 572,
			'RAISES' => 376
		},
		DEFAULT => -322,
		GOTOS => {
			'context_expr' => 574,
			'raises_expr' => 573
		}
	},
	{#State 408
		DEFAULT => -385
	},
	{#State 409
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'VALUEBASE' => 155,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'WCHAR' => 86,
			'error' => 576,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'wide_string_type' => 380,
			'integer_type' => 174,
			'boolean_type' => 173,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 381,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'signed_short_int' => 95,
			'string_type' => 382,
			'base_type_spec' => 383,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'unsigned_long_int' => 115,
			'param_type_spec' => 575,
			'unsigned_short_int' => 107,
			'signed_longlong_int' => 90
		}
	},
	{#State 410
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 189
		},
		GOTOS => {
			'attr_declarator' => 579,
			'simple_declarator' => 578,
			'simple_declarators' => 577
		}
	},
	{#State 411
		DEFAULT => -391
	},
	{#State 412
		DEFAULT => -62
	},
	{#State 413
		DEFAULT => -69
	},
	{#State 414
		DEFAULT => -58
	},
	{#State 415
		DEFAULT => -65
	},
	{#State 416
		ACTIONS => {
			'error' => 581,
			";" => 580
		}
	},
	{#State 417
		DEFAULT => -256
	},
	{#State 418
		DEFAULT => -257
	},
	{#State 419
		DEFAULT => -261
	},
	{#State 420
		DEFAULT => -185
	},
	{#State 421
		DEFAULT => -183
	},
	{#State 422
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 583,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'const_exp' => 582,
			'and_expr' => 442,
			'or_expr' => 425,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'wide_string_literal' => 421,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 423
		DEFAULT => -188
	},
	{#State 424
		DEFAULT => -195
	},
	{#State 425
		ACTIONS => {
			"|" => 584
		},
		DEFAULT => -155
	},
	{#State 426
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 426
		},
		DEFAULT => -191,
		GOTOS => {
			'wide_string_literal' => 585
		}
	},
	{#State 427
		DEFAULT => -193
	},
	{#State 428
		DEFAULT => -182
	},
	{#State 429
		DEFAULT => -187
	},
	{#State 430
		DEFAULT => -186
	},
	{#State 431
		DEFAULT => -174
	},
	{#State 432
		DEFAULT => -184
	},
	{#State 433
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -177
	},
	{#State 434
		ACTIONS => {
			">" => 586
		}
	},
	{#State 435
		ACTIONS => {
			">" => 587
		}
	},
	{#State 436
		ACTIONS => {
			"^" => 588
		},
		DEFAULT => -156
	},
	{#State 437
		ACTIONS => {
			"<<" => 589,
			">>" => 590
		},
		DEFAULT => -160
	},
	{#State 438
		DEFAULT => -194
	},
	{#State 439
		DEFAULT => -178
	},
	{#State 440
		ACTIONS => {
			"+" => 592,
			"-" => 591
		},
		DEFAULT => -162
	},
	{#State 441
		DEFAULT => -173
	},
	{#State 442
		ACTIONS => {
			"&" => 593
		},
		DEFAULT => -158
	},
	{#State 443
		DEFAULT => -181
	},
	{#State 444
		ACTIONS => {
			"%" => 594,
			"*" => 595,
			"/" => 596
		},
		DEFAULT => -165
	},
	{#State 445
		DEFAULT => -175
	},
	{#State 446
		DEFAULT => -168
	},
	{#State 447
		DEFAULT => -176
	},
	{#State 448
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			"::" => 94,
			'STRING_LITERAL' => 198,
			'FALSE' => 438,
			'CHARACTER_LITERAL' => 432,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			'TRUE' => 427,
			"(" => 422
		},
		GOTOS => {
			'scoped_name' => 433,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 597,
			'literal' => 439,
			'wide_string_literal' => 421
		}
	},
	{#State 449
		DEFAULT => -81
	},
	{#State 450
		DEFAULT => -80
	},
	{#State 451
		DEFAULT => -249
	},
	{#State 452
		ACTIONS => {
			">" => 598
		}
	},
	{#State 453
		ACTIONS => {
			">" => 599
		}
	},
	{#State 454
		DEFAULT => -142
	},
	{#State 455
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 601,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'const_exp' => 600,
			'and_expr' => 442,
			'or_expr' => 425,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'wide_string_literal' => 421,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 456
		DEFAULT => -50
	},
	{#State 457
		ACTIONS => {
			'error' => 603,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 370,
			'interface_name' => 372,
			'interface_names' => 602
		}
	},
	{#State 458
		DEFAULT => -43
	},
	{#State 459
		DEFAULT => -42
	},
	{#State 460
		ACTIONS => {
			'error' => 605,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 604
		}
	},
	{#State 461
		DEFAULT => -454
	},
	{#State 462
		DEFAULT => -101
	},
	{#State 463
		DEFAULT => -99
	},
	{#State 464
		DEFAULT => -98
	},
	{#State 465
		DEFAULT => -499
	},
	{#State 466
		DEFAULT => -498
	},
	{#State 467
		DEFAULT => -317
	},
	{#State 468
		DEFAULT => -318
	},
	{#State 469
		DEFAULT => -457
	},
	{#State 470
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -462
	},
	{#State 471
		DEFAULT => -463
	},
	{#State 472
		DEFAULT => -426
	},
	{#State 473
		DEFAULT => -432
	},
	{#State 474
		DEFAULT => -425
	},
	{#State 475
		DEFAULT => -431
	},
	{#State 476
		DEFAULT => -421
	},
	{#State 477
		DEFAULT => -422
	},
	{#State 478
		DEFAULT => -428
	},
	{#State 479
		ACTIONS => {
			'error' => 607,
			'OBJECT' => 492,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 490,
			'interface_type' => 606
		}
	},
	{#State 480
		DEFAULT => -442
	},
	{#State 481
		DEFAULT => -427
	},
	{#State 482
		DEFAULT => -433
	},
	{#State 483
		DEFAULT => -424
	},
	{#State 484
		DEFAULT => -430
	},
	{#State 485
		ACTIONS => {
			'error' => 608,
			'IDENTIFIER' => 609,
			"::" => 259
		}
	},
	{#State 486
		DEFAULT => -446
	},
	{#State 487
		DEFAULT => -408
	},
	{#State 488
		DEFAULT => -409
	},
	{#State 489
		ACTIONS => {
			'error' => 610,
			'IDENTIFIER' => 611
		}
	},
	{#State 490
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -437
	},
	{#State 491
		DEFAULT => -436
	},
	{#State 492
		DEFAULT => -438
	},
	{#State 493
		ACTIONS => {
			'error' => 612,
			'IDENTIFIER' => 613,
			"::" => 259
		}
	},
	{#State 494
		DEFAULT => -449
	},
	{#State 495
		DEFAULT => -423
	},
	{#State 496
		DEFAULT => -429
	},
	{#State 497
		ACTIONS => {
			'error' => 614,
			'IDENTIFIER' => 615,
			"::" => 259
		}
	},
	{#State 498
		DEFAULT => -452
	},
	{#State 499
		DEFAULT => -476
	},
	{#State 500
		DEFAULT => -491
	},
	{#State 501
		DEFAULT => -490
	},
	{#State 502
		DEFAULT => -470
	},
	{#State 503
		DEFAULT => -467
	},
	{#State 504
		DEFAULT => -473
	},
	{#State 505
		DEFAULT => -475
	},
	{#State 506
		DEFAULT => -472
	},
	{#State 507
		DEFAULT => -474
	},
	{#State 508
		DEFAULT => -483
	},
	{#State 509
		DEFAULT => -482
	},
	{#State 510
		DEFAULT => -468
	},
	{#State 511
		ACTIONS => {
			'error' => 618,
			")" => 616,
			'IN' => 558
		},
		GOTOS => {
			'init_param_decls' => 617,
			'init_param_attribute' => 560,
			'init_param_decl' => 562
		}
	},
	{#State 512
		DEFAULT => -489
	},
	{#State 513
		DEFAULT => -484
	},
	{#State 514
		ACTIONS => {
			'error' => 621,
			")" => 619,
			'IN' => 558
		},
		GOTOS => {
			'init_param_decls' => 620,
			'init_param_attribute' => 560,
			'init_param_decl' => 562
		}
	},
	{#State 515
		DEFAULT => -481
	},
	{#State 516
		DEFAULT => -33
	},
	{#State 517
		DEFAULT => -34
	},
	{#State 518
		ACTIONS => {
			">" => 622
		}
	},
	{#State 519
		ACTIONS => {
			">" => 624,
			"," => 623
		}
	},
	{#State 520
		ACTIONS => {
			"," => 625
		}
	},
	{#State 521
		ACTIONS => {
			">" => 626
		}
	},
	{#State 522
		DEFAULT => -296
	},
	{#State 523
		ACTIONS => {
			'IDENTIFIER' => 336
		},
		DEFAULT => -295,
		GOTOS => {
			'enumerators' => 627,
			'enumerator' => 333
		}
	},
	{#State 524
		DEFAULT => -288
	},
	{#State 525
		DEFAULT => -289
	},
	{#State 526
		DEFAULT => -272
	},
	{#State 527
		ACTIONS => {
			")" => 628
		}
	},
	{#State 528
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -275
	},
	{#State 529
		DEFAULT => -274
	},
	{#State 530
		ACTIONS => {
			")" => 629
		}
	},
	{#State 531
		DEFAULT => -273
	},
	{#State 532
		DEFAULT => -271
	},
	{#State 533
		ACTIONS => {
			'LONG' => 263
		},
		DEFAULT => -242
	},
	{#State 534
		DEFAULT => -410
	},
	{#State 535
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -417
	},
	{#State 536
		DEFAULT => -418
	},
	{#State 537
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 357
		},
		GOTOS => {
			'declarators' => 630,
			'declarator' => 355,
			'simple_declarator' => 356,
			'array_declarator' => 354,
			'complex_declarator' => 353
		}
	},
	{#State 538
		ACTIONS => {
			"[" => 540
		},
		DEFAULT => -310,
		GOTOS => {
			'fixed_array_sizes' => 631,
			'fixed_array_size' => 538
		}
	},
	{#State 539
		DEFAULT => -309
	},
	{#State 540
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 633,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'primary_expr' => 441,
			'and_expr' => 442,
			'scoped_name' => 433,
			'positive_int_const' => 632,
			'wide_string_literal' => 421,
			'boolean_literal' => 423,
			'mult_expr' => 444,
			'const_exp' => 424,
			'or_expr' => 425,
			'unary_expr' => 446,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 541
		DEFAULT => -505
	},
	{#State 542
		DEFAULT => -504
	},
	{#State 543
		DEFAULT => -509
	},
	{#State 544
		DEFAULT => -105
	},
	{#State 545
		ACTIONS => {
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 370,
			'interface_name' => 372,
			'interface_names' => 634
		}
	},
	{#State 546
		ACTIONS => {
			"," => 635
		},
		DEFAULT => -115
	},
	{#State 547
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -117
	},
	{#State 548
		DEFAULT => -111
	},
	{#State 549
		ACTIONS => {
			'SUPPORTS' => 220
		},
		DEFAULT => -109,
		GOTOS => {
			'supported_interface_spec' => 636
		}
	},
	{#State 550
		ACTIONS => {
			'error' => 639,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 638,
			'exception_names' => 637,
			'exception_name' => 640
		}
	},
	{#State 551
		DEFAULT => -348
	},
	{#State 552
		DEFAULT => -125
	},
	{#State 553
		DEFAULT => -126
	},
	{#State 554
		DEFAULT => -328
	},
	{#State 555
		DEFAULT => -327
	},
	{#State 556
		ACTIONS => {
			";" => 641
		}
	},
	{#State 557
		DEFAULT => -122
	},
	{#State 558
		DEFAULT => -139
	},
	{#State 559
		DEFAULT => -129
	},
	{#State 560
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'VALUEBASE' => 155,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'WCHAR' => 86,
			'error' => 643,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'wide_string_type' => 380,
			'integer_type' => 174,
			'boolean_type' => 173,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 381,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'signed_short_int' => 95,
			'string_type' => 382,
			'base_type_spec' => 383,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'unsigned_long_int' => 115,
			'param_type_spec' => 642,
			'unsigned_short_int' => 107,
			'signed_longlong_int' => 90
		}
	},
	{#State 561
		ACTIONS => {
			")" => 644
		}
	},
	{#State 562
		ACTIONS => {
			"," => 645
		},
		DEFAULT => -135
	},
	{#State 563
		ACTIONS => {
			")" => 646
		}
	},
	{#State 564
		DEFAULT => -343
	},
	{#State 565
		DEFAULT => -345
	},
	{#State 566
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'VALUEBASE' => 155,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'WCHAR' => 86,
			'error' => 648,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'wide_string_type' => 380,
			'integer_type' => 174,
			'boolean_type' => 173,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 381,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'signed_short_int' => 95,
			'string_type' => 382,
			'base_type_spec' => 383,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'unsigned_long_int' => 115,
			'param_type_spec' => 647,
			'unsigned_short_int' => 107,
			'signed_longlong_int' => 90
		}
	},
	{#State 567
		DEFAULT => -335
	},
	{#State 568
		DEFAULT => -344
	},
	{#State 569
		ACTIONS => {
			")" => 649
		}
	},
	{#State 570
		ACTIONS => {
			")" => 650
		}
	},
	{#State 571
		ACTIONS => {
			";" => 651,
			"," => 652
		},
		DEFAULT => -337
	},
	{#State 572
		ACTIONS => {
			'error' => 654,
			"(" => 653
		}
	},
	{#State 573
		ACTIONS => {
			'CONTEXT' => 572
		},
		DEFAULT => -323,
		GOTOS => {
			'context_expr' => 655
		}
	},
	{#State 574
		DEFAULT => -325
	},
	{#State 575
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 189
		},
		GOTOS => {
			'simple_declarator' => 658,
			'simple_declarators' => 657,
			'readonly_attr_declarator' => 656
		}
	},
	{#State 576
		DEFAULT => -384
	},
	{#State 577
		DEFAULT => -393
	},
	{#State 578
		ACTIONS => {
			'GETRAISES' => 663,
			'SETRAISES' => 662,
			"," => 660
		},
		DEFAULT => -388,
		GOTOS => {
			'set_except_expr' => 664,
			'get_except_expr' => 659,
			'attr_raises_expr' => 661
		}
	},
	{#State 579
		DEFAULT => -390
	},
	{#State 580
		DEFAULT => -262
	},
	{#State 581
		DEFAULT => -263
	},
	{#State 582
		ACTIONS => {
			")" => 665
		}
	},
	{#State 583
		ACTIONS => {
			")" => 666
		}
	},
	{#State 584
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'and_expr' => 442,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'xor_expr' => 667,
			'shift_expr' => 437,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 585
		DEFAULT => -192
	},
	{#State 586
		DEFAULT => -306
	},
	{#State 587
		DEFAULT => -308
	},
	{#State 588
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'and_expr' => 668,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'shift_expr' => 437,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 589
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 669
		}
	},
	{#State 590
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 670
		}
	},
	{#State 591
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 671,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448
		}
	},
	{#State 592
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 672,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448
		}
	},
	{#State 593
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'shift_expr' => 673,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 594
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'unary_expr' => 674,
			'scoped_name' => 433,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448
		}
	},
	{#State 595
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'unary_expr' => 675,
			'scoped_name' => 433,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448
		}
	},
	{#State 596
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'CHARACTER_LITERAL' => 432,
			"+" => 445,
			'FIXED_PT_LITERAL' => 430,
			'WIDE_CHARACTER_LITERAL' => 420,
			"-" => 431,
			"::" => 94,
			'FALSE' => 438,
			'WIDE_STRING_LITERAL' => 426,
			'INTEGER_LITERAL' => 443,
			"~" => 447,
			"(" => 422,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'unary_expr' => 676,
			'scoped_name' => 433,
			'wide_string_literal' => 421,
			'literal' => 439,
			'unary_operator' => 448
		}
	},
	{#State 597
		DEFAULT => -172
	},
	{#State 598
		DEFAULT => -303
	},
	{#State 599
		DEFAULT => -305
	},
	{#State 600
		DEFAULT => -140
	},
	{#State 601
		DEFAULT => -141
	},
	{#State 602
		DEFAULT => -72
	},
	{#State 603
		DEFAULT => -73
	},
	{#State 604
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -464
	},
	{#State 605
		DEFAULT => -465
	},
	{#State 606
		ACTIONS => {
			'error' => 677,
			'IDENTIFIER' => 678
		}
	},
	{#State 607
		DEFAULT => -441
	},
	{#State 608
		DEFAULT => -445
	},
	{#State 609
		DEFAULT => -444
	},
	{#State 610
		DEFAULT => -435
	},
	{#State 611
		DEFAULT => -434
	},
	{#State 612
		DEFAULT => -448
	},
	{#State 613
		DEFAULT => -447
	},
	{#State 614
		DEFAULT => -451
	},
	{#State 615
		DEFAULT => -450
	},
	{#State 616
		DEFAULT => -486
	},
	{#State 617
		ACTIONS => {
			")" => 679
		}
	},
	{#State 618
		ACTIONS => {
			")" => 680
		}
	},
	{#State 619
		DEFAULT => -478
	},
	{#State 620
		ACTIONS => {
			")" => 681
		}
	},
	{#State 621
		ACTIONS => {
			")" => 682
		}
	},
	{#State 622
		DEFAULT => -301
	},
	{#State 623
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 684,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'primary_expr' => 441,
			'and_expr' => 442,
			'scoped_name' => 433,
			'positive_int_const' => 683,
			'wide_string_literal' => 421,
			'boolean_literal' => 423,
			'mult_expr' => 444,
			'const_exp' => 424,
			'or_expr' => 425,
			'unary_expr' => 446,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 624
		DEFAULT => -300
	},
	{#State 625
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 686,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'string_literal' => 428,
			'primary_expr' => 441,
			'and_expr' => 442,
			'scoped_name' => 433,
			'positive_int_const' => 685,
			'wide_string_literal' => 421,
			'boolean_literal' => 423,
			'mult_expr' => 444,
			'const_exp' => 424,
			'or_expr' => 425,
			'unary_expr' => 446,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 626
		DEFAULT => -363
	},
	{#State 627
		DEFAULT => -294
	},
	{#State 628
		ACTIONS => {
			'error' => 688,
			"{" => 687
		}
	},
	{#State 629
		DEFAULT => -267
	},
	{#State 630
		DEFAULT => -226
	},
	{#State 631
		DEFAULT => -311
	},
	{#State 632
		ACTIONS => {
			"]" => 689
		}
	},
	{#State 633
		ACTIONS => {
			"]" => 690
		}
	},
	{#State 634
		DEFAULT => -75
	},
	{#State 635
		ACTIONS => {
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 547,
			'value_name' => 546,
			'value_names' => 691
		}
	},
	{#State 636
		DEFAULT => -110
	},
	{#State 637
		ACTIONS => {
			")" => 692
		}
	},
	{#State 638
		ACTIONS => {
			"::" => 259
		},
		DEFAULT => -351
	},
	{#State 639
		ACTIONS => {
			")" => 693
		}
	},
	{#State 640
		ACTIONS => {
			"," => 694
		},
		DEFAULT => -349
	},
	{#State 641
		DEFAULT => -121
	},
	{#State 642
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 189
		},
		GOTOS => {
			'simple_declarator' => 695
		}
	},
	{#State 643
		DEFAULT => -138
	},
	{#State 644
		DEFAULT => -130
	},
	{#State 645
		ACTIONS => {
			'IN' => 558
		},
		GOTOS => {
			'init_param_decls' => 696,
			'init_param_attribute' => 560,
			'init_param_decl' => 562
		}
	},
	{#State 646
		DEFAULT => -131
	},
	{#State 647
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 189
		},
		GOTOS => {
			'simple_declarator' => 697
		}
	},
	{#State 648
		DEFAULT => -342
	},
	{#State 649
		DEFAULT => -336
	},
	{#State 650
		DEFAULT => -334
	},
	{#State 651
		DEFAULT => -340
	},
	{#State 652
		ACTIONS => {
			'OUT' => 568,
			'INOUT' => 565,
			'IN' => 564
		},
		DEFAULT => -339,
		GOTOS => {
			'param_dcl' => 571,
			'param_dcls' => 698,
			'param_attribute' => 566
		}
	},
	{#State 653
		ACTIONS => {
			'error' => 701,
			'STRING_LITERAL' => 198
		},
		GOTOS => {
			'string_literal' => 699,
			'string_literals' => 700
		}
	},
	{#State 654
		DEFAULT => -354
	},
	{#State 655
		DEFAULT => -324
	},
	{#State 656
		DEFAULT => -383
	},
	{#State 657
		DEFAULT => -387
	},
	{#State 658
		ACTIONS => {
			'RAISES' => 376,
			"," => 660
		},
		DEFAULT => -388,
		GOTOS => {
			'raises_expr' => 702
		}
	},
	{#State 659
		ACTIONS => {
			'SETRAISES' => 662
		},
		DEFAULT => -395,
		GOTOS => {
			'set_except_expr' => 703
		}
	},
	{#State 660
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 189
		},
		GOTOS => {
			'simple_declarators' => 705,
			'simple_declarator' => 704
		}
	},
	{#State 661
		DEFAULT => -392
	},
	{#State 662
		ACTIONS => {
			'error' => 707,
			"(" => 706
		},
		GOTOS => {
			'exception_list' => 708
		}
	},
	{#State 663
		ACTIONS => {
			'error' => 709,
			"(" => 706
		},
		GOTOS => {
			'exception_list' => 710
		}
	},
	{#State 664
		DEFAULT => -396
	},
	{#State 665
		DEFAULT => -179
	},
	{#State 666
		DEFAULT => -180
	},
	{#State 667
		ACTIONS => {
			"^" => 588
		},
		DEFAULT => -157
	},
	{#State 668
		ACTIONS => {
			"&" => 593
		},
		DEFAULT => -159
	},
	{#State 669
		ACTIONS => {
			"+" => 592,
			"-" => 591
		},
		DEFAULT => -164
	},
	{#State 670
		ACTIONS => {
			"+" => 592,
			"-" => 591
		},
		DEFAULT => -163
	},
	{#State 671
		ACTIONS => {
			"%" => 594,
			"*" => 595,
			"/" => 596
		},
		DEFAULT => -167
	},
	{#State 672
		ACTIONS => {
			"%" => 594,
			"*" => 595,
			"/" => 596
		},
		DEFAULT => -166
	},
	{#State 673
		ACTIONS => {
			"<<" => 589,
			">>" => 590
		},
		DEFAULT => -161
	},
	{#State 674
		DEFAULT => -171
	},
	{#State 675
		DEFAULT => -169
	},
	{#State 676
		DEFAULT => -170
	},
	{#State 677
		DEFAULT => -440
	},
	{#State 678
		DEFAULT => -439
	},
	{#State 679
		DEFAULT => -487
	},
	{#State 680
		DEFAULT => -488
	},
	{#State 681
		DEFAULT => -479
	},
	{#State 682
		DEFAULT => -480
	},
	{#State 683
		ACTIONS => {
			">" => 711
		}
	},
	{#State 684
		ACTIONS => {
			">" => 712
		}
	},
	{#State 685
		ACTIONS => {
			">" => 713
		}
	},
	{#State 686
		ACTIONS => {
			">" => 714
		}
	},
	{#State 687
		ACTIONS => {
			'error' => 720,
			'CASE' => 718,
			'DEFAULT' => 719
		},
		GOTOS => {
			'case_labels' => 716,
			'switch_body' => 721,
			'case' => 715,
			'case_label' => 717
		}
	},
	{#State 688
		DEFAULT => -266
	},
	{#State 689
		DEFAULT => -312
	},
	{#State 690
		DEFAULT => -313
	},
	{#State 691
		DEFAULT => -116
	},
	{#State 692
		DEFAULT => -346
	},
	{#State 693
		DEFAULT => -347
	},
	{#State 694
		ACTIONS => {
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 638,
			'exception_names' => 722,
			'exception_name' => 640
		}
	},
	{#State 695
		DEFAULT => -137
	},
	{#State 696
		DEFAULT => -136
	},
	{#State 697
		DEFAULT => -341
	},
	{#State 698
		DEFAULT => -338
	},
	{#State 699
		ACTIONS => {
			"," => 723
		},
		DEFAULT => -355
	},
	{#State 700
		ACTIONS => {
			")" => 724
		}
	},
	{#State 701
		ACTIONS => {
			")" => 725
		}
	},
	{#State 702
		DEFAULT => -386
	},
	{#State 703
		DEFAULT => -394
	},
	{#State 704
		ACTIONS => {
			"," => 660
		},
		DEFAULT => -388
	},
	{#State 705
		DEFAULT => -389
	},
	{#State 706
		ACTIONS => {
			'error' => 727,
			'IDENTIFIER' => 114,
			"::" => 94
		},
		GOTOS => {
			'scoped_name' => 638,
			'exception_names' => 726,
			'exception_name' => 640
		}
	},
	{#State 707
		DEFAULT => -400
	},
	{#State 708
		DEFAULT => -399
	},
	{#State 709
		DEFAULT => -398
	},
	{#State 710
		DEFAULT => -397
	},
	{#State 711
		DEFAULT => -298
	},
	{#State 712
		DEFAULT => -299
	},
	{#State 713
		DEFAULT => -361
	},
	{#State 714
		DEFAULT => -362
	},
	{#State 715
		ACTIONS => {
			'CASE' => 718,
			'DEFAULT' => 719
		},
		DEFAULT => -276,
		GOTOS => {
			'case_labels' => 716,
			'switch_body' => 728,
			'case' => 715,
			'case_label' => 717
		}
	},
	{#State 716
		ACTIONS => {
			'CHAR' => 91,
			'OBJECT' => 172,
			'FIXED' => 163,
			'VALUEBASE' => 155,
			'SEQUENCE' => 150,
			'STRUCT' => 157,
			'DOUBLE' => 110,
			'LONG' => 111,
			'STRING' => 112,
			"::" => 94,
			'WSTRING' => 96,
			'UNSIGNED' => 103,
			'SHORT' => 105,
			'BOOLEAN' => 97,
			'IDENTIFIER' => 114,
			'UNION' => 160,
			'WCHAR' => 86,
			'FLOAT' => 89,
			'OCTET' => 88,
			'ENUM' => 16,
			'ANY' => 171
		},
		GOTOS => {
			'unsigned_int' => 82,
			'floating_pt_type' => 149,
			'signed_int' => 99,
			'value_base_type' => 164,
			'char_type' => 151,
			'object_type' => 165,
			'scoped_name' => 166,
			'octet_type' => 152,
			'wide_char_type' => 167,
			'signed_long_int' => 102,
			'type_spec' => 729,
			'string_type' => 168,
			'struct_header' => 10,
			'element_spec' => 730,
			'base_type_spec' => 169,
			'unsigned_longlong_int' => 87,
			'any_type' => 154,
			'enum_type' => 170,
			'enum_header' => 48,
			'unsigned_short_int' => 107,
			'union_header' => 50,
			'signed_longlong_int' => 90,
			'wide_string_type' => 156,
			'boolean_type' => 173,
			'integer_type' => 174,
			'signed_short_int' => 95,
			'struct_type' => 158,
			'union_type' => 159,
			'sequence_type' => 175,
			'unsigned_long_int' => 115,
			'template_type_spec' => 161,
			'constr_type_spec' => 162,
			'simple_type_spec' => 176,
			'fixed_pt_type' => 177
		}
	},
	{#State 717
		ACTIONS => {
			'CASE' => 718,
			'DEFAULT' => 719
		},
		DEFAULT => -280,
		GOTOS => {
			'case_labels' => 731,
			'case_label' => 717
		}
	},
	{#State 718
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 429,
			'CHARACTER_LITERAL' => 432,
			'WIDE_CHARACTER_LITERAL' => 420,
			"::" => 94,
			'INTEGER_LITERAL' => 443,
			"(" => 422,
			'IDENTIFIER' => 114,
			'STRING_LITERAL' => 198,
			'FIXED_PT_LITERAL' => 430,
			"+" => 445,
			'error' => 733,
			"-" => 431,
			'WIDE_STRING_LITERAL' => 426,
			'FALSE' => 438,
			"~" => 447,
			'TRUE' => 427
		},
		GOTOS => {
			'mult_expr' => 444,
			'string_literal' => 428,
			'boolean_literal' => 423,
			'primary_expr' => 441,
			'const_exp' => 732,
			'and_expr' => 442,
			'or_expr' => 425,
			'unary_expr' => 446,
			'scoped_name' => 433,
			'xor_expr' => 436,
			'shift_expr' => 437,
			'literal' => 439,
			'wide_string_literal' => 421,
			'unary_operator' => 448,
			'add_expr' => 440
		}
	},
	{#State 719
		ACTIONS => {
			'error' => 734,
			":" => 735
		}
	},
	{#State 720
		ACTIONS => {
			"}" => 736
		}
	},
	{#State 721
		ACTIONS => {
			"}" => 737
		}
	},
	{#State 722
		DEFAULT => -350
	},
	{#State 723
		ACTIONS => {
			'STRING_LITERAL' => 198
		},
		GOTOS => {
			'string_literal' => 699,
			'string_literals' => 738
		}
	},
	{#State 724
		DEFAULT => -352
	},
	{#State 725
		DEFAULT => -353
	},
	{#State 726
		ACTIONS => {
			")" => 739
		}
	},
	{#State 727
		ACTIONS => {
			")" => 740
		}
	},
	{#State 728
		DEFAULT => -277
	},
	{#State 729
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 357
		},
		GOTOS => {
			'declarator' => 741,
			'simple_declarator' => 356,
			'array_declarator' => 354,
			'complex_declarator' => 353
		}
	},
	{#State 730
		ACTIONS => {
			'error' => 743,
			";" => 742
		}
	},
	{#State 731
		DEFAULT => -281
	},
	{#State 732
		ACTIONS => {
			'error' => 744,
			":" => 745
		}
	},
	{#State 733
		DEFAULT => -284
	},
	{#State 734
		DEFAULT => -286
	},
	{#State 735
		DEFAULT => -285
	},
	{#State 736
		DEFAULT => -265
	},
	{#State 737
		DEFAULT => -264
	},
	{#State 738
		DEFAULT => -356
	},
	{#State 739
		DEFAULT => -401
	},
	{#State 740
		DEFAULT => -402
	},
	{#State 741
		DEFAULT => -287
	},
	{#State 742
		DEFAULT => -278
	},
	{#State 743
		DEFAULT => -279
	},
	{#State 744
		DEFAULT => -283
	},
	{#State 745
		DEFAULT => -282
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'specification', 2,
sub
#line 86 "parser30.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_import'		=>	$_[1],
					'list_decl'			=>	$_[2],
			);
		}
	],
	[#Rule 2
		 'specification', 1,
sub
#line 93 "parser30.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 3
		 'specification', 0,
sub
#line 99 "parser30.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 4
		 'specification', 1,
sub
#line 103 "parser30.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 5
		 'imports', 1,
sub
#line 110 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 6
		 'imports', 2,
sub
#line 114 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 7
		 'definitions', 1,
sub
#line 122 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 8
		 'definitions', 2,
sub
#line 126 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 9
		 'definitions', 3,
sub
#line 131 "parser30.yp"
{
			$_[0]->Error("import after definition.\n");
			unshift(@{$_[3]},$_[1]->getRef());
			$_[3];
		}
	],
	[#Rule 10
		 'definition', 2, undef
	],
	[#Rule 11
		 'definition', 2, undef
	],
	[#Rule 12
		 'definition', 2, undef
	],
	[#Rule 13
		 'definition', 2, undef
	],
	[#Rule 14
		 'definition', 2, undef
	],
	[#Rule 15
		 'definition', 2, undef
	],
	[#Rule 16
		 'definition', 2, undef
	],
	[#Rule 17
		 'definition', 2, undef
	],
	[#Rule 18
		 'definition', 2, undef
	],
	[#Rule 19
		 'definition', 2, undef
	],
	[#Rule 20
		 'definition', 2, undef
	],
	[#Rule 21
		 'definition', 2,
sub
#line 163 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 22
		 'definition', 2,
sub
#line 169 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 23
		 'definition', 2,
sub
#line 175 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 24
		 'definition', 2,
sub
#line 181 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 25
		 'definition', 2,
sub
#line 187 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 26
		 'definition', 2,
sub
#line 193 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 27
		 'definition', 2,
sub
#line 199 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 28
		 'definition', 2,
sub
#line 205 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 29
		 'definition', 2,
sub
#line 211 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 30
		 'definition', 2,
sub
#line 217 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 31
		 'definition', 2,
sub
#line 223 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 32
		 'definition', 3,
sub
#line 229 "parser30.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 33
		 'module', 4,
sub
#line 242 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 34
		 'module', 4,
sub
#line 249 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 35
		 'module', 3,
sub
#line 255 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 36
		 'module', 3,
sub
#line 261 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 37
		 'module_header', 2,
sub
#line 270 "parser30.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 38
		 'module_header', 2,
sub
#line 276 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 39
		 'interface', 1, undef
	],
	[#Rule 40
		 'interface', 1, undef
	],
	[#Rule 41
		 'interface_dcl', 3,
sub
#line 293 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 42
		 'interface_dcl', 4,
sub
#line 301 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 43
		 'interface_dcl', 4,
sub
#line 309 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 44
		 'forward_dcl', 3,
sub
#line 320 "parser30.yp"
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
	[#Rule 45
		 'forward_dcl', 3,
sub
#line 336 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 46
		 'interface_mod', 1, undef
	],
	[#Rule 47
		 'interface_mod', 1, undef
	],
	[#Rule 48
		 'interface_mod', 0, undef
	],
	[#Rule 49
		 'interface_header', 3,
sub
#line 354 "parser30.yp"
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
	[#Rule 50
		 'interface_header', 4,
sub
#line 370 "parser30.yp"
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
	[#Rule 51
		 'interface_header', 3,
sub
#line 392 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 52
		 'interface_body', 1, undef
	],
	[#Rule 53
		 'exports', 1,
sub
#line 406 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 54
		 'exports', 2,
sub
#line 410 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 55
		 '_export', 1, undef
	],
	[#Rule 56
		 '_export', 1,
sub
#line 421 "parser30.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 57
		 '_export', 1,
sub
#line 426 "parser30.yp"
{
			$_[0]->Error("initializer unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 58
		 'export', 2, undef
	],
	[#Rule 59
		 'export', 2, undef
	],
	[#Rule 60
		 'export', 2, undef
	],
	[#Rule 61
		 'export', 2, undef
	],
	[#Rule 62
		 'export', 2, undef
	],
	[#Rule 63
		 'export', 2, undef
	],
	[#Rule 64
		 'export', 2, undef
	],
	[#Rule 65
		 'export', 2,
sub
#line 448 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 66
		 'export', 2,
sub
#line 454 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 67
		 'export', 2,
sub
#line 460 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 68
		 'export', 2,
sub
#line 466 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 69
		 'export', 2,
sub
#line 472 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 70
		 'export', 2,
sub
#line 478 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 71
		 'export', 2,
sub
#line 484 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 72
		 'interface_inheritance_spec', 2,
sub
#line 494 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 73
		 'interface_inheritance_spec', 2,
sub
#line 498 "parser30.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 74
		 'interface_names', 1,
sub
#line 506 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 75
		 'interface_names', 3,
sub
#line 510 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 76
		 'interface_name', 1,
sub
#line 519 "parser30.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 77
		 'scoped_name', 1, undef
	],
	[#Rule 78
		 'scoped_name', 2,
sub
#line 529 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 79
		 'scoped_name', 2,
sub
#line 533 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 80
		 'scoped_name', 3,
sub
#line 539 "parser30.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 81
		 'scoped_name', 3,
sub
#line 543 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 82
		 'value', 1, undef
	],
	[#Rule 83
		 'value', 1, undef
	],
	[#Rule 84
		 'value', 1, undef
	],
	[#Rule 85
		 'value', 1, undef
	],
	[#Rule 86
		 'value_forward_dcl', 2,
sub
#line 565 "parser30.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 87
		 'value_forward_dcl', 3,
sub
#line 571 "parser30.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 88
		 'value_box_dcl', 2,
sub
#line 581 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 89
		 'value_box_header', 2,
sub
#line 592 "parser30.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 90
		 'value_abs_dcl', 3,
sub
#line 602 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 91
		 'value_abs_dcl', 4,
sub
#line 610 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 92
		 'value_abs_dcl', 4,
sub
#line 618 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 93
		 'value_abs_header', 3,
sub
#line 628 "parser30.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 94
		 'value_abs_header', 4,
sub
#line 634 "parser30.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 95
		 'value_abs_header', 3,
sub
#line 641 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 96
		 'value_abs_header', 2,
sub
#line 646 "parser30.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 97
		 'value_dcl', 3,
sub
#line 655 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 98
		 'value_dcl', 4,
sub
#line 663 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 99
		 'value_dcl', 4,
sub
#line 671 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 100
		 'value_elements', 1,
sub
#line 681 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 101
		 'value_elements', 2,
sub
#line 685 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 102
		 'value_header', 2,
sub
#line 694 "parser30.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 103
		 'value_header', 3,
sub
#line 700 "parser30.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 104
		 'value_header', 3,
sub
#line 707 "parser30.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 105
		 'value_header', 4,
sub
#line 714 "parser30.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 106
		 'value_header', 2,
sub
#line 722 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 107
		 'value_header', 3,
sub
#line 727 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 108
		 'value_header', 2,
sub
#line 732 "parser30.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 109
		 'value_inheritance_spec', 3,
sub
#line 741 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3]
			);
		}
	],
	[#Rule 110
		 'value_inheritance_spec', 4,
sub
#line 748 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 111
		 'value_inheritance_spec', 3,
sub
#line 756 "parser30.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'value_inheritance_spec', 1,
sub
#line 761 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 113
		 'inheritance_mod', 1, undef
	],
	[#Rule 114
		 'inheritance_mod', 0, undef
	],
	[#Rule 115
		 'value_names', 1,
sub
#line 777 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 116
		 'value_names', 3,
sub
#line 781 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 117
		 'value_name', 1,
sub
#line 790 "parser30.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 118
		 'value_element', 1, undef
	],
	[#Rule 119
		 'value_element', 1, undef
	],
	[#Rule 120
		 'value_element', 1, undef
	],
	[#Rule 121
		 'state_member', 4,
sub
#line 808 "parser30.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 122
		 'state_member', 3,
sub
#line 816 "parser30.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 123
		 'state_mod', 1, undef
	],
	[#Rule 124
		 'state_mod', 1, undef
	],
	[#Rule 125
		 'init_dcl', 3,
sub
#line 832 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 126
		 'init_dcl', 3,
sub
#line 838 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 127
		 'init_dcl', 2, undef
	],
	[#Rule 128
		 'init_dcl', 2,
sub
#line 848 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 129
		 'init_header_param', 3,
sub
#line 857 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 130
		 'init_header_param', 4,
sub
#line 863 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 131
		 'init_header_param', 4,
sub
#line 871 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 132
		 'init_header_param', 2,
sub
#line 878 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 133
		 'init_header', 2,
sub
#line 888 "parser30.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 134
		 'init_header', 2,
sub
#line 894 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 135
		 'init_param_decls', 1,
sub
#line 903 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 136
		 'init_param_decls', 3,
sub
#line 907 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 137
		 'init_param_decl', 3,
sub
#line 916 "parser30.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 138
		 'init_param_decl', 2,
sub
#line 924 "parser30.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 139
		 'init_param_attribute', 1, undef
	],
	[#Rule 140
		 'const_dcl', 5,
sub
#line 939 "parser30.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 141
		 'const_dcl', 5,
sub
#line 947 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 142
		 'const_dcl', 4,
sub
#line 952 "parser30.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 143
		 'const_dcl', 3,
sub
#line 957 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 144
		 'const_dcl', 2,
sub
#line 962 "parser30.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 145
		 'const_type', 1, undef
	],
	[#Rule 146
		 'const_type', 1, undef
	],
	[#Rule 147
		 'const_type', 1, undef
	],
	[#Rule 148
		 'const_type', 1, undef
	],
	[#Rule 149
		 'const_type', 1, undef
	],
	[#Rule 150
		 'const_type', 1, undef
	],
	[#Rule 151
		 'const_type', 1, undef
	],
	[#Rule 152
		 'const_type', 1, undef
	],
	[#Rule 153
		 'const_type', 1,
sub
#line 987 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 154
		 'const_type', 1, undef
	],
	[#Rule 155
		 'const_exp', 1, undef
	],
	[#Rule 156
		 'or_expr', 1, undef
	],
	[#Rule 157
		 'or_expr', 3,
sub
#line 1005 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 158
		 'xor_expr', 1, undef
	],
	[#Rule 159
		 'xor_expr', 3,
sub
#line 1015 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 160
		 'and_expr', 1, undef
	],
	[#Rule 161
		 'and_expr', 3,
sub
#line 1025 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 162
		 'shift_expr', 1, undef
	],
	[#Rule 163
		 'shift_expr', 3,
sub
#line 1035 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 164
		 'shift_expr', 3,
sub
#line 1039 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 165
		 'add_expr', 1, undef
	],
	[#Rule 166
		 'add_expr', 3,
sub
#line 1049 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 167
		 'add_expr', 3,
sub
#line 1053 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 168
		 'mult_expr', 1, undef
	],
	[#Rule 169
		 'mult_expr', 3,
sub
#line 1063 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 170
		 'mult_expr', 3,
sub
#line 1067 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 171
		 'mult_expr', 3,
sub
#line 1071 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 172
		 'unary_expr', 2,
sub
#line 1079 "parser30.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 173
		 'unary_expr', 1, undef
	],
	[#Rule 174
		 'unary_operator', 1, undef
	],
	[#Rule 175
		 'unary_operator', 1, undef
	],
	[#Rule 176
		 'unary_operator', 1, undef
	],
	[#Rule 177
		 'primary_expr', 1,
sub
#line 1099 "parser30.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 178
		 'primary_expr', 1,
sub
#line 1105 "parser30.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 179
		 'primary_expr', 3,
sub
#line 1109 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 180
		 'primary_expr', 3,
sub
#line 1113 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 181
		 'literal', 1,
sub
#line 1122 "parser30.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 182
		 'literal', 1,
sub
#line 1129 "parser30.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 183
		 'literal', 1,
sub
#line 1135 "parser30.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 184
		 'literal', 1,
sub
#line 1141 "parser30.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 185
		 'literal', 1,
sub
#line 1147 "parser30.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 186
		 'literal', 1,
sub
#line 1153 "parser30.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 187
		 'literal', 1,
sub
#line 1160 "parser30.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 188
		 'literal', 1, undef
	],
	[#Rule 189
		 'string_literal', 1, undef
	],
	[#Rule 190
		 'string_literal', 2,
sub
#line 1174 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 191
		 'wide_string_literal', 1, undef
	],
	[#Rule 192
		 'wide_string_literal', 2,
sub
#line 1183 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 193
		 'boolean_literal', 1,
sub
#line 1191 "parser30.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 194
		 'boolean_literal', 1,
sub
#line 1197 "parser30.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 195
		 'positive_int_const', 1,
sub
#line 1207 "parser30.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 196
		 'type_dcl', 2,
sub
#line 1217 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 197
		 'type_dcl', 1, undef
	],
	[#Rule 198
		 'type_dcl', 1, undef
	],
	[#Rule 199
		 'type_dcl', 1, undef
	],
	[#Rule 200
		 'type_dcl', 2,
sub
#line 1227 "parser30.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 201
		 'type_dcl', 1, undef
	],
	[#Rule 202
		 'type_dcl', 2,
sub
#line 1236 "parser30.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 203
		 'type_declarator', 2,
sub
#line 1245 "parser30.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 204
		 'type_spec', 1, undef
	],
	[#Rule 205
		 'type_spec', 1, undef
	],
	[#Rule 206
		 'simple_type_spec', 1, undef
	],
	[#Rule 207
		 'simple_type_spec', 1, undef
	],
	[#Rule 208
		 'simple_type_spec', 1,
sub
#line 1268 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 209
		 'base_type_spec', 1, undef
	],
	[#Rule 210
		 'base_type_spec', 1, undef
	],
	[#Rule 211
		 'base_type_spec', 1, undef
	],
	[#Rule 212
		 'base_type_spec', 1, undef
	],
	[#Rule 213
		 'base_type_spec', 1, undef
	],
	[#Rule 214
		 'base_type_spec', 1, undef
	],
	[#Rule 215
		 'base_type_spec', 1, undef
	],
	[#Rule 216
		 'base_type_spec', 1, undef
	],
	[#Rule 217
		 'base_type_spec', 1, undef
	],
	[#Rule 218
		 'template_type_spec', 1, undef
	],
	[#Rule 219
		 'template_type_spec', 1, undef
	],
	[#Rule 220
		 'template_type_spec', 1, undef
	],
	[#Rule 221
		 'template_type_spec', 1, undef
	],
	[#Rule 222
		 'constr_type_spec', 1, undef
	],
	[#Rule 223
		 'constr_type_spec', 1, undef
	],
	[#Rule 224
		 'constr_type_spec', 1, undef
	],
	[#Rule 225
		 'declarators', 1,
sub
#line 1320 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 226
		 'declarators', 3,
sub
#line 1324 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 227
		 'declarator', 1,
sub
#line 1333 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 228
		 'declarator', 1, undef
	],
	[#Rule 229
		 'simple_declarator', 1, undef
	],
	[#Rule 230
		 'simple_declarator', 2,
sub
#line 1345 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 231
		 'simple_declarator', 2,
sub
#line 1350 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 232
		 'complex_declarator', 1, undef
	],
	[#Rule 233
		 'floating_pt_type', 1,
sub
#line 1365 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 234
		 'floating_pt_type', 1,
sub
#line 1371 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 235
		 'floating_pt_type', 2,
sub
#line 1377 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 236
		 'integer_type', 1, undef
	],
	[#Rule 237
		 'integer_type', 1, undef
	],
	[#Rule 238
		 'signed_int', 1, undef
	],
	[#Rule 239
		 'signed_int', 1, undef
	],
	[#Rule 240
		 'signed_int', 1, undef
	],
	[#Rule 241
		 'signed_short_int', 1,
sub
#line 1405 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 242
		 'signed_long_int', 1,
sub
#line 1415 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 243
		 'signed_longlong_int', 2,
sub
#line 1425 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 244
		 'unsigned_int', 1, undef
	],
	[#Rule 245
		 'unsigned_int', 1, undef
	],
	[#Rule 246
		 'unsigned_int', 1, undef
	],
	[#Rule 247
		 'unsigned_short_int', 2,
sub
#line 1445 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 248
		 'unsigned_long_int', 2,
sub
#line 1455 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 249
		 'unsigned_longlong_int', 3,
sub
#line 1465 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 250
		 'char_type', 1,
sub
#line 1475 "parser30.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 251
		 'wide_char_type', 1,
sub
#line 1485 "parser30.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 252
		 'boolean_type', 1,
sub
#line 1495 "parser30.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 253
		 'octet_type', 1,
sub
#line 1505 "parser30.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 254
		 'any_type', 1,
sub
#line 1515 "parser30.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 255
		 'object_type', 1,
sub
#line 1525 "parser30.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 256
		 'struct_type', 4,
sub
#line 1535 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 257
		 'struct_type', 4,
sub
#line 1542 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 258
		 'struct_header', 2,
sub
#line 1551 "parser30.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 259
		 'struct_header', 2,
sub
#line 1557 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 260
		 'member_list', 1,
sub
#line 1566 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 261
		 'member_list', 2,
sub
#line 1570 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 262
		 'member', 3,
sub
#line 1579 "parser30.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 263
		 'member', 3,
sub
#line 1586 "parser30.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 264
		 'union_type', 8,
sub
#line 1599 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 265
		 'union_type', 8,
sub
#line 1607 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'union_type', 6,
sub
#line 1613 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'union_type', 5,
sub
#line 1619 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 268
		 'union_type', 3,
sub
#line 1625 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 269
		 'union_header', 2,
sub
#line 1634 "parser30.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 270
		 'union_header', 2,
sub
#line 1640 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 271
		 'switch_type_spec', 1, undef
	],
	[#Rule 272
		 'switch_type_spec', 1, undef
	],
	[#Rule 273
		 'switch_type_spec', 1, undef
	],
	[#Rule 274
		 'switch_type_spec', 1, undef
	],
	[#Rule 275
		 'switch_type_spec', 1,
sub
#line 1657 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 276
		 'switch_body', 1,
sub
#line 1665 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 277
		 'switch_body', 2,
sub
#line 1669 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 278
		 'case', 3,
sub
#line 1678 "parser30.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 279
		 'case', 3,
sub
#line 1685 "parser30.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 280
		 'case_labels', 1,
sub
#line 1697 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 281
		 'case_labels', 2,
sub
#line 1701 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 282
		 'case_label', 3,
sub
#line 1710 "parser30.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 283
		 'case_label', 3,
sub
#line 1714 "parser30.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 284
		 'case_label', 2,
sub
#line 1720 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 285
		 'case_label', 2,
sub
#line 1725 "parser30.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 286
		 'case_label', 2,
sub
#line 1729 "parser30.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 287
		 'element_spec', 2,
sub
#line 1739 "parser30.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 288
		 'enum_type', 4,
sub
#line 1750 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 289
		 'enum_type', 4,
sub
#line 1756 "parser30.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 290
		 'enum_type', 2,
sub
#line 1761 "parser30.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 291
		 'enum_header', 2,
sub
#line 1769 "parser30.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 292
		 'enum_header', 2,
sub
#line 1775 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 293
		 'enumerators', 1,
sub
#line 1783 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 294
		 'enumerators', 3,
sub
#line 1787 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 295
		 'enumerators', 2,
sub
#line 1792 "parser30.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 296
		 'enumerators', 2,
sub
#line 1797 "parser30.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 297
		 'enumerator', 1,
sub
#line 1806 "parser30.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 298
		 'sequence_type', 6,
sub
#line 1816 "parser30.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 299
		 'sequence_type', 6,
sub
#line 1824 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 300
		 'sequence_type', 4,
sub
#line 1829 "parser30.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 301
		 'sequence_type', 4,
sub
#line 1836 "parser30.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 302
		 'sequence_type', 2,
sub
#line 1841 "parser30.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 303
		 'string_type', 4,
sub
#line 1850 "parser30.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 304
		 'string_type', 1,
sub
#line 1857 "parser30.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 305
		 'string_type', 4,
sub
#line 1863 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 306
		 'wide_string_type', 4,
sub
#line 1872 "parser30.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 307
		 'wide_string_type', 1,
sub
#line 1879 "parser30.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 308
		 'wide_string_type', 4,
sub
#line 1885 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 309
		 'array_declarator', 2,
sub
#line 1894 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 310
		 'fixed_array_sizes', 1,
sub
#line 1902 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 311
		 'fixed_array_sizes', 2,
sub
#line 1906 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 312
		 'fixed_array_size', 3,
sub
#line 1915 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 313
		 'fixed_array_size', 3,
sub
#line 1919 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 314
		 'attr_dcl', 1, undef
	],
	[#Rule 315
		 'attr_dcl', 1, undef
	],
	[#Rule 316
		 'except_dcl', 3,
sub
#line 1936 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 317
		 'except_dcl', 4,
sub
#line 1941 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 318
		 'except_dcl', 4,
sub
#line 1948 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 319
		 'except_dcl', 2,
sub
#line 1954 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 320
		 'exception_header', 2,
sub
#line 1963 "parser30.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 321
		 'exception_header', 2,
sub
#line 1969 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 322
		 'op_dcl', 2,
sub
#line 1978 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 323
		 'op_dcl', 3,
sub
#line 1986 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 324
		 'op_dcl', 4,
sub
#line 1995 "parser30.yp"
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
	[#Rule 325
		 'op_dcl', 3,
sub
#line 2005 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 326
		 'op_dcl', 2,
sub
#line 2014 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 327
		 'op_header', 3,
sub
#line 2024 "parser30.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 328
		 'op_header', 3,
sub
#line 2032 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 329
		 'op_mod', 1, undef
	],
	[#Rule 330
		 'op_mod', 0, undef
	],
	[#Rule 331
		 'op_attribute', 1, undef
	],
	[#Rule 332
		 'op_type_spec', 1, undef
	],
	[#Rule 333
		 'op_type_spec', 1,
sub
#line 2056 "parser30.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 334
		 'parameter_dcls', 3,
sub
#line 2066 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 335
		 'parameter_dcls', 2,
sub
#line 2070 "parser30.yp"
{
			undef;
		}
	],
	[#Rule 336
		 'parameter_dcls', 3,
sub
#line 2074 "parser30.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 337
		 'param_dcls', 1,
sub
#line 2082 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 338
		 'param_dcls', 3,
sub
#line 2086 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 339
		 'param_dcls', 2,
sub
#line 2091 "parser30.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 340
		 'param_dcls', 2,
sub
#line 2096 "parser30.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 341
		 'param_dcl', 3,
sub
#line 2105 "parser30.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 342
		 'param_dcl', 2,
sub
#line 2113 "parser30.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 343
		 'param_attribute', 1, undef
	],
	[#Rule 344
		 'param_attribute', 1, undef
	],
	[#Rule 345
		 'param_attribute', 1, undef
	],
	[#Rule 346
		 'raises_expr', 4,
sub
#line 2132 "parser30.yp"
{
			$_[3];
		}
	],
	[#Rule 347
		 'raises_expr', 4,
sub
#line 2136 "parser30.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 348
		 'raises_expr', 2,
sub
#line 2141 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 349
		 'exception_names', 1,
sub
#line 2149 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 350
		 'exception_names', 3,
sub
#line 2153 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 351
		 'exception_name', 1,
sub
#line 2161 "parser30.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 352
		 'context_expr', 4,
sub
#line 2169 "parser30.yp"
{
			$_[3];
		}
	],
	[#Rule 353
		 'context_expr', 4,
sub
#line 2173 "parser30.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 354
		 'context_expr', 2,
sub
#line 2178 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 355
		 'string_literals', 1,
sub
#line 2186 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 356
		 'string_literals', 3,
sub
#line 2190 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 357
		 'param_type_spec', 1, undef
	],
	[#Rule 358
		 'param_type_spec', 1, undef
	],
	[#Rule 359
		 'param_type_spec', 1, undef
	],
	[#Rule 360
		 'param_type_spec', 1,
sub
#line 2205 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 361
		 'fixed_pt_type', 6,
sub
#line 2213 "parser30.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 362
		 'fixed_pt_type', 6,
sub
#line 2221 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 363
		 'fixed_pt_type', 4,
sub
#line 2226 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 364
		 'fixed_pt_type', 2,
sub
#line 2231 "parser30.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 365
		 'fixed_pt_const_type', 1,
sub
#line 2240 "parser30.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 366
		 'value_base_type', 1,
sub
#line 2250 "parser30.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 367
		 'constr_forward_decl', 2,
sub
#line 2260 "parser30.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 368
		 'constr_forward_decl', 2,
sub
#line 2266 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 369
		 'constr_forward_decl', 2,
sub
#line 2271 "parser30.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 370
		 'constr_forward_decl', 2,
sub
#line 2277 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 371
		 'import', 3,
sub
#line 2286 "parser30.yp"
{
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 372
		 'import', 3,
sub
#line 2292 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 373
		 'import', 2,
sub
#line 2300 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 374
		 'imported_scope', 1, undef
	],
	[#Rule 375
		 'imported_scope', 1, undef
	],
	[#Rule 376
		 'type_id_dcl', 3,
sub
#line 2317 "parser30.yp"
{
			new TypeId($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 377
		 'type_id_dcl', 3,
sub
#line 2324 "parser30.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 378
		 'type_id_dcl', 2,
sub
#line 2329 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 379
		 'type_prefix_dcl', 3,
sub
#line 2338 "parser30.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 380
		 'type_prefix_dcl', 3,
sub
#line 2345 "parser30.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 381
		 'type_prefix_dcl', 3,
sub
#line 2350 "parser30.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	'',
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 382
		 'type_prefix_dcl', 2,
sub
#line 2357 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 383
		 'readonly_attr_spec', 4,
sub
#line 2366 "parser30.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]->{list_expr},
					'list_getraise'		=>	$_[4]->{list_getraise},
			);
		}
	],
	[#Rule 384
		 'readonly_attr_spec', 3,
sub
#line 2375 "parser30.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 385
		 'readonly_attr_spec', 2,
sub
#line 2380 "parser30.yp"
{
			$_[0]->Error("'attribute' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 386
		 'readonly_attr_declarator', 2,
sub
#line 2389 "parser30.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]
			};
		}
	],
	[#Rule 387
		 'readonly_attr_declarator', 1,
sub
#line 2396 "parser30.yp"
{
			{
				'list_expr'			=> $_[1]
			};
		}
	],
	[#Rule 388
		 'simple_declarators', 1,
sub
#line 2405 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 389
		 'simple_declarators', 3,
sub
#line 2409 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 390
		 'attr_spec', 3,
sub
#line 2418 "parser30.yp"
{
			new Attributes($_[0],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]->{list_expr},
					'list_getraise'		=>	$_[3]->{list_getraise},
					'list_setraise'		=>	$_[3]->{list_setraise},
			);
		}
	],
	[#Rule 391
		 'attr_spec', 2,
sub
#line 2427 "parser30.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 392
		 'attr_declarator', 2,
sub
#line 2436 "parser30.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]->{list_getraise},
				'list_setraise'		=> $_[2]->{list_setraise}
			};
		}
	],
	[#Rule 393
		 'attr_declarator', 1,
sub
#line 2444 "parser30.yp"
{
			{
				'list_expr'			=> $_[1]
			};
		}
	],
	[#Rule 394
		 'attr_raises_expr', 2,
sub
#line 2454 "parser30.yp"
{
			{
				'list_getraise'		=> $_[1],
				'list_setraise'		=> $_[2]
			};
		}
	],
	[#Rule 395
		 'attr_raises_expr', 1,
sub
#line 2461 "parser30.yp"
{
			{
				'list_getraise'		=> $_[1],
			};
		}
	],
	[#Rule 396
		 'attr_raises_expr', 1,
sub
#line 2467 "parser30.yp"
{
			{
				'list_setraise'		=> $_[1]
			};
		}
	],
	[#Rule 397
		 'get_except_expr', 2,
sub
#line 2477 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 398
		 'get_except_expr', 2,
sub
#line 2481 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 399
		 'set_except_expr', 2,
sub
#line 2490 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 400
		 'set_except_expr', 2,
sub
#line 2494 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 401
		 'exception_list', 3,
sub
#line 2503 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 402
		 'exception_list', 3,
sub
#line 2507 "parser30.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 403
		 'component', 1, undef
	],
	[#Rule 404
		 'component', 1, undef
	],
	[#Rule 405
		 'component_forward_dcl', 2,
sub
#line 2524 "parser30.yp"
{
			new ForwardComponent($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 406
		 'component_forward_dcl', 2,
sub
#line 2530 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 407
		 'component_dcl', 3,
sub
#line 2539 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 408
		 'component_dcl', 4,
sub
#line 2547 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 409
		 'component_dcl', 4,
sub
#line 2555 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 410
		 'component_header', 4,
sub
#line 2566 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3],
					'list_support'			=>	$_[4],
			);
		}
	],
	[#Rule 411
		 'component_header', 3,
sub
#line 2574 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3],
			);
		}
	],
	[#Rule 412
		 'component_header', 3,
sub
#line 2581 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'list_support'			=>	$_[3],
			);
		}
	],
	[#Rule 413
		 'component_header', 2,
sub
#line 2588 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
			);
		}
	],
	[#Rule 414
		 'component_header', 2,
sub
#line 2594 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 415
		 'supported_interface_spec', 2,
sub
#line 2603 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 416
		 'supported_interface_spec', 2,
sub
#line 2607 "parser30.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 417
		 'component_inheritance_spec', 2,
sub
#line 2616 "parser30.yp"
{
			Component->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 418
		 'component_inheritance_spec', 2,
sub
#line 2620 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 419
		 'component_body', 1, undef
	],
	[#Rule 420
		 'component_exports', 1,
sub
#line 2634 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 421
		 'component_exports', 2,
sub
#line 2638 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 422
		 'component_export', 2, undef
	],
	[#Rule 423
		 'component_export', 2, undef
	],
	[#Rule 424
		 'component_export', 2, undef
	],
	[#Rule 425
		 'component_export', 2, undef
	],
	[#Rule 426
		 'component_export', 2, undef
	],
	[#Rule 427
		 'component_export', 2, undef
	],
	[#Rule 428
		 'component_export', 2,
sub
#line 2659 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 429
		 'component_export', 2,
sub
#line 2665 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 430
		 'component_export', 2,
sub
#line 2671 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 431
		 'component_export', 2,
sub
#line 2677 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 432
		 'component_export', 2,
sub
#line 2683 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 433
		 'component_export', 2,
sub
#line 2689 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 434
		 'provides_dcl', 3,
sub
#line 2699 "parser30.yp"
{
			new Provides($_[0],
					'idf'					=>	$_[3],
					'type'					=>	$_[2],
			);
		}
	],
	[#Rule 435
		 'provides_dcl', 3,
sub
#line 2706 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 436
		 'provides_dcl', 2,
sub
#line 2711 "parser30.yp"
{
			$_[0]->Error("Interface type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 437
		 'interface_type', 1,
sub
#line 2720 "parser30.yp"
{
			BaseInterface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 438
		 'interface_type', 1, undef
	],
	[#Rule 439
		 'uses_dcl', 4,
sub
#line 2730 "parser30.yp"
{
			new Uses($_[0],
					'modifier'				=>	$_[2],
					'idf'					=>	$_[4],
					'type'					=>	$_[3],
			);
		}
	],
	[#Rule 440
		 'uses_dcl', 4,
sub
#line 2738 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 441
		 'uses_dcl', 3,
sub
#line 2743 "parser30.yp"
{
			$_[0]->Error("Interface type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 442
		 'uses_mod', 1, undef
	],
	[#Rule 443
		 'uses_mod', 0, undef
	],
	[#Rule 444
		 'emits_dcl', 3,
sub
#line 2759 "parser30.yp"
{
			new Emits($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 445
		 'emits_dcl', 3,
sub
#line 2766 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 446
		 'emits_dcl', 2,
sub
#line 2771 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 447
		 'publishes_dcl', 3,
sub
#line 2780 "parser30.yp"
{
			new Publishes($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 448
		 'publishes_dcl', 3,
sub
#line 2787 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 449
		 'publishes_dcl', 2,
sub
#line 2792 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 450
		 'consumes_dcl', 3,
sub
#line 2801 "parser30.yp"
{
			new Consumes($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 451
		 'consumes_dcl', 3,
sub
#line 2808 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 452
		 'consumes_dcl', 2,
sub
#line 2813 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 453
		 'home_dcl', 2,
sub
#line 2822 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[2],
			) if (defined $_[1]);
		}
	],
	[#Rule 454
		 'home_header', 4,
sub
#line 2834 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'manage'			=>	Component->Lookup($_[0],$_[3]),
					'primarykey'		=>	$_[4],
			) if (defined $_[1]);
		}
	],
	[#Rule 455
		 'home_header', 3,
sub
#line 2841 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'manage'			=>	Component->Lookup($_[0],$_[3]),
			) if (defined $_[1]);
		}
	],
	[#Rule 456
		 'home_header', 3,
sub
#line 2847 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 457
		 'home_header_spec', 4,
sub
#line 2856 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3],
					'list_support'		=>	$_[4],
			);
		}
	],
	[#Rule 458
		 'home_header_spec', 3,
sub
#line 2864 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3],
			);
		}
	],
	[#Rule 459
		 'home_header_spec', 3,
sub
#line 2871 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'list_support'		=>	$_[3],
			);
		}
	],
	[#Rule 460
		 'home_header_spec', 2,
sub
#line 2878 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 461
		 'home_header_spec', 2,
sub
#line 2884 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 462
		 'home_inheritance_spec', 2,
sub
#line 2893 "parser30.yp"
{
			Home->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 463
		 'home_inheritance_spec', 2,
sub
#line 2897 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 464
		 'primary_key_spec', 2,
sub
#line 2906 "parser30.yp"
{
			Value->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 465
		 'primary_key_spec', 2,
sub
#line 2910 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 466
		 'home_body', 2,
sub
#line 2919 "parser30.yp"
{
			[];
		}
	],
	[#Rule 467
		 'home_body', 3,
sub
#line 2923 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 468
		 'home_body', 3,
sub
#line 2927 "parser30.yp"
{
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 469
		 'home_exports', 1,
sub
#line 2935 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 470
		 'home_exports', 2,
sub
#line 2939 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 471
		 'home_export', 1, undef
	],
	[#Rule 472
		 'home_export', 2, undef
	],
	[#Rule 473
		 'home_export', 2, undef
	],
	[#Rule 474
		 'home_export', 2,
sub
#line 2954 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 475
		 'home_export', 2,
sub
#line 2960 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 476
		 'factory_dcl', 2,
sub
#line 2970 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 477
		 'factory_dcl', 1, undef
	],
	[#Rule 478
		 'factory_header_param', 3,
sub
#line 2981 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 479
		 'factory_header_param', 4,
sub
#line 2987 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'		=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 480
		 'factory_header_param', 4,
sub
#line 2995 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 481
		 'factory_header_param', 2,
sub
#line 3002 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 482
		 'factory_header', 2,
sub
#line 3012 "parser30.yp"
{
			new Factory($_[0],							# like Operation
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 483
		 'factory_header', 2,
sub
#line 3018 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 484
		 'finder_dcl', 2,
sub
#line 3027 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 485
		 'finder_dcl', 1, undef
	],
	[#Rule 486
		 'finder_header_param', 3,
sub
#line 3038 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 487
		 'finder_header_param', 4,
sub
#line 3044 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'		=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 488
		 'finder_header_param', 4,
sub
#line 3052 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 489
		 'finder_header_param', 2,
sub
#line 3059 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 490
		 'finder_header', 2,
sub
#line 3069 "parser30.yp"
{
			new Finder($_[0],							# like Operation
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 491
		 'finder_header', 2,
sub
#line 3075 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 492
		 'event', 1, undef
	],
	[#Rule 493
		 'event', 1, undef
	],
	[#Rule 494
		 'event', 1, undef
	],
	[#Rule 495
		 'event_forward_dcl', 2,
sub
#line 3094 "parser30.yp"
{
			new ForwardRegularEvent($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 496
		 'event_forward_dcl', 3,
sub
#line 3100 "parser30.yp"
{
			new ForwardAbstractEvent($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 497
		 'event_abs_dcl', 3,
sub
#line 3110 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 498
		 'event_abs_dcl', 4,
sub
#line 3118 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 499
		 'event_abs_dcl', 4,
sub
#line 3126 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 500
		 'event_abs_header', 3,
sub
#line 3136 "parser30.yp"
{
			new AbstractEvent($_[0],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 501
		 'event_abs_header', 4,
sub
#line 3142 "parser30.yp"
{
			new AbstractEvent($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 502
		 'event_abs_header', 3,
sub
#line 3149 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 503
		 'event_dcl', 3,
sub
#line 3158 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 504
		 'event_dcl', 4,
sub
#line 3166 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 505
		 'event_dcl', 4,
sub
#line 3174 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 506
		 'event_header', 2,
sub
#line 3185 "parser30.yp"
{
			new RegularEvent($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 507
		 'event_header', 3,
sub
#line 3191 "parser30.yp"
{
			new RegularEvent($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 508
		 'event_header', 3,
sub
#line 3198 "parser30.yp"
{
			new RegularEvent($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 509
		 'event_header', 4,
sub
#line 3205 "parser30.yp"
{
			new RegularEvent($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 510
		 'event_header', 2,
sub
#line 3213 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 511
		 'event_header', 3,
sub
#line 3218 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 3224 "parser30.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '3.0';

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
