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
			'IDENTIFIER' => 61,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'error' => 45,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 63,
			'EXCEPTION' => 50,
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
			'module' => 62,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 1
		DEFAULT => -82
	},
	{#State 2
		ACTIONS => {
			'error' => 68,
			'VALUETYPE' => 67,
			'EVENTTYPE' => 66,
			'INTERFACE' => -46
		}
	},
	{#State 3
		ACTIONS => {
			'' => 69
		}
	},
	{#State 4
		ACTIONS => {
			'error' => 71,
			";" => 70
		}
	},
	{#State 5
		ACTIONS => {
			'error' => 72,
			'IDENTIFIER' => 73
		}
	},
	{#State 6
		ACTIONS => {
			"{" => 74
		}
	},
	{#State 7
		ACTIONS => {
			'error' => 76,
			";" => 75
		}
	},
	{#State 8
		DEFAULT => -79
	},
	{#State 9
		ACTIONS => {
			'IMPORT' => 57
		},
		DEFAULT => -5,
		GOTOS => {
			'import' => 9,
			'imports' => 77
		}
	},
	{#State 10
		ACTIONS => {
			"{" => 78
		}
	},
	{#State 11
		DEFAULT => -39
	},
	{#State 12
		ACTIONS => {
			'error' => 80,
			";" => 79
		}
	},
	{#State 13
		ACTIONS => {
			'SHORT' => 104,
			'CHAR' => 90,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'FIXED' => 97,
			'WCHAR' => 85,
			'DOUBLE' => 109,
			'error' => 105,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'OCTET' => 87,
			'FLOAT' => 88,
			'WSTRING' => 95,
			'UNSIGNED' => 102
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 82,
			'signed_int' => 98,
			'wide_string_type' => 91,
			'integer_type' => 108,
			'boolean_type' => 107,
			'char_type' => 83,
			'scoped_name' => 99,
			'octet_type' => 84,
			'wide_char_type' => 100,
			'fixed_pt_const_type' => 92,
			'signed_long_int' => 101,
			'signed_short_int' => 94,
			'const_type' => 112,
			'string_type' => 103,
			'unsigned_longlong_int' => 86,
			'unsigned_long_int' => 114,
			'unsigned_short_int' => 106,
			'signed_longlong_int' => 89
		}
	},
	{#State 14
		DEFAULT => -80
	},
	{#State 15
		DEFAULT => -2
	},
	{#State 16
		ACTIONS => {
			'error' => 115,
			'IDENTIFIER' => 116
		}
	},
	{#State 17
		ACTIONS => {
			'INTERFACE' => 117
		}
	},
	{#State 18
		DEFAULT => -399
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
			'IDENTIFIER' => 61,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 63,
			'EXCEPTION' => 50,
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
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 118,
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
			'module' => 62,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 20
		ACTIONS => {
			"{" => 119
		}
	},
	{#State 21
		ACTIONS => {
			'MANAGES' => 120
		}
	},
	{#State 22
		ACTIONS => {
			"{" => 121
		}
	},
	{#State 23
		ACTIONS => {
			'error' => 122,
			'IDENTIFIER' => 123
		}
	},
	{#State 24
		DEFAULT => -489
	},
	{#State 25
		ACTIONS => {
			"{" => 124
		}
	},
	{#State 26
		DEFAULT => -193
	},
	{#State 27
		ACTIONS => {
			'error' => 126,
			"{" => 125
		}
	},
	{#State 28
		DEFAULT => -194
	},
	{#State 29
		ACTIONS => {
			'error' => 127,
			'IDENTIFIER' => 128
		}
	},
	{#State 30
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 130
		}
	},
	{#State 31
		ACTIONS => {
			"{" => 131
		}
	},
	{#State 32
		ACTIONS => {
			"{" => 132
		},
		GOTOS => {
			'home_body' => 133
		}
	},
	{#State 33
		DEFAULT => -400
	},
	{#State 34
		ACTIONS => {
			'error' => 135,
			";" => 134
		}
	},
	{#State 35
		ACTIONS => {
			'error' => 137,
			";" => 136
		}
	},
	{#State 36
		ACTIONS => {
			'error' => 139,
			"{" => 138
		}
	},
	{#State 37
		DEFAULT => -81
	},
	{#State 38
		ACTIONS => {
			'error' => 140,
			'IDENTIFIER' => 141
		}
	},
	{#State 39
		ACTIONS => {
			'error' => 143,
			";" => 142
		}
	},
	{#State 40
		DEFAULT => -488
	},
	{#State 41
		ACTIONS => {
			'error' => 144,
			'IDENTIFIER' => 145
		}
	},
	{#State 42
		ACTIONS => {
			'error' => 147,
			";" => 146
		}
	},
	{#State 43
		DEFAULT => -40
	},
	{#State 44
		DEFAULT => -195
	},
	{#State 45
		DEFAULT => -4
	},
	{#State 46
		DEFAULT => -197
	},
	{#State 47
		ACTIONS => {
			'error' => 149,
			"{" => 148
		}
	},
	{#State 48
		DEFAULT => -47
	},
	{#State 49
		ACTIONS => {
			'SWITCH' => 150
		}
	},
	{#State 50
		ACTIONS => {
			'error' => 151,
			'IDENTIFIER' => 152
		}
	},
	{#State 51
		ACTIONS => {
			'error' => 154,
			";" => 153
		}
	},
	{#State 52
		ACTIONS => {
			'error' => 156,
			";" => 155
		}
	},
	{#State 53
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 159
		},
		GOTOS => {
			'simple_declarator' => 158
		}
	},
	{#State 54
		ACTIONS => {
			'error' => 160,
			'IDENTIFIER' => 161
		}
	},
	{#State 55
		DEFAULT => -490
	},
	{#State 56
		ACTIONS => {
			'error' => 163,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 162
		}
	},
	{#State 57
		ACTIONS => {
			'error' => 167,
			'IDENTIFIER' => 113,
			"::" => 93,
			'STRING_LITERAL' => 168
		},
		GOTOS => {
			'scoped_name' => 166,
			'string_literal' => 164,
			'imported_scope' => 165
		}
	},
	{#State 58
		ACTIONS => {
			'error' => 171,
			'IDENTIFIER' => 113,
			"::" => 169
		},
		GOTOS => {
			'scoped_name' => 170
		}
	},
	{#State 59
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'FIXED' => 187,
			'VALUEBASE' => 179,
			'SEQUENCE' => 173,
			'STRUCT' => 181,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'UNION' => 184,
			'WCHAR' => 85,
			'error' => 195,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ENUM' => 16,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 190,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'type_spec' => 176,
			'type_declarator' => 177,
			'string_type' => 192,
			'struct_header' => 10,
			'base_type_spec' => 193,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'enum_type' => 194,
			'enum_header' => 47,
			'unsigned_short_int' => 106,
			'union_header' => 49,
			'signed_longlong_int' => 89,
			'wide_string_type' => 180,
			'boolean_type' => 198,
			'integer_type' => 199,
			'signed_short_int' => 94,
			'struct_type' => 182,
			'union_type' => 183,
			'sequence_type' => 200,
			'unsigned_long_int' => 114,
			'template_type_spec' => 185,
			'constr_type_spec' => 186,
			'simple_type_spec' => 201,
			'fixed_pt_type' => 202
		}
	},
	{#State 60
		ACTIONS => {
			"{" => 203
		}
	},
	{#State 61
		ACTIONS => {
			'error' => 204
		}
	},
	{#State 62
		ACTIONS => {
			'error' => 206,
			";" => 205
		}
	},
	{#State 63
		ACTIONS => {
			'error' => 209,
			'VALUETYPE' => 208,
			'EVENTTYPE' => 207
		}
	},
	{#State 64
		ACTIONS => {
			'error' => 211,
			";" => 210
		}
	},
	{#State 65
		ACTIONS => {
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
			'IDENTIFIER' => 61,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 63,
			'EXCEPTION' => 50,
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
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 212,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 51,
			'imports' => 213,
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
			'module' => 62,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 66
		ACTIONS => {
			'error' => 214,
			'IDENTIFIER' => 215
		}
	},
	{#State 67
		ACTIONS => {
			'error' => 216,
			'IDENTIFIER' => 217
		}
	},
	{#State 68
		DEFAULT => -92
	},
	{#State 69
		DEFAULT => 0
	},
	{#State 70
		DEFAULT => -13
	},
	{#State 71
		DEFAULT => -24
	},
	{#State 72
		DEFAULT => -506
	},
	{#State 73
		ACTIONS => {
			"{" => -502,
			":" => 220,
			'SUPPORTS' => 218
		},
		DEFAULT => -491,
		GOTOS => {
			'supported_interface_spec' => 221,
			'value_inheritance_spec' => 219
		}
	},
	{#State 74
		ACTIONS => {
			'ONEWAY' => 222,
			'UNSIGNED' => -326,
			'SHORT' => -326,
			'WCHAR' => -326,
			'error' => 231,
			'CONST' => 13,
			"}" => 232,
			'EXCEPTION' => 50,
			'FLOAT' => -326,
			'OCTET' => -326,
			'ENUM' => 16,
			'ANY' => -326,
			'CHAR' => -326,
			'OBJECT' => -326,
			'NATIVE' => 53,
			'VALUEBASE' => -326,
			'VOID' => -326,
			'STRUCT' => 23,
			'DOUBLE' => -326,
			'TYPEID' => 56,
			'LONG' => -326,
			'STRING' => -326,
			"::" => -326,
			'TYPEPREFIX' => 58,
			'WSTRING' => -326,
			'BOOLEAN' => -326,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -326,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238
		},
		GOTOS => {
			'const_dcl' => 233,
			'op_mod' => 223,
			'except_dcl' => 229,
			'attr_spec' => 224,
			'op_attribute' => 225,
			'readonly_attr_spec' => 226,
			'exports' => 234,
			'type_id_dcl' => 230,
			'export' => 235,
			'struct_type' => 26,
			'op_header' => 236,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 239,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'type_dcl' => 240,
			'union_header' => 49
		}
	},
	{#State 75
		DEFAULT => -19
	},
	{#State 76
		DEFAULT => -30
	},
	{#State 77
		DEFAULT => -6
	},
	{#State 78
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'FIXED' => 187,
			'VALUEBASE' => 179,
			'SEQUENCE' => 173,
			'STRUCT' => 181,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'UNION' => 184,
			'WCHAR' => 85,
			'error' => 243,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ENUM' => 16,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 190,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'type_spec' => 241,
			'string_type' => 192,
			'struct_header' => 10,
			'base_type_spec' => 193,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'enum_type' => 194,
			'enum_header' => 47,
			'member_list' => 242,
			'unsigned_short_int' => 106,
			'union_header' => 49,
			'signed_longlong_int' => 89,
			'wide_string_type' => 180,
			'boolean_type' => 198,
			'integer_type' => 199,
			'signed_short_int' => 94,
			'member' => 244,
			'struct_type' => 182,
			'union_type' => 183,
			'sequence_type' => 200,
			'unsigned_long_int' => 114,
			'template_type_spec' => 185,
			'constr_type_spec' => 186,
			'simple_type_spec' => 201,
			'fixed_pt_type' => 202
		}
	},
	{#State 79
		DEFAULT => -17
	},
	{#State 80
		DEFAULT => -28
	},
	{#State 81
		DEFAULT => -233
	},
	{#State 82
		DEFAULT => -145
	},
	{#State 83
		DEFAULT => -142
	},
	{#State 84
		DEFAULT => -150
	},
	{#State 85
		DEFAULT => -247
	},
	{#State 86
		DEFAULT => -242
	},
	{#State 87
		DEFAULT => -249
	},
	{#State 88
		DEFAULT => -229
	},
	{#State 89
		DEFAULT => -236
	},
	{#State 90
		DEFAULT => -246
	},
	{#State 91
		DEFAULT => -147
	},
	{#State 92
		DEFAULT => -148
	},
	{#State 93
		ACTIONS => {
			'error' => 245,
			'IDENTIFIER' => 246
		}
	},
	{#State 94
		DEFAULT => -234
	},
	{#State 95
		ACTIONS => {
			"<" => 247
		},
		DEFAULT => -303
	},
	{#State 96
		DEFAULT => -248
	},
	{#State 97
		DEFAULT => -361
	},
	{#State 98
		DEFAULT => -232
	},
	{#State 99
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -149
	},
	{#State 100
		DEFAULT => -143
	},
	{#State 101
		DEFAULT => -235
	},
	{#State 102
		ACTIONS => {
			'SHORT' => 249,
			'LONG' => 250
		}
	},
	{#State 103
		DEFAULT => -146
	},
	{#State 104
		DEFAULT => -237
	},
	{#State 105
		DEFAULT => -140
	},
	{#State 106
		DEFAULT => -240
	},
	{#State 107
		DEFAULT => -144
	},
	{#State 108
		DEFAULT => -141
	},
	{#State 109
		DEFAULT => -230
	},
	{#State 110
		ACTIONS => {
			'DOUBLE' => 251,
			'LONG' => 252
		},
		DEFAULT => -238
	},
	{#State 111
		ACTIONS => {
			"<" => 253
		},
		DEFAULT => -300
	},
	{#State 112
		ACTIONS => {
			'error' => 254,
			'IDENTIFIER' => 255
		}
	},
	{#State 113
		DEFAULT => -74
	},
	{#State 114
		DEFAULT => -241
	},
	{#State 115
		DEFAULT => -288
	},
	{#State 116
		DEFAULT => -287
	},
	{#State 117
		ACTIONS => {
			'error' => 256,
			'IDENTIFIER' => 257
		}
	},
	{#State 118
		DEFAULT => -1
	},
	{#State 119
		ACTIONS => {
			'ONEWAY' => 222,
			'UNSIGNED' => -326,
			'SHORT' => -326,
			'WCHAR' => -326,
			'error' => 258,
			'CONST' => 13,
			"}" => 259,
			'EXCEPTION' => 50,
			'FLOAT' => -326,
			'OCTET' => -326,
			'ENUM' => 16,
			'ANY' => -326,
			'CHAR' => -326,
			'OBJECT' => -326,
			'NATIVE' => 53,
			'VALUEBASE' => -326,
			'VOID' => -326,
			'STRUCT' => 23,
			'DOUBLE' => -326,
			'TYPEID' => 56,
			'LONG' => -326,
			'STRING' => -326,
			"::" => -326,
			'TYPEPREFIX' => 58,
			'WSTRING' => -326,
			'BOOLEAN' => -326,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -326,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238
		},
		GOTOS => {
			'const_dcl' => 233,
			'op_mod' => 223,
			'except_dcl' => 229,
			'attr_spec' => 224,
			'op_attribute' => 225,
			'readonly_attr_spec' => 226,
			'exports' => 260,
			'type_id_dcl' => 230,
			'export' => 235,
			'struct_type' => 26,
			'op_header' => 236,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 239,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'type_dcl' => 240,
			'union_header' => 49,
			'interface_body' => 261
		}
	},
	{#State 120
		ACTIONS => {
			'error' => 263,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 262
		}
	},
	{#State 121
		ACTIONS => {
			'PRIVATE' => 265,
			'ONEWAY' => 222,
			'FACTORY' => 271,
			'UNSIGNED' => -326,
			'SHORT' => -326,
			'WCHAR' => -326,
			'error' => 273,
			'CONST' => 13,
			'EXCEPTION' => 50,
			"}" => 274,
			'FLOAT' => -326,
			'OCTET' => -326,
			'ENUM' => 16,
			'ANY' => -326,
			'CHAR' => -326,
			'OBJECT' => -326,
			'NATIVE' => 53,
			'VALUEBASE' => -326,
			'VOID' => -326,
			'STRUCT' => 23,
			'DOUBLE' => -326,
			'TYPEID' => 56,
			'LONG' => -326,
			'STRING' => -326,
			"::" => -326,
			'TYPEPREFIX' => 58,
			'WSTRING' => -326,
			'BOOLEAN' => -326,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -326,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238,
			'PUBLIC' => 268
		},
		GOTOS => {
			'init_header_param' => 264,
			'const_dcl' => 233,
			'op_mod' => 223,
			'value_elements' => 275,
			'except_dcl' => 229,
			'state_member' => 270,
			'attr_spec' => 224,
			'op_attribute' => 225,
			'state_mod' => 266,
			'value_element' => 267,
			'readonly_attr_spec' => 226,
			'type_id_dcl' => 230,
			'export' => 276,
			'init_header' => 272,
			'struct_type' => 26,
			'op_header' => 236,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 239,
			'enum_type' => 44,
			'init_dcl' => 269,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'type_dcl' => 240,
			'union_header' => 49
		}
	},
	{#State 122
		ACTIONS => {
			"{" => -255
		},
		DEFAULT => -364
	},
	{#State 123
		ACTIONS => {
			"{" => -254
		},
		DEFAULT => -363
	},
	{#State 124
		ACTIONS => {
			'ONEWAY' => 222,
			'UNSIGNED' => -326,
			'SHORT' => -326,
			'WCHAR' => -326,
			'error' => 277,
			'CONST' => 13,
			"}" => 278,
			'EXCEPTION' => 50,
			'FLOAT' => -326,
			'OCTET' => -326,
			'ENUM' => 16,
			'ANY' => -326,
			'CHAR' => -326,
			'OBJECT' => -326,
			'NATIVE' => 53,
			'VALUEBASE' => -326,
			'VOID' => -326,
			'STRUCT' => 23,
			'DOUBLE' => -326,
			'TYPEID' => 56,
			'LONG' => -326,
			'STRING' => -326,
			"::" => -326,
			'TYPEPREFIX' => 58,
			'WSTRING' => -326,
			'BOOLEAN' => -326,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -326,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238
		},
		GOTOS => {
			'const_dcl' => 233,
			'op_mod' => 223,
			'except_dcl' => 229,
			'attr_spec' => 224,
			'op_attribute' => 225,
			'readonly_attr_spec' => 226,
			'exports' => 279,
			'type_id_dcl' => 230,
			'export' => 235,
			'struct_type' => 26,
			'op_header' => 236,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 239,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'type_dcl' => 240,
			'union_header' => 49
		}
	},
	{#State 125
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'FIXED' => 187,
			'VALUEBASE' => 179,
			'SEQUENCE' => 173,
			'STRUCT' => 181,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'UNION' => 184,
			'WCHAR' => 85,
			'error' => 281,
			"}" => 282,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ENUM' => 16,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 190,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'type_spec' => 241,
			'string_type' => 192,
			'struct_header' => 10,
			'base_type_spec' => 193,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'enum_type' => 194,
			'enum_header' => 47,
			'member_list' => 280,
			'unsigned_short_int' => 106,
			'union_header' => 49,
			'signed_longlong_int' => 89,
			'wide_string_type' => 180,
			'boolean_type' => 198,
			'integer_type' => 199,
			'signed_short_int' => 94,
			'member' => 244,
			'struct_type' => 182,
			'union_type' => 183,
			'sequence_type' => 200,
			'unsigned_long_int' => 114,
			'template_type_spec' => 185,
			'constr_type_spec' => 186,
			'simple_type_spec' => 201,
			'fixed_pt_type' => 202
		}
	},
	{#State 126
		DEFAULT => -315
	},
	{#State 127
		ACTIONS => {
			'SWITCH' => -266
		},
		DEFAULT => -366
	},
	{#State 128
		ACTIONS => {
			'SWITCH' => -265
		},
		DEFAULT => -365
	},
	{#State 129
		DEFAULT => -457
	},
	{#State 130
		ACTIONS => {
			":" => 284,
			'SUPPORTS' => 218
		},
		DEFAULT => -456,
		GOTOS => {
			'home_inheritance_spec' => 283,
			'supported_interface_spec' => 285
		}
	},
	{#State 131
		ACTIONS => {
			'error' => 296,
			'PUBLISHES' => 299,
			"}" => 297,
			'USES' => 291,
			'READONLY' => 237,
			'PROVIDES' => 298,
			'CONSUMES' => 301,
			'ATTRIBUTE' => 238,
			'EMITS' => 294
		},
		GOTOS => {
			'consumes_dcl' => 286,
			'emits_dcl' => 293,
			'attr_spec' => 224,
			'provides_dcl' => 290,
			'readonly_attr_spec' => 226,
			'component_exports' => 287,
			'attr_dcl' => 292,
			'publishes_dcl' => 288,
			'uses_dcl' => 300,
			'component_export' => 289,
			'component_body' => 295
		}
	},
	{#State 132
		ACTIONS => {
			'ONEWAY' => 222,
			'FACTORY' => 308,
			'UNSIGNED' => -326,
			'SHORT' => -326,
			'WCHAR' => -326,
			'error' => 309,
			'CONST' => 13,
			'OCTET' => -326,
			'FLOAT' => -326,
			'EXCEPTION' => 50,
			"}" => 310,
			'ENUM' => 16,
			'FINDER' => 303,
			'ANY' => -326,
			'CHAR' => -326,
			'OBJECT' => -326,
			'NATIVE' => 53,
			'VALUEBASE' => -326,
			'VOID' => -326,
			'STRUCT' => 23,
			'DOUBLE' => -326,
			'TYPEID' => 56,
			'LONG' => -326,
			'STRING' => -326,
			"::" => -326,
			'TYPEPREFIX' => 58,
			'WSTRING' => -326,
			'TYPEDEF' => 59,
			'BOOLEAN' => -326,
			'IDENTIFIER' => -326,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238
		},
		GOTOS => {
			'const_dcl' => 233,
			'op_mod' => 223,
			'except_dcl' => 229,
			'attr_spec' => 224,
			'factory_header_param' => 302,
			'home_exports' => 305,
			'home_export' => 304,
			'op_attribute' => 225,
			'readonly_attr_spec' => 226,
			'finder_dcl' => 306,
			'type_id_dcl' => 230,
			'export' => 311,
			'struct_type' => 26,
			'finder_header' => 312,
			'exception_header' => 27,
			'union_type' => 28,
			'op_header' => 236,
			'struct_header' => 10,
			'factory_dcl' => 307,
			'enum_type' => 44,
			'finder_header_param' => 313,
			'op_dcl' => 239,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'union_header' => 49,
			'type_dcl' => 240,
			'factory_header' => 314
		}
	},
	{#State 133
		DEFAULT => -449
	},
	{#State 134
		DEFAULT => -18
	},
	{#State 135
		DEFAULT => -29
	},
	{#State 136
		DEFAULT => -12
	},
	{#State 137
		DEFAULT => -23
	},
	{#State 138
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
			'IDENTIFIER' => 61,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'error' => 316,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 63,
			'EXCEPTION' => 50,
			"}" => 317,
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
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 315,
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
			'module' => 62,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 139
		ACTIONS => {
			"}" => 318
		}
	},
	{#State 140
		DEFAULT => -102
	},
	{#State 141
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'FIXED' => 187,
			'VALUEBASE' => 179,
			'SEQUENCE' => 173,
			'STRUCT' => 181,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			":" => 220,
			'UNION' => 184,
			'WCHAR' => 85,
			"{" => -98,
			'FLOAT' => 88,
			'OCTET' => 87,
			'SUPPORTS' => 218,
			'ENUM' => 16,
			'ANY' => 196
		},
		DEFAULT => -83,
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 190,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'type_spec' => 319,
			'string_type' => 192,
			'struct_header' => 10,
			'base_type_spec' => 193,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'enum_type' => 194,
			'enum_header' => 47,
			'unsigned_short_int' => 106,
			'union_header' => 49,
			'signed_longlong_int' => 89,
			'wide_string_type' => 180,
			'boolean_type' => 198,
			'integer_type' => 199,
			'signed_short_int' => 94,
			'value_inheritance_spec' => 320,
			'struct_type' => 182,
			'union_type' => 183,
			'sequence_type' => 200,
			'unsigned_long_int' => 114,
			'template_type_spec' => 185,
			'constr_type_spec' => 186,
			'simple_type_spec' => 201,
			'fixed_pt_type' => 202,
			'supported_interface_spec' => 221
		}
	},
	{#State 142
		DEFAULT => -16
	},
	{#State 143
		DEFAULT => -27
	},
	{#State 144
		DEFAULT => -38
	},
	{#State 145
		DEFAULT => -37
	},
	{#State 146
		DEFAULT => -15
	},
	{#State 147
		DEFAULT => -26
	},
	{#State 148
		ACTIONS => {
			'error' => 323,
			'IDENTIFIER' => 324
		},
		GOTOS => {
			'enumerators' => 322,
			'enumerator' => 321
		}
	},
	{#State 149
		DEFAULT => -286
	},
	{#State 150
		ACTIONS => {
			'error' => 326,
			"(" => 325
		}
	},
	{#State 151
		DEFAULT => -317
	},
	{#State 152
		DEFAULT => -316
	},
	{#State 153
		DEFAULT => -11
	},
	{#State 154
		DEFAULT => -22
	},
	{#State 155
		DEFAULT => -20
	},
	{#State 156
		DEFAULT => -31
	},
	{#State 157
		ACTIONS => {
			";" => 327,
			"," => 328
		}
	},
	{#State 158
		DEFAULT => -196
	},
	{#State 159
		DEFAULT => -225
	},
	{#State 160
		ACTIONS => {
			"{" => -410
		},
		DEFAULT => -402
	},
	{#State 161
		ACTIONS => {
			"{" => -409,
			":" => 330,
			'SUPPORTS' => 218
		},
		DEFAULT => -401,
		GOTOS => {
			'component_inheritance_spec' => 329,
			'supported_interface_spec' => 331
		}
	},
	{#State 162
		ACTIONS => {
			'error' => 333,
			"::" => 248,
			'STRING_LITERAL' => 168
		},
		GOTOS => {
			'string_literal' => 332
		}
	},
	{#State 163
		DEFAULT => -374
	},
	{#State 164
		DEFAULT => -371
	},
	{#State 165
		ACTIONS => {
			'error' => 335,
			";" => 334
		}
	},
	{#State 166
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -370
	},
	{#State 167
		DEFAULT => -369
	},
	{#State 168
		ACTIONS => {
			'STRING_LITERAL' => 168
		},
		DEFAULT => -185,
		GOTOS => {
			'string_literal' => 336
		}
	},
	{#State 169
		ACTIONS => {
			'error' => 245,
			'IDENTIFIER' => 246,
			'STRING_LITERAL' => 168
		},
		GOTOS => {
			'string_literal' => 337
		}
	},
	{#State 170
		ACTIONS => {
			'error' => 339,
			"::" => 248,
			'STRING_LITERAL' => 168
		},
		GOTOS => {
			'string_literal' => 338
		}
	},
	{#State 171
		DEFAULT => -378
	},
	{#State 172
		DEFAULT => -205
	},
	{#State 173
		ACTIONS => {
			'error' => 341,
			"<" => 340
		}
	},
	{#State 174
		DEFAULT => -207
	},
	{#State 175
		DEFAULT => -210
	},
	{#State 176
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 347
		},
		GOTOS => {
			'declarators' => 342,
			'declarator' => 345,
			'simple_declarator' => 346,
			'array_declarator' => 344,
			'complex_declarator' => 343
		}
	},
	{#State 177
		DEFAULT => -192
	},
	{#State 178
		DEFAULT => -211
	},
	{#State 179
		DEFAULT => -362
	},
	{#State 180
		DEFAULT => -216
	},
	{#State 181
		ACTIONS => {
			'error' => 348,
			'IDENTIFIER' => 349
		}
	},
	{#State 182
		DEFAULT => -218
	},
	{#State 183
		DEFAULT => -219
	},
	{#State 184
		ACTIONS => {
			'error' => 350,
			'IDENTIFIER' => 351
		}
	},
	{#State 185
		DEFAULT => -203
	},
	{#State 186
		DEFAULT => -201
	},
	{#State 187
		ACTIONS => {
			'error' => 353,
			"<" => 352
		}
	},
	{#State 188
		DEFAULT => -213
	},
	{#State 189
		DEFAULT => -212
	},
	{#State 190
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -204
	},
	{#State 191
		DEFAULT => -208
	},
	{#State 192
		DEFAULT => -215
	},
	{#State 193
		DEFAULT => -202
	},
	{#State 194
		DEFAULT => -220
	},
	{#State 195
		DEFAULT => -198
	},
	{#State 196
		DEFAULT => -250
	},
	{#State 197
		DEFAULT => -251
	},
	{#State 198
		DEFAULT => -209
	},
	{#State 199
		DEFAULT => -206
	},
	{#State 200
		DEFAULT => -214
	},
	{#State 201
		DEFAULT => -200
	},
	{#State 202
		DEFAULT => -217
	},
	{#State 203
		ACTIONS => {
			'PRIVATE' => 265,
			'ONEWAY' => 222,
			'FACTORY' => 271,
			'UNSIGNED' => -326,
			'SHORT' => -326,
			'WCHAR' => -326,
			'error' => 354,
			'CONST' => 13,
			'EXCEPTION' => 50,
			"}" => 355,
			'FLOAT' => -326,
			'OCTET' => -326,
			'ENUM' => 16,
			'ANY' => -326,
			'CHAR' => -326,
			'OBJECT' => -326,
			'NATIVE' => 53,
			'VALUEBASE' => -326,
			'VOID' => -326,
			'STRUCT' => 23,
			'DOUBLE' => -326,
			'TYPEID' => 56,
			'LONG' => -326,
			'STRING' => -326,
			"::" => -326,
			'TYPEPREFIX' => 58,
			'WSTRING' => -326,
			'BOOLEAN' => -326,
			'TYPEDEF' => 59,
			'IDENTIFIER' => -326,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238,
			'PUBLIC' => 268
		},
		GOTOS => {
			'init_header_param' => 264,
			'const_dcl' => 233,
			'op_mod' => 223,
			'value_elements' => 356,
			'except_dcl' => 229,
			'state_member' => 270,
			'attr_spec' => 224,
			'op_attribute' => 225,
			'state_mod' => 266,
			'value_element' => 267,
			'readonly_attr_spec' => 226,
			'type_id_dcl' => 230,
			'export' => 276,
			'init_header' => 272,
			'struct_type' => 26,
			'op_header' => 236,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 239,
			'enum_type' => 44,
			'init_dcl' => 269,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'type_dcl' => 240,
			'union_header' => 49
		}
	},
	{#State 204
		ACTIONS => {
			";" => 357
		}
	},
	{#State 205
		DEFAULT => -14
	},
	{#State 206
		DEFAULT => -25
	},
	{#State 207
		ACTIONS => {
			'error' => 358,
			'IDENTIFIER' => 359
		}
	},
	{#State 208
		ACTIONS => {
			'error' => 360,
			'IDENTIFIER' => 361
		}
	},
	{#State 209
		DEFAULT => -104
	},
	{#State 210
		DEFAULT => -10
	},
	{#State 211
		DEFAULT => -21
	},
	{#State 212
		DEFAULT => -8
	},
	{#State 213
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
			'IDENTIFIER' => 61,
			'MODULE' => 41,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 48,
			'CONST' => 13,
			'CUSTOM' => 63,
			'EXCEPTION' => 50,
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
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 12,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 362,
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
			'module' => 62,
			'type_dcl' => 64,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 214
		DEFAULT => -498
	},
	{#State 215
		ACTIONS => {
			"{" => -496,
			":" => 220,
			'SUPPORTS' => 218
		},
		DEFAULT => -492,
		GOTOS => {
			'supported_interface_spec' => 221,
			'value_inheritance_spec' => 363
		}
	},
	{#State 216
		DEFAULT => -91
	},
	{#State 217
		ACTIONS => {
			"{" => -89,
			":" => 220,
			'SUPPORTS' => 218
		},
		DEFAULT => -84,
		GOTOS => {
			'supported_interface_spec' => 221,
			'value_inheritance_spec' => 364
		}
	},
	{#State 218
		ACTIONS => {
			'error' => 367,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 366,
			'interface_name' => 368,
			'interface_names' => 365
		}
	},
	{#State 219
		DEFAULT => -504
	},
	{#State 220
		ACTIONS => {
			'TRUNCATABLE' => 370
		},
		DEFAULT => -110,
		GOTOS => {
			'inheritance_mod' => 369
		}
	},
	{#State 221
		DEFAULT => -108
	},
	{#State 222
		DEFAULT => -327
	},
	{#State 223
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'VALUEBASE' => 179,
			'VOID' => 376,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'WCHAR' => 85,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'wide_string_type' => 372,
			'integer_type' => 199,
			'boolean_type' => 198,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 373,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'signed_short_int' => 94,
			'string_type' => 374,
			'op_type_spec' => 377,
			'base_type_spec' => 375,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'unsigned_long_int' => 114,
			'param_type_spec' => 371,
			'unsigned_short_int' => 106,
			'signed_longlong_int' => 89
		}
	},
	{#State 224
		DEFAULT => -311
	},
	{#State 225
		DEFAULT => -325
	},
	{#State 226
		DEFAULT => -310
	},
	{#State 227
		ACTIONS => {
			'error' => 379,
			";" => 378
		}
	},
	{#State 228
		ACTIONS => {
			'error' => 381,
			";" => 380
		}
	},
	{#State 229
		ACTIONS => {
			'error' => 383,
			";" => 382
		}
	},
	{#State 230
		ACTIONS => {
			'error' => 385,
			";" => 384
		}
	},
	{#State 231
		ACTIONS => {
			"}" => 386
		}
	},
	{#State 232
		DEFAULT => -86
	},
	{#State 233
		ACTIONS => {
			'error' => 388,
			";" => 387
		}
	},
	{#State 234
		ACTIONS => {
			"}" => 389
		}
	},
	{#State 235
		ACTIONS => {
			'ONEWAY' => 222,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238,
			'CONST' => 13,
			'EXCEPTION' => 50,
			"}" => -53,
			'ENUM' => 16
		},
		DEFAULT => -326,
		GOTOS => {
			'const_dcl' => 233,
			'op_mod' => 223,
			'except_dcl' => 229,
			'attr_spec' => 224,
			'op_attribute' => 225,
			'readonly_attr_spec' => 226,
			'exports' => 390,
			'type_id_dcl' => 230,
			'export' => 235,
			'struct_type' => 26,
			'op_header' => 236,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 239,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'type_dcl' => 240,
			'union_header' => 49
		}
	},
	{#State 236
		ACTIONS => {
			'error' => 392,
			"(" => 391
		},
		GOTOS => {
			'parameter_dcls' => 393
		}
	},
	{#State 237
		ACTIONS => {
			'error' => 394,
			'ATTRIBUTE' => 395
		}
	},
	{#State 238
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'VALUEBASE' => 179,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'WCHAR' => 85,
			'error' => 397,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'wide_string_type' => 372,
			'integer_type' => 199,
			'boolean_type' => 198,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 373,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'signed_short_int' => 94,
			'string_type' => 374,
			'base_type_spec' => 375,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'unsigned_long_int' => 114,
			'param_type_spec' => 396,
			'unsigned_short_int' => 106,
			'signed_longlong_int' => 89
		}
	},
	{#State 239
		ACTIONS => {
			'error' => 399,
			";" => 398
		}
	},
	{#State 240
		ACTIONS => {
			'error' => 401,
			";" => 400
		}
	},
	{#State 241
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 347
		},
		GOTOS => {
			'declarators' => 402,
			'declarator' => 345,
			'simple_declarator' => 346,
			'array_declarator' => 344,
			'complex_declarator' => 343
		}
	},
	{#State 242
		ACTIONS => {
			"}" => 403
		}
	},
	{#State 243
		ACTIONS => {
			"}" => 404
		}
	},
	{#State 244
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'FIXED' => 187,
			'VALUEBASE' => 179,
			'SEQUENCE' => 173,
			'STRUCT' => 181,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'UNION' => 184,
			'WCHAR' => 85,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ENUM' => 16,
			'ANY' => 196
		},
		DEFAULT => -256,
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 190,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'type_spec' => 241,
			'string_type' => 192,
			'struct_header' => 10,
			'base_type_spec' => 193,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'enum_type' => 194,
			'enum_header' => 47,
			'member_list' => 405,
			'unsigned_short_int' => 106,
			'union_header' => 49,
			'signed_longlong_int' => 89,
			'wide_string_type' => 180,
			'boolean_type' => 198,
			'integer_type' => 199,
			'signed_short_int' => 94,
			'member' => 244,
			'struct_type' => 182,
			'union_type' => 183,
			'sequence_type' => 200,
			'unsigned_long_int' => 114,
			'template_type_spec' => 185,
			'constr_type_spec' => 186,
			'simple_type_spec' => 201,
			'fixed_pt_type' => 202
		}
	},
	{#State 245
		DEFAULT => -76
	},
	{#State 246
		DEFAULT => -75
	},
	{#State 247
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 421,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'primary_expr' => 427,
			'and_expr' => 428,
			'scoped_name' => 419,
			'positive_int_const' => 420,
			'wide_string_literal' => 407,
			'boolean_literal' => 409,
			'mult_expr' => 430,
			'const_exp' => 410,
			'or_expr' => 411,
			'unary_expr' => 432,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 248
		ACTIONS => {
			'error' => 435,
			'IDENTIFIER' => 436
		}
	},
	{#State 249
		DEFAULT => -243
	},
	{#State 250
		ACTIONS => {
			'LONG' => 437
		},
		DEFAULT => -244
	},
	{#State 251
		DEFAULT => -231
	},
	{#State 252
		DEFAULT => -239
	},
	{#State 253
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 439,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'primary_expr' => 427,
			'and_expr' => 428,
			'scoped_name' => 419,
			'positive_int_const' => 438,
			'wide_string_literal' => 407,
			'boolean_literal' => 409,
			'mult_expr' => 430,
			'const_exp' => 410,
			'or_expr' => 411,
			'unary_expr' => 432,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 254
		DEFAULT => -139
	},
	{#State 255
		ACTIONS => {
			'error' => 440,
			"=" => 441
		}
	},
	{#State 256
		ACTIONS => {
			"{" => -51
		},
		DEFAULT => -45
	},
	{#State 257
		ACTIONS => {
			"{" => -49,
			":" => 443
		},
		DEFAULT => -44,
		GOTOS => {
			'interface_inheritance_spec' => 442
		}
	},
	{#State 258
		ACTIONS => {
			"}" => 444
		}
	},
	{#State 259
		DEFAULT => -41
	},
	{#State 260
		DEFAULT => -52
	},
	{#State 261
		ACTIONS => {
			"}" => 445
		}
	},
	{#State 262
		ACTIONS => {
			"::" => 248,
			'PRIMARYKEY' => 446
		},
		DEFAULT => -451,
		GOTOS => {
			'primary_key_spec' => 447
		}
	},
	{#State 263
		DEFAULT => -452
	},
	{#State 264
		ACTIONS => {
			'error' => 450,
			'RAISES' => 449,
			";" => 448
		},
		GOTOS => {
			'raises_expr' => 451
		}
	},
	{#State 265
		DEFAULT => -120
	},
	{#State 266
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'FIXED' => 187,
			'VALUEBASE' => 179,
			'SEQUENCE' => 173,
			'STRUCT' => 181,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'UNION' => 184,
			'WCHAR' => 85,
			'error' => 453,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ENUM' => 16,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 190,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'type_spec' => 452,
			'string_type' => 192,
			'struct_header' => 10,
			'base_type_spec' => 193,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'enum_type' => 194,
			'enum_header' => 47,
			'unsigned_short_int' => 106,
			'union_header' => 49,
			'signed_longlong_int' => 89,
			'wide_string_type' => 180,
			'boolean_type' => 198,
			'integer_type' => 199,
			'signed_short_int' => 94,
			'struct_type' => 182,
			'union_type' => 183,
			'sequence_type' => 200,
			'unsigned_long_int' => 114,
			'template_type_spec' => 185,
			'constr_type_spec' => 186,
			'simple_type_spec' => 201,
			'fixed_pt_type' => 202
		}
	},
	{#State 267
		ACTIONS => {
			'PRIVATE' => 265,
			'ONEWAY' => 222,
			'FACTORY' => 271,
			'CONST' => 13,
			'EXCEPTION' => 50,
			"}" => -96,
			'ENUM' => 16,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238,
			'PUBLIC' => 268
		},
		DEFAULT => -326,
		GOTOS => {
			'init_header_param' => 264,
			'const_dcl' => 233,
			'op_mod' => 223,
			'value_elements' => 454,
			'except_dcl' => 229,
			'state_member' => 270,
			'attr_spec' => 224,
			'op_attribute' => 225,
			'state_mod' => 266,
			'value_element' => 267,
			'readonly_attr_spec' => 226,
			'type_id_dcl' => 230,
			'export' => 276,
			'init_header' => 272,
			'struct_type' => 26,
			'op_header' => 236,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 10,
			'op_dcl' => 239,
			'enum_type' => 44,
			'init_dcl' => 269,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'type_dcl' => 240,
			'union_header' => 49
		}
	},
	{#State 268
		DEFAULT => -119
	},
	{#State 269
		DEFAULT => -116
	},
	{#State 270
		DEFAULT => -115
	},
	{#State 271
		ACTIONS => {
			'error' => 455,
			'IDENTIFIER' => 456
		}
	},
	{#State 272
		ACTIONS => {
			'error' => 458,
			"(" => 457
		}
	},
	{#State 273
		ACTIONS => {
			"}" => 459
		}
	},
	{#State 274
		DEFAULT => -93
	},
	{#State 275
		ACTIONS => {
			"}" => 460
		}
	},
	{#State 276
		DEFAULT => -114
	},
	{#State 277
		ACTIONS => {
			"}" => 461
		}
	},
	{#State 278
		DEFAULT => -493
	},
	{#State 279
		ACTIONS => {
			"}" => 462
		}
	},
	{#State 280
		ACTIONS => {
			"}" => 463
		}
	},
	{#State 281
		ACTIONS => {
			"}" => 464
		}
	},
	{#State 282
		DEFAULT => -312
	},
	{#State 283
		ACTIONS => {
			'SUPPORTS' => 218
		},
		DEFAULT => -454,
		GOTOS => {
			'supported_interface_spec' => 465
		}
	},
	{#State 284
		ACTIONS => {
			'error' => 467,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 466
		}
	},
	{#State 285
		DEFAULT => -455
	},
	{#State 286
		ACTIONS => {
			'error' => 469,
			";" => 468
		}
	},
	{#State 287
		DEFAULT => -415
	},
	{#State 288
		ACTIONS => {
			'error' => 471,
			";" => 470
		}
	},
	{#State 289
		ACTIONS => {
			'PUBLISHES' => 299,
			'USES' => 291,
			'READONLY' => 237,
			'PROVIDES' => 298,
			'ATTRIBUTE' => 238,
			'EMITS' => 294,
			'CONSUMES' => 301
		},
		DEFAULT => -416,
		GOTOS => {
			'consumes_dcl' => 286,
			'emits_dcl' => 293,
			'attr_spec' => 224,
			'provides_dcl' => 290,
			'readonly_attr_spec' => 226,
			'component_exports' => 472,
			'attr_dcl' => 292,
			'publishes_dcl' => 288,
			'uses_dcl' => 300,
			'component_export' => 289
		}
	},
	{#State 290
		ACTIONS => {
			'error' => 474,
			";" => 473
		}
	},
	{#State 291
		ACTIONS => {
			'MULTIPLE' => 476
		},
		DEFAULT => -439,
		GOTOS => {
			'uses_mod' => 475
		}
	},
	{#State 292
		ACTIONS => {
			'error' => 478,
			";" => 477
		}
	},
	{#State 293
		ACTIONS => {
			'error' => 480,
			";" => 479
		}
	},
	{#State 294
		ACTIONS => {
			'error' => 482,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 481
		}
	},
	{#State 295
		ACTIONS => {
			"}" => 483
		}
	},
	{#State 296
		ACTIONS => {
			"}" => 484
		}
	},
	{#State 297
		DEFAULT => -403
	},
	{#State 298
		ACTIONS => {
			'error' => 487,
			'OBJECT' => 488,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 486,
			'interface_type' => 485
		}
	},
	{#State 299
		ACTIONS => {
			'error' => 490,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 489
		}
	},
	{#State 300
		ACTIONS => {
			'error' => 492,
			";" => 491
		}
	},
	{#State 301
		ACTIONS => {
			'error' => 494,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 493
		}
	},
	{#State 302
		ACTIONS => {
			'RAISES' => 449
		},
		DEFAULT => -473,
		GOTOS => {
			'raises_expr' => 495
		}
	},
	{#State 303
		ACTIONS => {
			'error' => 496,
			'IDENTIFIER' => 497
		}
	},
	{#State 304
		ACTIONS => {
			'ONEWAY' => 222,
			'FACTORY' => 308,
			'CONST' => 13,
			"}" => -465,
			'EXCEPTION' => 50,
			'ENUM' => 16,
			'FINDER' => 303,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 237,
			'ATTRIBUTE' => 238
		},
		DEFAULT => -326,
		GOTOS => {
			'const_dcl' => 233,
			'op_mod' => 223,
			'except_dcl' => 229,
			'attr_spec' => 224,
			'factory_header_param' => 302,
			'home_exports' => 498,
			'home_export' => 304,
			'op_attribute' => 225,
			'readonly_attr_spec' => 226,
			'finder_dcl' => 306,
			'type_id_dcl' => 230,
			'export' => 311,
			'struct_type' => 26,
			'finder_header' => 312,
			'exception_header' => 27,
			'union_type' => 28,
			'op_header' => 236,
			'struct_header' => 10,
			'factory_dcl' => 307,
			'enum_type' => 44,
			'finder_header_param' => 313,
			'op_dcl' => 239,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 227,
			'attr_dcl' => 228,
			'union_header' => 49,
			'type_dcl' => 240,
			'factory_header' => 314
		}
	},
	{#State 305
		ACTIONS => {
			"}" => 499
		}
	},
	{#State 306
		ACTIONS => {
			'error' => 501,
			";" => 500
		}
	},
	{#State 307
		ACTIONS => {
			'error' => 503,
			";" => 502
		}
	},
	{#State 308
		ACTIONS => {
			'error' => 504,
			'IDENTIFIER' => 505
		}
	},
	{#State 309
		ACTIONS => {
			"}" => 506
		}
	},
	{#State 310
		DEFAULT => -462
	},
	{#State 311
		DEFAULT => -467
	},
	{#State 312
		ACTIONS => {
			'error' => 508,
			"(" => 507
		}
	},
	{#State 313
		ACTIONS => {
			'RAISES' => 449
		},
		DEFAULT => -481,
		GOTOS => {
			'raises_expr' => 509
		}
	},
	{#State 314
		ACTIONS => {
			'error' => 511,
			"(" => 510
		}
	},
	{#State 315
		ACTIONS => {
			"}" => 512
		}
	},
	{#State 316
		ACTIONS => {
			"}" => 513
		}
	},
	{#State 317
		DEFAULT => -35
	},
	{#State 318
		DEFAULT => -36
	},
	{#State 319
		DEFAULT => -85
	},
	{#State 320
		DEFAULT => -100
	},
	{#State 321
		ACTIONS => {
			";" => 514,
			"," => 515
		},
		DEFAULT => -289
	},
	{#State 322
		ACTIONS => {
			"}" => 516
		}
	},
	{#State 323
		ACTIONS => {
			"}" => 517
		}
	},
	{#State 324
		DEFAULT => -293
	},
	{#State 325
		ACTIONS => {
			'SHORT' => 104,
			'CHAR' => 90,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'error' => 522,
			'LONG' => 525,
			"::" => 93,
			'ENUM' => 16,
			'UNSIGNED' => 102
		},
		GOTOS => {
			'switch_type_spec' => 519,
			'unsigned_int' => 81,
			'signed_int' => 98,
			'integer_type' => 524,
			'boolean_type' => 523,
			'unsigned_longlong_int' => 86,
			'char_type' => 518,
			'enum_type' => 521,
			'unsigned_long_int' => 114,
			'enum_header' => 47,
			'scoped_name' => 520,
			'unsigned_short_int' => 106,
			'signed_long_int' => 101,
			'signed_short_int' => 94,
			'signed_longlong_int' => 89
		}
	},
	{#State 326
		DEFAULT => -264
	},
	{#State 327
		DEFAULT => -227
	},
	{#State 328
		DEFAULT => -226
	},
	{#State 329
		ACTIONS => {
			'SUPPORTS' => 218
		},
		DEFAULT => -407,
		GOTOS => {
			'supported_interface_spec' => 526
		}
	},
	{#State 330
		ACTIONS => {
			'error' => 528,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 527
		}
	},
	{#State 331
		DEFAULT => -408
	},
	{#State 332
		DEFAULT => -372
	},
	{#State 333
		DEFAULT => -373
	},
	{#State 334
		DEFAULT => -367
	},
	{#State 335
		DEFAULT => -368
	},
	{#State 336
		DEFAULT => -186
	},
	{#State 337
		DEFAULT => -377
	},
	{#State 338
		DEFAULT => -375
	},
	{#State 339
		DEFAULT => -376
	},
	{#State 340
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'FIXED' => 187,
			'VALUEBASE' => 179,
			'SEQUENCE' => 173,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'WCHAR' => 85,
			'error' => 529,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'wide_string_type' => 180,
			'integer_type' => 199,
			'boolean_type' => 198,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 190,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'signed_short_int' => 94,
			'string_type' => 192,
			'sequence_type' => 200,
			'base_type_spec' => 193,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'unsigned_long_int' => 114,
			'template_type_spec' => 185,
			'unsigned_short_int' => 106,
			'simple_type_spec' => 530,
			'fixed_pt_type' => 202,
			'signed_longlong_int' => 89
		}
	},
	{#State 341
		DEFAULT => -298
	},
	{#State 342
		DEFAULT => -199
	},
	{#State 343
		DEFAULT => -224
	},
	{#State 344
		DEFAULT => -228
	},
	{#State 345
		ACTIONS => {
			"," => 531
		},
		DEFAULT => -221
	},
	{#State 346
		DEFAULT => -223
	},
	{#State 347
		ACTIONS => {
			"[" => 534
		},
		DEFAULT => -225,
		GOTOS => {
			'fixed_array_sizes' => 533,
			'fixed_array_size' => 532
		}
	},
	{#State 348
		DEFAULT => -255
	},
	{#State 349
		DEFAULT => -254
	},
	{#State 350
		DEFAULT => -266
	},
	{#State 351
		DEFAULT => -265
	},
	{#State 352
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 536,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'primary_expr' => 427,
			'and_expr' => 428,
			'scoped_name' => 419,
			'positive_int_const' => 535,
			'wide_string_literal' => 407,
			'boolean_literal' => 409,
			'mult_expr' => 430,
			'const_exp' => 410,
			'or_expr' => 411,
			'unary_expr' => 432,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 353
		DEFAULT => -360
	},
	{#State 354
		ACTIONS => {
			"}" => 537
		}
	},
	{#State 355
		DEFAULT => -499
	},
	{#State 356
		ACTIONS => {
			"}" => 538
		}
	},
	{#State 357
		DEFAULT => -32
	},
	{#State 358
		DEFAULT => -507
	},
	{#State 359
		ACTIONS => {
			":" => 220,
			'SUPPORTS' => 218
		},
		DEFAULT => -503,
		GOTOS => {
			'supported_interface_spec' => 221,
			'value_inheritance_spec' => 539
		}
	},
	{#State 360
		DEFAULT => -103
	},
	{#State 361
		ACTIONS => {
			":" => 220,
			'SUPPORTS' => 218
		},
		DEFAULT => -99,
		GOTOS => {
			'supported_interface_spec' => 221,
			'value_inheritance_spec' => 540
		}
	},
	{#State 362
		DEFAULT => -9
	},
	{#State 363
		DEFAULT => -497
	},
	{#State 364
		DEFAULT => -90
	},
	{#State 365
		DEFAULT => -411
	},
	{#State 366
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -73
	},
	{#State 367
		DEFAULT => -412
	},
	{#State 368
		ACTIONS => {
			"," => 541
		},
		DEFAULT => -71
	},
	{#State 369
		ACTIONS => {
			'error' => 544,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 543,
			'value_name' => 542,
			'value_names' => 545
		}
	},
	{#State 370
		DEFAULT => -109
	},
	{#State 371
		DEFAULT => -328
	},
	{#State 372
		DEFAULT => -355
	},
	{#State 373
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -356
	},
	{#State 374
		DEFAULT => -354
	},
	{#State 375
		DEFAULT => -353
	},
	{#State 376
		DEFAULT => -329
	},
	{#State 377
		ACTIONS => {
			'error' => 546,
			'IDENTIFIER' => 547
		}
	},
	{#State 378
		DEFAULT => -61
	},
	{#State 379
		DEFAULT => -68
	},
	{#State 380
		DEFAULT => -58
	},
	{#State 381
		DEFAULT => -65
	},
	{#State 382
		DEFAULT => -57
	},
	{#State 383
		DEFAULT => -64
	},
	{#State 384
		DEFAULT => -60
	},
	{#State 385
		DEFAULT => -67
	},
	{#State 386
		DEFAULT => -88
	},
	{#State 387
		DEFAULT => -56
	},
	{#State 388
		DEFAULT => -63
	},
	{#State 389
		DEFAULT => -87
	},
	{#State 390
		DEFAULT => -54
	},
	{#State 391
		ACTIONS => {
			'error' => 553,
			")" => 551,
			'OUT' => 552,
			'INOUT' => 549,
			'IN' => 548
		},
		GOTOS => {
			'param_dcl' => 555,
			'param_dcls' => 554,
			'param_attribute' => 550
		}
	},
	{#State 392
		DEFAULT => -322
	},
	{#State 393
		ACTIONS => {
			'CONTEXT' => 556,
			'RAISES' => 449
		},
		DEFAULT => -318,
		GOTOS => {
			'context_expr' => 558,
			'raises_expr' => 557
		}
	},
	{#State 394
		DEFAULT => -381
	},
	{#State 395
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'VALUEBASE' => 179,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'WCHAR' => 85,
			'error' => 560,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'wide_string_type' => 372,
			'integer_type' => 199,
			'boolean_type' => 198,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 373,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'signed_short_int' => 94,
			'string_type' => 374,
			'base_type_spec' => 375,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'unsigned_long_int' => 114,
			'param_type_spec' => 559,
			'unsigned_short_int' => 106,
			'signed_longlong_int' => 89
		}
	},
	{#State 396
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 159
		},
		GOTOS => {
			'attr_declarator' => 563,
			'simple_declarator' => 562,
			'simple_declarators' => 561
		}
	},
	{#State 397
		DEFAULT => -387
	},
	{#State 398
		DEFAULT => -59
	},
	{#State 399
		DEFAULT => -66
	},
	{#State 400
		DEFAULT => -55
	},
	{#State 401
		DEFAULT => -62
	},
	{#State 402
		ACTIONS => {
			'error' => 565,
			";" => 564
		}
	},
	{#State 403
		DEFAULT => -252
	},
	{#State 404
		DEFAULT => -253
	},
	{#State 405
		DEFAULT => -257
	},
	{#State 406
		DEFAULT => -181
	},
	{#State 407
		DEFAULT => -179
	},
	{#State 408
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 567,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'const_exp' => 566,
			'and_expr' => 428,
			'or_expr' => 411,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'wide_string_literal' => 407,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 409
		DEFAULT => -184
	},
	{#State 410
		DEFAULT => -191
	},
	{#State 411
		ACTIONS => {
			"|" => 568
		},
		DEFAULT => -151
	},
	{#State 412
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 412
		},
		DEFAULT => -187,
		GOTOS => {
			'wide_string_literal' => 569
		}
	},
	{#State 413
		DEFAULT => -189
	},
	{#State 414
		DEFAULT => -178
	},
	{#State 415
		DEFAULT => -183
	},
	{#State 416
		DEFAULT => -182
	},
	{#State 417
		DEFAULT => -170
	},
	{#State 418
		DEFAULT => -180
	},
	{#State 419
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -173
	},
	{#State 420
		ACTIONS => {
			">" => 570
		}
	},
	{#State 421
		ACTIONS => {
			">" => 571
		}
	},
	{#State 422
		ACTIONS => {
			"^" => 572
		},
		DEFAULT => -152
	},
	{#State 423
		ACTIONS => {
			"<<" => 573,
			">>" => 574
		},
		DEFAULT => -156
	},
	{#State 424
		DEFAULT => -190
	},
	{#State 425
		DEFAULT => -174
	},
	{#State 426
		ACTIONS => {
			"+" => 576,
			"-" => 575
		},
		DEFAULT => -158
	},
	{#State 427
		DEFAULT => -169
	},
	{#State 428
		ACTIONS => {
			"&" => 577
		},
		DEFAULT => -154
	},
	{#State 429
		DEFAULT => -177
	},
	{#State 430
		ACTIONS => {
			"%" => 578,
			"*" => 579,
			"/" => 580
		},
		DEFAULT => -161
	},
	{#State 431
		DEFAULT => -171
	},
	{#State 432
		DEFAULT => -164
	},
	{#State 433
		DEFAULT => -172
	},
	{#State 434
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			"::" => 93,
			'STRING_LITERAL' => 168,
			'FALSE' => 424,
			'CHARACTER_LITERAL' => 418,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			'TRUE' => 413,
			"(" => 408
		},
		GOTOS => {
			'scoped_name' => 419,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 581,
			'literal' => 425,
			'wide_string_literal' => 407
		}
	},
	{#State 435
		DEFAULT => -78
	},
	{#State 436
		DEFAULT => -77
	},
	{#State 437
		DEFAULT => -245
	},
	{#State 438
		ACTIONS => {
			">" => 582
		}
	},
	{#State 439
		ACTIONS => {
			">" => 583
		}
	},
	{#State 440
		DEFAULT => -138
	},
	{#State 441
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 585,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'const_exp' => 584,
			'and_expr' => 428,
			'or_expr' => 411,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'wide_string_literal' => 407,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 442
		DEFAULT => -50
	},
	{#State 443
		ACTIONS => {
			'error' => 587,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 366,
			'interface_name' => 368,
			'interface_names' => 586
		}
	},
	{#State 444
		DEFAULT => -43
	},
	{#State 445
		DEFAULT => -42
	},
	{#State 446
		ACTIONS => {
			'error' => 589,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 588
		}
	},
	{#State 447
		DEFAULT => -450
	},
	{#State 448
		DEFAULT => -123
	},
	{#State 449
		ACTIONS => {
			'error' => 591,
			"(" => 590
		}
	},
	{#State 450
		DEFAULT => -124
	},
	{#State 451
		ACTIONS => {
			'error' => 593,
			";" => 592
		}
	},
	{#State 452
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 347
		},
		GOTOS => {
			'declarators' => 594,
			'declarator' => 345,
			'simple_declarator' => 346,
			'array_declarator' => 344,
			'complex_declarator' => 343
		}
	},
	{#State 453
		ACTIONS => {
			";" => 595
		}
	},
	{#State 454
		DEFAULT => -97
	},
	{#State 455
		DEFAULT => -130
	},
	{#State 456
		DEFAULT => -129
	},
	{#State 457
		ACTIONS => {
			'error' => 601,
			")" => 597,
			'IN' => 596
		},
		GOTOS => {
			'init_param_decls' => 599,
			'init_param_attribute' => 598,
			'init_param_decl' => 600
		}
	},
	{#State 458
		DEFAULT => -128
	},
	{#State 459
		DEFAULT => -95
	},
	{#State 460
		DEFAULT => -94
	},
	{#State 461
		DEFAULT => -495
	},
	{#State 462
		DEFAULT => -494
	},
	{#State 463
		DEFAULT => -313
	},
	{#State 464
		DEFAULT => -314
	},
	{#State 465
		DEFAULT => -453
	},
	{#State 466
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -458
	},
	{#State 467
		DEFAULT => -459
	},
	{#State 468
		DEFAULT => -422
	},
	{#State 469
		DEFAULT => -428
	},
	{#State 470
		DEFAULT => -421
	},
	{#State 471
		DEFAULT => -427
	},
	{#State 472
		DEFAULT => -417
	},
	{#State 473
		DEFAULT => -418
	},
	{#State 474
		DEFAULT => -424
	},
	{#State 475
		ACTIONS => {
			'error' => 603,
			'OBJECT' => 488,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 486,
			'interface_type' => 602
		}
	},
	{#State 476
		DEFAULT => -438
	},
	{#State 477
		DEFAULT => -423
	},
	{#State 478
		DEFAULT => -429
	},
	{#State 479
		DEFAULT => -420
	},
	{#State 480
		DEFAULT => -426
	},
	{#State 481
		ACTIONS => {
			'error' => 604,
			'IDENTIFIER' => 605,
			"::" => 248
		}
	},
	{#State 482
		DEFAULT => -442
	},
	{#State 483
		DEFAULT => -404
	},
	{#State 484
		DEFAULT => -405
	},
	{#State 485
		ACTIONS => {
			'error' => 606,
			'IDENTIFIER' => 607
		}
	},
	{#State 486
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -433
	},
	{#State 487
		DEFAULT => -432
	},
	{#State 488
		DEFAULT => -434
	},
	{#State 489
		ACTIONS => {
			'error' => 608,
			'IDENTIFIER' => 609,
			"::" => 248
		}
	},
	{#State 490
		DEFAULT => -445
	},
	{#State 491
		DEFAULT => -419
	},
	{#State 492
		DEFAULT => -425
	},
	{#State 493
		ACTIONS => {
			'error' => 610,
			'IDENTIFIER' => 611,
			"::" => 248
		}
	},
	{#State 494
		DEFAULT => -448
	},
	{#State 495
		DEFAULT => -472
	},
	{#State 496
		DEFAULT => -487
	},
	{#State 497
		DEFAULT => -486
	},
	{#State 498
		DEFAULT => -466
	},
	{#State 499
		DEFAULT => -463
	},
	{#State 500
		DEFAULT => -469
	},
	{#State 501
		DEFAULT => -471
	},
	{#State 502
		DEFAULT => -468
	},
	{#State 503
		DEFAULT => -470
	},
	{#State 504
		DEFAULT => -479
	},
	{#State 505
		DEFAULT => -478
	},
	{#State 506
		DEFAULT => -464
	},
	{#State 507
		ACTIONS => {
			'error' => 614,
			")" => 612,
			'IN' => 596
		},
		GOTOS => {
			'init_param_decls' => 613,
			'init_param_attribute' => 598,
			'init_param_decl' => 600
		}
	},
	{#State 508
		DEFAULT => -485
	},
	{#State 509
		DEFAULT => -480
	},
	{#State 510
		ACTIONS => {
			'error' => 617,
			")" => 615,
			'IN' => 596
		},
		GOTOS => {
			'init_param_decls' => 616,
			'init_param_attribute' => 598,
			'init_param_decl' => 600
		}
	},
	{#State 511
		DEFAULT => -477
	},
	{#State 512
		DEFAULT => -33
	},
	{#State 513
		DEFAULT => -34
	},
	{#State 514
		DEFAULT => -292
	},
	{#State 515
		ACTIONS => {
			'IDENTIFIER' => 324
		},
		DEFAULT => -291,
		GOTOS => {
			'enumerators' => 618,
			'enumerator' => 321
		}
	},
	{#State 516
		DEFAULT => -284
	},
	{#State 517
		DEFAULT => -285
	},
	{#State 518
		DEFAULT => -268
	},
	{#State 519
		ACTIONS => {
			")" => 619
		}
	},
	{#State 520
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -271
	},
	{#State 521
		DEFAULT => -270
	},
	{#State 522
		ACTIONS => {
			")" => 620
		}
	},
	{#State 523
		DEFAULT => -269
	},
	{#State 524
		DEFAULT => -267
	},
	{#State 525
		ACTIONS => {
			'LONG' => 252
		},
		DEFAULT => -238
	},
	{#State 526
		DEFAULT => -406
	},
	{#State 527
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -413
	},
	{#State 528
		DEFAULT => -414
	},
	{#State 529
		ACTIONS => {
			">" => 621
		}
	},
	{#State 530
		ACTIONS => {
			">" => 623,
			"," => 622
		}
	},
	{#State 531
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 347
		},
		GOTOS => {
			'declarators' => 624,
			'declarator' => 345,
			'simple_declarator' => 346,
			'array_declarator' => 344,
			'complex_declarator' => 343
		}
	},
	{#State 532
		ACTIONS => {
			"[" => 534
		},
		DEFAULT => -306,
		GOTOS => {
			'fixed_array_sizes' => 625,
			'fixed_array_size' => 532
		}
	},
	{#State 533
		DEFAULT => -305
	},
	{#State 534
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 627,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'primary_expr' => 427,
			'and_expr' => 428,
			'scoped_name' => 419,
			'positive_int_const' => 626,
			'wide_string_literal' => 407,
			'boolean_literal' => 409,
			'mult_expr' => 430,
			'const_exp' => 410,
			'or_expr' => 411,
			'unary_expr' => 432,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 535
		ACTIONS => {
			"," => 628
		}
	},
	{#State 536
		ACTIONS => {
			">" => 629
		}
	},
	{#State 537
		DEFAULT => -501
	},
	{#State 538
		DEFAULT => -500
	},
	{#State 539
		DEFAULT => -505
	},
	{#State 540
		DEFAULT => -101
	},
	{#State 541
		ACTIONS => {
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 366,
			'interface_name' => 368,
			'interface_names' => 630
		}
	},
	{#State 542
		ACTIONS => {
			"," => 631
		},
		DEFAULT => -111
	},
	{#State 543
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -113
	},
	{#State 544
		DEFAULT => -107
	},
	{#State 545
		ACTIONS => {
			'SUPPORTS' => 218
		},
		DEFAULT => -105,
		GOTOS => {
			'supported_interface_spec' => 632
		}
	},
	{#State 546
		DEFAULT => -324
	},
	{#State 547
		DEFAULT => -323
	},
	{#State 548
		DEFAULT => -339
	},
	{#State 549
		DEFAULT => -341
	},
	{#State 550
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'VALUEBASE' => 179,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'WCHAR' => 85,
			'error' => 634,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'wide_string_type' => 372,
			'integer_type' => 199,
			'boolean_type' => 198,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 373,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'signed_short_int' => 94,
			'string_type' => 374,
			'base_type_spec' => 375,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'unsigned_long_int' => 114,
			'param_type_spec' => 633,
			'unsigned_short_int' => 106,
			'signed_longlong_int' => 89
		}
	},
	{#State 551
		DEFAULT => -331
	},
	{#State 552
		DEFAULT => -340
	},
	{#State 553
		ACTIONS => {
			")" => 635
		}
	},
	{#State 554
		ACTIONS => {
			")" => 636
		}
	},
	{#State 555
		ACTIONS => {
			";" => 637,
			"," => 638
		},
		DEFAULT => -333
	},
	{#State 556
		ACTIONS => {
			'error' => 640,
			"(" => 639
		}
	},
	{#State 557
		ACTIONS => {
			'CONTEXT' => 556
		},
		DEFAULT => -319,
		GOTOS => {
			'context_expr' => 641
		}
	},
	{#State 558
		DEFAULT => -321
	},
	{#State 559
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 159
		},
		GOTOS => {
			'simple_declarator' => 644,
			'simple_declarators' => 643,
			'readonly_attr_declarator' => 642
		}
	},
	{#State 560
		DEFAULT => -380
	},
	{#State 561
		DEFAULT => -389
	},
	{#State 562
		ACTIONS => {
			'GETRAISES' => 649,
			'SETRAISES' => 648,
			"," => 646
		},
		DEFAULT => -384,
		GOTOS => {
			'set_except_expr' => 650,
			'get_except_expr' => 645,
			'attr_raises_expr' => 647
		}
	},
	{#State 563
		DEFAULT => -386
	},
	{#State 564
		DEFAULT => -258
	},
	{#State 565
		DEFAULT => -259
	},
	{#State 566
		ACTIONS => {
			")" => 651
		}
	},
	{#State 567
		ACTIONS => {
			")" => 652
		}
	},
	{#State 568
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'and_expr' => 428,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'xor_expr' => 653,
			'shift_expr' => 423,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 569
		DEFAULT => -188
	},
	{#State 570
		DEFAULT => -302
	},
	{#State 571
		DEFAULT => -304
	},
	{#State 572
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'and_expr' => 654,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'shift_expr' => 423,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 573
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 655
		}
	},
	{#State 574
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 656
		}
	},
	{#State 575
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 657,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434
		}
	},
	{#State 576
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 658,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434
		}
	},
	{#State 577
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'shift_expr' => 659,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 578
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'unary_expr' => 660,
			'scoped_name' => 419,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434
		}
	},
	{#State 579
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'unary_expr' => 661,
			'scoped_name' => 419,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434
		}
	},
	{#State 580
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'CHARACTER_LITERAL' => 418,
			"+" => 431,
			'FIXED_PT_LITERAL' => 416,
			'WIDE_CHARACTER_LITERAL' => 406,
			"-" => 417,
			"::" => 93,
			'FALSE' => 424,
			'WIDE_STRING_LITERAL' => 412,
			'INTEGER_LITERAL' => 429,
			"~" => 433,
			"(" => 408,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'unary_expr' => 662,
			'scoped_name' => 419,
			'wide_string_literal' => 407,
			'literal' => 425,
			'unary_operator' => 434
		}
	},
	{#State 581
		DEFAULT => -168
	},
	{#State 582
		DEFAULT => -299
	},
	{#State 583
		DEFAULT => -301
	},
	{#State 584
		DEFAULT => -136
	},
	{#State 585
		DEFAULT => -137
	},
	{#State 586
		DEFAULT => -69
	},
	{#State 587
		DEFAULT => -70
	},
	{#State 588
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -460
	},
	{#State 589
		DEFAULT => -461
	},
	{#State 590
		ACTIONS => {
			'error' => 665,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 664,
			'exception_names' => 663,
			'exception_name' => 666
		}
	},
	{#State 591
		DEFAULT => -344
	},
	{#State 592
		DEFAULT => -121
	},
	{#State 593
		DEFAULT => -122
	},
	{#State 594
		ACTIONS => {
			";" => 667
		}
	},
	{#State 595
		DEFAULT => -118
	},
	{#State 596
		DEFAULT => -135
	},
	{#State 597
		DEFAULT => -125
	},
	{#State 598
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'VALUEBASE' => 179,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'WCHAR' => 85,
			'error' => 669,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'wide_string_type' => 372,
			'integer_type' => 199,
			'boolean_type' => 198,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 373,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'signed_short_int' => 94,
			'string_type' => 374,
			'base_type_spec' => 375,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'unsigned_long_int' => 114,
			'param_type_spec' => 668,
			'unsigned_short_int' => 106,
			'signed_longlong_int' => 89
		}
	},
	{#State 599
		ACTIONS => {
			")" => 670
		}
	},
	{#State 600
		ACTIONS => {
			"," => 671
		},
		DEFAULT => -131
	},
	{#State 601
		ACTIONS => {
			")" => 672
		}
	},
	{#State 602
		ACTIONS => {
			'error' => 673,
			'IDENTIFIER' => 674
		}
	},
	{#State 603
		DEFAULT => -437
	},
	{#State 604
		DEFAULT => -441
	},
	{#State 605
		DEFAULT => -440
	},
	{#State 606
		DEFAULT => -431
	},
	{#State 607
		DEFAULT => -430
	},
	{#State 608
		DEFAULT => -444
	},
	{#State 609
		DEFAULT => -443
	},
	{#State 610
		DEFAULT => -447
	},
	{#State 611
		DEFAULT => -446
	},
	{#State 612
		DEFAULT => -482
	},
	{#State 613
		ACTIONS => {
			")" => 675
		}
	},
	{#State 614
		ACTIONS => {
			")" => 676
		}
	},
	{#State 615
		DEFAULT => -474
	},
	{#State 616
		ACTIONS => {
			")" => 677
		}
	},
	{#State 617
		ACTIONS => {
			")" => 678
		}
	},
	{#State 618
		DEFAULT => -290
	},
	{#State 619
		ACTIONS => {
			'error' => 680,
			"{" => 679
		}
	},
	{#State 620
		DEFAULT => -263
	},
	{#State 621
		DEFAULT => -297
	},
	{#State 622
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 682,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'primary_expr' => 427,
			'and_expr' => 428,
			'scoped_name' => 419,
			'positive_int_const' => 681,
			'wide_string_literal' => 407,
			'boolean_literal' => 409,
			'mult_expr' => 430,
			'const_exp' => 410,
			'or_expr' => 411,
			'unary_expr' => 432,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 623
		DEFAULT => -296
	},
	{#State 624
		DEFAULT => -222
	},
	{#State 625
		DEFAULT => -307
	},
	{#State 626
		ACTIONS => {
			"]" => 683
		}
	},
	{#State 627
		ACTIONS => {
			"]" => 684
		}
	},
	{#State 628
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 686,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'string_literal' => 414,
			'primary_expr' => 427,
			'and_expr' => 428,
			'scoped_name' => 419,
			'positive_int_const' => 685,
			'wide_string_literal' => 407,
			'boolean_literal' => 409,
			'mult_expr' => 430,
			'const_exp' => 410,
			'or_expr' => 411,
			'unary_expr' => 432,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 629
		DEFAULT => -359
	},
	{#State 630
		DEFAULT => -72
	},
	{#State 631
		ACTIONS => {
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 543,
			'value_name' => 542,
			'value_names' => 687
		}
	},
	{#State 632
		DEFAULT => -106
	},
	{#State 633
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 159
		},
		GOTOS => {
			'simple_declarator' => 688
		}
	},
	{#State 634
		DEFAULT => -338
	},
	{#State 635
		DEFAULT => -332
	},
	{#State 636
		DEFAULT => -330
	},
	{#State 637
		DEFAULT => -336
	},
	{#State 638
		ACTIONS => {
			'OUT' => 552,
			'INOUT' => 549,
			'IN' => 548
		},
		DEFAULT => -335,
		GOTOS => {
			'param_dcl' => 555,
			'param_dcls' => 689,
			'param_attribute' => 550
		}
	},
	{#State 639
		ACTIONS => {
			'error' => 692,
			'STRING_LITERAL' => 168
		},
		GOTOS => {
			'string_literal' => 690,
			'string_literals' => 691
		}
	},
	{#State 640
		DEFAULT => -350
	},
	{#State 641
		DEFAULT => -320
	},
	{#State 642
		DEFAULT => -379
	},
	{#State 643
		DEFAULT => -383
	},
	{#State 644
		ACTIONS => {
			'RAISES' => 449,
			"," => 646
		},
		DEFAULT => -384,
		GOTOS => {
			'raises_expr' => 693
		}
	},
	{#State 645
		ACTIONS => {
			'SETRAISES' => 648
		},
		DEFAULT => -391,
		GOTOS => {
			'set_except_expr' => 694
		}
	},
	{#State 646
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 159
		},
		GOTOS => {
			'simple_declarators' => 696,
			'simple_declarator' => 695
		}
	},
	{#State 647
		DEFAULT => -388
	},
	{#State 648
		ACTIONS => {
			'error' => 698,
			"(" => 697
		},
		GOTOS => {
			'exception_list' => 699
		}
	},
	{#State 649
		ACTIONS => {
			'error' => 700,
			"(" => 697
		},
		GOTOS => {
			'exception_list' => 701
		}
	},
	{#State 650
		DEFAULT => -392
	},
	{#State 651
		DEFAULT => -175
	},
	{#State 652
		DEFAULT => -176
	},
	{#State 653
		ACTIONS => {
			"^" => 572
		},
		DEFAULT => -153
	},
	{#State 654
		ACTIONS => {
			"&" => 577
		},
		DEFAULT => -155
	},
	{#State 655
		ACTIONS => {
			"+" => 576,
			"-" => 575
		},
		DEFAULT => -160
	},
	{#State 656
		ACTIONS => {
			"+" => 576,
			"-" => 575
		},
		DEFAULT => -159
	},
	{#State 657
		ACTIONS => {
			"%" => 578,
			"*" => 579,
			"/" => 580
		},
		DEFAULT => -163
	},
	{#State 658
		ACTIONS => {
			"%" => 578,
			"*" => 579,
			"/" => 580
		},
		DEFAULT => -162
	},
	{#State 659
		ACTIONS => {
			"<<" => 573,
			">>" => 574
		},
		DEFAULT => -157
	},
	{#State 660
		DEFAULT => -167
	},
	{#State 661
		DEFAULT => -165
	},
	{#State 662
		DEFAULT => -166
	},
	{#State 663
		ACTIONS => {
			")" => 702
		}
	},
	{#State 664
		ACTIONS => {
			"::" => 248
		},
		DEFAULT => -347
	},
	{#State 665
		ACTIONS => {
			")" => 703
		}
	},
	{#State 666
		ACTIONS => {
			"," => 704
		},
		DEFAULT => -345
	},
	{#State 667
		DEFAULT => -117
	},
	{#State 668
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 159
		},
		GOTOS => {
			'simple_declarator' => 705
		}
	},
	{#State 669
		DEFAULT => -134
	},
	{#State 670
		DEFAULT => -126
	},
	{#State 671
		ACTIONS => {
			'IN' => 596
		},
		GOTOS => {
			'init_param_decls' => 706,
			'init_param_attribute' => 598,
			'init_param_decl' => 600
		}
	},
	{#State 672
		DEFAULT => -127
	},
	{#State 673
		DEFAULT => -436
	},
	{#State 674
		DEFAULT => -435
	},
	{#State 675
		DEFAULT => -483
	},
	{#State 676
		DEFAULT => -484
	},
	{#State 677
		DEFAULT => -475
	},
	{#State 678
		DEFAULT => -476
	},
	{#State 679
		ACTIONS => {
			'error' => 712,
			'CASE' => 710,
			'DEFAULT' => 711
		},
		GOTOS => {
			'case_labels' => 708,
			'switch_body' => 713,
			'case' => 707,
			'case_label' => 709
		}
	},
	{#State 680
		DEFAULT => -262
	},
	{#State 681
		ACTIONS => {
			">" => 714
		}
	},
	{#State 682
		ACTIONS => {
			">" => 715
		}
	},
	{#State 683
		DEFAULT => -308
	},
	{#State 684
		DEFAULT => -309
	},
	{#State 685
		ACTIONS => {
			">" => 716
		}
	},
	{#State 686
		ACTIONS => {
			">" => 717
		}
	},
	{#State 687
		DEFAULT => -112
	},
	{#State 688
		DEFAULT => -337
	},
	{#State 689
		DEFAULT => -334
	},
	{#State 690
		ACTIONS => {
			"," => 718
		},
		DEFAULT => -351
	},
	{#State 691
		ACTIONS => {
			")" => 719
		}
	},
	{#State 692
		ACTIONS => {
			")" => 720
		}
	},
	{#State 693
		DEFAULT => -382
	},
	{#State 694
		DEFAULT => -390
	},
	{#State 695
		ACTIONS => {
			"," => 646
		},
		DEFAULT => -384
	},
	{#State 696
		DEFAULT => -385
	},
	{#State 697
		ACTIONS => {
			'error' => 722,
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 664,
			'exception_names' => 721,
			'exception_name' => 666
		}
	},
	{#State 698
		DEFAULT => -396
	},
	{#State 699
		DEFAULT => -395
	},
	{#State 700
		DEFAULT => -394
	},
	{#State 701
		DEFAULT => -393
	},
	{#State 702
		DEFAULT => -342
	},
	{#State 703
		DEFAULT => -343
	},
	{#State 704
		ACTIONS => {
			'IDENTIFIER' => 113,
			"::" => 93
		},
		GOTOS => {
			'scoped_name' => 664,
			'exception_names' => 723,
			'exception_name' => 666
		}
	},
	{#State 705
		DEFAULT => -133
	},
	{#State 706
		DEFAULT => -132
	},
	{#State 707
		ACTIONS => {
			'CASE' => 710,
			'DEFAULT' => 711
		},
		DEFAULT => -272,
		GOTOS => {
			'case_labels' => 708,
			'switch_body' => 724,
			'case' => 707,
			'case_label' => 709
		}
	},
	{#State 708
		ACTIONS => {
			'CHAR' => 90,
			'OBJECT' => 197,
			'FIXED' => 187,
			'VALUEBASE' => 179,
			'SEQUENCE' => 173,
			'STRUCT' => 181,
			'DOUBLE' => 109,
			'LONG' => 110,
			'STRING' => 111,
			"::" => 93,
			'WSTRING' => 95,
			'UNSIGNED' => 102,
			'SHORT' => 104,
			'BOOLEAN' => 96,
			'IDENTIFIER' => 113,
			'UNION' => 184,
			'WCHAR' => 85,
			'FLOAT' => 88,
			'OCTET' => 87,
			'ENUM' => 16,
			'ANY' => 196
		},
		GOTOS => {
			'unsigned_int' => 81,
			'floating_pt_type' => 172,
			'signed_int' => 98,
			'value_base_type' => 188,
			'char_type' => 174,
			'object_type' => 189,
			'scoped_name' => 190,
			'octet_type' => 175,
			'wide_char_type' => 191,
			'signed_long_int' => 101,
			'type_spec' => 725,
			'string_type' => 192,
			'struct_header' => 10,
			'element_spec' => 726,
			'base_type_spec' => 193,
			'unsigned_longlong_int' => 86,
			'any_type' => 178,
			'enum_type' => 194,
			'enum_header' => 47,
			'unsigned_short_int' => 106,
			'union_header' => 49,
			'signed_longlong_int' => 89,
			'wide_string_type' => 180,
			'boolean_type' => 198,
			'integer_type' => 199,
			'signed_short_int' => 94,
			'struct_type' => 182,
			'union_type' => 183,
			'sequence_type' => 200,
			'unsigned_long_int' => 114,
			'template_type_spec' => 185,
			'constr_type_spec' => 186,
			'simple_type_spec' => 201,
			'fixed_pt_type' => 202
		}
	},
	{#State 709
		ACTIONS => {
			'CASE' => 710,
			'DEFAULT' => 711
		},
		DEFAULT => -276,
		GOTOS => {
			'case_labels' => 727,
			'case_label' => 709
		}
	},
	{#State 710
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 415,
			'CHARACTER_LITERAL' => 418,
			'WIDE_CHARACTER_LITERAL' => 406,
			"::" => 93,
			'INTEGER_LITERAL' => 429,
			"(" => 408,
			'IDENTIFIER' => 113,
			'STRING_LITERAL' => 168,
			'FIXED_PT_LITERAL' => 416,
			"+" => 431,
			'error' => 729,
			"-" => 417,
			'WIDE_STRING_LITERAL' => 412,
			'FALSE' => 424,
			"~" => 433,
			'TRUE' => 413
		},
		GOTOS => {
			'mult_expr' => 430,
			'string_literal' => 414,
			'boolean_literal' => 409,
			'primary_expr' => 427,
			'const_exp' => 728,
			'and_expr' => 428,
			'or_expr' => 411,
			'unary_expr' => 432,
			'scoped_name' => 419,
			'xor_expr' => 422,
			'shift_expr' => 423,
			'literal' => 425,
			'wide_string_literal' => 407,
			'unary_operator' => 434,
			'add_expr' => 426
		}
	},
	{#State 711
		ACTIONS => {
			'error' => 730,
			":" => 731
		}
	},
	{#State 712
		ACTIONS => {
			"}" => 732
		}
	},
	{#State 713
		ACTIONS => {
			"}" => 733
		}
	},
	{#State 714
		DEFAULT => -294
	},
	{#State 715
		DEFAULT => -295
	},
	{#State 716
		DEFAULT => -357
	},
	{#State 717
		DEFAULT => -358
	},
	{#State 718
		ACTIONS => {
			'STRING_LITERAL' => 168
		},
		GOTOS => {
			'string_literal' => 690,
			'string_literals' => 734
		}
	},
	{#State 719
		DEFAULT => -348
	},
	{#State 720
		DEFAULT => -349
	},
	{#State 721
		ACTIONS => {
			")" => 735
		}
	},
	{#State 722
		ACTIONS => {
			")" => 736
		}
	},
	{#State 723
		DEFAULT => -346
	},
	{#State 724
		DEFAULT => -273
	},
	{#State 725
		ACTIONS => {
			'error' => 157,
			'IDENTIFIER' => 347
		},
		GOTOS => {
			'declarator' => 737,
			'simple_declarator' => 346,
			'array_declarator' => 344,
			'complex_declarator' => 343
		}
	},
	{#State 726
		ACTIONS => {
			'error' => 739,
			";" => 738
		}
	},
	{#State 727
		DEFAULT => -277
	},
	{#State 728
		ACTIONS => {
			'error' => 740,
			":" => 741
		}
	},
	{#State 729
		DEFAULT => -280
	},
	{#State 730
		DEFAULT => -282
	},
	{#State 731
		DEFAULT => -281
	},
	{#State 732
		DEFAULT => -261
	},
	{#State 733
		DEFAULT => -260
	},
	{#State 734
		DEFAULT => -352
	},
	{#State 735
		DEFAULT => -397
	},
	{#State 736
		DEFAULT => -398
	},
	{#State 737
		DEFAULT => -283
	},
	{#State 738
		DEFAULT => -274
	},
	{#State 739
		DEFAULT => -275
	},
	{#State 740
		DEFAULT => -279
	},
	{#State 741
		DEFAULT => -278
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
		 'export', 2, undef
	],
	[#Rule 61
		 'export', 2, undef
	],
	[#Rule 62
		 'export', 2,
sub
#line 433 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 63
		 'export', 2,
sub
#line 439 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 64
		 'export', 2,
sub
#line 445 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 65
		 'export', 2,
sub
#line 451 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 66
		 'export', 2,
sub
#line 457 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 67
		 'export', 2,
sub
#line 463 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 68
		 'export', 2,
sub
#line 469 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 69
		 'interface_inheritance_spec', 2,
sub
#line 479 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 70
		 'interface_inheritance_spec', 2,
sub
#line 483 "parser30.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 71
		 'interface_names', 1,
sub
#line 491 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 72
		 'interface_names', 3,
sub
#line 495 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 73
		 'interface_name', 1,
sub
#line 504 "parser30.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 74
		 'scoped_name', 1, undef
	],
	[#Rule 75
		 'scoped_name', 2,
sub
#line 514 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 76
		 'scoped_name', 2,
sub
#line 518 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 77
		 'scoped_name', 3,
sub
#line 524 "parser30.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 78
		 'scoped_name', 3,
sub
#line 528 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 79
		 'value', 1, undef
	],
	[#Rule 80
		 'value', 1, undef
	],
	[#Rule 81
		 'value', 1, undef
	],
	[#Rule 82
		 'value', 1, undef
	],
	[#Rule 83
		 'value_forward_dcl', 2,
sub
#line 550 "parser30.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 84
		 'value_forward_dcl', 3,
sub
#line 556 "parser30.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 85
		 'value_box_dcl', 3,
sub
#line 566 "parser30.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 86
		 'value_abs_dcl', 3,
sub
#line 577 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 87
		 'value_abs_dcl', 4,
sub
#line 585 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 88
		 'value_abs_dcl', 4,
sub
#line 593 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 89
		 'value_abs_header', 3,
sub
#line 603 "parser30.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 90
		 'value_abs_header', 4,
sub
#line 609 "parser30.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 91
		 'value_abs_header', 3,
sub
#line 616 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 92
		 'value_abs_header', 2,
sub
#line 621 "parser30.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 93
		 'value_dcl', 3,
sub
#line 630 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 94
		 'value_dcl', 4,
sub
#line 638 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 95
		 'value_dcl', 4,
sub
#line 646 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 96
		 'value_elements', 1,
sub
#line 656 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 97
		 'value_elements', 2,
sub
#line 660 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 98
		 'value_header', 2,
sub
#line 669 "parser30.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 99
		 'value_header', 3,
sub
#line 675 "parser30.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 100
		 'value_header', 3,
sub
#line 682 "parser30.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 101
		 'value_header', 4,
sub
#line 689 "parser30.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 102
		 'value_header', 2,
sub
#line 697 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 103
		 'value_header', 3,
sub
#line 702 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 104
		 'value_header', 2,
sub
#line 707 "parser30.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 105
		 'value_inheritance_spec', 3,
sub
#line 716 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3]
			);
		}
	],
	[#Rule 106
		 'value_inheritance_spec', 4,
sub
#line 723 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 107
		 'value_inheritance_spec', 3,
sub
#line 731 "parser30.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 108
		 'value_inheritance_spec', 1,
sub
#line 736 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 109
		 'inheritance_mod', 1, undef
	],
	[#Rule 110
		 'inheritance_mod', 0, undef
	],
	[#Rule 111
		 'value_names', 1,
sub
#line 752 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 112
		 'value_names', 3,
sub
#line 756 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 113
		 'value_name', 1,
sub
#line 765 "parser30.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 114
		 'value_element', 1, undef
	],
	[#Rule 115
		 'value_element', 1, undef
	],
	[#Rule 116
		 'value_element', 1, undef
	],
	[#Rule 117
		 'state_member', 4,
sub
#line 783 "parser30.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 118
		 'state_member', 3,
sub
#line 791 "parser30.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'state_mod', 1, undef
	],
	[#Rule 120
		 'state_mod', 1, undef
	],
	[#Rule 121
		 'init_dcl', 3,
sub
#line 807 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 122
		 'init_dcl', 3,
sub
#line 813 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 123
		 'init_dcl', 2, undef
	],
	[#Rule 124
		 'init_dcl', 2,
sub
#line 823 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 125
		 'init_header_param', 3,
sub
#line 832 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 126
		 'init_header_param', 4,
sub
#line 838 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 127
		 'init_header_param', 4,
sub
#line 846 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 128
		 'init_header_param', 2,
sub
#line 853 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 129
		 'init_header', 2,
sub
#line 863 "parser30.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 130
		 'init_header', 2,
sub
#line 869 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 131
		 'init_param_decls', 1,
sub
#line 878 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 132
		 'init_param_decls', 3,
sub
#line 882 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 133
		 'init_param_decl', 3,
sub
#line 891 "parser30.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 134
		 'init_param_decl', 2,
sub
#line 899 "parser30.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 135
		 'init_param_attribute', 1, undef
	],
	[#Rule 136
		 'const_dcl', 5,
sub
#line 914 "parser30.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 137
		 'const_dcl', 5,
sub
#line 922 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 138
		 'const_dcl', 4,
sub
#line 927 "parser30.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 139
		 'const_dcl', 3,
sub
#line 932 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 140
		 'const_dcl', 2,
sub
#line 937 "parser30.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
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
		 'const_type', 1, undef
	],
	[#Rule 148
		 'const_type', 1, undef
	],
	[#Rule 149
		 'const_type', 1,
sub
#line 962 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 150
		 'const_type', 1, undef
	],
	[#Rule 151
		 'const_exp', 1, undef
	],
	[#Rule 152
		 'or_expr', 1, undef
	],
	[#Rule 153
		 'or_expr', 3,
sub
#line 980 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 154
		 'xor_expr', 1, undef
	],
	[#Rule 155
		 'xor_expr', 3,
sub
#line 990 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 156
		 'and_expr', 1, undef
	],
	[#Rule 157
		 'and_expr', 3,
sub
#line 1000 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 158
		 'shift_expr', 1, undef
	],
	[#Rule 159
		 'shift_expr', 3,
sub
#line 1010 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 160
		 'shift_expr', 3,
sub
#line 1014 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 161
		 'add_expr', 1, undef
	],
	[#Rule 162
		 'add_expr', 3,
sub
#line 1024 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 163
		 'add_expr', 3,
sub
#line 1028 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 164
		 'mult_expr', 1, undef
	],
	[#Rule 165
		 'mult_expr', 3,
sub
#line 1038 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 166
		 'mult_expr', 3,
sub
#line 1042 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 167
		 'mult_expr', 3,
sub
#line 1046 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 168
		 'unary_expr', 2,
sub
#line 1054 "parser30.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 169
		 'unary_expr', 1, undef
	],
	[#Rule 170
		 'unary_operator', 1, undef
	],
	[#Rule 171
		 'unary_operator', 1, undef
	],
	[#Rule 172
		 'unary_operator', 1, undef
	],
	[#Rule 173
		 'primary_expr', 1,
sub
#line 1074 "parser30.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 174
		 'primary_expr', 1,
sub
#line 1080 "parser30.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 175
		 'primary_expr', 3,
sub
#line 1084 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 176
		 'primary_expr', 3,
sub
#line 1088 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 177
		 'literal', 1,
sub
#line 1097 "parser30.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 178
		 'literal', 1,
sub
#line 1104 "parser30.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 179
		 'literal', 1,
sub
#line 1110 "parser30.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 180
		 'literal', 1,
sub
#line 1116 "parser30.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 181
		 'literal', 1,
sub
#line 1122 "parser30.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 182
		 'literal', 1,
sub
#line 1128 "parser30.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 183
		 'literal', 1,
sub
#line 1135 "parser30.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 184
		 'literal', 1, undef
	],
	[#Rule 185
		 'string_literal', 1, undef
	],
	[#Rule 186
		 'string_literal', 2,
sub
#line 1149 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 187
		 'wide_string_literal', 1, undef
	],
	[#Rule 188
		 'wide_string_literal', 2,
sub
#line 1158 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 189
		 'boolean_literal', 1,
sub
#line 1166 "parser30.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 190
		 'boolean_literal', 1,
sub
#line 1172 "parser30.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 191
		 'positive_int_const', 1,
sub
#line 1182 "parser30.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 192
		 'type_dcl', 2,
sub
#line 1192 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 193
		 'type_dcl', 1, undef
	],
	[#Rule 194
		 'type_dcl', 1, undef
	],
	[#Rule 195
		 'type_dcl', 1, undef
	],
	[#Rule 196
		 'type_dcl', 2,
sub
#line 1202 "parser30.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 197
		 'type_dcl', 1, undef
	],
	[#Rule 198
		 'type_dcl', 2,
sub
#line 1211 "parser30.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 199
		 'type_declarator', 2,
sub
#line 1220 "parser30.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 200
		 'type_spec', 1, undef
	],
	[#Rule 201
		 'type_spec', 1, undef
	],
	[#Rule 202
		 'simple_type_spec', 1, undef
	],
	[#Rule 203
		 'simple_type_spec', 1, undef
	],
	[#Rule 204
		 'simple_type_spec', 1,
sub
#line 1243 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
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
		 'base_type_spec', 1, undef
	],
	[#Rule 213
		 'base_type_spec', 1, undef
	],
	[#Rule 214
		 'template_type_spec', 1, undef
	],
	[#Rule 215
		 'template_type_spec', 1, undef
	],
	[#Rule 216
		 'template_type_spec', 1, undef
	],
	[#Rule 217
		 'template_type_spec', 1, undef
	],
	[#Rule 218
		 'constr_type_spec', 1, undef
	],
	[#Rule 219
		 'constr_type_spec', 1, undef
	],
	[#Rule 220
		 'constr_type_spec', 1, undef
	],
	[#Rule 221
		 'declarators', 1,
sub
#line 1295 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 222
		 'declarators', 3,
sub
#line 1299 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 223
		 'declarator', 1,
sub
#line 1308 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 224
		 'declarator', 1, undef
	],
	[#Rule 225
		 'simple_declarator', 1, undef
	],
	[#Rule 226
		 'simple_declarator', 2,
sub
#line 1320 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 227
		 'simple_declarator', 2,
sub
#line 1325 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 228
		 'complex_declarator', 1, undef
	],
	[#Rule 229
		 'floating_pt_type', 1,
sub
#line 1340 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'floating_pt_type', 1,
sub
#line 1346 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 231
		 'floating_pt_type', 2,
sub
#line 1352 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 232
		 'integer_type', 1, undef
	],
	[#Rule 233
		 'integer_type', 1, undef
	],
	[#Rule 234
		 'signed_int', 1, undef
	],
	[#Rule 235
		 'signed_int', 1, undef
	],
	[#Rule 236
		 'signed_int', 1, undef
	],
	[#Rule 237
		 'signed_short_int', 1,
sub
#line 1380 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 238
		 'signed_long_int', 1,
sub
#line 1390 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 239
		 'signed_longlong_int', 2,
sub
#line 1400 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 240
		 'unsigned_int', 1, undef
	],
	[#Rule 241
		 'unsigned_int', 1, undef
	],
	[#Rule 242
		 'unsigned_int', 1, undef
	],
	[#Rule 243
		 'unsigned_short_int', 2,
sub
#line 1420 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 244
		 'unsigned_long_int', 2,
sub
#line 1430 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 245
		 'unsigned_longlong_int', 3,
sub
#line 1440 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 246
		 'char_type', 1,
sub
#line 1450 "parser30.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 247
		 'wide_char_type', 1,
sub
#line 1460 "parser30.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 248
		 'boolean_type', 1,
sub
#line 1470 "parser30.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 249
		 'octet_type', 1,
sub
#line 1480 "parser30.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 250
		 'any_type', 1,
sub
#line 1490 "parser30.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 251
		 'object_type', 1,
sub
#line 1500 "parser30.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 252
		 'struct_type', 4,
sub
#line 1510 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 253
		 'struct_type', 4,
sub
#line 1517 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 254
		 'struct_header', 2,
sub
#line 1526 "parser30.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 255
		 'struct_header', 2,
sub
#line 1532 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 256
		 'member_list', 1,
sub
#line 1541 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 257
		 'member_list', 2,
sub
#line 1545 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 258
		 'member', 3,
sub
#line 1554 "parser30.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 259
		 'member', 3,
sub
#line 1561 "parser30.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 260
		 'union_type', 8,
sub
#line 1574 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 261
		 'union_type', 8,
sub
#line 1582 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 262
		 'union_type', 6,
sub
#line 1588 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 263
		 'union_type', 5,
sub
#line 1594 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 264
		 'union_type', 3,
sub
#line 1600 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 265
		 'union_header', 2,
sub
#line 1609 "parser30.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 266
		 'union_header', 2,
sub
#line 1615 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'switch_type_spec', 1, undef
	],
	[#Rule 268
		 'switch_type_spec', 1, undef
	],
	[#Rule 269
		 'switch_type_spec', 1, undef
	],
	[#Rule 270
		 'switch_type_spec', 1, undef
	],
	[#Rule 271
		 'switch_type_spec', 1,
sub
#line 1632 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 272
		 'switch_body', 1,
sub
#line 1640 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 273
		 'switch_body', 2,
sub
#line 1644 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 274
		 'case', 3,
sub
#line 1653 "parser30.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 275
		 'case', 3,
sub
#line 1660 "parser30.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 276
		 'case_labels', 1,
sub
#line 1672 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 277
		 'case_labels', 2,
sub
#line 1676 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 278
		 'case_label', 3,
sub
#line 1685 "parser30.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 279
		 'case_label', 3,
sub
#line 1689 "parser30.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 280
		 'case_label', 2,
sub
#line 1695 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 281
		 'case_label', 2,
sub
#line 1700 "parser30.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 282
		 'case_label', 2,
sub
#line 1704 "parser30.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 283
		 'element_spec', 2,
sub
#line 1714 "parser30.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 284
		 'enum_type', 4,
sub
#line 1725 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 285
		 'enum_type', 4,
sub
#line 1731 "parser30.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 286
		 'enum_type', 2,
sub
#line 1736 "parser30.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 287
		 'enum_header', 2,
sub
#line 1744 "parser30.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 288
		 'enum_header', 2,
sub
#line 1750 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 289
		 'enumerators', 1,
sub
#line 1758 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 290
		 'enumerators', 3,
sub
#line 1762 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 291
		 'enumerators', 2,
sub
#line 1767 "parser30.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 292
		 'enumerators', 2,
sub
#line 1772 "parser30.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 293
		 'enumerator', 1,
sub
#line 1781 "parser30.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 294
		 'sequence_type', 6,
sub
#line 1791 "parser30.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 295
		 'sequence_type', 6,
sub
#line 1799 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 296
		 'sequence_type', 4,
sub
#line 1804 "parser30.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 297
		 'sequence_type', 4,
sub
#line 1811 "parser30.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 298
		 'sequence_type', 2,
sub
#line 1816 "parser30.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 299
		 'string_type', 4,
sub
#line 1825 "parser30.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 300
		 'string_type', 1,
sub
#line 1832 "parser30.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 301
		 'string_type', 4,
sub
#line 1838 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 302
		 'wide_string_type', 4,
sub
#line 1847 "parser30.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 303
		 'wide_string_type', 1,
sub
#line 1854 "parser30.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 304
		 'wide_string_type', 4,
sub
#line 1860 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 305
		 'array_declarator', 2,
sub
#line 1869 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 306
		 'fixed_array_sizes', 1,
sub
#line 1877 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 307
		 'fixed_array_sizes', 2,
sub
#line 1881 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 308
		 'fixed_array_size', 3,
sub
#line 1890 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 309
		 'fixed_array_size', 3,
sub
#line 1894 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 310
		 'attr_dcl', 1, undef
	],
	[#Rule 311
		 'attr_dcl', 1, undef
	],
	[#Rule 312
		 'except_dcl', 3,
sub
#line 1911 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 313
		 'except_dcl', 4,
sub
#line 1916 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 314
		 'except_dcl', 4,
sub
#line 1923 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 315
		 'except_dcl', 2,
sub
#line 1929 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 316
		 'exception_header', 2,
sub
#line 1938 "parser30.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 317
		 'exception_header', 2,
sub
#line 1944 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 318
		 'op_dcl', 2,
sub
#line 1953 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 319
		 'op_dcl', 3,
sub
#line 1961 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 320
		 'op_dcl', 4,
sub
#line 1970 "parser30.yp"
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
	[#Rule 321
		 'op_dcl', 3,
sub
#line 1980 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 322
		 'op_dcl', 2,
sub
#line 1989 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 323
		 'op_header', 3,
sub
#line 1999 "parser30.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 324
		 'op_header', 3,
sub
#line 2007 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 325
		 'op_mod', 1, undef
	],
	[#Rule 326
		 'op_mod', 0, undef
	],
	[#Rule 327
		 'op_attribute', 1, undef
	],
	[#Rule 328
		 'op_type_spec', 1, undef
	],
	[#Rule 329
		 'op_type_spec', 1,
sub
#line 2031 "parser30.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 330
		 'parameter_dcls', 3,
sub
#line 2041 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 331
		 'parameter_dcls', 2,
sub
#line 2045 "parser30.yp"
{
			undef;
		}
	],
	[#Rule 332
		 'parameter_dcls', 3,
sub
#line 2049 "parser30.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 333
		 'param_dcls', 1,
sub
#line 2057 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 334
		 'param_dcls', 3,
sub
#line 2061 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 335
		 'param_dcls', 2,
sub
#line 2066 "parser30.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 336
		 'param_dcls', 2,
sub
#line 2071 "parser30.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 337
		 'param_dcl', 3,
sub
#line 2080 "parser30.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 338
		 'param_dcl', 2,
sub
#line 2088 "parser30.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 339
		 'param_attribute', 1, undef
	],
	[#Rule 340
		 'param_attribute', 1, undef
	],
	[#Rule 341
		 'param_attribute', 1, undef
	],
	[#Rule 342
		 'raises_expr', 4,
sub
#line 2107 "parser30.yp"
{
			$_[3];
		}
	],
	[#Rule 343
		 'raises_expr', 4,
sub
#line 2111 "parser30.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 344
		 'raises_expr', 2,
sub
#line 2116 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 345
		 'exception_names', 1,
sub
#line 2124 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 346
		 'exception_names', 3,
sub
#line 2128 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 347
		 'exception_name', 1,
sub
#line 2136 "parser30.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 348
		 'context_expr', 4,
sub
#line 2144 "parser30.yp"
{
			$_[3];
		}
	],
	[#Rule 349
		 'context_expr', 4,
sub
#line 2148 "parser30.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 350
		 'context_expr', 2,
sub
#line 2153 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 351
		 'string_literals', 1,
sub
#line 2161 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 352
		 'string_literals', 3,
sub
#line 2165 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 353
		 'param_type_spec', 1, undef
	],
	[#Rule 354
		 'param_type_spec', 1, undef
	],
	[#Rule 355
		 'param_type_spec', 1, undef
	],
	[#Rule 356
		 'param_type_spec', 1,
sub
#line 2180 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 357
		 'fixed_pt_type', 6,
sub
#line 2188 "parser30.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 358
		 'fixed_pt_type', 6,
sub
#line 2196 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 359
		 'fixed_pt_type', 4,
sub
#line 2201 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 360
		 'fixed_pt_type', 2,
sub
#line 2206 "parser30.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 361
		 'fixed_pt_const_type', 1,
sub
#line 2215 "parser30.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 362
		 'value_base_type', 1,
sub
#line 2225 "parser30.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 363
		 'constr_forward_decl', 2,
sub
#line 2235 "parser30.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 364
		 'constr_forward_decl', 2,
sub
#line 2241 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 365
		 'constr_forward_decl', 2,
sub
#line 2246 "parser30.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 366
		 'constr_forward_decl', 2,
sub
#line 2252 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 367
		 'import', 3,
sub
#line 2261 "parser30.yp"
{
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 368
		 'import', 3,
sub
#line 2267 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 369
		 'import', 2,
sub
#line 2275 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 370
		 'imported_scope', 1, undef
	],
	[#Rule 371
		 'imported_scope', 1, undef
	],
	[#Rule 372
		 'type_id_dcl', 3,
sub
#line 2292 "parser30.yp"
{
			new TypeId($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 373
		 'type_id_dcl', 3,
sub
#line 2299 "parser30.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 374
		 'type_id_dcl', 2,
sub
#line 2304 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 375
		 'type_prefix_dcl', 3,
sub
#line 2313 "parser30.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 376
		 'type_prefix_dcl', 3,
sub
#line 2320 "parser30.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 377
		 'type_prefix_dcl', 3,
sub
#line 2325 "parser30.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	'',
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 378
		 'type_prefix_dcl', 2,
sub
#line 2332 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 379
		 'readonly_attr_spec', 4,
sub
#line 2341 "parser30.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]->{list_expr},
					'list_getraise'		=>	$_[4]->{list_getraise},
			);
		}
	],
	[#Rule 380
		 'readonly_attr_spec', 3,
sub
#line 2350 "parser30.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 381
		 'readonly_attr_spec', 2,
sub
#line 2355 "parser30.yp"
{
			$_[0]->Error("'attribute' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 382
		 'readonly_attr_declarator', 2,
sub
#line 2364 "parser30.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]
			};
		}
	],
	[#Rule 383
		 'readonly_attr_declarator', 1,
sub
#line 2371 "parser30.yp"
{
			{
				'list_expr'			=> $_[1]
			};
		}
	],
	[#Rule 384
		 'simple_declarators', 1,
sub
#line 2380 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 385
		 'simple_declarators', 3,
sub
#line 2384 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 386
		 'attr_spec', 3,
sub
#line 2393 "parser30.yp"
{
			new Attributes($_[0],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]->{list_expr},
					'list_getraise'		=>	$_[3]->{list_getraise},
					'list_setraise'		=>	$_[3]->{list_setraise},
			);
		}
	],
	[#Rule 387
		 'attr_spec', 2,
sub
#line 2402 "parser30.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 388
		 'attr_declarator', 2,
sub
#line 2411 "parser30.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]->{list_getraise},
				'list_setraise'		=> $_[2]->{list_setraise}
			};
		}
	],
	[#Rule 389
		 'attr_declarator', 1,
sub
#line 2419 "parser30.yp"
{
			{
				'list_expr'			=> $_[1]
			};
		}
	],
	[#Rule 390
		 'attr_raises_expr', 2,
sub
#line 2429 "parser30.yp"
{
			{
				'list_getraise'		=> $_[1],
				'list_setraise'		=> $_[2]
			};
		}
	],
	[#Rule 391
		 'attr_raises_expr', 1,
sub
#line 2436 "parser30.yp"
{
			{
				'list_getraise'		=> $_[1],
			};
		}
	],
	[#Rule 392
		 'attr_raises_expr', 1,
sub
#line 2442 "parser30.yp"
{
			{
				'list_setraise'		=> $_[1]
			};
		}
	],
	[#Rule 393
		 'get_except_expr', 2,
sub
#line 2452 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 394
		 'get_except_expr', 2,
sub
#line 2456 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 395
		 'set_except_expr', 2,
sub
#line 2465 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 396
		 'set_except_expr', 2,
sub
#line 2469 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 397
		 'exception_list', 3,
sub
#line 2478 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 398
		 'exception_list', 3,
sub
#line 2482 "parser30.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 399
		 'component', 1, undef
	],
	[#Rule 400
		 'component', 1, undef
	],
	[#Rule 401
		 'component_forward_dcl', 2,
sub
#line 2499 "parser30.yp"
{
			new ForwardComponent($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 402
		 'component_forward_dcl', 2,
sub
#line 2505 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 403
		 'component_dcl', 3,
sub
#line 2514 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 404
		 'component_dcl', 4,
sub
#line 2522 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 405
		 'component_dcl', 4,
sub
#line 2530 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 406
		 'component_header', 4,
sub
#line 2541 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3],
					'list_support'			=>	$_[4],
			);
		}
	],
	[#Rule 407
		 'component_header', 3,
sub
#line 2549 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3],
			);
		}
	],
	[#Rule 408
		 'component_header', 3,
sub
#line 2556 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'list_support'			=>	$_[3],
			);
		}
	],
	[#Rule 409
		 'component_header', 2,
sub
#line 2563 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
			);
		}
	],
	[#Rule 410
		 'component_header', 2,
sub
#line 2569 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 411
		 'supported_interface_spec', 2,
sub
#line 2578 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 412
		 'supported_interface_spec', 2,
sub
#line 2582 "parser30.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 413
		 'component_inheritance_spec', 2,
sub
#line 2591 "parser30.yp"
{
			Component->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 414
		 'component_inheritance_spec', 2,
sub
#line 2595 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 415
		 'component_body', 1, undef
	],
	[#Rule 416
		 'component_exports', 1,
sub
#line 2609 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 417
		 'component_exports', 2,
sub
#line 2613 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
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
		 'component_export', 2, undef
	],
	[#Rule 423
		 'component_export', 2, undef
	],
	[#Rule 424
		 'component_export', 2,
sub
#line 2634 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 425
		 'component_export', 2,
sub
#line 2640 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 426
		 'component_export', 2,
sub
#line 2646 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 427
		 'component_export', 2,
sub
#line 2652 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 428
		 'component_export', 2,
sub
#line 2658 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 429
		 'component_export', 2,
sub
#line 2664 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 430
		 'provides_dcl', 3,
sub
#line 2674 "parser30.yp"
{
			new Provides($_[0],
					'idf'					=>	$_[3],
					'type'					=>	$_[2],
			);
		}
	],
	[#Rule 431
		 'provides_dcl', 3,
sub
#line 2681 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 432
		 'provides_dcl', 2,
sub
#line 2686 "parser30.yp"
{
			$_[0]->Error("Interface type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 433
		 'interface_type', 1,
sub
#line 2695 "parser30.yp"
{
			BaseInterface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 434
		 'interface_type', 1, undef
	],
	[#Rule 435
		 'uses_dcl', 4,
sub
#line 2705 "parser30.yp"
{
			new Uses($_[0],
					'modifier'				=>	$_[2],
					'idf'					=>	$_[4],
					'type'					=>	$_[3],
			);
		}
	],
	[#Rule 436
		 'uses_dcl', 4,
sub
#line 2713 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 437
		 'uses_dcl', 3,
sub
#line 2718 "parser30.yp"
{
			$_[0]->Error("Interface type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 438
		 'uses_mod', 1, undef
	],
	[#Rule 439
		 'uses_mod', 0, undef
	],
	[#Rule 440
		 'emits_dcl', 3,
sub
#line 2734 "parser30.yp"
{
			new Emits($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 441
		 'emits_dcl', 3,
sub
#line 2741 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 442
		 'emits_dcl', 2,
sub
#line 2746 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 443
		 'publishes_dcl', 3,
sub
#line 2755 "parser30.yp"
{
			new Publishes($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 444
		 'publishes_dcl', 3,
sub
#line 2762 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 445
		 'publishes_dcl', 2,
sub
#line 2767 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 446
		 'consumes_dcl', 3,
sub
#line 2776 "parser30.yp"
{
			new Consumes($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 447
		 'consumes_dcl', 3,
sub
#line 2783 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 448
		 'consumes_dcl', 2,
sub
#line 2788 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 449
		 'home_dcl', 2,
sub
#line 2797 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[2],
			) if (defined $_[1]);
		}
	],
	[#Rule 450
		 'home_header', 4,
sub
#line 2809 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'manage'			=>	Component->Lookup($_[0],$_[3]),
					'primarykey'		=>	$_[4],
			) if (defined $_[1]);
		}
	],
	[#Rule 451
		 'home_header', 3,
sub
#line 2816 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'manage'			=>	Component->Lookup($_[0],$_[3]),
			) if (defined $_[1]);
		}
	],
	[#Rule 452
		 'home_header', 3,
sub
#line 2822 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 453
		 'home_header_spec', 4,
sub
#line 2831 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3],
					'list_support'		=>	$_[4],
			);
		}
	],
	[#Rule 454
		 'home_header_spec', 3,
sub
#line 2839 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3],
			);
		}
	],
	[#Rule 455
		 'home_header_spec', 3,
sub
#line 2846 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'list_support'		=>	$_[3],
			);
		}
	],
	[#Rule 456
		 'home_header_spec', 2,
sub
#line 2853 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 457
		 'home_header_spec', 2,
sub
#line 2859 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 458
		 'home_inheritance_spec', 2,
sub
#line 2868 "parser30.yp"
{
			Home->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 459
		 'home_inheritance_spec', 2,
sub
#line 2872 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 460
		 'primary_key_spec', 2,
sub
#line 2881 "parser30.yp"
{
			Value->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 461
		 'primary_key_spec', 2,
sub
#line 2885 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 462
		 'home_body', 2,
sub
#line 2894 "parser30.yp"
{
			[];
		}
	],
	[#Rule 463
		 'home_body', 3,
sub
#line 2898 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 464
		 'home_body', 3,
sub
#line 2902 "parser30.yp"
{
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 465
		 'home_exports', 1,
sub
#line 2910 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 466
		 'home_exports', 2,
sub
#line 2914 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 467
		 'home_export', 1, undef
	],
	[#Rule 468
		 'home_export', 2, undef
	],
	[#Rule 469
		 'home_export', 2, undef
	],
	[#Rule 470
		 'home_export', 2,
sub
#line 2929 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 471
		 'home_export', 2,
sub
#line 2935 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 472
		 'factory_dcl', 2,
sub
#line 2945 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 473
		 'factory_dcl', 1, undef
	],
	[#Rule 474
		 'factory_header_param', 3,
sub
#line 2956 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 475
		 'factory_header_param', 4,
sub
#line 2962 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'		=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 476
		 'factory_header_param', 4,
sub
#line 2970 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 477
		 'factory_header_param', 2,
sub
#line 2977 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 478
		 'factory_header', 2,
sub
#line 2987 "parser30.yp"
{
			new Factory($_[0],							# like Operation
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 479
		 'factory_header', 2,
sub
#line 2993 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 480
		 'finder_dcl', 2,
sub
#line 3002 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 481
		 'finder_dcl', 1, undef
	],
	[#Rule 482
		 'finder_header_param', 3,
sub
#line 3013 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 483
		 'finder_header_param', 4,
sub
#line 3019 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'		=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 484
		 'finder_header_param', 4,
sub
#line 3027 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 485
		 'finder_header_param', 2,
sub
#line 3034 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 486
		 'finder_header', 2,
sub
#line 3044 "parser30.yp"
{
			new Finder($_[0],							# like Operation
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 487
		 'finder_header', 2,
sub
#line 3050 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 488
		 'event', 1, undef
	],
	[#Rule 489
		 'event', 1, undef
	],
	[#Rule 490
		 'event', 1, undef
	],
	[#Rule 491
		 'event_forward_dcl', 2,
sub
#line 3069 "parser30.yp"
{
			new ForwardRegularEvent($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 492
		 'event_forward_dcl', 3,
sub
#line 3075 "parser30.yp"
{
			new ForwardAbstractEvent($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 493
		 'event_abs_dcl', 3,
sub
#line 3085 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 494
		 'event_abs_dcl', 4,
sub
#line 3093 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 495
		 'event_abs_dcl', 4,
sub
#line 3101 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 496
		 'event_abs_header', 3,
sub
#line 3111 "parser30.yp"
{
			new AbstractEvent($_[0],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 497
		 'event_abs_header', 4,
sub
#line 3117 "parser30.yp"
{
			new AbstractEvent($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 498
		 'event_abs_header', 3,
sub
#line 3124 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 499
		 'event_dcl', 3,
sub
#line 3133 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 500
		 'event_dcl', 4,
sub
#line 3141 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 501
		 'event_dcl', 4,
sub
#line 3149 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 502
		 'event_header', 2,
sub
#line 3160 "parser30.yp"
{
			new RegularEvent($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 503
		 'event_header', 3,
sub
#line 3166 "parser30.yp"
{
			new RegularEvent($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 504
		 'event_header', 3,
sub
#line 3173 "parser30.yp"
{
			new RegularEvent($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 505
		 'event_header', 4,
sub
#line 3180 "parser30.yp"
{
			new RegularEvent($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 506
		 'event_header', 2,
sub
#line 3188 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 507
		 'event_header', 3,
sub
#line 3193 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 3199 "parser30.yp"


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
