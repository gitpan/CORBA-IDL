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
			'NATIVE' => 53,
			'ABSTRACT' => 2,
			'COMPONENT' => 54,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'IMPORT' => 57,
			'TYPEPREFIX' => 58,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 59,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'error' => 45,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 62,
			'EXCEPTION' => 50,
			'ENUM' => 16,
			'INTERFACE' => -46
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
			'enum_type' => 44,
			'forward_dcl' => 43,
			'enum_header' => 47,
			'constr_forward_decl' => 46,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 15,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 51,
			'imports' => 19,
			'home_dcl' => 52,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 55,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'union_type' => 28,
			'exception_header' => 27,
			'event_header' => 60,
			'component_header' => 31,
			'module' => 61,
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 64
		}
	},
	{#State 1
		DEFAULT => -80
	},
	{#State 2
		ACTIONS => {
			'error' => 67,
			'VALUETYPE' => 66,
			'EVENTTYPE' => 65,
			'INTERFACE' => -44
		}
	},
	{#State 3
		ACTIONS => {
			'' => 68
		}
	},
	{#State 4
		ACTIONS => {
			'error' => 70,
			";" => 69
		}
	},
	{#State 5
		ACTIONS => {
			'error' => 71,
			'IDENTIFIER' => 72
		}
	},
	{#State 6
		ACTIONS => {
			"{" => 73
		}
	},
	{#State 7
		ACTIONS => {
			'error' => 75,
			";" => 74
		}
	},
	{#State 8
		DEFAULT => -77
	},
	{#State 9
		ACTIONS => {
			'IMPORT' => 57
		},
		DEFAULT => -5,
		GOTOS => {
			'import' => 9,
			'imports' => 76
		}
	},
	{#State 10
		ACTIONS => {
			"{" => 77
		}
	},
	{#State 11
		DEFAULT => -37
	},
	{#State 12
		ACTIONS => {
			'error' => 79,
			";" => 78
		}
	},
	{#State 13
		ACTIONS => {
			'SHORT' => 103,
			'CHAR' => 89,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'FIXED' => 96,
			'WCHAR' => 84,
			'DOUBLE' => 108,
			'error' => 104,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'OCTET' => 86,
			'FLOAT' => 87,
			'WSTRING' => 94,
			'UNSIGNED' => 101
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 81,
			'signed_int' => 97,
			'wide_string_type' => 90,
			'integer_type' => 107,
			'boolean_type' => 106,
			'char_type' => 82,
			'scoped_name' => 98,
			'octet_type' => 83,
			'wide_char_type' => 99,
			'fixed_pt_const_type' => 91,
			'signed_long_int' => 100,
			'signed_short_int' => 93,
			'const_type' => 111,
			'string_type' => 102,
			'unsigned_longlong_int' => 85,
			'unsigned_long_int' => 113,
			'unsigned_short_int' => 105,
			'signed_longlong_int' => 88
		}
	},
	{#State 14
		DEFAULT => -78
	},
	{#State 15
		DEFAULT => -2
	},
	{#State 16
		ACTIONS => {
			'error' => 114,
			'IDENTIFIER' => 115
		}
	},
	{#State 17
		ACTIONS => {
			'INTERFACE' => 116
		}
	},
	{#State 18
		DEFAULT => -397
	},
	{#State 19
		ACTIONS => {
			'NATIVE' => 53,
			'ABSTRACT' => 2,
			'COMPONENT' => 54,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 59,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 62,
			'EXCEPTION' => 50,
			'ENUM' => 16
		},
		DEFAULT => -46,
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
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 117,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 51,
			'home_dcl' => 52,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 55,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'exception_header' => 27,
			'union_type' => 28,
			'event_header' => 60,
			'component_header' => 31,
			'module' => 61,
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 64
		}
	},
	{#State 20
		ACTIONS => {
			"{" => 118
		}
	},
	{#State 21
		ACTIONS => {
			'MANAGES' => 119
		}
	},
	{#State 22
		ACTIONS => {
			"{" => 120
		}
	},
	{#State 23
		ACTIONS => {
			'error' => 121,
			'IDENTIFIER' => 122
		}
	},
	{#State 24
		DEFAULT => -487
	},
	{#State 25
		ACTIONS => {
			"{" => 123
		}
	},
	{#State 26
		DEFAULT => -191
	},
	{#State 27
		ACTIONS => {
			'error' => 125,
			"{" => 124
		}
	},
	{#State 28
		DEFAULT => -192
	},
	{#State 29
		ACTIONS => {
			'error' => 126,
			'IDENTIFIER' => 127
		}
	},
	{#State 30
		ACTIONS => {
			'error' => 128,
			'IDENTIFIER' => 129
		}
	},
	{#State 31
		ACTIONS => {
			"{" => 130
		}
	},
	{#State 32
		ACTIONS => {
			"{" => 131
		},
		GOTOS => {
			'home_body' => 132
		}
	},
	{#State 33
		DEFAULT => -398
	},
	{#State 34
		ACTIONS => {
			'error' => 134,
			";" => 133
		}
	},
	{#State 35
		ACTIONS => {
			'error' => 136,
			";" => 135
		}
	},
	{#State 36
		ACTIONS => {
			'error' => 138,
			"{" => 137
		}
	},
	{#State 37
		DEFAULT => -79
	},
	{#State 38
		ACTIONS => {
			'error' => 139,
			'IDENTIFIER' => 140
		}
	},
	{#State 39
		ACTIONS => {
			'error' => 142,
			";" => 141
		}
	},
	{#State 40
		DEFAULT => -486
	},
	{#State 41
		ACTIONS => {
			'error' => 143,
			'IDENTIFIER' => 144
		}
	},
	{#State 42
		ACTIONS => {
			'error' => 146,
			";" => 145
		}
	},
	{#State 43
		DEFAULT => -38
	},
	{#State 44
		DEFAULT => -193
	},
	{#State 45
		DEFAULT => -4
	},
	{#State 46
		DEFAULT => -195
	},
	{#State 47
		ACTIONS => {
			'error' => 148,
			"{" => 147
		}
	},
	{#State 48
		DEFAULT => -45
	},
	{#State 49
		ACTIONS => {
			'SWITCH' => 149
		}
	},
	{#State 50
		ACTIONS => {
			'error' => 150,
			'IDENTIFIER' => 151
		}
	},
	{#State 51
		ACTIONS => {
			'error' => 153,
			";" => 152
		}
	},
	{#State 52
		ACTIONS => {
			'error' => 155,
			";" => 154
		}
	},
	{#State 53
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'simple_declarator' => 157
		}
	},
	{#State 54
		ACTIONS => {
			'error' => 159,
			'IDENTIFIER' => 160
		}
	},
	{#State 55
		DEFAULT => -488
	},
	{#State 56
		ACTIONS => {
			'error' => 162,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 161
		}
	},
	{#State 57
		ACTIONS => {
			'error' => 166,
			'IDENTIFIER' => 112,
			"::" => 92,
			'STRING_LITERAL' => 167
		},
		GOTOS => {
			'scoped_name' => 165,
			'string_literal' => 163,
			'imported_scope' => 164
		}
	},
	{#State 58
		ACTIONS => {
			'error' => 170,
			'IDENTIFIER' => 112,
			"::" => 168
		},
		GOTOS => {
			'scoped_name' => 169
		}
	},
	{#State 59
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'FIXED' => 186,
			'VALUEBASE' => 178,
			'SEQUENCE' => 172,
			'STRUCT' => 180,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'UNION' => 183,
			'WCHAR' => 84,
			'error' => 194,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ENUM' => 16,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 189,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'type_spec' => 175,
			'type_declarator' => 176,
			'string_type' => 191,
			'struct_header' => 10,
			'base_type_spec' => 192,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'enum_type' => 193,
			'enum_header' => 47,
			'unsigned_short_int' => 105,
			'union_header' => 49,
			'signed_longlong_int' => 88,
			'wide_string_type' => 179,
			'boolean_type' => 197,
			'integer_type' => 198,
			'signed_short_int' => 93,
			'struct_type' => 181,
			'union_type' => 182,
			'sequence_type' => 199,
			'unsigned_long_int' => 113,
			'template_type_spec' => 184,
			'constr_type_spec' => 185,
			'simple_type_spec' => 200,
			'fixed_pt_type' => 201
		}
	},
	{#State 60
		ACTIONS => {
			"{" => 202
		}
	},
	{#State 61
		ACTIONS => {
			'error' => 204,
			";" => 203
		}
	},
	{#State 62
		ACTIONS => {
			'error' => 207,
			'VALUETYPE' => 206,
			'EVENTTYPE' => 205
		}
	},
	{#State 63
		ACTIONS => {
			'error' => 209,
			";" => 208
		}
	},
	{#State 64
		ACTIONS => {
			'NATIVE' => 53,
			'ABSTRACT' => 2,
			'COMPONENT' => 54,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 59,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 62,
			'EXCEPTION' => 50,
			'ENUM' => 16,
			'INTERFACE' => -46
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
			'struct_header' => 10,
			'interface_dcl' => 11,
			'value' => 42,
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 210,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 51,
			'home_dcl' => 52,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 55,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'exception_header' => 27,
			'union_type' => 28,
			'event_header' => 60,
			'component_header' => 31,
			'module' => 61,
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 64
		}
	},
	{#State 65
		ACTIONS => {
			'error' => 211,
			'IDENTIFIER' => 212
		}
	},
	{#State 66
		ACTIONS => {
			'error' => 213,
			'IDENTIFIER' => 214
		}
	},
	{#State 67
		DEFAULT => -90
	},
	{#State 68
		DEFAULT => 0
	},
	{#State 69
		DEFAULT => -12
	},
	{#State 70
		DEFAULT => -23
	},
	{#State 71
		DEFAULT => -504
	},
	{#State 72
		ACTIONS => {
			"{" => -500,
			":" => 217,
			'SUPPORTS' => 215
		},
		DEFAULT => -489,
		GOTOS => {
			'supported_interface_spec' => 218,
			'value_inheritance_spec' => 216
		}
	},
	{#State 73
		ACTIONS => {
			'ONEWAY' => 219,
			'UNSIGNED' => -324,
			'SHORT' => -324,
			'WCHAR' => -324,
			'error' => 228,
			'CONST' => 13,
			"}" => 229,
			'EXCEPTION' => 50,
			'FLOAT' => -324,
			'OCTET' => -324,
			'ENUM' => 16,
			'ANY' => -324,
			'CHAR' => -324,
			'OBJECT' => -324,
			'NATIVE' => 53,
			'VALUEBASE' => -324,
			'VOID' => -324,
			'STRUCT' => 23,
			'DOUBLE' => -324,
			'TYPEID' => 56,
			'LONG' => -324,
			'STRING' => -324,
			"::" => -324,
			'TYPEPREFIX' => 58,
			'WSTRING' => -324,
			'BOOLEAN' => -324,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -324,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235
		},
		GOTOS => {
			'const_dcl' => 230,
			'op_mod' => 220,
			'except_dcl' => 226,
			'attr_spec' => 221,
			'op_attribute' => 222,
			'readonly_attr_spec' => 223,
			'exports' => 231,
			'type_id_dcl' => 227,
			'export' => 232,
			'struct_type' => 26,
			'op_header' => 233,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 236,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'type_dcl' => 237,
			'union_header' => 49
		}
	},
	{#State 74
		DEFAULT => -18
	},
	{#State 75
		DEFAULT => -29
	},
	{#State 76
		DEFAULT => -6
	},
	{#State 77
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'FIXED' => 186,
			'VALUEBASE' => 178,
			'SEQUENCE' => 172,
			'STRUCT' => 180,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'UNION' => 183,
			'WCHAR' => 84,
			'error' => 240,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ENUM' => 16,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 189,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'type_spec' => 238,
			'string_type' => 191,
			'struct_header' => 10,
			'base_type_spec' => 192,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'enum_type' => 193,
			'enum_header' => 47,
			'member_list' => 239,
			'unsigned_short_int' => 105,
			'union_header' => 49,
			'signed_longlong_int' => 88,
			'wide_string_type' => 179,
			'boolean_type' => 197,
			'integer_type' => 198,
			'signed_short_int' => 93,
			'member' => 241,
			'struct_type' => 181,
			'union_type' => 182,
			'sequence_type' => 199,
			'unsigned_long_int' => 113,
			'template_type_spec' => 184,
			'constr_type_spec' => 185,
			'simple_type_spec' => 200,
			'fixed_pt_type' => 201
		}
	},
	{#State 78
		DEFAULT => -16
	},
	{#State 79
		DEFAULT => -27
	},
	{#State 80
		DEFAULT => -231
	},
	{#State 81
		DEFAULT => -143
	},
	{#State 82
		DEFAULT => -140
	},
	{#State 83
		DEFAULT => -148
	},
	{#State 84
		DEFAULT => -245
	},
	{#State 85
		DEFAULT => -240
	},
	{#State 86
		DEFAULT => -247
	},
	{#State 87
		DEFAULT => -227
	},
	{#State 88
		DEFAULT => -234
	},
	{#State 89
		DEFAULT => -244
	},
	{#State 90
		DEFAULT => -145
	},
	{#State 91
		DEFAULT => -146
	},
	{#State 92
		ACTIONS => {
			'error' => 242,
			'IDENTIFIER' => 243
		}
	},
	{#State 93
		DEFAULT => -232
	},
	{#State 94
		ACTIONS => {
			"<" => 244
		},
		DEFAULT => -301
	},
	{#State 95
		DEFAULT => -246
	},
	{#State 96
		DEFAULT => -359
	},
	{#State 97
		DEFAULT => -230
	},
	{#State 98
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -147
	},
	{#State 99
		DEFAULT => -141
	},
	{#State 100
		DEFAULT => -233
	},
	{#State 101
		ACTIONS => {
			'SHORT' => 246,
			'LONG' => 247
		}
	},
	{#State 102
		DEFAULT => -144
	},
	{#State 103
		DEFAULT => -235
	},
	{#State 104
		DEFAULT => -138
	},
	{#State 105
		DEFAULT => -238
	},
	{#State 106
		DEFAULT => -142
	},
	{#State 107
		DEFAULT => -139
	},
	{#State 108
		DEFAULT => -228
	},
	{#State 109
		ACTIONS => {
			'DOUBLE' => 248,
			'LONG' => 249
		},
		DEFAULT => -236
	},
	{#State 110
		ACTIONS => {
			"<" => 250
		},
		DEFAULT => -298
	},
	{#State 111
		ACTIONS => {
			'error' => 251,
			'IDENTIFIER' => 252
		}
	},
	{#State 112
		DEFAULT => -72
	},
	{#State 113
		DEFAULT => -239
	},
	{#State 114
		DEFAULT => -286
	},
	{#State 115
		DEFAULT => -285
	},
	{#State 116
		ACTIONS => {
			'error' => 253,
			'IDENTIFIER' => 254
		}
	},
	{#State 117
		DEFAULT => -1
	},
	{#State 118
		ACTIONS => {
			'ONEWAY' => 219,
			'UNSIGNED' => -324,
			'SHORT' => -324,
			'WCHAR' => -324,
			'error' => 255,
			'CONST' => 13,
			"}" => 256,
			'EXCEPTION' => 50,
			'FLOAT' => -324,
			'OCTET' => -324,
			'ENUM' => 16,
			'ANY' => -324,
			'CHAR' => -324,
			'OBJECT' => -324,
			'NATIVE' => 53,
			'VALUEBASE' => -324,
			'VOID' => -324,
			'STRUCT' => 23,
			'DOUBLE' => -324,
			'TYPEID' => 56,
			'LONG' => -324,
			'STRING' => -324,
			"::" => -324,
			'TYPEPREFIX' => 58,
			'WSTRING' => -324,
			'BOOLEAN' => -324,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -324,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235
		},
		GOTOS => {
			'const_dcl' => 230,
			'op_mod' => 220,
			'except_dcl' => 226,
			'attr_spec' => 221,
			'op_attribute' => 222,
			'readonly_attr_spec' => 223,
			'exports' => 257,
			'type_id_dcl' => 227,
			'export' => 232,
			'struct_type' => 26,
			'op_header' => 233,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 236,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'type_dcl' => 237,
			'union_header' => 49,
			'interface_body' => 258
		}
	},
	{#State 119
		ACTIONS => {
			'error' => 260,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 259
		}
	},
	{#State 120
		ACTIONS => {
			'PRIVATE' => 262,
			'ONEWAY' => 219,
			'FACTORY' => 268,
			'UNSIGNED' => -324,
			'SHORT' => -324,
			'WCHAR' => -324,
			'error' => 270,
			'CONST' => 13,
			'EXCEPTION' => 50,
			"}" => 271,
			'FLOAT' => -324,
			'OCTET' => -324,
			'ENUM' => 16,
			'ANY' => -324,
			'CHAR' => -324,
			'OBJECT' => -324,
			'NATIVE' => 53,
			'VALUEBASE' => -324,
			'VOID' => -324,
			'STRUCT' => 23,
			'DOUBLE' => -324,
			'TYPEID' => 56,
			'LONG' => -324,
			'STRING' => -324,
			"::" => -324,
			'TYPEPREFIX' => 58,
			'WSTRING' => -324,
			'BOOLEAN' => -324,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -324,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235,
			'PUBLIC' => 265
		},
		GOTOS => {
			'init_header_param' => 261,
			'const_dcl' => 230,
			'op_mod' => 220,
			'value_elements' => 272,
			'except_dcl' => 226,
			'state_member' => 267,
			'attr_spec' => 221,
			'op_attribute' => 222,
			'state_mod' => 263,
			'value_element' => 264,
			'readonly_attr_spec' => 223,
			'type_id_dcl' => 227,
			'export' => 273,
			'init_header' => 269,
			'struct_type' => 26,
			'op_header' => 233,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 236,
			'enum_type' => 44,
			'init_dcl' => 266,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'type_dcl' => 237,
			'union_header' => 49
		}
	},
	{#State 121
		ACTIONS => {
			"{" => -253
		},
		DEFAULT => -362
	},
	{#State 122
		ACTIONS => {
			"{" => -252
		},
		DEFAULT => -361
	},
	{#State 123
		ACTIONS => {
			'ONEWAY' => 219,
			'UNSIGNED' => -324,
			'SHORT' => -324,
			'WCHAR' => -324,
			'error' => 274,
			'CONST' => 13,
			"}" => 275,
			'EXCEPTION' => 50,
			'FLOAT' => -324,
			'OCTET' => -324,
			'ENUM' => 16,
			'ANY' => -324,
			'CHAR' => -324,
			'OBJECT' => -324,
			'NATIVE' => 53,
			'VALUEBASE' => -324,
			'VOID' => -324,
			'STRUCT' => 23,
			'DOUBLE' => -324,
			'TYPEID' => 56,
			'LONG' => -324,
			'STRING' => -324,
			"::" => -324,
			'TYPEPREFIX' => 58,
			'WSTRING' => -324,
			'BOOLEAN' => -324,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -324,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235
		},
		GOTOS => {
			'const_dcl' => 230,
			'op_mod' => 220,
			'except_dcl' => 226,
			'attr_spec' => 221,
			'op_attribute' => 222,
			'readonly_attr_spec' => 223,
			'exports' => 276,
			'type_id_dcl' => 227,
			'export' => 232,
			'struct_type' => 26,
			'op_header' => 233,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 236,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'type_dcl' => 237,
			'union_header' => 49
		}
	},
	{#State 124
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'FIXED' => 186,
			'VALUEBASE' => 178,
			'SEQUENCE' => 172,
			'STRUCT' => 180,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'UNION' => 183,
			'WCHAR' => 84,
			'error' => 278,
			"}" => 279,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ENUM' => 16,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 189,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'type_spec' => 238,
			'string_type' => 191,
			'struct_header' => 10,
			'base_type_spec' => 192,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'enum_type' => 193,
			'enum_header' => 47,
			'member_list' => 277,
			'unsigned_short_int' => 105,
			'union_header' => 49,
			'signed_longlong_int' => 88,
			'wide_string_type' => 179,
			'boolean_type' => 197,
			'integer_type' => 198,
			'signed_short_int' => 93,
			'member' => 241,
			'struct_type' => 181,
			'union_type' => 182,
			'sequence_type' => 199,
			'unsigned_long_int' => 113,
			'template_type_spec' => 184,
			'constr_type_spec' => 185,
			'simple_type_spec' => 200,
			'fixed_pt_type' => 201
		}
	},
	{#State 125
		DEFAULT => -313
	},
	{#State 126
		ACTIONS => {
			'SWITCH' => -264
		},
		DEFAULT => -364
	},
	{#State 127
		ACTIONS => {
			'SWITCH' => -263
		},
		DEFAULT => -363
	},
	{#State 128
		DEFAULT => -455
	},
	{#State 129
		ACTIONS => {
			":" => 281,
			'SUPPORTS' => 215
		},
		DEFAULT => -454,
		GOTOS => {
			'home_inheritance_spec' => 280,
			'supported_interface_spec' => 282
		}
	},
	{#State 130
		ACTIONS => {
			'error' => 293,
			'PUBLISHES' => 296,
			"}" => 294,
			'USES' => 288,
			'READONLY' => 234,
			'PROVIDES' => 295,
			'CONSUMES' => 298,
			'ATTRIBUTE' => 235,
			'EMITS' => 291
		},
		GOTOS => {
			'consumes_dcl' => 283,
			'emits_dcl' => 290,
			'attr_spec' => 221,
			'provides_dcl' => 287,
			'readonly_attr_spec' => 223,
			'component_exports' => 284,
			'attr_dcl' => 289,
			'publishes_dcl' => 285,
			'uses_dcl' => 297,
			'component_export' => 286,
			'component_body' => 292
		}
	},
	{#State 131
		ACTIONS => {
			'ONEWAY' => 219,
			'FACTORY' => 305,
			'UNSIGNED' => -324,
			'SHORT' => -324,
			'WCHAR' => -324,
			'error' => 306,
			'CONST' => 13,
			'OCTET' => -324,
			'FLOAT' => -324,
			'EXCEPTION' => 50,
			"}" => 307,
			'ENUM' => 16,
			'FINDER' => 300,
			'ANY' => -324,
			'CHAR' => -324,
			'OBJECT' => -324,
			'NATIVE' => 53,
			'VALUEBASE' => -324,
			'VOID' => -324,
			'STRUCT' => 23,
			'DOUBLE' => -324,
			'TYPEID' => 56,
			'LONG' => -324,
			'STRING' => -324,
			"::" => -324,
			'TYPEPREFIX' => 58,
			'WSTRING' => -324,
			'TYPEDEF' => 59,
			'BOOLEAN' => -324,
			'IDENTIFIER' => -324,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235
		},
		GOTOS => {
			'const_dcl' => 230,
			'op_mod' => 220,
			'except_dcl' => 226,
			'attr_spec' => 221,
			'factory_header_param' => 299,
			'home_exports' => 302,
			'home_export' => 301,
			'op_attribute' => 222,
			'readonly_attr_spec' => 223,
			'finder_dcl' => 303,
			'type_id_dcl' => 227,
			'export' => 308,
			'struct_type' => 26,
			'finder_header' => 309,
			'exception_header' => 27,
			'union_type' => 28,
			'op_header' => 233,
			'struct_header' => 10,
			'factory_dcl' => 304,
			'enum_type' => 44,
			'finder_header_param' => 310,
			'op_dcl' => 236,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'union_header' => 49,
			'type_dcl' => 237,
			'factory_header' => 311
		}
	},
	{#State 132
		DEFAULT => -447
	},
	{#State 133
		DEFAULT => -17
	},
	{#State 134
		DEFAULT => -28
	},
	{#State 135
		DEFAULT => -11
	},
	{#State 136
		DEFAULT => -22
	},
	{#State 137
		ACTIONS => {
			'NATIVE' => 53,
			'ABSTRACT' => 2,
			'COMPONENT' => 54,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'VALUETYPE' => 38,
			'EVENTTYPE' => 5,
			'TYPEDEF' => 59,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'error' => 313,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 62,
			'EXCEPTION' => 50,
			"}" => 314,
			'ENUM' => 16,
			'INTERFACE' => -46
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
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 312,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 51,
			'home_dcl' => 52,
			'interface_header' => 20,
			'home_header_spec' => 21,
			'value_header' => 22,
			'event_forward_dcl' => 55,
			'event_abs_dcl' => 24,
			'event_abs_header' => 25,
			'struct_type' => 26,
			'exception_header' => 27,
			'union_type' => 28,
			'event_header' => 60,
			'component_header' => 31,
			'module' => 61,
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 64
		}
	},
	{#State 138
		ACTIONS => {
			"}" => 315
		}
	},
	{#State 139
		DEFAULT => -100
	},
	{#State 140
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'FIXED' => 186,
			'VALUEBASE' => 178,
			'SEQUENCE' => 172,
			'STRUCT' => 180,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			":" => 217,
			'UNION' => 183,
			'WCHAR' => 84,
			"{" => -96,
			'FLOAT' => 87,
			'OCTET' => 86,
			'SUPPORTS' => 215,
			'ENUM' => 16,
			'ANY' => 195
		},
		DEFAULT => -81,
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 189,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'type_spec' => 316,
			'string_type' => 191,
			'struct_header' => 10,
			'base_type_spec' => 192,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'enum_type' => 193,
			'enum_header' => 47,
			'unsigned_short_int' => 105,
			'union_header' => 49,
			'signed_longlong_int' => 88,
			'wide_string_type' => 179,
			'boolean_type' => 197,
			'integer_type' => 198,
			'signed_short_int' => 93,
			'value_inheritance_spec' => 317,
			'struct_type' => 181,
			'union_type' => 182,
			'sequence_type' => 199,
			'unsigned_long_int' => 113,
			'template_type_spec' => 184,
			'constr_type_spec' => 185,
			'simple_type_spec' => 200,
			'fixed_pt_type' => 201,
			'supported_interface_spec' => 218
		}
	},
	{#State 141
		DEFAULT => -15
	},
	{#State 142
		DEFAULT => -26
	},
	{#State 143
		DEFAULT => -36
	},
	{#State 144
		DEFAULT => -35
	},
	{#State 145
		DEFAULT => -14
	},
	{#State 146
		DEFAULT => -25
	},
	{#State 147
		ACTIONS => {
			'error' => 320,
			'IDENTIFIER' => 321
		},
		GOTOS => {
			'enumerators' => 319,
			'enumerator' => 318
		}
	},
	{#State 148
		DEFAULT => -284
	},
	{#State 149
		ACTIONS => {
			'error' => 323,
			"(" => 322
		}
	},
	{#State 150
		DEFAULT => -315
	},
	{#State 151
		DEFAULT => -314
	},
	{#State 152
		DEFAULT => -10
	},
	{#State 153
		DEFAULT => -21
	},
	{#State 154
		DEFAULT => -19
	},
	{#State 155
		DEFAULT => -30
	},
	{#State 156
		ACTIONS => {
			";" => 324,
			"," => 325
		}
	},
	{#State 157
		DEFAULT => -194
	},
	{#State 158
		DEFAULT => -223
	},
	{#State 159
		ACTIONS => {
			"{" => -408
		},
		DEFAULT => -400
	},
	{#State 160
		ACTIONS => {
			"{" => -407,
			":" => 327,
			'SUPPORTS' => 215
		},
		DEFAULT => -399,
		GOTOS => {
			'component_inheritance_spec' => 326,
			'supported_interface_spec' => 328
		}
	},
	{#State 161
		ACTIONS => {
			'error' => 330,
			"::" => 245,
			'STRING_LITERAL' => 167
		},
		GOTOS => {
			'string_literal' => 329
		}
	},
	{#State 162
		DEFAULT => -372
	},
	{#State 163
		DEFAULT => -369
	},
	{#State 164
		ACTIONS => {
			'error' => 332,
			";" => 331
		}
	},
	{#State 165
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -368
	},
	{#State 166
		DEFAULT => -367
	},
	{#State 167
		ACTIONS => {
			'STRING_LITERAL' => 167
		},
		DEFAULT => -183,
		GOTOS => {
			'string_literal' => 333
		}
	},
	{#State 168
		ACTIONS => {
			'error' => 242,
			'IDENTIFIER' => 243,
			'STRING_LITERAL' => 167
		},
		GOTOS => {
			'string_literal' => 334
		}
	},
	{#State 169
		ACTIONS => {
			'error' => 336,
			"::" => 245,
			'STRING_LITERAL' => 167
		},
		GOTOS => {
			'string_literal' => 335
		}
	},
	{#State 170
		DEFAULT => -376
	},
	{#State 171
		DEFAULT => -203
	},
	{#State 172
		ACTIONS => {
			'error' => 338,
			"<" => 337
		}
	},
	{#State 173
		DEFAULT => -205
	},
	{#State 174
		DEFAULT => -208
	},
	{#State 175
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 344
		},
		GOTOS => {
			'declarators' => 339,
			'declarator' => 342,
			'simple_declarator' => 343,
			'array_declarator' => 341,
			'complex_declarator' => 340
		}
	},
	{#State 176
		DEFAULT => -190
	},
	{#State 177
		DEFAULT => -209
	},
	{#State 178
		DEFAULT => -360
	},
	{#State 179
		DEFAULT => -214
	},
	{#State 180
		ACTIONS => {
			'error' => 345,
			'IDENTIFIER' => 346
		}
	},
	{#State 181
		DEFAULT => -216
	},
	{#State 182
		DEFAULT => -217
	},
	{#State 183
		ACTIONS => {
			'error' => 347,
			'IDENTIFIER' => 348
		}
	},
	{#State 184
		DEFAULT => -201
	},
	{#State 185
		DEFAULT => -199
	},
	{#State 186
		ACTIONS => {
			'error' => 350,
			"<" => 349
		}
	},
	{#State 187
		DEFAULT => -211
	},
	{#State 188
		DEFAULT => -210
	},
	{#State 189
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -202
	},
	{#State 190
		DEFAULT => -206
	},
	{#State 191
		DEFAULT => -213
	},
	{#State 192
		DEFAULT => -200
	},
	{#State 193
		DEFAULT => -218
	},
	{#State 194
		DEFAULT => -196
	},
	{#State 195
		DEFAULT => -248
	},
	{#State 196
		DEFAULT => -249
	},
	{#State 197
		DEFAULT => -207
	},
	{#State 198
		DEFAULT => -204
	},
	{#State 199
		DEFAULT => -212
	},
	{#State 200
		DEFAULT => -198
	},
	{#State 201
		DEFAULT => -215
	},
	{#State 202
		ACTIONS => {
			'PRIVATE' => 262,
			'ONEWAY' => 219,
			'FACTORY' => 268,
			'UNSIGNED' => -324,
			'SHORT' => -324,
			'WCHAR' => -324,
			'error' => 351,
			'CONST' => 13,
			'EXCEPTION' => 50,
			"}" => 352,
			'FLOAT' => -324,
			'OCTET' => -324,
			'ENUM' => 16,
			'ANY' => -324,
			'CHAR' => -324,
			'OBJECT' => -324,
			'NATIVE' => 53,
			'VALUEBASE' => -324,
			'VOID' => -324,
			'STRUCT' => 23,
			'DOUBLE' => -324,
			'TYPEID' => 56,
			'LONG' => -324,
			'STRING' => -324,
			"::" => -324,
			'TYPEPREFIX' => 58,
			'WSTRING' => -324,
			'BOOLEAN' => -324,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -324,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235,
			'PUBLIC' => 265
		},
		GOTOS => {
			'init_header_param' => 261,
			'const_dcl' => 230,
			'op_mod' => 220,
			'value_elements' => 353,
			'except_dcl' => 226,
			'state_member' => 267,
			'attr_spec' => 221,
			'op_attribute' => 222,
			'state_mod' => 263,
			'value_element' => 264,
			'readonly_attr_spec' => 223,
			'type_id_dcl' => 227,
			'export' => 273,
			'init_header' => 269,
			'struct_type' => 26,
			'op_header' => 233,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 236,
			'enum_type' => 44,
			'init_dcl' => 266,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'type_dcl' => 237,
			'union_header' => 49
		}
	},
	{#State 203
		DEFAULT => -13
	},
	{#State 204
		DEFAULT => -24
	},
	{#State 205
		ACTIONS => {
			'error' => 354,
			'IDENTIFIER' => 355
		}
	},
	{#State 206
		ACTIONS => {
			'error' => 356,
			'IDENTIFIER' => 357
		}
	},
	{#State 207
		DEFAULT => -102
	},
	{#State 208
		DEFAULT => -9
	},
	{#State 209
		DEFAULT => -20
	},
	{#State 210
		DEFAULT => -8
	},
	{#State 211
		DEFAULT => -496
	},
	{#State 212
		ACTIONS => {
			"{" => -494,
			":" => 217,
			'SUPPORTS' => 215
		},
		DEFAULT => -490,
		GOTOS => {
			'supported_interface_spec' => 218,
			'value_inheritance_spec' => 358
		}
	},
	{#State 213
		DEFAULT => -89
	},
	{#State 214
		ACTIONS => {
			"{" => -87,
			":" => 217,
			'SUPPORTS' => 215
		},
		DEFAULT => -82,
		GOTOS => {
			'supported_interface_spec' => 218,
			'value_inheritance_spec' => 359
		}
	},
	{#State 215
		ACTIONS => {
			'error' => 362,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 361,
			'interface_name' => 363,
			'interface_names' => 360
		}
	},
	{#State 216
		DEFAULT => -502
	},
	{#State 217
		ACTIONS => {
			'TRUNCATABLE' => 365
		},
		DEFAULT => -108,
		GOTOS => {
			'inheritance_mod' => 364
		}
	},
	{#State 218
		DEFAULT => -106
	},
	{#State 219
		DEFAULT => -325
	},
	{#State 220
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'VALUEBASE' => 178,
			'VOID' => 371,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'WCHAR' => 84,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'wide_string_type' => 367,
			'integer_type' => 198,
			'boolean_type' => 197,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 368,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'signed_short_int' => 93,
			'string_type' => 369,
			'op_type_spec' => 372,
			'base_type_spec' => 370,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'unsigned_long_int' => 113,
			'param_type_spec' => 366,
			'unsigned_short_int' => 105,
			'signed_longlong_int' => 88
		}
	},
	{#State 221
		DEFAULT => -309
	},
	{#State 222
		DEFAULT => -323
	},
	{#State 223
		DEFAULT => -308
	},
	{#State 224
		ACTIONS => {
			'error' => 374,
			";" => 373
		}
	},
	{#State 225
		ACTIONS => {
			'error' => 376,
			";" => 375
		}
	},
	{#State 226
		ACTIONS => {
			'error' => 378,
			";" => 377
		}
	},
	{#State 227
		ACTIONS => {
			'error' => 380,
			";" => 379
		}
	},
	{#State 228
		ACTIONS => {
			"}" => 381
		}
	},
	{#State 229
		DEFAULT => -84
	},
	{#State 230
		ACTIONS => {
			'error' => 383,
			";" => 382
		}
	},
	{#State 231
		ACTIONS => {
			"}" => 384
		}
	},
	{#State 232
		ACTIONS => {
			'ONEWAY' => 219,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235,
			'CONST' => 13,
			'EXCEPTION' => 50,
			"}" => -51,
			'ENUM' => 16
		},
		DEFAULT => -324,
		GOTOS => {
			'const_dcl' => 230,
			'op_mod' => 220,
			'except_dcl' => 226,
			'attr_spec' => 221,
			'op_attribute' => 222,
			'readonly_attr_spec' => 223,
			'exports' => 385,
			'type_id_dcl' => 227,
			'export' => 232,
			'struct_type' => 26,
			'op_header' => 233,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 236,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'type_dcl' => 237,
			'union_header' => 49
		}
	},
	{#State 233
		ACTIONS => {
			'error' => 387,
			"(" => 386
		},
		GOTOS => {
			'parameter_dcls' => 388
		}
	},
	{#State 234
		ACTIONS => {
			'error' => 389,
			'ATTRIBUTE' => 390
		}
	},
	{#State 235
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'VALUEBASE' => 178,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'WCHAR' => 84,
			'error' => 392,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'wide_string_type' => 367,
			'integer_type' => 198,
			'boolean_type' => 197,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 368,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'signed_short_int' => 93,
			'string_type' => 369,
			'base_type_spec' => 370,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'unsigned_long_int' => 113,
			'param_type_spec' => 391,
			'unsigned_short_int' => 105,
			'signed_longlong_int' => 88
		}
	},
	{#State 236
		ACTIONS => {
			'error' => 394,
			";" => 393
		}
	},
	{#State 237
		ACTIONS => {
			'error' => 396,
			";" => 395
		}
	},
	{#State 238
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 344
		},
		GOTOS => {
			'declarators' => 397,
			'declarator' => 342,
			'simple_declarator' => 343,
			'array_declarator' => 341,
			'complex_declarator' => 340
		}
	},
	{#State 239
		ACTIONS => {
			"}" => 398
		}
	},
	{#State 240
		ACTIONS => {
			"}" => 399
		}
	},
	{#State 241
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'FIXED' => 186,
			'VALUEBASE' => 178,
			'SEQUENCE' => 172,
			'STRUCT' => 180,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'UNION' => 183,
			'WCHAR' => 84,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ENUM' => 16,
			'ANY' => 195
		},
		DEFAULT => -254,
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 189,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'type_spec' => 238,
			'string_type' => 191,
			'struct_header' => 10,
			'base_type_spec' => 192,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'enum_type' => 193,
			'enum_header' => 47,
			'member_list' => 400,
			'unsigned_short_int' => 105,
			'union_header' => 49,
			'signed_longlong_int' => 88,
			'wide_string_type' => 179,
			'boolean_type' => 197,
			'integer_type' => 198,
			'signed_short_int' => 93,
			'member' => 241,
			'struct_type' => 181,
			'union_type' => 182,
			'sequence_type' => 199,
			'unsigned_long_int' => 113,
			'template_type_spec' => 184,
			'constr_type_spec' => 185,
			'simple_type_spec' => 200,
			'fixed_pt_type' => 201
		}
	},
	{#State 242
		DEFAULT => -74
	},
	{#State 243
		DEFAULT => -73
	},
	{#State 244
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 416,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'primary_expr' => 422,
			'and_expr' => 423,
			'scoped_name' => 414,
			'positive_int_const' => 415,
			'wide_string_literal' => 402,
			'boolean_literal' => 404,
			'mult_expr' => 425,
			'const_exp' => 405,
			'or_expr' => 406,
			'unary_expr' => 427,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 245
		ACTIONS => {
			'error' => 430,
			'IDENTIFIER' => 431
		}
	},
	{#State 246
		DEFAULT => -241
	},
	{#State 247
		ACTIONS => {
			'LONG' => 432
		},
		DEFAULT => -242
	},
	{#State 248
		DEFAULT => -229
	},
	{#State 249
		DEFAULT => -237
	},
	{#State 250
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 434,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'primary_expr' => 422,
			'and_expr' => 423,
			'scoped_name' => 414,
			'positive_int_const' => 433,
			'wide_string_literal' => 402,
			'boolean_literal' => 404,
			'mult_expr' => 425,
			'const_exp' => 405,
			'or_expr' => 406,
			'unary_expr' => 427,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 251
		DEFAULT => -137
	},
	{#State 252
		ACTIONS => {
			'error' => 435,
			"=" => 436
		}
	},
	{#State 253
		ACTIONS => {
			"{" => -49
		},
		DEFAULT => -43
	},
	{#State 254
		ACTIONS => {
			"{" => -47,
			":" => 438
		},
		DEFAULT => -42,
		GOTOS => {
			'interface_inheritance_spec' => 437
		}
	},
	{#State 255
		ACTIONS => {
			"}" => 439
		}
	},
	{#State 256
		DEFAULT => -39
	},
	{#State 257
		DEFAULT => -50
	},
	{#State 258
		ACTIONS => {
			"}" => 440
		}
	},
	{#State 259
		ACTIONS => {
			"::" => 245,
			'PRIMARYKEY' => 441
		},
		DEFAULT => -449,
		GOTOS => {
			'primary_key_spec' => 442
		}
	},
	{#State 260
		DEFAULT => -450
	},
	{#State 261
		ACTIONS => {
			'error' => 445,
			'RAISES' => 444,
			";" => 443
		},
		GOTOS => {
			'raises_expr' => 446
		}
	},
	{#State 262
		DEFAULT => -118
	},
	{#State 263
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'FIXED' => 186,
			'VALUEBASE' => 178,
			'SEQUENCE' => 172,
			'STRUCT' => 180,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'UNION' => 183,
			'WCHAR' => 84,
			'error' => 448,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ENUM' => 16,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 189,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'type_spec' => 447,
			'string_type' => 191,
			'struct_header' => 10,
			'base_type_spec' => 192,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'enum_type' => 193,
			'enum_header' => 47,
			'unsigned_short_int' => 105,
			'union_header' => 49,
			'signed_longlong_int' => 88,
			'wide_string_type' => 179,
			'boolean_type' => 197,
			'integer_type' => 198,
			'signed_short_int' => 93,
			'struct_type' => 181,
			'union_type' => 182,
			'sequence_type' => 199,
			'unsigned_long_int' => 113,
			'template_type_spec' => 184,
			'constr_type_spec' => 185,
			'simple_type_spec' => 200,
			'fixed_pt_type' => 201
		}
	},
	{#State 264
		ACTIONS => {
			'PRIVATE' => 262,
			'ONEWAY' => 219,
			'FACTORY' => 268,
			'CONST' => 13,
			'EXCEPTION' => 50,
			"}" => -94,
			'ENUM' => 16,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235,
			'PUBLIC' => 265
		},
		DEFAULT => -324,
		GOTOS => {
			'init_header_param' => 261,
			'const_dcl' => 230,
			'op_mod' => 220,
			'value_elements' => 449,
			'except_dcl' => 226,
			'state_member' => 267,
			'attr_spec' => 221,
			'op_attribute' => 222,
			'state_mod' => 263,
			'value_element' => 264,
			'readonly_attr_spec' => 223,
			'type_id_dcl' => 227,
			'export' => 273,
			'init_header' => 269,
			'struct_type' => 26,
			'op_header' => 233,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 236,
			'enum_type' => 44,
			'init_dcl' => 266,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'type_dcl' => 237,
			'union_header' => 49
		}
	},
	{#State 265
		DEFAULT => -117
	},
	{#State 266
		DEFAULT => -114
	},
	{#State 267
		DEFAULT => -113
	},
	{#State 268
		ACTIONS => {
			'error' => 450,
			'IDENTIFIER' => 451
		}
	},
	{#State 269
		ACTIONS => {
			'error' => 453,
			"(" => 452
		}
	},
	{#State 270
		ACTIONS => {
			"}" => 454
		}
	},
	{#State 271
		DEFAULT => -91
	},
	{#State 272
		ACTIONS => {
			"}" => 455
		}
	},
	{#State 273
		DEFAULT => -112
	},
	{#State 274
		ACTIONS => {
			"}" => 456
		}
	},
	{#State 275
		DEFAULT => -491
	},
	{#State 276
		ACTIONS => {
			"}" => 457
		}
	},
	{#State 277
		ACTIONS => {
			"}" => 458
		}
	},
	{#State 278
		ACTIONS => {
			"}" => 459
		}
	},
	{#State 279
		DEFAULT => -310
	},
	{#State 280
		ACTIONS => {
			'SUPPORTS' => 215
		},
		DEFAULT => -452,
		GOTOS => {
			'supported_interface_spec' => 460
		}
	},
	{#State 281
		ACTIONS => {
			'error' => 462,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 461
		}
	},
	{#State 282
		DEFAULT => -453
	},
	{#State 283
		ACTIONS => {
			'error' => 464,
			";" => 463
		}
	},
	{#State 284
		DEFAULT => -413
	},
	{#State 285
		ACTIONS => {
			'error' => 466,
			";" => 465
		}
	},
	{#State 286
		ACTIONS => {
			'PUBLISHES' => 296,
			'USES' => 288,
			'READONLY' => 234,
			'PROVIDES' => 295,
			'ATTRIBUTE' => 235,
			'EMITS' => 291,
			'CONSUMES' => 298
		},
		DEFAULT => -414,
		GOTOS => {
			'consumes_dcl' => 283,
			'emits_dcl' => 290,
			'attr_spec' => 221,
			'provides_dcl' => 287,
			'readonly_attr_spec' => 223,
			'component_exports' => 467,
			'attr_dcl' => 289,
			'publishes_dcl' => 285,
			'uses_dcl' => 297,
			'component_export' => 286
		}
	},
	{#State 287
		ACTIONS => {
			'error' => 469,
			";" => 468
		}
	},
	{#State 288
		ACTIONS => {
			'MULTIPLE' => 471
		},
		DEFAULT => -437,
		GOTOS => {
			'uses_mod' => 470
		}
	},
	{#State 289
		ACTIONS => {
			'error' => 473,
			";" => 472
		}
	},
	{#State 290
		ACTIONS => {
			'error' => 475,
			";" => 474
		}
	},
	{#State 291
		ACTIONS => {
			'error' => 477,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 476
		}
	},
	{#State 292
		ACTIONS => {
			"}" => 478
		}
	},
	{#State 293
		ACTIONS => {
			"}" => 479
		}
	},
	{#State 294
		DEFAULT => -401
	},
	{#State 295
		ACTIONS => {
			'error' => 482,
			'OBJECT' => 483,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 481,
			'interface_type' => 480
		}
	},
	{#State 296
		ACTIONS => {
			'error' => 485,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 484
		}
	},
	{#State 297
		ACTIONS => {
			'error' => 487,
			";" => 486
		}
	},
	{#State 298
		ACTIONS => {
			'error' => 489,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 488
		}
	},
	{#State 299
		ACTIONS => {
			'RAISES' => 444
		},
		DEFAULT => -471,
		GOTOS => {
			'raises_expr' => 490
		}
	},
	{#State 300
		ACTIONS => {
			'error' => 491,
			'IDENTIFIER' => 492
		}
	},
	{#State 301
		ACTIONS => {
			'ONEWAY' => 219,
			'FACTORY' => 305,
			'CONST' => 13,
			"}" => -463,
			'EXCEPTION' => 50,
			'ENUM' => 16,
			'FINDER' => 300,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 234,
			'ATTRIBUTE' => 235
		},
		DEFAULT => -324,
		GOTOS => {
			'const_dcl' => 230,
			'op_mod' => 220,
			'except_dcl' => 226,
			'attr_spec' => 221,
			'factory_header_param' => 299,
			'home_exports' => 493,
			'home_export' => 301,
			'op_attribute' => 222,
			'readonly_attr_spec' => 223,
			'finder_dcl' => 303,
			'type_id_dcl' => 227,
			'export' => 308,
			'struct_type' => 26,
			'finder_header' => 309,
			'exception_header' => 27,
			'union_type' => 28,
			'op_header' => 233,
			'struct_header' => 10,
			'factory_dcl' => 304,
			'enum_type' => 44,
			'finder_header_param' => 310,
			'op_dcl' => 236,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 224,
			'attr_dcl' => 225,
			'union_header' => 49,
			'type_dcl' => 237,
			'factory_header' => 311
		}
	},
	{#State 302
		ACTIONS => {
			"}" => 494
		}
	},
	{#State 303
		ACTIONS => {
			'error' => 496,
			";" => 495
		}
	},
	{#State 304
		ACTIONS => {
			'error' => 498,
			";" => 497
		}
	},
	{#State 305
		ACTIONS => {
			'error' => 499,
			'IDENTIFIER' => 500
		}
	},
	{#State 306
		ACTIONS => {
			"}" => 501
		}
	},
	{#State 307
		DEFAULT => -460
	},
	{#State 308
		DEFAULT => -465
	},
	{#State 309
		ACTIONS => {
			'error' => 503,
			"(" => 502
		}
	},
	{#State 310
		ACTIONS => {
			'RAISES' => 444
		},
		DEFAULT => -479,
		GOTOS => {
			'raises_expr' => 504
		}
	},
	{#State 311
		ACTIONS => {
			'error' => 506,
			"(" => 505
		}
	},
	{#State 312
		ACTIONS => {
			"}" => 507
		}
	},
	{#State 313
		ACTIONS => {
			"}" => 508
		}
	},
	{#State 314
		DEFAULT => -33
	},
	{#State 315
		DEFAULT => -34
	},
	{#State 316
		DEFAULT => -83
	},
	{#State 317
		DEFAULT => -98
	},
	{#State 318
		ACTIONS => {
			";" => 509,
			"," => 510
		},
		DEFAULT => -287
	},
	{#State 319
		ACTIONS => {
			"}" => 511
		}
	},
	{#State 320
		ACTIONS => {
			"}" => 512
		}
	},
	{#State 321
		DEFAULT => -291
	},
	{#State 322
		ACTIONS => {
			'SHORT' => 103,
			'CHAR' => 89,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'error' => 517,
			'LONG' => 520,
			"::" => 92,
			'ENUM' => 16,
			'UNSIGNED' => 101
		},
		GOTOS => {
			'switch_type_spec' => 514,
			'unsigned_int' => 80,
			'signed_int' => 97,
			'integer_type' => 519,
			'boolean_type' => 518,
			'unsigned_longlong_int' => 85,
			'char_type' => 513,
			'enum_type' => 516,
			'unsigned_long_int' => 113,
			'enum_header' => 47,
			'scoped_name' => 515,
			'unsigned_short_int' => 105,
			'signed_long_int' => 100,
			'signed_short_int' => 93,
			'signed_longlong_int' => 88
		}
	},
	{#State 323
		DEFAULT => -262
	},
	{#State 324
		DEFAULT => -225
	},
	{#State 325
		DEFAULT => -224
	},
	{#State 326
		ACTIONS => {
			'SUPPORTS' => 215
		},
		DEFAULT => -405,
		GOTOS => {
			'supported_interface_spec' => 521
		}
	},
	{#State 327
		ACTIONS => {
			'error' => 523,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 522
		}
	},
	{#State 328
		DEFAULT => -406
	},
	{#State 329
		DEFAULT => -370
	},
	{#State 330
		DEFAULT => -371
	},
	{#State 331
		DEFAULT => -365
	},
	{#State 332
		DEFAULT => -366
	},
	{#State 333
		DEFAULT => -184
	},
	{#State 334
		DEFAULT => -375
	},
	{#State 335
		DEFAULT => -373
	},
	{#State 336
		DEFAULT => -374
	},
	{#State 337
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'FIXED' => 186,
			'VALUEBASE' => 178,
			'SEQUENCE' => 172,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'WCHAR' => 84,
			'error' => 524,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'wide_string_type' => 179,
			'integer_type' => 198,
			'boolean_type' => 197,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 189,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'signed_short_int' => 93,
			'string_type' => 191,
			'sequence_type' => 199,
			'base_type_spec' => 192,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'unsigned_long_int' => 113,
			'template_type_spec' => 184,
			'unsigned_short_int' => 105,
			'simple_type_spec' => 525,
			'fixed_pt_type' => 201,
			'signed_longlong_int' => 88
		}
	},
	{#State 338
		DEFAULT => -296
	},
	{#State 339
		DEFAULT => -197
	},
	{#State 340
		DEFAULT => -222
	},
	{#State 341
		DEFAULT => -226
	},
	{#State 342
		ACTIONS => {
			"," => 526
		},
		DEFAULT => -219
	},
	{#State 343
		DEFAULT => -221
	},
	{#State 344
		ACTIONS => {
			"[" => 529
		},
		DEFAULT => -223,
		GOTOS => {
			'fixed_array_sizes' => 528,
			'fixed_array_size' => 527
		}
	},
	{#State 345
		DEFAULT => -253
	},
	{#State 346
		DEFAULT => -252
	},
	{#State 347
		DEFAULT => -264
	},
	{#State 348
		DEFAULT => -263
	},
	{#State 349
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 531,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'primary_expr' => 422,
			'and_expr' => 423,
			'scoped_name' => 414,
			'positive_int_const' => 530,
			'wide_string_literal' => 402,
			'boolean_literal' => 404,
			'mult_expr' => 425,
			'const_exp' => 405,
			'or_expr' => 406,
			'unary_expr' => 427,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 350
		DEFAULT => -358
	},
	{#State 351
		ACTIONS => {
			"}" => 532
		}
	},
	{#State 352
		DEFAULT => -497
	},
	{#State 353
		ACTIONS => {
			"}" => 533
		}
	},
	{#State 354
		DEFAULT => -505
	},
	{#State 355
		ACTIONS => {
			":" => 217,
			'SUPPORTS' => 215
		},
		DEFAULT => -501,
		GOTOS => {
			'supported_interface_spec' => 218,
			'value_inheritance_spec' => 534
		}
	},
	{#State 356
		DEFAULT => -101
	},
	{#State 357
		ACTIONS => {
			":" => 217,
			'SUPPORTS' => 215
		},
		DEFAULT => -97,
		GOTOS => {
			'supported_interface_spec' => 218,
			'value_inheritance_spec' => 535
		}
	},
	{#State 358
		DEFAULT => -495
	},
	{#State 359
		DEFAULT => -88
	},
	{#State 360
		DEFAULT => -409
	},
	{#State 361
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -71
	},
	{#State 362
		DEFAULT => -410
	},
	{#State 363
		ACTIONS => {
			"," => 536
		},
		DEFAULT => -69
	},
	{#State 364
		ACTIONS => {
			'error' => 539,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 538,
			'value_name' => 537,
			'value_names' => 540
		}
	},
	{#State 365
		DEFAULT => -107
	},
	{#State 366
		DEFAULT => -326
	},
	{#State 367
		DEFAULT => -353
	},
	{#State 368
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -354
	},
	{#State 369
		DEFAULT => -352
	},
	{#State 370
		DEFAULT => -351
	},
	{#State 371
		DEFAULT => -327
	},
	{#State 372
		ACTIONS => {
			'error' => 541,
			'IDENTIFIER' => 542
		}
	},
	{#State 373
		DEFAULT => -59
	},
	{#State 374
		DEFAULT => -66
	},
	{#State 375
		DEFAULT => -56
	},
	{#State 376
		DEFAULT => -63
	},
	{#State 377
		DEFAULT => -55
	},
	{#State 378
		DEFAULT => -62
	},
	{#State 379
		DEFAULT => -58
	},
	{#State 380
		DEFAULT => -65
	},
	{#State 381
		DEFAULT => -86
	},
	{#State 382
		DEFAULT => -54
	},
	{#State 383
		DEFAULT => -61
	},
	{#State 384
		DEFAULT => -85
	},
	{#State 385
		DEFAULT => -52
	},
	{#State 386
		ACTIONS => {
			'error' => 548,
			")" => 546,
			'OUT' => 547,
			'INOUT' => 544,
			'IN' => 543
		},
		GOTOS => {
			'param_dcl' => 550,
			'param_dcls' => 549,
			'param_attribute' => 545
		}
	},
	{#State 387
		DEFAULT => -320
	},
	{#State 388
		ACTIONS => {
			'CONTEXT' => 551,
			'RAISES' => 444
		},
		DEFAULT => -316,
		GOTOS => {
			'context_expr' => 553,
			'raises_expr' => 552
		}
	},
	{#State 389
		DEFAULT => -379
	},
	{#State 390
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'VALUEBASE' => 178,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'WCHAR' => 84,
			'error' => 555,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'wide_string_type' => 367,
			'integer_type' => 198,
			'boolean_type' => 197,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 368,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'signed_short_int' => 93,
			'string_type' => 369,
			'base_type_spec' => 370,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'unsigned_long_int' => 113,
			'param_type_spec' => 554,
			'unsigned_short_int' => 105,
			'signed_longlong_int' => 88
		}
	},
	{#State 391
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'attr_declarator' => 558,
			'simple_declarator' => 557,
			'simple_declarators' => 556
		}
	},
	{#State 392
		DEFAULT => -385
	},
	{#State 393
		DEFAULT => -57
	},
	{#State 394
		DEFAULT => -64
	},
	{#State 395
		DEFAULT => -53
	},
	{#State 396
		DEFAULT => -60
	},
	{#State 397
		ACTIONS => {
			'error' => 560,
			";" => 559
		}
	},
	{#State 398
		DEFAULT => -250
	},
	{#State 399
		DEFAULT => -251
	},
	{#State 400
		DEFAULT => -255
	},
	{#State 401
		DEFAULT => -179
	},
	{#State 402
		DEFAULT => -177
	},
	{#State 403
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 562,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 425,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'const_exp' => 561,
			'and_expr' => 423,
			'or_expr' => 406,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'wide_string_literal' => 402,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 404
		DEFAULT => -182
	},
	{#State 405
		DEFAULT => -189
	},
	{#State 406
		ACTIONS => {
			"|" => 563
		},
		DEFAULT => -149
	},
	{#State 407
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 407
		},
		DEFAULT => -185,
		GOTOS => {
			'wide_string_literal' => 564
		}
	},
	{#State 408
		DEFAULT => -187
	},
	{#State 409
		DEFAULT => -176
	},
	{#State 410
		DEFAULT => -181
	},
	{#State 411
		DEFAULT => -180
	},
	{#State 412
		DEFAULT => -168
	},
	{#State 413
		DEFAULT => -178
	},
	{#State 414
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -171
	},
	{#State 415
		ACTIONS => {
			">" => 565
		}
	},
	{#State 416
		ACTIONS => {
			">" => 566
		}
	},
	{#State 417
		ACTIONS => {
			"^" => 567
		},
		DEFAULT => -150
	},
	{#State 418
		ACTIONS => {
			"<<" => 568,
			">>" => 569
		},
		DEFAULT => -154
	},
	{#State 419
		DEFAULT => -188
	},
	{#State 420
		DEFAULT => -172
	},
	{#State 421
		ACTIONS => {
			"+" => 571,
			"-" => 570
		},
		DEFAULT => -156
	},
	{#State 422
		DEFAULT => -167
	},
	{#State 423
		ACTIONS => {
			"&" => 572
		},
		DEFAULT => -152
	},
	{#State 424
		DEFAULT => -175
	},
	{#State 425
		ACTIONS => {
			"%" => 573,
			"*" => 574,
			"/" => 575
		},
		DEFAULT => -159
	},
	{#State 426
		DEFAULT => -169
	},
	{#State 427
		DEFAULT => -162
	},
	{#State 428
		DEFAULT => -170
	},
	{#State 429
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			"::" => 92,
			'STRING_LITERAL' => 167,
			'FALSE' => 419,
			'CHARACTER_LITERAL' => 413,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			'TRUE' => 408,
			"(" => 403
		},
		GOTOS => {
			'scoped_name' => 414,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 576,
			'literal' => 420,
			'wide_string_literal' => 402
		}
	},
	{#State 430
		DEFAULT => -76
	},
	{#State 431
		DEFAULT => -75
	},
	{#State 432
		DEFAULT => -243
	},
	{#State 433
		ACTIONS => {
			">" => 577
		}
	},
	{#State 434
		ACTIONS => {
			">" => 578
		}
	},
	{#State 435
		DEFAULT => -136
	},
	{#State 436
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 580,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 425,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'const_exp' => 579,
			'and_expr' => 423,
			'or_expr' => 406,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'wide_string_literal' => 402,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 437
		DEFAULT => -48
	},
	{#State 438
		ACTIONS => {
			'error' => 582,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 361,
			'interface_name' => 363,
			'interface_names' => 581
		}
	},
	{#State 439
		DEFAULT => -41
	},
	{#State 440
		DEFAULT => -40
	},
	{#State 441
		ACTIONS => {
			'error' => 584,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 583
		}
	},
	{#State 442
		DEFAULT => -448
	},
	{#State 443
		DEFAULT => -121
	},
	{#State 444
		ACTIONS => {
			'error' => 586,
			"(" => 585
		}
	},
	{#State 445
		DEFAULT => -122
	},
	{#State 446
		ACTIONS => {
			'error' => 588,
			";" => 587
		}
	},
	{#State 447
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 344
		},
		GOTOS => {
			'declarators' => 589,
			'declarator' => 342,
			'simple_declarator' => 343,
			'array_declarator' => 341,
			'complex_declarator' => 340
		}
	},
	{#State 448
		ACTIONS => {
			";" => 590
		}
	},
	{#State 449
		DEFAULT => -95
	},
	{#State 450
		DEFAULT => -128
	},
	{#State 451
		DEFAULT => -127
	},
	{#State 452
		ACTIONS => {
			'error' => 596,
			")" => 592,
			'IN' => 591
		},
		GOTOS => {
			'init_param_decls' => 594,
			'init_param_attribute' => 593,
			'init_param_decl' => 595
		}
	},
	{#State 453
		DEFAULT => -126
	},
	{#State 454
		DEFAULT => -93
	},
	{#State 455
		DEFAULT => -92
	},
	{#State 456
		DEFAULT => -493
	},
	{#State 457
		DEFAULT => -492
	},
	{#State 458
		DEFAULT => -311
	},
	{#State 459
		DEFAULT => -312
	},
	{#State 460
		DEFAULT => -451
	},
	{#State 461
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -456
	},
	{#State 462
		DEFAULT => -457
	},
	{#State 463
		DEFAULT => -420
	},
	{#State 464
		DEFAULT => -426
	},
	{#State 465
		DEFAULT => -419
	},
	{#State 466
		DEFAULT => -425
	},
	{#State 467
		DEFAULT => -415
	},
	{#State 468
		DEFAULT => -416
	},
	{#State 469
		DEFAULT => -422
	},
	{#State 470
		ACTIONS => {
			'error' => 598,
			'OBJECT' => 483,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 481,
			'interface_type' => 597
		}
	},
	{#State 471
		DEFAULT => -436
	},
	{#State 472
		DEFAULT => -421
	},
	{#State 473
		DEFAULT => -427
	},
	{#State 474
		DEFAULT => -418
	},
	{#State 475
		DEFAULT => -424
	},
	{#State 476
		ACTIONS => {
			'error' => 599,
			'IDENTIFIER' => 600,
			"::" => 245
		}
	},
	{#State 477
		DEFAULT => -440
	},
	{#State 478
		DEFAULT => -402
	},
	{#State 479
		DEFAULT => -403
	},
	{#State 480
		ACTIONS => {
			'error' => 601,
			'IDENTIFIER' => 602
		}
	},
	{#State 481
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -431
	},
	{#State 482
		DEFAULT => -430
	},
	{#State 483
		DEFAULT => -432
	},
	{#State 484
		ACTIONS => {
			'error' => 603,
			'IDENTIFIER' => 604,
			"::" => 245
		}
	},
	{#State 485
		DEFAULT => -443
	},
	{#State 486
		DEFAULT => -417
	},
	{#State 487
		DEFAULT => -423
	},
	{#State 488
		ACTIONS => {
			'error' => 605,
			'IDENTIFIER' => 606,
			"::" => 245
		}
	},
	{#State 489
		DEFAULT => -446
	},
	{#State 490
		DEFAULT => -470
	},
	{#State 491
		DEFAULT => -485
	},
	{#State 492
		DEFAULT => -484
	},
	{#State 493
		DEFAULT => -464
	},
	{#State 494
		DEFAULT => -461
	},
	{#State 495
		DEFAULT => -467
	},
	{#State 496
		DEFAULT => -469
	},
	{#State 497
		DEFAULT => -466
	},
	{#State 498
		DEFAULT => -468
	},
	{#State 499
		DEFAULT => -477
	},
	{#State 500
		DEFAULT => -476
	},
	{#State 501
		DEFAULT => -462
	},
	{#State 502
		ACTIONS => {
			'error' => 609,
			")" => 607,
			'IN' => 591
		},
		GOTOS => {
			'init_param_decls' => 608,
			'init_param_attribute' => 593,
			'init_param_decl' => 595
		}
	},
	{#State 503
		DEFAULT => -483
	},
	{#State 504
		DEFAULT => -478
	},
	{#State 505
		ACTIONS => {
			'error' => 612,
			")" => 610,
			'IN' => 591
		},
		GOTOS => {
			'init_param_decls' => 611,
			'init_param_attribute' => 593,
			'init_param_decl' => 595
		}
	},
	{#State 506
		DEFAULT => -475
	},
	{#State 507
		DEFAULT => -31
	},
	{#State 508
		DEFAULT => -32
	},
	{#State 509
		DEFAULT => -290
	},
	{#State 510
		ACTIONS => {
			'IDENTIFIER' => 321
		},
		DEFAULT => -289,
		GOTOS => {
			'enumerators' => 613,
			'enumerator' => 318
		}
	},
	{#State 511
		DEFAULT => -282
	},
	{#State 512
		DEFAULT => -283
	},
	{#State 513
		DEFAULT => -266
	},
	{#State 514
		ACTIONS => {
			")" => 614
		}
	},
	{#State 515
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -269
	},
	{#State 516
		DEFAULT => -268
	},
	{#State 517
		ACTIONS => {
			")" => 615
		}
	},
	{#State 518
		DEFAULT => -267
	},
	{#State 519
		DEFAULT => -265
	},
	{#State 520
		ACTIONS => {
			'LONG' => 249
		},
		DEFAULT => -236
	},
	{#State 521
		DEFAULT => -404
	},
	{#State 522
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -411
	},
	{#State 523
		DEFAULT => -412
	},
	{#State 524
		ACTIONS => {
			">" => 616
		}
	},
	{#State 525
		ACTIONS => {
			">" => 618,
			"," => 617
		}
	},
	{#State 526
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 344
		},
		GOTOS => {
			'declarators' => 619,
			'declarator' => 342,
			'simple_declarator' => 343,
			'array_declarator' => 341,
			'complex_declarator' => 340
		}
	},
	{#State 527
		ACTIONS => {
			"[" => 529
		},
		DEFAULT => -304,
		GOTOS => {
			'fixed_array_sizes' => 620,
			'fixed_array_size' => 527
		}
	},
	{#State 528
		DEFAULT => -303
	},
	{#State 529
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 622,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'primary_expr' => 422,
			'and_expr' => 423,
			'scoped_name' => 414,
			'positive_int_const' => 621,
			'wide_string_literal' => 402,
			'boolean_literal' => 404,
			'mult_expr' => 425,
			'const_exp' => 405,
			'or_expr' => 406,
			'unary_expr' => 427,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 530
		ACTIONS => {
			"," => 623
		}
	},
	{#State 531
		ACTIONS => {
			">" => 624
		}
	},
	{#State 532
		DEFAULT => -499
	},
	{#State 533
		DEFAULT => -498
	},
	{#State 534
		DEFAULT => -503
	},
	{#State 535
		DEFAULT => -99
	},
	{#State 536
		ACTIONS => {
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 361,
			'interface_name' => 363,
			'interface_names' => 625
		}
	},
	{#State 537
		ACTIONS => {
			"," => 626
		},
		DEFAULT => -109
	},
	{#State 538
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -111
	},
	{#State 539
		DEFAULT => -105
	},
	{#State 540
		ACTIONS => {
			'SUPPORTS' => 215
		},
		DEFAULT => -103,
		GOTOS => {
			'supported_interface_spec' => 627
		}
	},
	{#State 541
		DEFAULT => -322
	},
	{#State 542
		DEFAULT => -321
	},
	{#State 543
		DEFAULT => -337
	},
	{#State 544
		DEFAULT => -339
	},
	{#State 545
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'VALUEBASE' => 178,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'WCHAR' => 84,
			'error' => 629,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'wide_string_type' => 367,
			'integer_type' => 198,
			'boolean_type' => 197,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 368,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'signed_short_int' => 93,
			'string_type' => 369,
			'base_type_spec' => 370,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'unsigned_long_int' => 113,
			'param_type_spec' => 628,
			'unsigned_short_int' => 105,
			'signed_longlong_int' => 88
		}
	},
	{#State 546
		DEFAULT => -329
	},
	{#State 547
		DEFAULT => -338
	},
	{#State 548
		ACTIONS => {
			")" => 630
		}
	},
	{#State 549
		ACTIONS => {
			")" => 631
		}
	},
	{#State 550
		ACTIONS => {
			";" => 632,
			"," => 633
		},
		DEFAULT => -331
	},
	{#State 551
		ACTIONS => {
			'error' => 635,
			"(" => 634
		}
	},
	{#State 552
		ACTIONS => {
			'CONTEXT' => 551
		},
		DEFAULT => -317,
		GOTOS => {
			'context_expr' => 636
		}
	},
	{#State 553
		DEFAULT => -319
	},
	{#State 554
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'simple_declarator' => 639,
			'simple_declarators' => 638,
			'readonly_attr_declarator' => 637
		}
	},
	{#State 555
		DEFAULT => -378
	},
	{#State 556
		DEFAULT => -387
	},
	{#State 557
		ACTIONS => {
			'GETRAISES' => 644,
			'SETRAISES' => 643,
			"," => 641
		},
		DEFAULT => -382,
		GOTOS => {
			'set_except_expr' => 645,
			'get_except_expr' => 640,
			'attr_raises_expr' => 642
		}
	},
	{#State 558
		DEFAULT => -384
	},
	{#State 559
		DEFAULT => -256
	},
	{#State 560
		DEFAULT => -257
	},
	{#State 561
		ACTIONS => {
			")" => 646
		}
	},
	{#State 562
		ACTIONS => {
			")" => 647
		}
	},
	{#State 563
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 425,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'and_expr' => 423,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'xor_expr' => 648,
			'shift_expr' => 418,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 564
		DEFAULT => -186
	},
	{#State 565
		DEFAULT => -300
	},
	{#State 566
		DEFAULT => -302
	},
	{#State 567
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 425,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'and_expr' => 649,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'shift_expr' => 418,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 568
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 425,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 650
		}
	},
	{#State 569
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 425,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 651
		}
	},
	{#State 570
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 652,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429
		}
	},
	{#State 571
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 653,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429
		}
	},
	{#State 572
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 425,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'shift_expr' => 654,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 573
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'unary_expr' => 655,
			'scoped_name' => 414,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429
		}
	},
	{#State 574
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'unary_expr' => 656,
			'scoped_name' => 414,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429
		}
	},
	{#State 575
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'CHARACTER_LITERAL' => 413,
			"+" => 426,
			'FIXED_PT_LITERAL' => 411,
			'WIDE_CHARACTER_LITERAL' => 401,
			"-" => 412,
			"::" => 92,
			'FALSE' => 419,
			'WIDE_STRING_LITERAL' => 407,
			'INTEGER_LITERAL' => 424,
			"~" => 428,
			"(" => 403,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'unary_expr' => 657,
			'scoped_name' => 414,
			'wide_string_literal' => 402,
			'literal' => 420,
			'unary_operator' => 429
		}
	},
	{#State 576
		DEFAULT => -166
	},
	{#State 577
		DEFAULT => -297
	},
	{#State 578
		DEFAULT => -299
	},
	{#State 579
		DEFAULT => -134
	},
	{#State 580
		DEFAULT => -135
	},
	{#State 581
		DEFAULT => -67
	},
	{#State 582
		DEFAULT => -68
	},
	{#State 583
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -458
	},
	{#State 584
		DEFAULT => -459
	},
	{#State 585
		ACTIONS => {
			'error' => 660,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 659,
			'exception_names' => 658,
			'exception_name' => 661
		}
	},
	{#State 586
		DEFAULT => -342
	},
	{#State 587
		DEFAULT => -119
	},
	{#State 588
		DEFAULT => -120
	},
	{#State 589
		ACTIONS => {
			";" => 662
		}
	},
	{#State 590
		DEFAULT => -116
	},
	{#State 591
		DEFAULT => -133
	},
	{#State 592
		DEFAULT => -123
	},
	{#State 593
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'VALUEBASE' => 178,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'WCHAR' => 84,
			'error' => 664,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'wide_string_type' => 367,
			'integer_type' => 198,
			'boolean_type' => 197,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 368,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'signed_short_int' => 93,
			'string_type' => 369,
			'base_type_spec' => 370,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'unsigned_long_int' => 113,
			'param_type_spec' => 663,
			'unsigned_short_int' => 105,
			'signed_longlong_int' => 88
		}
	},
	{#State 594
		ACTIONS => {
			")" => 665
		}
	},
	{#State 595
		ACTIONS => {
			"," => 666
		},
		DEFAULT => -129
	},
	{#State 596
		ACTIONS => {
			")" => 667
		}
	},
	{#State 597
		ACTIONS => {
			'error' => 668,
			'IDENTIFIER' => 669
		}
	},
	{#State 598
		DEFAULT => -435
	},
	{#State 599
		DEFAULT => -439
	},
	{#State 600
		DEFAULT => -438
	},
	{#State 601
		DEFAULT => -429
	},
	{#State 602
		DEFAULT => -428
	},
	{#State 603
		DEFAULT => -442
	},
	{#State 604
		DEFAULT => -441
	},
	{#State 605
		DEFAULT => -445
	},
	{#State 606
		DEFAULT => -444
	},
	{#State 607
		DEFAULT => -480
	},
	{#State 608
		ACTIONS => {
			")" => 670
		}
	},
	{#State 609
		ACTIONS => {
			")" => 671
		}
	},
	{#State 610
		DEFAULT => -472
	},
	{#State 611
		ACTIONS => {
			")" => 672
		}
	},
	{#State 612
		ACTIONS => {
			")" => 673
		}
	},
	{#State 613
		DEFAULT => -288
	},
	{#State 614
		ACTIONS => {
			'error' => 675,
			"{" => 674
		}
	},
	{#State 615
		DEFAULT => -261
	},
	{#State 616
		DEFAULT => -295
	},
	{#State 617
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 677,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'primary_expr' => 422,
			'and_expr' => 423,
			'scoped_name' => 414,
			'positive_int_const' => 676,
			'wide_string_literal' => 402,
			'boolean_literal' => 404,
			'mult_expr' => 425,
			'const_exp' => 405,
			'or_expr' => 406,
			'unary_expr' => 427,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 618
		DEFAULT => -294
	},
	{#State 619
		DEFAULT => -220
	},
	{#State 620
		DEFAULT => -305
	},
	{#State 621
		ACTIONS => {
			"]" => 678
		}
	},
	{#State 622
		ACTIONS => {
			"]" => 679
		}
	},
	{#State 623
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 681,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'string_literal' => 409,
			'primary_expr' => 422,
			'and_expr' => 423,
			'scoped_name' => 414,
			'positive_int_const' => 680,
			'wide_string_literal' => 402,
			'boolean_literal' => 404,
			'mult_expr' => 425,
			'const_exp' => 405,
			'or_expr' => 406,
			'unary_expr' => 427,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 624
		DEFAULT => -357
	},
	{#State 625
		DEFAULT => -70
	},
	{#State 626
		ACTIONS => {
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 538,
			'value_name' => 537,
			'value_names' => 682
		}
	},
	{#State 627
		DEFAULT => -104
	},
	{#State 628
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'simple_declarator' => 683
		}
	},
	{#State 629
		DEFAULT => -336
	},
	{#State 630
		DEFAULT => -330
	},
	{#State 631
		DEFAULT => -328
	},
	{#State 632
		DEFAULT => -334
	},
	{#State 633
		ACTIONS => {
			'OUT' => 547,
			'INOUT' => 544,
			'IN' => 543
		},
		DEFAULT => -333,
		GOTOS => {
			'param_dcl' => 550,
			'param_dcls' => 684,
			'param_attribute' => 545
		}
	},
	{#State 634
		ACTIONS => {
			'error' => 687,
			'STRING_LITERAL' => 167
		},
		GOTOS => {
			'string_literal' => 685,
			'string_literals' => 686
		}
	},
	{#State 635
		DEFAULT => -348
	},
	{#State 636
		DEFAULT => -318
	},
	{#State 637
		DEFAULT => -377
	},
	{#State 638
		DEFAULT => -381
	},
	{#State 639
		ACTIONS => {
			'RAISES' => 444,
			"," => 641
		},
		DEFAULT => -382,
		GOTOS => {
			'raises_expr' => 688
		}
	},
	{#State 640
		ACTIONS => {
			'SETRAISES' => 643
		},
		DEFAULT => -389,
		GOTOS => {
			'set_except_expr' => 689
		}
	},
	{#State 641
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'simple_declarators' => 691,
			'simple_declarator' => 690
		}
	},
	{#State 642
		DEFAULT => -386
	},
	{#State 643
		ACTIONS => {
			'error' => 693,
			"(" => 692
		},
		GOTOS => {
			'exception_list' => 694
		}
	},
	{#State 644
		ACTIONS => {
			'error' => 695,
			"(" => 692
		},
		GOTOS => {
			'exception_list' => 696
		}
	},
	{#State 645
		DEFAULT => -390
	},
	{#State 646
		DEFAULT => -173
	},
	{#State 647
		DEFAULT => -174
	},
	{#State 648
		ACTIONS => {
			"^" => 567
		},
		DEFAULT => -151
	},
	{#State 649
		ACTIONS => {
			"&" => 572
		},
		DEFAULT => -153
	},
	{#State 650
		ACTIONS => {
			"+" => 571,
			"-" => 570
		},
		DEFAULT => -158
	},
	{#State 651
		ACTIONS => {
			"+" => 571,
			"-" => 570
		},
		DEFAULT => -157
	},
	{#State 652
		ACTIONS => {
			"%" => 573,
			"*" => 574,
			"/" => 575
		},
		DEFAULT => -161
	},
	{#State 653
		ACTIONS => {
			"%" => 573,
			"*" => 574,
			"/" => 575
		},
		DEFAULT => -160
	},
	{#State 654
		ACTIONS => {
			"<<" => 568,
			">>" => 569
		},
		DEFAULT => -155
	},
	{#State 655
		DEFAULT => -165
	},
	{#State 656
		DEFAULT => -163
	},
	{#State 657
		DEFAULT => -164
	},
	{#State 658
		ACTIONS => {
			")" => 697
		}
	},
	{#State 659
		ACTIONS => {
			"::" => 245
		},
		DEFAULT => -345
	},
	{#State 660
		ACTIONS => {
			")" => 698
		}
	},
	{#State 661
		ACTIONS => {
			"," => 699
		},
		DEFAULT => -343
	},
	{#State 662
		DEFAULT => -115
	},
	{#State 663
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 158
		},
		GOTOS => {
			'simple_declarator' => 700
		}
	},
	{#State 664
		DEFAULT => -132
	},
	{#State 665
		DEFAULT => -124
	},
	{#State 666
		ACTIONS => {
			'IN' => 591
		},
		GOTOS => {
			'init_param_decls' => 701,
			'init_param_attribute' => 593,
			'init_param_decl' => 595
		}
	},
	{#State 667
		DEFAULT => -125
	},
	{#State 668
		DEFAULT => -434
	},
	{#State 669
		DEFAULT => -433
	},
	{#State 670
		DEFAULT => -481
	},
	{#State 671
		DEFAULT => -482
	},
	{#State 672
		DEFAULT => -473
	},
	{#State 673
		DEFAULT => -474
	},
	{#State 674
		ACTIONS => {
			'error' => 707,
			'CASE' => 705,
			'DEFAULT' => 706
		},
		GOTOS => {
			'case_labels' => 703,
			'switch_body' => 708,
			'case' => 702,
			'case_label' => 704
		}
	},
	{#State 675
		DEFAULT => -260
	},
	{#State 676
		ACTIONS => {
			">" => 709
		}
	},
	{#State 677
		ACTIONS => {
			">" => 710
		}
	},
	{#State 678
		DEFAULT => -306
	},
	{#State 679
		DEFAULT => -307
	},
	{#State 680
		ACTIONS => {
			">" => 711
		}
	},
	{#State 681
		ACTIONS => {
			">" => 712
		}
	},
	{#State 682
		DEFAULT => -110
	},
	{#State 683
		DEFAULT => -335
	},
	{#State 684
		DEFAULT => -332
	},
	{#State 685
		ACTIONS => {
			"," => 713
		},
		DEFAULT => -349
	},
	{#State 686
		ACTIONS => {
			")" => 714
		}
	},
	{#State 687
		ACTIONS => {
			")" => 715
		}
	},
	{#State 688
		DEFAULT => -380
	},
	{#State 689
		DEFAULT => -388
	},
	{#State 690
		ACTIONS => {
			"," => 641
		},
		DEFAULT => -382
	},
	{#State 691
		DEFAULT => -383
	},
	{#State 692
		ACTIONS => {
			'error' => 717,
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 659,
			'exception_names' => 716,
			'exception_name' => 661
		}
	},
	{#State 693
		DEFAULT => -394
	},
	{#State 694
		DEFAULT => -393
	},
	{#State 695
		DEFAULT => -392
	},
	{#State 696
		DEFAULT => -391
	},
	{#State 697
		DEFAULT => -340
	},
	{#State 698
		DEFAULT => -341
	},
	{#State 699
		ACTIONS => {
			'IDENTIFIER' => 112,
			"::" => 92
		},
		GOTOS => {
			'scoped_name' => 659,
			'exception_names' => 718,
			'exception_name' => 661
		}
	},
	{#State 700
		DEFAULT => -131
	},
	{#State 701
		DEFAULT => -130
	},
	{#State 702
		ACTIONS => {
			'CASE' => 705,
			'DEFAULT' => 706
		},
		DEFAULT => -270,
		GOTOS => {
			'case_labels' => 703,
			'switch_body' => 719,
			'case' => 702,
			'case_label' => 704
		}
	},
	{#State 703
		ACTIONS => {
			'CHAR' => 89,
			'OBJECT' => 196,
			'FIXED' => 186,
			'VALUEBASE' => 178,
			'SEQUENCE' => 172,
			'STRUCT' => 180,
			'DOUBLE' => 108,
			'LONG' => 109,
			'STRING' => 110,
			"::" => 92,
			'WSTRING' => 94,
			'UNSIGNED' => 101,
			'SHORT' => 103,
			'BOOLEAN' => 95,
			'IDENTIFIER' => 112,
			'UNION' => 183,
			'WCHAR' => 84,
			'FLOAT' => 87,
			'OCTET' => 86,
			'ENUM' => 16,
			'ANY' => 195
		},
		GOTOS => {
			'unsigned_int' => 80,
			'floating_pt_type' => 171,
			'signed_int' => 97,
			'value_base_type' => 187,
			'char_type' => 173,
			'object_type' => 188,
			'scoped_name' => 189,
			'octet_type' => 174,
			'wide_char_type' => 190,
			'signed_long_int' => 100,
			'type_spec' => 720,
			'string_type' => 191,
			'struct_header' => 10,
			'element_spec' => 721,
			'base_type_spec' => 192,
			'unsigned_longlong_int' => 85,
			'any_type' => 177,
			'enum_type' => 193,
			'enum_header' => 47,
			'unsigned_short_int' => 105,
			'union_header' => 49,
			'signed_longlong_int' => 88,
			'wide_string_type' => 179,
			'boolean_type' => 197,
			'integer_type' => 198,
			'signed_short_int' => 93,
			'struct_type' => 181,
			'union_type' => 182,
			'sequence_type' => 199,
			'unsigned_long_int' => 113,
			'template_type_spec' => 184,
			'constr_type_spec' => 185,
			'simple_type_spec' => 200,
			'fixed_pt_type' => 201
		}
	},
	{#State 704
		ACTIONS => {
			'CASE' => 705,
			'DEFAULT' => 706
		},
		DEFAULT => -274,
		GOTOS => {
			'case_labels' => 722,
			'case_label' => 704
		}
	},
	{#State 705
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 410,
			'CHARACTER_LITERAL' => 413,
			'WIDE_CHARACTER_LITERAL' => 401,
			"::" => 92,
			'INTEGER_LITERAL' => 424,
			"(" => 403,
			'IDENTIFIER' => 112,
			'STRING_LITERAL' => 167,
			'FIXED_PT_LITERAL' => 411,
			"+" => 426,
			'error' => 724,
			"-" => 412,
			'WIDE_STRING_LITERAL' => 407,
			'FALSE' => 419,
			"~" => 428,
			'TRUE' => 408
		},
		GOTOS => {
			'mult_expr' => 425,
			'string_literal' => 409,
			'boolean_literal' => 404,
			'primary_expr' => 422,
			'const_exp' => 723,
			'and_expr' => 423,
			'or_expr' => 406,
			'unary_expr' => 427,
			'scoped_name' => 414,
			'xor_expr' => 417,
			'shift_expr' => 418,
			'literal' => 420,
			'wide_string_literal' => 402,
			'unary_operator' => 429,
			'add_expr' => 421
		}
	},
	{#State 706
		ACTIONS => {
			'error' => 725,
			":" => 726
		}
	},
	{#State 707
		ACTIONS => {
			"}" => 727
		}
	},
	{#State 708
		ACTIONS => {
			"}" => 728
		}
	},
	{#State 709
		DEFAULT => -292
	},
	{#State 710
		DEFAULT => -293
	},
	{#State 711
		DEFAULT => -355
	},
	{#State 712
		DEFAULT => -356
	},
	{#State 713
		ACTIONS => {
			'STRING_LITERAL' => 167
		},
		GOTOS => {
			'string_literal' => 685,
			'string_literals' => 729
		}
	},
	{#State 714
		DEFAULT => -346
	},
	{#State 715
		DEFAULT => -347
	},
	{#State 716
		ACTIONS => {
			")" => 730
		}
	},
	{#State 717
		ACTIONS => {
			")" => 731
		}
	},
	{#State 718
		DEFAULT => -344
	},
	{#State 719
		DEFAULT => -271
	},
	{#State 720
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 344
		},
		GOTOS => {
			'declarator' => 732,
			'simple_declarator' => 343,
			'array_declarator' => 341,
			'complex_declarator' => 340
		}
	},
	{#State 721
		ACTIONS => {
			'error' => 734,
			";" => 733
		}
	},
	{#State 722
		DEFAULT => -275
	},
	{#State 723
		ACTIONS => {
			'error' => 735,
			":" => 736
		}
	},
	{#State 724
		DEFAULT => -278
	},
	{#State 725
		DEFAULT => -280
	},
	{#State 726
		DEFAULT => -279
	},
	{#State 727
		DEFAULT => -259
	},
	{#State 728
		DEFAULT => -258
	},
	{#State 729
		DEFAULT => -350
	},
	{#State 730
		DEFAULT => -395
	},
	{#State 731
		DEFAULT => -396
	},
	{#State 732
		DEFAULT => -281
	},
	{#State 733
		DEFAULT => -272
	},
	{#State 734
		DEFAULT => -273
	},
	{#State 735
		DEFAULT => -277
	},
	{#State 736
		DEFAULT => -276
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
		 'definition', 2, undef
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
		 'definition', 2,
sub
#line 157 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
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
		 'module', 4,
sub
#line 227 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 32
		 'module', 4,
sub
#line 234 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 33
		 'module', 3,
sub
#line 240 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 34
		 'module', 3,
sub
#line 246 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 35
		 'module_header', 2,
sub
#line 255 "parser30.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 36
		 'module_header', 2,
sub
#line 261 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 37
		 'interface', 1, undef
	],
	[#Rule 38
		 'interface', 1, undef
	],
	[#Rule 39
		 'interface_dcl', 3,
sub
#line 278 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 40
		 'interface_dcl', 4,
sub
#line 286 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 41
		 'interface_dcl', 4,
sub
#line 294 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 42
		 'forward_dcl', 3,
sub
#line 305 "parser30.yp"
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
	[#Rule 43
		 'forward_dcl', 3,
sub
#line 321 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 44
		 'interface_mod', 1, undef
	],
	[#Rule 45
		 'interface_mod', 1, undef
	],
	[#Rule 46
		 'interface_mod', 0, undef
	],
	[#Rule 47
		 'interface_header', 3,
sub
#line 339 "parser30.yp"
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
	[#Rule 48
		 'interface_header', 4,
sub
#line 355 "parser30.yp"
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
	[#Rule 49
		 'interface_header', 3,
sub
#line 377 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 50
		 'interface_body', 1, undef
	],
	[#Rule 51
		 'exports', 1,
sub
#line 391 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 52
		 'exports', 2,
sub
#line 395 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 53
		 'export', 2, undef
	],
	[#Rule 54
		 'export', 2, undef
	],
	[#Rule 55
		 'export', 2, undef
	],
	[#Rule 56
		 'export', 2, undef
	],
	[#Rule 57
		 'export', 2, undef
	],
	[#Rule 58
		 'export', 2, undef
	],
	[#Rule 59
		 'export', 2, undef
	],
	[#Rule 60
		 'export', 2,
sub
#line 418 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 61
		 'export', 2,
sub
#line 424 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 62
		 'export', 2,
sub
#line 430 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 63
		 'export', 2,
sub
#line 436 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 64
		 'export', 2,
sub
#line 442 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
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
		 'interface_inheritance_spec', 2,
sub
#line 464 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 68
		 'interface_inheritance_spec', 2,
sub
#line 468 "parser30.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 69
		 'interface_names', 1,
sub
#line 476 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 70
		 'interface_names', 3,
sub
#line 480 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 71
		 'interface_name', 1,
sub
#line 489 "parser30.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 72
		 'scoped_name', 1, undef
	],
	[#Rule 73
		 'scoped_name', 2,
sub
#line 499 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 74
		 'scoped_name', 2,
sub
#line 503 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 75
		 'scoped_name', 3,
sub
#line 509 "parser30.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 76
		 'scoped_name', 3,
sub
#line 513 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 77
		 'value', 1, undef
	],
	[#Rule 78
		 'value', 1, undef
	],
	[#Rule 79
		 'value', 1, undef
	],
	[#Rule 80
		 'value', 1, undef
	],
	[#Rule 81
		 'value_forward_dcl', 2,
sub
#line 535 "parser30.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 82
		 'value_forward_dcl', 3,
sub
#line 541 "parser30.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 83
		 'value_box_dcl', 3,
sub
#line 551 "parser30.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 84
		 'value_abs_dcl', 3,
sub
#line 562 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 85
		 'value_abs_dcl', 4,
sub
#line 570 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 86
		 'value_abs_dcl', 4,
sub
#line 578 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 87
		 'value_abs_header', 3,
sub
#line 588 "parser30.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 88
		 'value_abs_header', 4,
sub
#line 594 "parser30.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 89
		 'value_abs_header', 3,
sub
#line 601 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 90
		 'value_abs_header', 2,
sub
#line 606 "parser30.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 91
		 'value_dcl', 3,
sub
#line 615 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 92
		 'value_dcl', 4,
sub
#line 623 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 93
		 'value_dcl', 4,
sub
#line 631 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 94
		 'value_elements', 1,
sub
#line 641 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 95
		 'value_elements', 2,
sub
#line 645 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 96
		 'value_header', 2,
sub
#line 654 "parser30.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 97
		 'value_header', 3,
sub
#line 660 "parser30.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 98
		 'value_header', 3,
sub
#line 667 "parser30.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 99
		 'value_header', 4,
sub
#line 674 "parser30.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 100
		 'value_header', 2,
sub
#line 682 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 101
		 'value_header', 3,
sub
#line 687 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 102
		 'value_header', 2,
sub
#line 692 "parser30.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 103
		 'value_inheritance_spec', 3,
sub
#line 701 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3]
			);
		}
	],
	[#Rule 104
		 'value_inheritance_spec', 4,
sub
#line 708 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 105
		 'value_inheritance_spec', 3,
sub
#line 716 "parser30.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 106
		 'value_inheritance_spec', 1,
sub
#line 721 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 107
		 'inheritance_mod', 1, undef
	],
	[#Rule 108
		 'inheritance_mod', 0, undef
	],
	[#Rule 109
		 'value_names', 1,
sub
#line 737 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 110
		 'value_names', 3,
sub
#line 741 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 111
		 'value_name', 1,
sub
#line 750 "parser30.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 112
		 'value_element', 1, undef
	],
	[#Rule 113
		 'value_element', 1, undef
	],
	[#Rule 114
		 'value_element', 1, undef
	],
	[#Rule 115
		 'state_member', 4,
sub
#line 768 "parser30.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 116
		 'state_member', 3,
sub
#line 776 "parser30.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 117
		 'state_mod', 1, undef
	],
	[#Rule 118
		 'state_mod', 1, undef
	],
	[#Rule 119
		 'init_dcl', 3,
sub
#line 792 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 120
		 'init_dcl', 3,
sub
#line 798 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 121
		 'init_dcl', 2, undef
	],
	[#Rule 122
		 'init_dcl', 2,
sub
#line 808 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 123
		 'init_header_param', 3,
sub
#line 817 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 124
		 'init_header_param', 4,
sub
#line 823 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 125
		 'init_header_param', 4,
sub
#line 831 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 126
		 'init_header_param', 2,
sub
#line 838 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 127
		 'init_header', 2,
sub
#line 848 "parser30.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 128
		 'init_header', 2,
sub
#line 854 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 129
		 'init_param_decls', 1,
sub
#line 863 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 130
		 'init_param_decls', 3,
sub
#line 867 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 131
		 'init_param_decl', 3,
sub
#line 876 "parser30.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 132
		 'init_param_decl', 2,
sub
#line 884 "parser30.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 133
		 'init_param_attribute', 1, undef
	],
	[#Rule 134
		 'const_dcl', 5,
sub
#line 899 "parser30.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 135
		 'const_dcl', 5,
sub
#line 907 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 136
		 'const_dcl', 4,
sub
#line 912 "parser30.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 137
		 'const_dcl', 3,
sub
#line 917 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 138
		 'const_dcl', 2,
sub
#line 922 "parser30.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 139
		 'const_type', 1, undef
	],
	[#Rule 140
		 'const_type', 1, undef
	],
	[#Rule 141
		 'const_type', 1, undef
	],
	[#Rule 142
		 'const_type', 1, undef
	],
	[#Rule 143
		 'const_type', 1, undef
	],
	[#Rule 144
		 'const_type', 1, undef
	],
	[#Rule 145
		 'const_type', 1, undef
	],
	[#Rule 146
		 'const_type', 1, undef
	],
	[#Rule 147
		 'const_type', 1,
sub
#line 947 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 148
		 'const_type', 1, undef
	],
	[#Rule 149
		 'const_exp', 1, undef
	],
	[#Rule 150
		 'or_expr', 1, undef
	],
	[#Rule 151
		 'or_expr', 3,
sub
#line 965 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 152
		 'xor_expr', 1, undef
	],
	[#Rule 153
		 'xor_expr', 3,
sub
#line 975 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 154
		 'and_expr', 1, undef
	],
	[#Rule 155
		 'and_expr', 3,
sub
#line 985 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 156
		 'shift_expr', 1, undef
	],
	[#Rule 157
		 'shift_expr', 3,
sub
#line 995 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 158
		 'shift_expr', 3,
sub
#line 999 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 159
		 'add_expr', 1, undef
	],
	[#Rule 160
		 'add_expr', 3,
sub
#line 1009 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 161
		 'add_expr', 3,
sub
#line 1013 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 162
		 'mult_expr', 1, undef
	],
	[#Rule 163
		 'mult_expr', 3,
sub
#line 1023 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 164
		 'mult_expr', 3,
sub
#line 1027 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 165
		 'mult_expr', 3,
sub
#line 1031 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 166
		 'unary_expr', 2,
sub
#line 1039 "parser30.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 167
		 'unary_expr', 1, undef
	],
	[#Rule 168
		 'unary_operator', 1, undef
	],
	[#Rule 169
		 'unary_operator', 1, undef
	],
	[#Rule 170
		 'unary_operator', 1, undef
	],
	[#Rule 171
		 'primary_expr', 1,
sub
#line 1059 "parser30.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 172
		 'primary_expr', 1,
sub
#line 1065 "parser30.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 173
		 'primary_expr', 3,
sub
#line 1069 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 174
		 'primary_expr', 3,
sub
#line 1073 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 175
		 'literal', 1,
sub
#line 1082 "parser30.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 176
		 'literal', 1,
sub
#line 1089 "parser30.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 177
		 'literal', 1,
sub
#line 1095 "parser30.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 178
		 'literal', 1,
sub
#line 1101 "parser30.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 179
		 'literal', 1,
sub
#line 1107 "parser30.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 180
		 'literal', 1,
sub
#line 1113 "parser30.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 181
		 'literal', 1,
sub
#line 1120 "parser30.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 182
		 'literal', 1, undef
	],
	[#Rule 183
		 'string_literal', 1, undef
	],
	[#Rule 184
		 'string_literal', 2,
sub
#line 1134 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 185
		 'wide_string_literal', 1, undef
	],
	[#Rule 186
		 'wide_string_literal', 2,
sub
#line 1143 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 187
		 'boolean_literal', 1,
sub
#line 1151 "parser30.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 188
		 'boolean_literal', 1,
sub
#line 1157 "parser30.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 189
		 'positive_int_const', 1,
sub
#line 1167 "parser30.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 190
		 'type_dcl', 2,
sub
#line 1177 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 191
		 'type_dcl', 1, undef
	],
	[#Rule 192
		 'type_dcl', 1, undef
	],
	[#Rule 193
		 'type_dcl', 1, undef
	],
	[#Rule 194
		 'type_dcl', 2,
sub
#line 1187 "parser30.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 195
		 'type_dcl', 1, undef
	],
	[#Rule 196
		 'type_dcl', 2,
sub
#line 1196 "parser30.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 197
		 'type_declarator', 2,
sub
#line 1205 "parser30.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 198
		 'type_spec', 1, undef
	],
	[#Rule 199
		 'type_spec', 1, undef
	],
	[#Rule 200
		 'simple_type_spec', 1, undef
	],
	[#Rule 201
		 'simple_type_spec', 1, undef
	],
	[#Rule 202
		 'simple_type_spec', 1,
sub
#line 1228 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 203
		 'base_type_spec', 1, undef
	],
	[#Rule 204
		 'base_type_spec', 1, undef
	],
	[#Rule 205
		 'base_type_spec', 1, undef
	],
	[#Rule 206
		 'base_type_spec', 1, undef
	],
	[#Rule 207
		 'base_type_spec', 1, undef
	],
	[#Rule 208
		 'base_type_spec', 1, undef
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
		 'template_type_spec', 1, undef
	],
	[#Rule 213
		 'template_type_spec', 1, undef
	],
	[#Rule 214
		 'template_type_spec', 1, undef
	],
	[#Rule 215
		 'template_type_spec', 1, undef
	],
	[#Rule 216
		 'constr_type_spec', 1, undef
	],
	[#Rule 217
		 'constr_type_spec', 1, undef
	],
	[#Rule 218
		 'constr_type_spec', 1, undef
	],
	[#Rule 219
		 'declarators', 1,
sub
#line 1280 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 220
		 'declarators', 3,
sub
#line 1284 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 221
		 'declarator', 1,
sub
#line 1293 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 222
		 'declarator', 1, undef
	],
	[#Rule 223
		 'simple_declarator', 1, undef
	],
	[#Rule 224
		 'simple_declarator', 2,
sub
#line 1305 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 225
		 'simple_declarator', 2,
sub
#line 1310 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 226
		 'complex_declarator', 1, undef
	],
	[#Rule 227
		 'floating_pt_type', 1,
sub
#line 1325 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 228
		 'floating_pt_type', 1,
sub
#line 1331 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 229
		 'floating_pt_type', 2,
sub
#line 1337 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 230
		 'integer_type', 1, undef
	],
	[#Rule 231
		 'integer_type', 1, undef
	],
	[#Rule 232
		 'signed_int', 1, undef
	],
	[#Rule 233
		 'signed_int', 1, undef
	],
	[#Rule 234
		 'signed_int', 1, undef
	],
	[#Rule 235
		 'signed_short_int', 1,
sub
#line 1365 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 236
		 'signed_long_int', 1,
sub
#line 1375 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 237
		 'signed_longlong_int', 2,
sub
#line 1385 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 238
		 'unsigned_int', 1, undef
	],
	[#Rule 239
		 'unsigned_int', 1, undef
	],
	[#Rule 240
		 'unsigned_int', 1, undef
	],
	[#Rule 241
		 'unsigned_short_int', 2,
sub
#line 1405 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 242
		 'unsigned_long_int', 2,
sub
#line 1415 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 243
		 'unsigned_longlong_int', 3,
sub
#line 1425 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 244
		 'char_type', 1,
sub
#line 1435 "parser30.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 245
		 'wide_char_type', 1,
sub
#line 1445 "parser30.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 246
		 'boolean_type', 1,
sub
#line 1455 "parser30.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 247
		 'octet_type', 1,
sub
#line 1465 "parser30.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 248
		 'any_type', 1,
sub
#line 1475 "parser30.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 249
		 'object_type', 1,
sub
#line 1485 "parser30.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 250
		 'struct_type', 4,
sub
#line 1495 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 251
		 'struct_type', 4,
sub
#line 1502 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 252
		 'struct_header', 2,
sub
#line 1511 "parser30.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 253
		 'struct_header', 2,
sub
#line 1517 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 254
		 'member_list', 1,
sub
#line 1526 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 255
		 'member_list', 2,
sub
#line 1530 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 256
		 'member', 3,
sub
#line 1539 "parser30.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 257
		 'member', 3,
sub
#line 1546 "parser30.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 258
		 'union_type', 8,
sub
#line 1559 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 259
		 'union_type', 8,
sub
#line 1567 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 260
		 'union_type', 6,
sub
#line 1573 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 261
		 'union_type', 5,
sub
#line 1579 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 262
		 'union_type', 3,
sub
#line 1585 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 263
		 'union_header', 2,
sub
#line 1594 "parser30.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 264
		 'union_header', 2,
sub
#line 1600 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 265
		 'switch_type_spec', 1, undef
	],
	[#Rule 266
		 'switch_type_spec', 1, undef
	],
	[#Rule 267
		 'switch_type_spec', 1, undef
	],
	[#Rule 268
		 'switch_type_spec', 1, undef
	],
	[#Rule 269
		 'switch_type_spec', 1,
sub
#line 1617 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 270
		 'switch_body', 1,
sub
#line 1625 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 271
		 'switch_body', 2,
sub
#line 1629 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 272
		 'case', 3,
sub
#line 1638 "parser30.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 273
		 'case', 3,
sub
#line 1645 "parser30.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 274
		 'case_labels', 1,
sub
#line 1657 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 275
		 'case_labels', 2,
sub
#line 1661 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 276
		 'case_label', 3,
sub
#line 1670 "parser30.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 277
		 'case_label', 3,
sub
#line 1674 "parser30.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 278
		 'case_label', 2,
sub
#line 1680 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'case_label', 2,
sub
#line 1685 "parser30.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 280
		 'case_label', 2,
sub
#line 1689 "parser30.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 281
		 'element_spec', 2,
sub
#line 1699 "parser30.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 282
		 'enum_type', 4,
sub
#line 1710 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 283
		 'enum_type', 4,
sub
#line 1716 "parser30.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 284
		 'enum_type', 2,
sub
#line 1721 "parser30.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 285
		 'enum_header', 2,
sub
#line 1729 "parser30.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 286
		 'enum_header', 2,
sub
#line 1735 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 287
		 'enumerators', 1,
sub
#line 1743 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 288
		 'enumerators', 3,
sub
#line 1747 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 289
		 'enumerators', 2,
sub
#line 1752 "parser30.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 290
		 'enumerators', 2,
sub
#line 1757 "parser30.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 291
		 'enumerator', 1,
sub
#line 1766 "parser30.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 292
		 'sequence_type', 6,
sub
#line 1776 "parser30.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 293
		 'sequence_type', 6,
sub
#line 1784 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 294
		 'sequence_type', 4,
sub
#line 1789 "parser30.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 295
		 'sequence_type', 4,
sub
#line 1796 "parser30.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 296
		 'sequence_type', 2,
sub
#line 1801 "parser30.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 297
		 'string_type', 4,
sub
#line 1810 "parser30.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 298
		 'string_type', 1,
sub
#line 1817 "parser30.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 299
		 'string_type', 4,
sub
#line 1823 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 300
		 'wide_string_type', 4,
sub
#line 1832 "parser30.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 301
		 'wide_string_type', 1,
sub
#line 1839 "parser30.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 302
		 'wide_string_type', 4,
sub
#line 1845 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 303
		 'array_declarator', 2,
sub
#line 1854 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 304
		 'fixed_array_sizes', 1,
sub
#line 1862 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 305
		 'fixed_array_sizes', 2,
sub
#line 1866 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 306
		 'fixed_array_size', 3,
sub
#line 1875 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 307
		 'fixed_array_size', 3,
sub
#line 1879 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 308
		 'attr_dcl', 1, undef
	],
	[#Rule 309
		 'attr_dcl', 1, undef
	],
	[#Rule 310
		 'except_dcl', 3,
sub
#line 1896 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 311
		 'except_dcl', 4,
sub
#line 1901 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 312
		 'except_dcl', 4,
sub
#line 1908 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 313
		 'except_dcl', 2,
sub
#line 1914 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 314
		 'exception_header', 2,
sub
#line 1923 "parser30.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 315
		 'exception_header', 2,
sub
#line 1929 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 316
		 'op_dcl', 2,
sub
#line 1938 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 317
		 'op_dcl', 3,
sub
#line 1946 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 318
		 'op_dcl', 4,
sub
#line 1955 "parser30.yp"
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
	[#Rule 319
		 'op_dcl', 3,
sub
#line 1965 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 320
		 'op_dcl', 2,
sub
#line 1974 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 321
		 'op_header', 3,
sub
#line 1984 "parser30.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 322
		 'op_header', 3,
sub
#line 1992 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 323
		 'op_mod', 1, undef
	],
	[#Rule 324
		 'op_mod', 0, undef
	],
	[#Rule 325
		 'op_attribute', 1, undef
	],
	[#Rule 326
		 'op_type_spec', 1, undef
	],
	[#Rule 327
		 'op_type_spec', 1,
sub
#line 2016 "parser30.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 328
		 'parameter_dcls', 3,
sub
#line 2026 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 329
		 'parameter_dcls', 2,
sub
#line 2030 "parser30.yp"
{
			undef;
		}
	],
	[#Rule 330
		 'parameter_dcls', 3,
sub
#line 2034 "parser30.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 331
		 'param_dcls', 1,
sub
#line 2042 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 332
		 'param_dcls', 3,
sub
#line 2046 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 333
		 'param_dcls', 2,
sub
#line 2051 "parser30.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 334
		 'param_dcls', 2,
sub
#line 2056 "parser30.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 335
		 'param_dcl', 3,
sub
#line 2065 "parser30.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 336
		 'param_dcl', 2,
sub
#line 2073 "parser30.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 337
		 'param_attribute', 1, undef
	],
	[#Rule 338
		 'param_attribute', 1, undef
	],
	[#Rule 339
		 'param_attribute', 1, undef
	],
	[#Rule 340
		 'raises_expr', 4,
sub
#line 2092 "parser30.yp"
{
			$_[3];
		}
	],
	[#Rule 341
		 'raises_expr', 4,
sub
#line 2096 "parser30.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 342
		 'raises_expr', 2,
sub
#line 2101 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 343
		 'exception_names', 1,
sub
#line 2109 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 344
		 'exception_names', 3,
sub
#line 2113 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 345
		 'exception_name', 1,
sub
#line 2121 "parser30.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 346
		 'context_expr', 4,
sub
#line 2129 "parser30.yp"
{
			$_[3];
		}
	],
	[#Rule 347
		 'context_expr', 4,
sub
#line 2133 "parser30.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 348
		 'context_expr', 2,
sub
#line 2138 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 349
		 'string_literals', 1,
sub
#line 2146 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 350
		 'string_literals', 3,
sub
#line 2150 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 351
		 'param_type_spec', 1, undef
	],
	[#Rule 352
		 'param_type_spec', 1, undef
	],
	[#Rule 353
		 'param_type_spec', 1, undef
	],
	[#Rule 354
		 'param_type_spec', 1,
sub
#line 2165 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 355
		 'fixed_pt_type', 6,
sub
#line 2173 "parser30.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 356
		 'fixed_pt_type', 6,
sub
#line 2181 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 357
		 'fixed_pt_type', 4,
sub
#line 2186 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 358
		 'fixed_pt_type', 2,
sub
#line 2191 "parser30.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 359
		 'fixed_pt_const_type', 1,
sub
#line 2200 "parser30.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 360
		 'value_base_type', 1,
sub
#line 2210 "parser30.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 361
		 'constr_forward_decl', 2,
sub
#line 2220 "parser30.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 362
		 'constr_forward_decl', 2,
sub
#line 2226 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 363
		 'constr_forward_decl', 2,
sub
#line 2231 "parser30.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 364
		 'constr_forward_decl', 2,
sub
#line 2237 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 365
		 'import', 3,
sub
#line 2246 "parser30.yp"
{
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 366
		 'import', 3,
sub
#line 2252 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 367
		 'import', 2,
sub
#line 2260 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 368
		 'imported_scope', 1, undef
	],
	[#Rule 369
		 'imported_scope', 1, undef
	],
	[#Rule 370
		 'type_id_dcl', 3,
sub
#line 2277 "parser30.yp"
{
			new TypeId($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 371
		 'type_id_dcl', 3,
sub
#line 2284 "parser30.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 372
		 'type_id_dcl', 2,
sub
#line 2289 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 373
		 'type_prefix_dcl', 3,
sub
#line 2298 "parser30.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 374
		 'type_prefix_dcl', 3,
sub
#line 2305 "parser30.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 375
		 'type_prefix_dcl', 3,
sub
#line 2310 "parser30.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	'',
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 376
		 'type_prefix_dcl', 2,
sub
#line 2317 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 377
		 'readonly_attr_spec', 4,
sub
#line 2326 "parser30.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]->{list_expr},
					'list_getraise'		=>	$_[4]->{list_getraise},
			);
		}
	],
	[#Rule 378
		 'readonly_attr_spec', 3,
sub
#line 2335 "parser30.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 379
		 'readonly_attr_spec', 2,
sub
#line 2340 "parser30.yp"
{
			$_[0]->Error("'attribute' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 380
		 'readonly_attr_declarator', 2,
sub
#line 2349 "parser30.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]
			};
		}
	],
	[#Rule 381
		 'readonly_attr_declarator', 1,
sub
#line 2356 "parser30.yp"
{
			{
				'list_expr'			=> $_[1]
			};
		}
	],
	[#Rule 382
		 'simple_declarators', 1,
sub
#line 2365 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 383
		 'simple_declarators', 3,
sub
#line 2369 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 384
		 'attr_spec', 3,
sub
#line 2378 "parser30.yp"
{
			new Attributes($_[0],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]->{list_expr},
					'list_getraise'		=>	$_[3]->{list_getraise},
					'list_setraise'		=>	$_[3]->{list_setraise},
			);
		}
	],
	[#Rule 385
		 'attr_spec', 2,
sub
#line 2387 "parser30.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 386
		 'attr_declarator', 2,
sub
#line 2396 "parser30.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]->{list_getraise},
				'list_setraise'		=> $_[2]->{list_setraise}
			};
		}
	],
	[#Rule 387
		 'attr_declarator', 1,
sub
#line 2404 "parser30.yp"
{
			{
				'list_expr'			=> $_[1]
			};
		}
	],
	[#Rule 388
		 'attr_raises_expr', 2,
sub
#line 2414 "parser30.yp"
{
			{
				'list_getraise'		=> $_[1],
				'list_setraise'		=> $_[2]
			};
		}
	],
	[#Rule 389
		 'attr_raises_expr', 1,
sub
#line 2421 "parser30.yp"
{
			{
				'list_getraise'		=> $_[1],
			};
		}
	],
	[#Rule 390
		 'attr_raises_expr', 1,
sub
#line 2427 "parser30.yp"
{
			{
				'list_setraise'		=> $_[1]
			};
		}
	],
	[#Rule 391
		 'get_except_expr', 2,
sub
#line 2437 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 392
		 'get_except_expr', 2,
sub
#line 2441 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 393
		 'set_except_expr', 2,
sub
#line 2450 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 394
		 'set_except_expr', 2,
sub
#line 2454 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 395
		 'exception_list', 3,
sub
#line 2463 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 396
		 'exception_list', 3,
sub
#line 2467 "parser30.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 397
		 'component', 1, undef
	],
	[#Rule 398
		 'component', 1, undef
	],
	[#Rule 399
		 'component_forward_dcl', 2,
sub
#line 2484 "parser30.yp"
{
			new ForwardComponent($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 400
		 'component_forward_dcl', 2,
sub
#line 2490 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 401
		 'component_dcl', 3,
sub
#line 2499 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 402
		 'component_dcl', 4,
sub
#line 2507 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 403
		 'component_dcl', 4,
sub
#line 2515 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 404
		 'component_header', 4,
sub
#line 2526 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3],
					'list_support'			=>	$_[4],
			);
		}
	],
	[#Rule 405
		 'component_header', 3,
sub
#line 2534 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3],
			);
		}
	],
	[#Rule 406
		 'component_header', 3,
sub
#line 2541 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'list_support'			=>	$_[3],
			);
		}
	],
	[#Rule 407
		 'component_header', 2,
sub
#line 2548 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
			);
		}
	],
	[#Rule 408
		 'component_header', 2,
sub
#line 2554 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 409
		 'supported_interface_spec', 2,
sub
#line 2563 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 410
		 'supported_interface_spec', 2,
sub
#line 2567 "parser30.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 411
		 'component_inheritance_spec', 2,
sub
#line 2576 "parser30.yp"
{
			Component->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 412
		 'component_inheritance_spec', 2,
sub
#line 2580 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 413
		 'component_body', 1, undef
	],
	[#Rule 414
		 'component_exports', 1,
sub
#line 2594 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 415
		 'component_exports', 2,
sub
#line 2598 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 416
		 'component_export', 2, undef
	],
	[#Rule 417
		 'component_export', 2, undef
	],
	[#Rule 418
		 'component_export', 2, undef
	],
	[#Rule 419
		 'component_export', 2, undef
	],
	[#Rule 420
		 'component_export', 2, undef
	],
	[#Rule 421
		 'component_export', 2, undef
	],
	[#Rule 422
		 'component_export', 2,
sub
#line 2619 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 423
		 'component_export', 2,
sub
#line 2625 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 424
		 'component_export', 2,
sub
#line 2631 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 425
		 'component_export', 2,
sub
#line 2637 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 426
		 'component_export', 2,
sub
#line 2643 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 427
		 'component_export', 2,
sub
#line 2649 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 428
		 'provides_dcl', 3,
sub
#line 2659 "parser30.yp"
{
			new Provides($_[0],
					'idf'					=>	$_[3],
					'type'					=>	$_[2],
			);
		}
	],
	[#Rule 429
		 'provides_dcl', 3,
sub
#line 2666 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 430
		 'provides_dcl', 2,
sub
#line 2671 "parser30.yp"
{
			$_[0]->Error("Interface type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 431
		 'interface_type', 1,
sub
#line 2680 "parser30.yp"
{
			BaseInterface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 432
		 'interface_type', 1, undef
	],
	[#Rule 433
		 'uses_dcl', 4,
sub
#line 2690 "parser30.yp"
{
			new Uses($_[0],
					'modifier'				=>	$_[2],
					'idf'					=>	$_[4],
					'type'					=>	$_[3],
			);
		}
	],
	[#Rule 434
		 'uses_dcl', 4,
sub
#line 2698 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 435
		 'uses_dcl', 3,
sub
#line 2703 "parser30.yp"
{
			$_[0]->Error("Interface type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 436
		 'uses_mod', 1, undef
	],
	[#Rule 437
		 'uses_mod', 0, undef
	],
	[#Rule 438
		 'emits_dcl', 3,
sub
#line 2719 "parser30.yp"
{
			new Emits($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 439
		 'emits_dcl', 3,
sub
#line 2726 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 440
		 'emits_dcl', 2,
sub
#line 2731 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 441
		 'publishes_dcl', 3,
sub
#line 2740 "parser30.yp"
{
			new Publishes($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 442
		 'publishes_dcl', 3,
sub
#line 2747 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 443
		 'publishes_dcl', 2,
sub
#line 2752 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 444
		 'consumes_dcl', 3,
sub
#line 2761 "parser30.yp"
{
			new Consumes($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 445
		 'consumes_dcl', 3,
sub
#line 2768 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 446
		 'consumes_dcl', 2,
sub
#line 2773 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 447
		 'home_dcl', 2,
sub
#line 2782 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[2],
			) if (defined $_[1]);
		}
	],
	[#Rule 448
		 'home_header', 4,
sub
#line 2794 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'manage'			=>	Component->Lookup($_[0],$_[3]),
					'primarykey'		=>	$_[4],
			) if (defined $_[1]);
		}
	],
	[#Rule 449
		 'home_header', 3,
sub
#line 2801 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'manage'			=>	Component->Lookup($_[0],$_[3]),
			) if (defined $_[1]);
		}
	],
	[#Rule 450
		 'home_header', 3,
sub
#line 2807 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 451
		 'home_header_spec', 4,
sub
#line 2816 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3],
					'list_support'		=>	$_[4],
			);
		}
	],
	[#Rule 452
		 'home_header_spec', 3,
sub
#line 2824 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3],
			);
		}
	],
	[#Rule 453
		 'home_header_spec', 3,
sub
#line 2831 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'list_support'		=>	$_[3],
			);
		}
	],
	[#Rule 454
		 'home_header_spec', 2,
sub
#line 2838 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 455
		 'home_header_spec', 2,
sub
#line 2844 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 456
		 'home_inheritance_spec', 2,
sub
#line 2853 "parser30.yp"
{
			Home->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 457
		 'home_inheritance_spec', 2,
sub
#line 2857 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 458
		 'primary_key_spec', 2,
sub
#line 2866 "parser30.yp"
{
			Value->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 459
		 'primary_key_spec', 2,
sub
#line 2870 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 460
		 'home_body', 2,
sub
#line 2879 "parser30.yp"
{
			[];
		}
	],
	[#Rule 461
		 'home_body', 3,
sub
#line 2883 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 462
		 'home_body', 3,
sub
#line 2887 "parser30.yp"
{
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 463
		 'home_exports', 1,
sub
#line 2895 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 464
		 'home_exports', 2,
sub
#line 2899 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 465
		 'home_export', 1, undef
	],
	[#Rule 466
		 'home_export', 2, undef
	],
	[#Rule 467
		 'home_export', 2, undef
	],
	[#Rule 468
		 'home_export', 2,
sub
#line 2914 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 469
		 'home_export', 2,
sub
#line 2920 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 470
		 'factory_dcl', 2,
sub
#line 2930 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 471
		 'factory_dcl', 1, undef
	],
	[#Rule 472
		 'factory_header_param', 3,
sub
#line 2941 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 473
		 'factory_header_param', 4,
sub
#line 2947 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'		=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 474
		 'factory_header_param', 4,
sub
#line 2955 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 475
		 'factory_header_param', 2,
sub
#line 2962 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 476
		 'factory_header', 2,
sub
#line 2972 "parser30.yp"
{
			new Factory($_[0],							# like Operation
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 477
		 'factory_header', 2,
sub
#line 2978 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 478
		 'finder_dcl', 2,
sub
#line 2987 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 479
		 'finder_dcl', 1, undef
	],
	[#Rule 480
		 'finder_header_param', 3,
sub
#line 2998 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 481
		 'finder_header_param', 4,
sub
#line 3004 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'		=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 482
		 'finder_header_param', 4,
sub
#line 3012 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 483
		 'finder_header_param', 2,
sub
#line 3019 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 484
		 'finder_header', 2,
sub
#line 3029 "parser30.yp"
{
			new Finder($_[0],							# like Operation
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 485
		 'finder_header', 2,
sub
#line 3035 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 486
		 'event', 1, undef
	],
	[#Rule 487
		 'event', 1, undef
	],
	[#Rule 488
		 'event', 1, undef
	],
	[#Rule 489
		 'event_forward_dcl', 2,
sub
#line 3054 "parser30.yp"
{
			new ForwardRegularEvent($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 490
		 'event_forward_dcl', 3,
sub
#line 3060 "parser30.yp"
{
			new ForwardAbstractEvent($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 491
		 'event_abs_dcl', 3,
sub
#line 3070 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 492
		 'event_abs_dcl', 4,
sub
#line 3078 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 493
		 'event_abs_dcl', 4,
sub
#line 3086 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 494
		 'event_abs_header', 3,
sub
#line 3096 "parser30.yp"
{
			new AbstractEvent($_[0],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 495
		 'event_abs_header', 4,
sub
#line 3102 "parser30.yp"
{
			new AbstractEvent($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 496
		 'event_abs_header', 3,
sub
#line 3109 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 497
		 'event_dcl', 3,
sub
#line 3118 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 498
		 'event_dcl', 4,
sub
#line 3126 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 499
		 'event_dcl', 4,
sub
#line 3134 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 500
		 'event_header', 2,
sub
#line 3145 "parser30.yp"
{
			new RegularEvent($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 501
		 'event_header', 3,
sub
#line 3151 "parser30.yp"
{
			new RegularEvent($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 502
		 'event_header', 3,
sub
#line 3158 "parser30.yp"
{
			new RegularEvent($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 503
		 'event_header', 4,
sub
#line 3165 "parser30.yp"
{
			new RegularEvent($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 504
		 'event_header', 2,
sub
#line 3173 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 505
		 'event_header', 3,
sub
#line 3178 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 3184 "parser30.yp"


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
