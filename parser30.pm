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
			'VALUETYPE' => -88,
			'EVENTTYPE' => -88,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'IDENTIFIER' => 61,
			'MODULE' => 40,
			'UNION' => 29,
			'HOME' => 30,
			'error' => 45,
			'LOCAL' => 48,
			'CONST' => 12,
			'CUSTOM' => 64,
			'EXCEPTION' => 50,
			'ENUM' => 16,
			'INTERFACE' => -39
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
			'value_abs_header' => 5,
			'component' => 6,
			'event_dcl' => 39,
			'type_id_dcl' => 38,
			'value_dcl' => 7,
			'import' => 8,
			'struct_header' => 9,
			'interface_dcl' => 10,
			'value' => 41,
			'value_box_header' => 42,
			'enum_type' => 44,
			'forward_dcl' => 43,
			'enum_header' => 47,
			'constr_forward_decl' => 46,
			'type_prefix_dcl' => 11,
			'value_mod' => 13,
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
			'exception_header' => 27,
			'union_type' => 28,
			'event_header' => 60,
			'component_header' => 31,
			'module' => 62,
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 1
		DEFAULT => -69
	},
	{#State 2
		ACTIONS => {
			'error' => 68,
			'VALUETYPE' => 67,
			'EVENTTYPE' => 66,
			'INTERFACE' => -37
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
		},
		GOTOS => {
			'check_semicolon' => 72
		}
	},
	{#State 5
		ACTIONS => {
			"{" => 73
		}
	},
	{#State 6
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 74
		}
	},
	{#State 7
		DEFAULT => -66
	},
	{#State 8
		ACTIONS => {
			'IMPORT' => 57
		},
		DEFAULT => -5,
		GOTOS => {
			'import' => 8,
			'imports' => 75
		}
	},
	{#State 9
		ACTIONS => {
			"{" => 76
		}
	},
	{#State 10
		DEFAULT => -30
	},
	{#State 11
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 77
		}
	},
	{#State 12
		ACTIONS => {
			'SHORT' => 101,
			'CHAR' => 87,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'FIXED' => 94,
			'WCHAR' => 82,
			'DOUBLE' => 106,
			'error' => 102,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'OCTET' => 84,
			'FLOAT' => 85,
			'WSTRING' => 92,
			'UNSIGNED' => 99
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 79,
			'signed_int' => 95,
			'wide_string_type' => 88,
			'integer_type' => 105,
			'boolean_type' => 104,
			'char_type' => 80,
			'scoped_name' => 96,
			'octet_type' => 81,
			'wide_char_type' => 97,
			'fixed_pt_const_type' => 89,
			'signed_long_int' => 98,
			'signed_short_int' => 91,
			'const_type' => 109,
			'string_type' => 100,
			'unsigned_longlong_int' => 83,
			'unsigned_long_int' => 111,
			'unsigned_short_int' => 103,
			'signed_longlong_int' => 86
		}
	},
	{#State 13
		ACTIONS => {
			'VALUETYPE' => 113,
			'EVENTTYPE' => 112
		}
	},
	{#State 14
		DEFAULT => -67
	},
	{#State 15
		DEFAULT => -1
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
		DEFAULT => -387
	},
	{#State 19
		ACTIONS => {
			'NATIVE' => 53,
			'ABSTRACT' => 2,
			'COMPONENT' => 54,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'MODULE' => 40,
			'IDENTIFIER' => 61,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 48,
			'CONST' => 12,
			'EXCEPTION' => 50,
			'CUSTOM' => 64,
			'ENUM' => 16,
			'INTERFACE' => -39
		},
		DEFAULT => -88,
		GOTOS => {
			'component_forward_dcl' => 33,
			'value_forward_dcl' => 1,
			'event' => 34,
			'except_dcl' => 35,
			'module_header' => 36,
			'interface' => 4,
			'value_box_dcl' => 37,
			'value_abs_header' => 5,
			'component' => 6,
			'type_id_dcl' => 38,
			'event_dcl' => 39,
			'value_dcl' => 7,
			'struct_header' => 9,
			'interface_dcl' => 10,
			'value' => 41,
			'value_box_header' => 42,
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 11,
			'value_mod' => 13,
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
			'module' => 62,
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 65
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
		DEFAULT => -464
	},
	{#State 25
		ACTIONS => {
			"{" => 123
		}
	},
	{#State 26
		DEFAULT => -174
	},
	{#State 27
		ACTIONS => {
			'error' => 125,
			"{" => 124
		}
	},
	{#State 28
		DEFAULT => -175
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
		DEFAULT => -388
	},
	{#State 34
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 133
		}
	},
	{#State 35
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 134
		}
	},
	{#State 36
		ACTIONS => {
			'error' => 136,
			"{" => 135
		}
	},
	{#State 37
		DEFAULT => -68
	},
	{#State 38
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 137
		}
	},
	{#State 39
		DEFAULT => -463
	},
	{#State 40
		ACTIONS => {
			'error' => 138,
			'IDENTIFIER' => 139
		}
	},
	{#State 41
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 140
		}
	},
	{#State 42
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 165,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 158,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'type_spec' => 145,
			'string_type' => 160,
			'struct_header' => 9,
			'base_type_spec' => 161,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'enum_header' => 47,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'signed_longlong_int' => 86,
			'wide_string_type' => 148,
			'boolean_type' => 166,
			'integer_type' => 167,
			'signed_short_int' => 91,
			'struct_type' => 150,
			'union_type' => 151,
			'sequence_type' => 168,
			'unsigned_long_int' => 111,
			'template_type_spec' => 153,
			'constr_type_spec' => 154,
			'simple_type_spec' => 169,
			'fixed_pt_type' => 170
		}
	},
	{#State 43
		DEFAULT => -31
	},
	{#State 44
		DEFAULT => -176
	},
	{#State 45
		DEFAULT => -4
	},
	{#State 46
		DEFAULT => -178
	},
	{#State 47
		ACTIONS => {
			'error' => 172,
			"{" => 171
		}
	},
	{#State 48
		DEFAULT => -38
	},
	{#State 49
		ACTIONS => {
			'SWITCH' => 173
		}
	},
	{#State 50
		ACTIONS => {
			'error' => 174,
			'IDENTIFIER' => 175
		}
	},
	{#State 51
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 176
		}
	},
	{#State 52
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 177
		}
	},
	{#State 53
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 180
		},
		GOTOS => {
			'simple_declarator' => 179
		}
	},
	{#State 54
		ACTIONS => {
			'error' => 181,
			'IDENTIFIER' => 182
		}
	},
	{#State 55
		DEFAULT => -465
	},
	{#State 56
		ACTIONS => {
			'error' => 184,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 183
		}
	},
	{#State 57
		ACTIONS => {
			'error' => 188,
			'IDENTIFIER' => 110,
			"::" => 90,
			'STRING_LITERAL' => 189
		},
		GOTOS => {
			'scoped_name' => 187,
			'string_literal' => 185,
			'imported_scope' => 186
		}
	},
	{#State 58
		ACTIONS => {
			'error' => 192,
			'IDENTIFIER' => 110,
			"::" => 190
		},
		GOTOS => {
			'scoped_name' => 191
		}
	},
	{#State 59
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 165,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'error' => 195,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 158,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'type_spec' => 193,
			'type_declarator' => 194,
			'string_type' => 160,
			'struct_header' => 9,
			'base_type_spec' => 161,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'enum_header' => 47,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'signed_longlong_int' => 86,
			'wide_string_type' => 148,
			'boolean_type' => 166,
			'integer_type' => 167,
			'signed_short_int' => 91,
			'struct_type' => 150,
			'union_type' => 151,
			'sequence_type' => 168,
			'unsigned_long_int' => 111,
			'template_type_spec' => 153,
			'constr_type_spec' => 154,
			'simple_type_spec' => 169,
			'fixed_pt_type' => 170
		}
	},
	{#State 60
		ACTIONS => {
			"{" => 196
		}
	},
	{#State 61
		ACTIONS => {
			'error' => 197
		}
	},
	{#State 62
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 198
		}
	},
	{#State 63
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 199
		}
	},
	{#State 64
		DEFAULT => -87
	},
	{#State 65
		ACTIONS => {
			'NATIVE' => 53,
			'ABSTRACT' => 2,
			'COMPONENT' => 54,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'IMPORT' => 57,
			'VALUETYPE' => -88,
			'EVENTTYPE' => -88,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'IDENTIFIER' => 61,
			'MODULE' => 40,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 48,
			'CONST' => 12,
			'CUSTOM' => 64,
			'EXCEPTION' => 50,
			'ENUM' => 16,
			'INTERFACE' => -39
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
			'value_abs_header' => 5,
			'component' => 6,
			'type_id_dcl' => 38,
			'event_dcl' => 39,
			'value_dcl' => 7,
			'import' => 8,
			'struct_header' => 9,
			'interface_dcl' => 10,
			'value' => 41,
			'value_box_header' => 42,
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 11,
			'value_mod' => 13,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 200,
			'interface_mod' => 17,
			'component_dcl' => 18,
			'const_dcl' => 51,
			'imports' => 201,
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
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 66
		ACTIONS => {
			'error' => 202,
			'IDENTIFIER' => 203
		}
	},
	{#State 67
		ACTIONS => {
			'error' => 204,
			'IDENTIFIER' => 205
		}
	},
	{#State 68
		DEFAULT => -79
	},
	{#State 69
		DEFAULT => 0
	},
	{#State 70
		DEFAULT => -22
	},
	{#State 71
		DEFAULT => -23
	},
	{#State 72
		DEFAULT => -13
	},
	{#State 73
		ACTIONS => {
			'PRIVATE' => 207,
			'ONEWAY' => 208,
			'FIXED' => -303,
			'SEQUENCE' => -303,
			'FACTORY' => 220,
			'UNSIGNED' => -303,
			'SHORT' => -303,
			'WCHAR' => -303,
			'error' => 223,
			'CONST' => 12,
			'OCTET' => -303,
			'FLOAT' => -303,
			'EXCEPTION' => 50,
			"}" => 224,
			'ENUM' => 16,
			'ANY' => -303,
			'CHAR' => -303,
			'OBJECT' => -303,
			'NATIVE' => 53,
			'VALUEBASE' => -303,
			'VOID' => -303,
			'STRUCT' => 23,
			'DOUBLE' => -303,
			'TYPEID' => 56,
			'LONG' => -303,
			'STRING' => -303,
			"::" => -303,
			'TYPEPREFIX' => 58,
			'WSTRING' => -303,
			'TYPEDEF' => 59,
			'BOOLEAN' => -303,
			'IDENTIFIER' => -303,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231,
			'PUBLIC' => 215
		},
		GOTOS => {
			'init_header_param' => 206,
			'const_dcl' => 225,
			'op_mod' => 209,
			'state_member' => 219,
			'except_dcl' => 218,
			'attr_spec' => 210,
			'op_attribute' => 211,
			'state_mod' => 212,
			'readonly_attr_spec' => 213,
			'exports' => 226,
			'_export' => 227,
			'type_id_dcl' => 221,
			'export' => 228,
			'init_header' => 222,
			'struct_type' => 26,
			'op_header' => 229,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 9,
			'op_dcl' => 232,
			'enum_type' => 44,
			'init_dcl' => 216,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'type_dcl' => 233,
			'union_header' => 49
		}
	},
	{#State 74
		DEFAULT => -19
	},
	{#State 75
		DEFAULT => -6
	},
	{#State 76
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 165,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'error' => 236,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 158,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'type_spec' => 234,
			'string_type' => 160,
			'struct_header' => 9,
			'base_type_spec' => 161,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'enum_header' => 47,
			'member_list' => 235,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'signed_longlong_int' => 86,
			'wide_string_type' => 148,
			'boolean_type' => 166,
			'integer_type' => 167,
			'signed_short_int' => 91,
			'member' => 237,
			'struct_type' => 150,
			'union_type' => 151,
			'sequence_type' => 168,
			'unsigned_long_int' => 111,
			'template_type_spec' => 153,
			'constr_type_spec' => 154,
			'simple_type_spec' => 169,
			'fixed_pt_type' => 170
		}
	},
	{#State 77
		DEFAULT => -17
	},
	{#State 78
		DEFAULT => -215
	},
	{#State 79
		DEFAULT => -126
	},
	{#State 80
		DEFAULT => -123
	},
	{#State 81
		DEFAULT => -131
	},
	{#State 82
		DEFAULT => -229
	},
	{#State 83
		DEFAULT => -224
	},
	{#State 84
		DEFAULT => -231
	},
	{#State 85
		DEFAULT => -211
	},
	{#State 86
		DEFAULT => -218
	},
	{#State 87
		DEFAULT => -228
	},
	{#State 88
		DEFAULT => -128
	},
	{#State 89
		DEFAULT => -129
	},
	{#State 90
		ACTIONS => {
			'error' => 238,
			'IDENTIFIER' => 239
		}
	},
	{#State 91
		DEFAULT => -216
	},
	{#State 92
		ACTIONS => {
			"<" => 240
		},
		DEFAULT => -283
	},
	{#State 93
		DEFAULT => -230
	},
	{#State 94
		DEFAULT => -349
	},
	{#State 95
		DEFAULT => -214
	},
	{#State 96
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -130
	},
	{#State 97
		DEFAULT => -124
	},
	{#State 98
		DEFAULT => -217
	},
	{#State 99
		ACTIONS => {
			'SHORT' => 242,
			'LONG' => 243
		}
	},
	{#State 100
		DEFAULT => -127
	},
	{#State 101
		DEFAULT => -219
	},
	{#State 102
		DEFAULT => -121
	},
	{#State 103
		DEFAULT => -222
	},
	{#State 104
		DEFAULT => -125
	},
	{#State 105
		DEFAULT => -122
	},
	{#State 106
		DEFAULT => -212
	},
	{#State 107
		ACTIONS => {
			'DOUBLE' => 244,
			'LONG' => 245
		},
		DEFAULT => -220
	},
	{#State 108
		ACTIONS => {
			"<" => 246
		},
		DEFAULT => -280
	},
	{#State 109
		ACTIONS => {
			'error' => 247,
			'IDENTIFIER' => 248
		}
	},
	{#State 110
		DEFAULT => -61
	},
	{#State 111
		DEFAULT => -223
	},
	{#State 112
		ACTIONS => {
			'error' => 249,
			'IDENTIFIER' => 250
		}
	},
	{#State 113
		ACTIONS => {
			'error' => 251,
			'IDENTIFIER' => 252
		}
	},
	{#State 114
		DEFAULT => -268
	},
	{#State 115
		DEFAULT => -267
	},
	{#State 116
		ACTIONS => {
			'error' => 253,
			'IDENTIFIER' => 254
		}
	},
	{#State 117
		DEFAULT => -2
	},
	{#State 118
		ACTIONS => {
			'PRIVATE' => 207,
			'ONEWAY' => 208,
			'FIXED' => -303,
			'SEQUENCE' => -303,
			'FACTORY' => 220,
			'UNSIGNED' => -303,
			'SHORT' => -303,
			'WCHAR' => -303,
			'error' => 255,
			'CONST' => 12,
			'OCTET' => -303,
			'FLOAT' => -303,
			'EXCEPTION' => 50,
			"}" => 256,
			'ENUM' => 16,
			'ANY' => -303,
			'CHAR' => -303,
			'OBJECT' => -303,
			'NATIVE' => 53,
			'VALUEBASE' => -303,
			'VOID' => -303,
			'STRUCT' => 23,
			'DOUBLE' => -303,
			'TYPEID' => 56,
			'LONG' => -303,
			'STRING' => -303,
			"::" => -303,
			'TYPEPREFIX' => 58,
			'WSTRING' => -303,
			'TYPEDEF' => 59,
			'BOOLEAN' => -303,
			'IDENTIFIER' => -303,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231,
			'PUBLIC' => 215
		},
		GOTOS => {
			'init_header_param' => 206,
			'const_dcl' => 225,
			'op_mod' => 209,
			'state_member' => 219,
			'except_dcl' => 218,
			'attr_spec' => 210,
			'op_attribute' => 211,
			'state_mod' => 212,
			'readonly_attr_spec' => 213,
			'exports' => 257,
			'_export' => 227,
			'type_id_dcl' => 221,
			'export' => 228,
			'init_header' => 222,
			'struct_type' => 26,
			'op_header' => 229,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 9,
			'op_dcl' => 232,
			'enum_type' => 44,
			'init_dcl' => 216,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'type_dcl' => 233,
			'union_header' => 49,
			'interface_body' => 258
		}
	},
	{#State 119
		ACTIONS => {
			'error' => 260,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 259
		}
	},
	{#State 120
		ACTIONS => {
			'PRIVATE' => 207,
			'ONEWAY' => 208,
			'FIXED' => -303,
			'SEQUENCE' => -303,
			'FACTORY' => 220,
			'UNSIGNED' => -303,
			'SHORT' => -303,
			'WCHAR' => -303,
			'error' => 264,
			'CONST' => 12,
			'OCTET' => -303,
			'FLOAT' => -303,
			'EXCEPTION' => 50,
			"}" => 265,
			'ENUM' => 16,
			'ANY' => -303,
			'CHAR' => -303,
			'OBJECT' => -303,
			'NATIVE' => 53,
			'VALUEBASE' => -303,
			'VOID' => -303,
			'STRUCT' => 23,
			'DOUBLE' => -303,
			'TYPEID' => 56,
			'LONG' => -303,
			'STRING' => -303,
			"::" => -303,
			'TYPEPREFIX' => 58,
			'WSTRING' => -303,
			'TYPEDEF' => 59,
			'BOOLEAN' => -303,
			'IDENTIFIER' => -303,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231,
			'PUBLIC' => 215
		},
		GOTOS => {
			'init_header_param' => 206,
			'const_dcl' => 225,
			'op_mod' => 209,
			'value_elements' => 266,
			'except_dcl' => 218,
			'state_member' => 263,
			'attr_spec' => 210,
			'op_attribute' => 211,
			'state_mod' => 212,
			'value_element' => 261,
			'readonly_attr_spec' => 213,
			'type_id_dcl' => 221,
			'export' => 267,
			'init_header' => 222,
			'struct_type' => 26,
			'op_header' => 229,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 9,
			'op_dcl' => 232,
			'enum_type' => 44,
			'init_dcl' => 262,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'type_dcl' => 233,
			'union_header' => 49
		}
	},
	{#State 121
		ACTIONS => {
			"{" => -237
		},
		DEFAULT => -352
	},
	{#State 122
		ACTIONS => {
			"{" => -236
		},
		DEFAULT => -351
	},
	{#State 123
		ACTIONS => {
			'PRIVATE' => 207,
			'ONEWAY' => 208,
			'FIXED' => -303,
			'SEQUENCE' => -303,
			'FACTORY' => 220,
			'UNSIGNED' => -303,
			'SHORT' => -303,
			'WCHAR' => -303,
			'error' => 268,
			'CONST' => 12,
			'OCTET' => -303,
			'FLOAT' => -303,
			'EXCEPTION' => 50,
			"}" => 269,
			'ENUM' => 16,
			'ANY' => -303,
			'CHAR' => -303,
			'OBJECT' => -303,
			'NATIVE' => 53,
			'VALUEBASE' => -303,
			'VOID' => -303,
			'STRUCT' => 23,
			'DOUBLE' => -303,
			'TYPEID' => 56,
			'LONG' => -303,
			'STRING' => -303,
			"::" => -303,
			'TYPEPREFIX' => 58,
			'WSTRING' => -303,
			'TYPEDEF' => 59,
			'BOOLEAN' => -303,
			'IDENTIFIER' => -303,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231,
			'PUBLIC' => 215
		},
		GOTOS => {
			'init_header_param' => 206,
			'const_dcl' => 225,
			'op_mod' => 209,
			'state_member' => 219,
			'except_dcl' => 218,
			'attr_spec' => 210,
			'op_attribute' => 211,
			'state_mod' => 212,
			'readonly_attr_spec' => 213,
			'exports' => 270,
			'_export' => 227,
			'type_id_dcl' => 221,
			'export' => 228,
			'init_header' => 222,
			'struct_type' => 26,
			'op_header' => 229,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 9,
			'op_dcl' => 232,
			'enum_type' => 44,
			'init_dcl' => 216,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'type_dcl' => 233,
			'union_header' => 49
		}
	},
	{#State 124
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 165,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'error' => 272,
			"}" => 273,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 158,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'type_spec' => 234,
			'string_type' => 160,
			'struct_header' => 9,
			'base_type_spec' => 161,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'enum_header' => 47,
			'member_list' => 271,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'signed_longlong_int' => 86,
			'wide_string_type' => 148,
			'boolean_type' => 166,
			'integer_type' => 167,
			'signed_short_int' => 91,
			'member' => 237,
			'struct_type' => 150,
			'union_type' => 151,
			'sequence_type' => 168,
			'unsigned_long_int' => 111,
			'template_type_spec' => 153,
			'constr_type_spec' => 154,
			'simple_type_spec' => 169,
			'fixed_pt_type' => 170
		}
	},
	{#State 125
		DEFAULT => -295
	},
	{#State 126
		ACTIONS => {
			'SWITCH' => -247
		},
		DEFAULT => -354
	},
	{#State 127
		ACTIONS => {
			'SWITCH' => -246
		},
		DEFAULT => -353
	},
	{#State 128
		DEFAULT => -434
	},
	{#State 129
		ACTIONS => {
			":" => 275
		},
		DEFAULT => -437,
		GOTOS => {
			'home_inheritance_spec' => 274
		}
	},
	{#State 130
		ACTIONS => {
			'error' => 286,
			'PUBLISHES' => 289,
			"}" => 287,
			'USES' => 281,
			'READONLY' => 230,
			'PROVIDES' => 288,
			'CONSUMES' => 291,
			'ATTRIBUTE' => 231,
			'EMITS' => 284
		},
		GOTOS => {
			'consumes_dcl' => 276,
			'emits_dcl' => 283,
			'attr_spec' => 210,
			'provides_dcl' => 280,
			'readonly_attr_spec' => 213,
			'component_exports' => 277,
			'attr_dcl' => 282,
			'publishes_dcl' => 278,
			'uses_dcl' => 290,
			'component_export' => 279,
			'component_body' => 285
		}
	},
	{#State 131
		ACTIONS => {
			'ONEWAY' => 208,
			'FIXED' => -303,
			'SEQUENCE' => -303,
			'FACTORY' => 298,
			'UNSIGNED' => -303,
			'SHORT' => -303,
			'WCHAR' => -303,
			'error' => 299,
			'CONST' => 12,
			'OCTET' => -303,
			'FLOAT' => -303,
			'EXCEPTION' => 50,
			"}" => 300,
			'ENUM' => 16,
			'FINDER' => 293,
			'ANY' => -303,
			'CHAR' => -303,
			'OBJECT' => -303,
			'NATIVE' => 53,
			'VALUEBASE' => -303,
			'VOID' => -303,
			'STRUCT' => 23,
			'DOUBLE' => -303,
			'TYPEID' => 56,
			'LONG' => -303,
			'STRING' => -303,
			"::" => -303,
			'TYPEPREFIX' => 58,
			'WSTRING' => -303,
			'TYPEDEF' => 59,
			'BOOLEAN' => -303,
			'IDENTIFIER' => -303,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231
		},
		GOTOS => {
			'const_dcl' => 225,
			'op_mod' => 209,
			'except_dcl' => 218,
			'attr_spec' => 210,
			'factory_header_param' => 292,
			'home_exports' => 295,
			'home_export' => 294,
			'op_attribute' => 211,
			'readonly_attr_spec' => 213,
			'finder_dcl' => 296,
			'type_id_dcl' => 221,
			'export' => 301,
			'struct_type' => 26,
			'finder_header' => 302,
			'exception_header' => 27,
			'union_type' => 28,
			'op_header' => 229,
			'struct_header' => 9,
			'factory_dcl' => 297,
			'enum_type' => 44,
			'finder_header_param' => 303,
			'op_dcl' => 232,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'union_header' => 49,
			'type_dcl' => 233,
			'factory_header' => 304
		}
	},
	{#State 132
		DEFAULT => -430
	},
	{#State 133
		DEFAULT => -18
	},
	{#State 134
		DEFAULT => -12
	},
	{#State 135
		ACTIONS => {
			'NATIVE' => 53,
			'ABSTRACT' => 2,
			'COMPONENT' => 54,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'VALUETYPE' => -88,
			'EVENTTYPE' => -88,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'IDENTIFIER' => 61,
			'MODULE' => 40,
			'UNION' => 29,
			'HOME' => 30,
			'error' => 306,
			'LOCAL' => 48,
			'CONST' => 12,
			'CUSTOM' => 64,
			'EXCEPTION' => 50,
			"}" => 307,
			'ENUM' => 16,
			'INTERFACE' => -39
		},
		GOTOS => {
			'component_forward_dcl' => 33,
			'value_forward_dcl' => 1,
			'event' => 34,
			'except_dcl' => 35,
			'module_header' => 36,
			'interface' => 4,
			'value_box_dcl' => 37,
			'value_abs_header' => 5,
			'component' => 6,
			'type_id_dcl' => 38,
			'event_dcl' => 39,
			'value_dcl' => 7,
			'struct_header' => 9,
			'interface_dcl' => 10,
			'value' => 41,
			'value_box_header' => 42,
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 11,
			'value_mod' => 13,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 305,
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
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 136
		ACTIONS => {
			"}" => 308
		}
	},
	{#State 137
		DEFAULT => -16
	},
	{#State 138
		DEFAULT => -29
	},
	{#State 139
		DEFAULT => -28
	},
	{#State 140
		DEFAULT => -15
	},
	{#State 141
		DEFAULT => -187
	},
	{#State 142
		ACTIONS => {
			'error' => 310,
			"<" => 309
		}
	},
	{#State 143
		DEFAULT => -189
	},
	{#State 144
		DEFAULT => -192
	},
	{#State 145
		DEFAULT => -72
	},
	{#State 146
		DEFAULT => -193
	},
	{#State 147
		DEFAULT => -350
	},
	{#State 148
		DEFAULT => -198
	},
	{#State 149
		ACTIONS => {
			'error' => 311,
			'IDENTIFIER' => 312
		}
	},
	{#State 150
		DEFAULT => -200
	},
	{#State 151
		DEFAULT => -201
	},
	{#State 152
		ACTIONS => {
			'error' => 313,
			'IDENTIFIER' => 314
		}
	},
	{#State 153
		DEFAULT => -184
	},
	{#State 154
		DEFAULT => -182
	},
	{#State 155
		ACTIONS => {
			'error' => 316,
			"<" => 315
		}
	},
	{#State 156
		DEFAULT => -195
	},
	{#State 157
		DEFAULT => -194
	},
	{#State 158
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -185
	},
	{#State 159
		DEFAULT => -190
	},
	{#State 160
		DEFAULT => -197
	},
	{#State 161
		DEFAULT => -183
	},
	{#State 162
		DEFAULT => -202
	},
	{#State 163
		DEFAULT => -232
	},
	{#State 164
		DEFAULT => -233
	},
	{#State 165
		DEFAULT => -186
	},
	{#State 166
		DEFAULT => -191
	},
	{#State 167
		DEFAULT => -188
	},
	{#State 168
		DEFAULT => -196
	},
	{#State 169
		DEFAULT => -181
	},
	{#State 170
		DEFAULT => -199
	},
	{#State 171
		ACTIONS => {
			'error' => 319,
			'IDENTIFIER' => 320
		},
		GOTOS => {
			'enumerators' => 318,
			'enumerator' => 317
		}
	},
	{#State 172
		DEFAULT => -266
	},
	{#State 173
		ACTIONS => {
			'error' => 322,
			"(" => 321
		}
	},
	{#State 174
		DEFAULT => -297
	},
	{#State 175
		DEFAULT => -296
	},
	{#State 176
		DEFAULT => -11
	},
	{#State 177
		DEFAULT => -20
	},
	{#State 178
		ACTIONS => {
			";" => 323,
			"," => 324
		}
	},
	{#State 179
		DEFAULT => -177
	},
	{#State 180
		DEFAULT => -207
	},
	{#State 181
		ACTIONS => {
			"{" => -395
		},
		DEFAULT => -390
	},
	{#State 182
		ACTIONS => {
			"{" => -401,
			'SUPPORTS' => -401,
			":" => 326
		},
		DEFAULT => -389,
		GOTOS => {
			'component_inheritance_spec' => 325
		}
	},
	{#State 183
		ACTIONS => {
			'error' => 328,
			"::" => 241,
			'STRING_LITERAL' => 189
		},
		GOTOS => {
			'string_literal' => 327
		}
	},
	{#State 184
		DEFAULT => -361
	},
	{#State 185
		DEFAULT => -358
	},
	{#State 186
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 329
		}
	},
	{#State 187
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -357
	},
	{#State 188
		DEFAULT => -356
	},
	{#State 189
		ACTIONS => {
			'STRING_LITERAL' => 189
		},
		DEFAULT => -166,
		GOTOS => {
			'string_literal' => 330
		}
	},
	{#State 190
		ACTIONS => {
			'error' => 238,
			'IDENTIFIER' => 239,
			'STRING_LITERAL' => 189
		},
		GOTOS => {
			'string_literal' => 331
		}
	},
	{#State 191
		ACTIONS => {
			'error' => 333,
			"::" => 241,
			'STRING_LITERAL' => 189
		},
		GOTOS => {
			'string_literal' => 332
		}
	},
	{#State 192
		DEFAULT => -365
	},
	{#State 193
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 339
		},
		GOTOS => {
			'declarators' => 334,
			'declarator' => 337,
			'simple_declarator' => 338,
			'array_declarator' => 336,
			'complex_declarator' => 335
		}
	},
	{#State 194
		DEFAULT => -173
	},
	{#State 195
		DEFAULT => -179
	},
	{#State 196
		ACTIONS => {
			'PRIVATE' => 207,
			'ONEWAY' => 208,
			'FIXED' => -303,
			'SEQUENCE' => -303,
			'FACTORY' => 220,
			'UNSIGNED' => -303,
			'SHORT' => -303,
			'WCHAR' => -303,
			'error' => 340,
			'CONST' => 12,
			'OCTET' => -303,
			'FLOAT' => -303,
			'EXCEPTION' => 50,
			"}" => 341,
			'ENUM' => 16,
			'ANY' => -303,
			'CHAR' => -303,
			'OBJECT' => -303,
			'NATIVE' => 53,
			'VALUEBASE' => -303,
			'VOID' => -303,
			'STRUCT' => 23,
			'DOUBLE' => -303,
			'TYPEID' => 56,
			'LONG' => -303,
			'STRING' => -303,
			"::" => -303,
			'TYPEPREFIX' => 58,
			'WSTRING' => -303,
			'TYPEDEF' => 59,
			'BOOLEAN' => -303,
			'IDENTIFIER' => -303,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231,
			'PUBLIC' => 215
		},
		GOTOS => {
			'init_header_param' => 206,
			'const_dcl' => 225,
			'op_mod' => 209,
			'value_elements' => 342,
			'except_dcl' => 218,
			'state_member' => 263,
			'attr_spec' => 210,
			'op_attribute' => 211,
			'state_mod' => 212,
			'value_element' => 261,
			'readonly_attr_spec' => 213,
			'type_id_dcl' => 221,
			'export' => 267,
			'init_header' => 222,
			'struct_type' => 26,
			'op_header' => 229,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 9,
			'op_dcl' => 232,
			'enum_type' => 44,
			'init_dcl' => 262,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'type_dcl' => 233,
			'union_header' => 49
		}
	},
	{#State 197
		ACTIONS => {
			";" => 343
		}
	},
	{#State 198
		DEFAULT => -14
	},
	{#State 199
		DEFAULT => -10
	},
	{#State 200
		DEFAULT => -8
	},
	{#State 201
		ACTIONS => {
			'NATIVE' => 53,
			'ABSTRACT' => 2,
			'COMPONENT' => 54,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'MODULE' => 40,
			'IDENTIFIER' => 61,
			'UNION' => 29,
			'HOME' => 30,
			'LOCAL' => 48,
			'CONST' => 12,
			'EXCEPTION' => 50,
			'CUSTOM' => 64,
			'ENUM' => 16,
			'INTERFACE' => -39
		},
		DEFAULT => -88,
		GOTOS => {
			'component_forward_dcl' => 33,
			'value_forward_dcl' => 1,
			'event' => 34,
			'except_dcl' => 35,
			'module_header' => 36,
			'interface' => 4,
			'value_box_dcl' => 37,
			'value_abs_header' => 5,
			'component' => 6,
			'type_id_dcl' => 38,
			'event_dcl' => 39,
			'value_dcl' => 7,
			'struct_header' => 9,
			'interface_dcl' => 10,
			'value' => 41,
			'value_box_header' => 42,
			'forward_dcl' => 43,
			'enum_type' => 44,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 11,
			'value_mod' => 13,
			'value_abs_dcl' => 14,
			'union_header' => 49,
			'definitions' => 344,
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
			'type_dcl' => 63,
			'home_header' => 32,
			'definition' => 65
		}
	},
	{#State 202
		DEFAULT => -472
	},
	{#State 203
		ACTIONS => {
			"{" => -398,
			":" => 347,
			'SUPPORTS' => 345
		},
		DEFAULT => -467,
		GOTOS => {
			'supported_interface_spec' => 348,
			'value_inheritance_spec' => 346
		}
	},
	{#State 204
		DEFAULT => -78
	},
	{#State 205
		ACTIONS => {
			"{" => -398,
			":" => 347,
			'SUPPORTS' => 345
		},
		DEFAULT => -71,
		GOTOS => {
			'supported_interface_spec' => 348,
			'value_inheritance_spec' => 349
		}
	},
	{#State 206
		ACTIONS => {
			'RAISES' => 350
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 351
		}
	},
	{#State 207
		DEFAULT => -104
	},
	{#State 208
		DEFAULT => -304
	},
	{#State 209
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 357,
			'SEQUENCE' => 142,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'WCHAR' => 82,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'wide_string_type' => 352,
			'integer_type' => 167,
			'boolean_type' => 166,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 354,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'signed_short_int' => 91,
			'string_type' => 355,
			'op_type_spec' => 358,
			'op_param_type_spec' => 353,
			'sequence_type' => 359,
			'base_type_spec' => 356,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'unsigned_long_int' => 111,
			'unsigned_short_int' => 103,
			'fixed_pt_type' => 360,
			'signed_longlong_int' => 86
		}
	},
	{#State 210
		DEFAULT => -291
	},
	{#State 211
		DEFAULT => -302
	},
	{#State 212
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 165,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'error' => 362,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 158,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'type_spec' => 361,
			'string_type' => 160,
			'struct_header' => 9,
			'base_type_spec' => 161,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'enum_header' => 47,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'signed_longlong_int' => 86,
			'wide_string_type' => 148,
			'boolean_type' => 166,
			'integer_type' => 167,
			'signed_short_int' => 91,
			'struct_type' => 150,
			'union_type' => 151,
			'sequence_type' => 168,
			'unsigned_long_int' => 111,
			'template_type_spec' => 153,
			'constr_type_spec' => 154,
			'simple_type_spec' => 169,
			'fixed_pt_type' => 170
		}
	},
	{#State 213
		DEFAULT => -290
	},
	{#State 214
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 363
		}
	},
	{#State 215
		DEFAULT => -103
	},
	{#State 216
		DEFAULT => -47
	},
	{#State 217
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 364
		}
	},
	{#State 218
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 365
		}
	},
	{#State 219
		DEFAULT => -46
	},
	{#State 220
		ACTIONS => {
			'error' => 366,
			'IDENTIFIER' => 367
		}
	},
	{#State 221
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 368
		}
	},
	{#State 222
		ACTIONS => {
			'error' => 370,
			"(" => 369
		}
	},
	{#State 223
		ACTIONS => {
			"}" => 371
		}
	},
	{#State 224
		DEFAULT => -74
	},
	{#State 225
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 372
		}
	},
	{#State 226
		ACTIONS => {
			"}" => 373
		}
	},
	{#State 227
		ACTIONS => {
			'PRIVATE' => 207,
			'ONEWAY' => 208,
			'FACTORY' => 220,
			'CONST' => 12,
			'EXCEPTION' => 50,
			"}" => -43,
			'ENUM' => 16,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231,
			'PUBLIC' => 215
		},
		DEFAULT => -303,
		GOTOS => {
			'init_header_param' => 206,
			'const_dcl' => 225,
			'op_mod' => 209,
			'state_member' => 219,
			'except_dcl' => 218,
			'attr_spec' => 210,
			'op_attribute' => 211,
			'state_mod' => 212,
			'readonly_attr_spec' => 213,
			'exports' => 374,
			'_export' => 227,
			'type_id_dcl' => 221,
			'export' => 228,
			'init_header' => 222,
			'struct_type' => 26,
			'op_header' => 229,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 9,
			'op_dcl' => 232,
			'enum_type' => 44,
			'init_dcl' => 216,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'type_dcl' => 233,
			'union_header' => 49
		}
	},
	{#State 228
		DEFAULT => -45
	},
	{#State 229
		ACTIONS => {
			'error' => 376,
			"(" => 375
		},
		GOTOS => {
			'parameter_dcls' => 377
		}
	},
	{#State 230
		ACTIONS => {
			'error' => 378,
			'ATTRIBUTE' => 379
		}
	},
	{#State 231
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 384,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'error' => 383,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'wide_string_type' => 352,
			'integer_type' => 167,
			'boolean_type' => 166,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 354,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'signed_short_int' => 91,
			'string_type' => 355,
			'op_param_type_spec' => 381,
			'struct_type' => 150,
			'union_type' => 151,
			'struct_header' => 9,
			'sequence_type' => 385,
			'base_type_spec' => 356,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'unsigned_long_int' => 111,
			'param_type_spec' => 380,
			'enum_header' => 47,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'constr_type_spec' => 382,
			'fixed_pt_type' => 386,
			'signed_longlong_int' => 86
		}
	},
	{#State 232
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 387
		}
	},
	{#State 233
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 388
		}
	},
	{#State 234
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 339
		},
		GOTOS => {
			'declarators' => 389,
			'declarator' => 337,
			'simple_declarator' => 338,
			'array_declarator' => 336,
			'complex_declarator' => 335
		}
	},
	{#State 235
		ACTIONS => {
			"}" => 390
		}
	},
	{#State 236
		ACTIONS => {
			"}" => 391
		}
	},
	{#State 237
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 165,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		DEFAULT => -238,
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 158,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'type_spec' => 234,
			'string_type' => 160,
			'struct_header' => 9,
			'base_type_spec' => 161,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'enum_header' => 47,
			'member_list' => 392,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'signed_longlong_int' => 86,
			'wide_string_type' => 148,
			'boolean_type' => 166,
			'integer_type' => 167,
			'signed_short_int' => 91,
			'member' => 237,
			'struct_type' => 150,
			'union_type' => 151,
			'sequence_type' => 168,
			'unsigned_long_int' => 111,
			'template_type_spec' => 153,
			'constr_type_spec' => 154,
			'simple_type_spec' => 169,
			'fixed_pt_type' => 170
		}
	},
	{#State 238
		DEFAULT => -63
	},
	{#State 239
		DEFAULT => -62
	},
	{#State 240
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 408,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'primary_expr' => 414,
			'and_expr' => 415,
			'scoped_name' => 406,
			'positive_int_const' => 407,
			'wide_string_literal' => 394,
			'boolean_literal' => 396,
			'mult_expr' => 417,
			'const_exp' => 397,
			'or_expr' => 398,
			'unary_expr' => 419,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 241
		ACTIONS => {
			'error' => 422,
			'IDENTIFIER' => 423
		}
	},
	{#State 242
		DEFAULT => -225
	},
	{#State 243
		ACTIONS => {
			'LONG' => 424
		},
		DEFAULT => -226
	},
	{#State 244
		DEFAULT => -213
	},
	{#State 245
		DEFAULT => -221
	},
	{#State 246
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 426,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'primary_expr' => 414,
			'and_expr' => 415,
			'scoped_name' => 406,
			'positive_int_const' => 425,
			'wide_string_literal' => 394,
			'boolean_literal' => 396,
			'mult_expr' => 417,
			'const_exp' => 397,
			'or_expr' => 398,
			'unary_expr' => 419,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 247
		DEFAULT => -120
	},
	{#State 248
		ACTIONS => {
			'error' => 427,
			"=" => 428
		}
	},
	{#State 249
		DEFAULT => -477
	},
	{#State 250
		ACTIONS => {
			"{" => -398,
			":" => 347,
			'SUPPORTS' => 345
		},
		DEFAULT => -466,
		GOTOS => {
			'supported_interface_spec' => 348,
			'value_inheritance_spec' => 429
		}
	},
	{#State 251
		DEFAULT => -86
	},
	{#State 252
		ACTIONS => {
			":" => 347,
			";" => -70,
			"{" => -398,
			'error' => -70,
			'SUPPORTS' => 345
		},
		DEFAULT => -73,
		GOTOS => {
			'supported_interface_spec' => 348,
			'value_inheritance_spec' => 430
		}
	},
	{#State 253
		ACTIONS => {
			"{" => -41
		},
		DEFAULT => -36
	},
	{#State 254
		ACTIONS => {
			"{" => -57,
			":" => 432
		},
		DEFAULT => -35,
		GOTOS => {
			'interface_inheritance_spec' => 431
		}
	},
	{#State 255
		ACTIONS => {
			"}" => 433
		}
	},
	{#State 256
		DEFAULT => -32
	},
	{#State 257
		DEFAULT => -42
	},
	{#State 258
		ACTIONS => {
			"}" => 434
		}
	},
	{#State 259
		ACTIONS => {
			"::" => 241,
			'PRIMARYKEY' => 435
		},
		DEFAULT => -440,
		GOTOS => {
			'primary_key_spec' => 436
		}
	},
	{#State 260
		DEFAULT => -432
	},
	{#State 261
		ACTIONS => {
			'PRIVATE' => 207,
			'ONEWAY' => 208,
			'FACTORY' => 220,
			'CONST' => 12,
			'EXCEPTION' => 50,
			"}" => -83,
			'ENUM' => 16,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231,
			'PUBLIC' => 215
		},
		DEFAULT => -303,
		GOTOS => {
			'init_header_param' => 206,
			'const_dcl' => 225,
			'op_mod' => 209,
			'value_elements' => 437,
			'except_dcl' => 218,
			'state_member' => 263,
			'attr_spec' => 210,
			'op_attribute' => 211,
			'state_mod' => 212,
			'value_element' => 261,
			'readonly_attr_spec' => 213,
			'type_id_dcl' => 221,
			'export' => 267,
			'init_header' => 222,
			'struct_type' => 26,
			'op_header' => 229,
			'exception_header' => 27,
			'union_type' => 28,
			'struct_header' => 9,
			'op_dcl' => 232,
			'enum_type' => 44,
			'init_dcl' => 262,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'type_dcl' => 233,
			'union_header' => 49
		}
	},
	{#State 262
		DEFAULT => -99
	},
	{#State 263
		DEFAULT => -98
	},
	{#State 264
		ACTIONS => {
			"}" => 438
		}
	},
	{#State 265
		DEFAULT => -80
	},
	{#State 266
		ACTIONS => {
			"}" => 439
		}
	},
	{#State 267
		DEFAULT => -97
	},
	{#State 268
		ACTIONS => {
			"}" => 440
		}
	},
	{#State 269
		DEFAULT => -468
	},
	{#State 270
		ACTIONS => {
			"}" => 441
		}
	},
	{#State 271
		ACTIONS => {
			"}" => 442
		}
	},
	{#State 272
		ACTIONS => {
			"}" => 443
		}
	},
	{#State 273
		DEFAULT => -292
	},
	{#State 274
		ACTIONS => {
			'SUPPORTS' => 345
		},
		DEFAULT => -398,
		GOTOS => {
			'supported_interface_spec' => 444
		}
	},
	{#State 275
		ACTIONS => {
			'error' => 446,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 445
		}
	},
	{#State 276
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 447
		}
	},
	{#State 277
		DEFAULT => -402
	},
	{#State 278
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 448
		}
	},
	{#State 279
		ACTIONS => {
			'PUBLISHES' => 289,
			'USES' => 281,
			'READONLY' => 230,
			'PROVIDES' => 288,
			'ATTRIBUTE' => 231,
			'EMITS' => 284,
			'CONSUMES' => 291
		},
		DEFAULT => -403,
		GOTOS => {
			'consumes_dcl' => 276,
			'emits_dcl' => 283,
			'attr_spec' => 210,
			'provides_dcl' => 280,
			'readonly_attr_spec' => 213,
			'component_exports' => 449,
			'attr_dcl' => 282,
			'publishes_dcl' => 278,
			'uses_dcl' => 290,
			'component_export' => 279
		}
	},
	{#State 280
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 450
		}
	},
	{#State 281
		ACTIONS => {
			'MULTIPLE' => 452
		},
		DEFAULT => -420,
		GOTOS => {
			'uses_mod' => 451
		}
	},
	{#State 282
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 453
		}
	},
	{#State 283
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 454
		}
	},
	{#State 284
		ACTIONS => {
			'error' => 456,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 455
		}
	},
	{#State 285
		ACTIONS => {
			"}" => 457
		}
	},
	{#State 286
		ACTIONS => {
			"}" => 458
		}
	},
	{#State 287
		DEFAULT => -391
	},
	{#State 288
		ACTIONS => {
			'error' => 461,
			'OBJECT' => 462,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 460,
			'interface_type' => 459
		}
	},
	{#State 289
		ACTIONS => {
			'error' => 464,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 463
		}
	},
	{#State 290
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 465
		}
	},
	{#State 291
		ACTIONS => {
			'error' => 467,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 466
		}
	},
	{#State 292
		ACTIONS => {
			'RAISES' => 350
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 468
		}
	},
	{#State 293
		ACTIONS => {
			'error' => 469,
			'IDENTIFIER' => 470
		}
	},
	{#State 294
		ACTIONS => {
			'ONEWAY' => 208,
			'FACTORY' => 298,
			'CONST' => 12,
			"}" => -444,
			'EXCEPTION' => 50,
			'ENUM' => 16,
			'FINDER' => 293,
			'NATIVE' => 53,
			'STRUCT' => 23,
			'TYPEID' => 56,
			'TYPEPREFIX' => 58,
			'TYPEDEF' => 59,
			'UNION' => 29,
			'READONLY' => 230,
			'ATTRIBUTE' => 231
		},
		DEFAULT => -303,
		GOTOS => {
			'const_dcl' => 225,
			'op_mod' => 209,
			'except_dcl' => 218,
			'attr_spec' => 210,
			'factory_header_param' => 292,
			'home_exports' => 471,
			'home_export' => 294,
			'op_attribute' => 211,
			'readonly_attr_spec' => 213,
			'finder_dcl' => 296,
			'type_id_dcl' => 221,
			'export' => 301,
			'struct_type' => 26,
			'finder_header' => 302,
			'exception_header' => 27,
			'union_type' => 28,
			'op_header' => 229,
			'struct_header' => 9,
			'factory_dcl' => 297,
			'enum_type' => 44,
			'finder_header_param' => 303,
			'op_dcl' => 232,
			'constr_forward_decl' => 46,
			'enum_header' => 47,
			'type_prefix_dcl' => 214,
			'attr_dcl' => 217,
			'union_header' => 49,
			'type_dcl' => 233,
			'factory_header' => 304
		}
	},
	{#State 295
		ACTIONS => {
			"}" => 472
		}
	},
	{#State 296
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 473
		}
	},
	{#State 297
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 474
		}
	},
	{#State 298
		ACTIONS => {
			'error' => 475,
			'IDENTIFIER' => 476
		}
	},
	{#State 299
		ACTIONS => {
			"}" => 477
		}
	},
	{#State 300
		DEFAULT => -441
	},
	{#State 301
		DEFAULT => -446
	},
	{#State 302
		ACTIONS => {
			'error' => 479,
			"(" => 478
		}
	},
	{#State 303
		ACTIONS => {
			'RAISES' => 350
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 480
		}
	},
	{#State 304
		ACTIONS => {
			'error' => 482,
			"(" => 481
		}
	},
	{#State 305
		ACTIONS => {
			"}" => 483
		}
	},
	{#State 306
		ACTIONS => {
			"}" => 484
		}
	},
	{#State 307
		DEFAULT => -26
	},
	{#State 308
		DEFAULT => -27
	},
	{#State 309
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 165,
			'SEQUENCE' => 142,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'WCHAR' => 82,
			'error' => 485,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'wide_string_type' => 148,
			'integer_type' => 167,
			'boolean_type' => 166,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 158,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'signed_short_int' => 91,
			'string_type' => 160,
			'sequence_type' => 168,
			'base_type_spec' => 161,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'unsigned_long_int' => 111,
			'template_type_spec' => 153,
			'unsigned_short_int' => 103,
			'simple_type_spec' => 486,
			'fixed_pt_type' => 170,
			'signed_longlong_int' => 86
		}
	},
	{#State 310
		DEFAULT => -278
	},
	{#State 311
		DEFAULT => -237
	},
	{#State 312
		DEFAULT => -236
	},
	{#State 313
		DEFAULT => -247
	},
	{#State 314
		DEFAULT => -246
	},
	{#State 315
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 488,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'primary_expr' => 414,
			'and_expr' => 415,
			'scoped_name' => 406,
			'positive_int_const' => 487,
			'wide_string_literal' => 394,
			'boolean_literal' => 396,
			'mult_expr' => 417,
			'const_exp' => 397,
			'or_expr' => 398,
			'unary_expr' => 419,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 316
		DEFAULT => -348
	},
	{#State 317
		ACTIONS => {
			";" => 489,
			"," => 490
		},
		DEFAULT => -269
	},
	{#State 318
		ACTIONS => {
			"}" => 491
		}
	},
	{#State 319
		ACTIONS => {
			"}" => 492
		}
	},
	{#State 320
		DEFAULT => -273
	},
	{#State 321
		ACTIONS => {
			'SHORT' => 101,
			'CHAR' => 87,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'error' => 497,
			'LONG' => 500,
			"::" => 90,
			'ENUM' => 16,
			'UNSIGNED' => 99
		},
		GOTOS => {
			'switch_type_spec' => 494,
			'unsigned_int' => 78,
			'signed_int' => 95,
			'integer_type' => 499,
			'boolean_type' => 498,
			'unsigned_longlong_int' => 83,
			'char_type' => 493,
			'enum_type' => 496,
			'unsigned_long_int' => 111,
			'enum_header' => 47,
			'scoped_name' => 495,
			'unsigned_short_int' => 103,
			'signed_long_int' => 98,
			'signed_short_int' => 91,
			'signed_longlong_int' => 86
		}
	},
	{#State 322
		DEFAULT => -245
	},
	{#State 323
		DEFAULT => -209
	},
	{#State 324
		DEFAULT => -208
	},
	{#State 325
		ACTIONS => {
			'SUPPORTS' => 345
		},
		DEFAULT => -398,
		GOTOS => {
			'supported_interface_spec' => 501
		}
	},
	{#State 326
		ACTIONS => {
			'error' => 503,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 502
		}
	},
	{#State 327
		DEFAULT => -359
	},
	{#State 328
		DEFAULT => -360
	},
	{#State 329
		DEFAULT => -355
	},
	{#State 330
		DEFAULT => -167
	},
	{#State 331
		DEFAULT => -364
	},
	{#State 332
		DEFAULT => -362
	},
	{#State 333
		DEFAULT => -363
	},
	{#State 334
		DEFAULT => -180
	},
	{#State 335
		DEFAULT => -206
	},
	{#State 336
		DEFAULT => -210
	},
	{#State 337
		ACTIONS => {
			"," => 504
		},
		DEFAULT => -203
	},
	{#State 338
		DEFAULT => -205
	},
	{#State 339
		ACTIONS => {
			"[" => 507
		},
		DEFAULT => -207,
		GOTOS => {
			'fixed_array_sizes' => 506,
			'fixed_array_size' => 505
		}
	},
	{#State 340
		ACTIONS => {
			"}" => 508
		}
	},
	{#State 341
		DEFAULT => -473
	},
	{#State 342
		ACTIONS => {
			"}" => 509
		}
	},
	{#State 343
		DEFAULT => -21
	},
	{#State 344
		DEFAULT => -9
	},
	{#State 345
		ACTIONS => {
			'error' => 512,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 511,
			'interface_name' => 513,
			'interface_names' => 510
		}
	},
	{#State 346
		DEFAULT => -471
	},
	{#State 347
		ACTIONS => {
			'TRUNCATABLE' => 515
		},
		DEFAULT => -93,
		GOTOS => {
			'inheritance_mod' => 514
		}
	},
	{#State 348
		DEFAULT => -91
	},
	{#State 349
		DEFAULT => -77
	},
	{#State 350
		ACTIONS => {
			'error' => 517,
			"(" => 516
		}
	},
	{#State 351
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 518
		}
	},
	{#State 352
		DEFAULT => -343
	},
	{#State 353
		DEFAULT => -305
	},
	{#State 354
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -344
	},
	{#State 355
		DEFAULT => -342
	},
	{#State 356
		DEFAULT => -341
	},
	{#State 357
		DEFAULT => -306
	},
	{#State 358
		ACTIONS => {
			'error' => 519,
			'IDENTIFIER' => 520
		}
	},
	{#State 359
		DEFAULT => -307
	},
	{#State 360
		DEFAULT => -308
	},
	{#State 361
		ACTIONS => {
			'error' => 522,
			'IDENTIFIER' => 339
		},
		GOTOS => {
			'declarators' => 521,
			'declarator' => 337,
			'simple_declarator' => 338,
			'array_declarator' => 336,
			'complex_declarator' => 335
		}
	},
	{#State 362
		ACTIONS => {
			";" => 523
		}
	},
	{#State 363
		DEFAULT => -54
	},
	{#State 364
		DEFAULT => -51
	},
	{#State 365
		DEFAULT => -50
	},
	{#State 366
		DEFAULT => -111
	},
	{#State 367
		DEFAULT => -110
	},
	{#State 368
		DEFAULT => -53
	},
	{#State 369
		ACTIONS => {
			'error' => 529,
			")" => 525,
			'IN' => 524
		},
		GOTOS => {
			'init_param_decls' => 527,
			'init_param_attribute' => 526,
			'init_param_decl' => 528
		}
	},
	{#State 370
		DEFAULT => -109
	},
	{#State 371
		DEFAULT => -76
	},
	{#State 372
		DEFAULT => -49
	},
	{#State 373
		DEFAULT => -75
	},
	{#State 374
		DEFAULT => -44
	},
	{#State 375
		ACTIONS => {
			'CHAR' => -322,
			'OBJECT' => -322,
			'FIXED' => -322,
			'VALUEBASE' => -322,
			'VOID' => -322,
			'IN' => 530,
			'SEQUENCE' => -322,
			'STRUCT' => -322,
			'DOUBLE' => -322,
			'LONG' => -322,
			'STRING' => -322,
			"::" => -322,
			'WSTRING' => -322,
			"..." => 535,
			'UNSIGNED' => -322,
			'SHORT' => -322,
			")" => 533,
			'BOOLEAN' => -322,
			'OUT' => 534,
			'IDENTIFIER' => -322,
			'UNION' => -322,
			'WCHAR' => -322,
			'error' => 536,
			'INOUT' => 531,
			'FLOAT' => -322,
			'OCTET' => -322,
			'ENUM' => -322,
			'ANY' => -322
		},
		GOTOS => {
			'param_dcl' => 538,
			'param_dcls' => 537,
			'param_attribute' => 532
		}
	},
	{#State 376
		DEFAULT => -299
	},
	{#State 377
		ACTIONS => {
			'RAISES' => 350
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 539
		}
	},
	{#State 378
		DEFAULT => -368
	},
	{#State 379
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 384,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'error' => 541,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'wide_string_type' => 352,
			'integer_type' => 167,
			'boolean_type' => 166,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 354,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'signed_short_int' => 91,
			'string_type' => 355,
			'op_param_type_spec' => 381,
			'struct_type' => 150,
			'union_type' => 151,
			'struct_header' => 9,
			'sequence_type' => 385,
			'base_type_spec' => 356,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'unsigned_long_int' => 111,
			'param_type_spec' => 540,
			'enum_header' => 47,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'constr_type_spec' => 382,
			'fixed_pt_type' => 386,
			'signed_longlong_int' => 86
		}
	},
	{#State 380
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 180
		},
		GOTOS => {
			'attr_declarator' => 543,
			'simple_declarator' => 542
		}
	},
	{#State 381
		DEFAULT => -336
	},
	{#State 382
		DEFAULT => -340
	},
	{#State 383
		DEFAULT => -374
	},
	{#State 384
		DEFAULT => -337
	},
	{#State 385
		DEFAULT => -338
	},
	{#State 386
		DEFAULT => -339
	},
	{#State 387
		DEFAULT => -52
	},
	{#State 388
		DEFAULT => -48
	},
	{#State 389
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 544
		}
	},
	{#State 390
		DEFAULT => -234
	},
	{#State 391
		DEFAULT => -235
	},
	{#State 392
		DEFAULT => -239
	},
	{#State 393
		DEFAULT => -162
	},
	{#State 394
		DEFAULT => -160
	},
	{#State 395
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 546,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 417,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'const_exp' => 545,
			'and_expr' => 415,
			'or_expr' => 398,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'wide_string_literal' => 394,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 396
		DEFAULT => -165
	},
	{#State 397
		DEFAULT => -172
	},
	{#State 398
		ACTIONS => {
			"|" => 547
		},
		DEFAULT => -132
	},
	{#State 399
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 399
		},
		DEFAULT => -168,
		GOTOS => {
			'wide_string_literal' => 548
		}
	},
	{#State 400
		DEFAULT => -170
	},
	{#State 401
		DEFAULT => -159
	},
	{#State 402
		DEFAULT => -164
	},
	{#State 403
		DEFAULT => -163
	},
	{#State 404
		DEFAULT => -151
	},
	{#State 405
		DEFAULT => -161
	},
	{#State 406
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -154
	},
	{#State 407
		ACTIONS => {
			">" => 549
		}
	},
	{#State 408
		ACTIONS => {
			">" => 550
		}
	},
	{#State 409
		ACTIONS => {
			"^" => 551
		},
		DEFAULT => -133
	},
	{#State 410
		ACTIONS => {
			"<<" => 552,
			">>" => 553
		},
		DEFAULT => -137
	},
	{#State 411
		DEFAULT => -171
	},
	{#State 412
		DEFAULT => -155
	},
	{#State 413
		ACTIONS => {
			"+" => 555,
			"-" => 554
		},
		DEFAULT => -139
	},
	{#State 414
		DEFAULT => -150
	},
	{#State 415
		ACTIONS => {
			"&" => 556
		},
		DEFAULT => -135
	},
	{#State 416
		DEFAULT => -158
	},
	{#State 417
		ACTIONS => {
			"%" => 557,
			"*" => 558,
			"/" => 559
		},
		DEFAULT => -142
	},
	{#State 418
		DEFAULT => -152
	},
	{#State 419
		DEFAULT => -145
	},
	{#State 420
		DEFAULT => -153
	},
	{#State 421
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			"::" => 90,
			'STRING_LITERAL' => 189,
			'FALSE' => 411,
			'CHARACTER_LITERAL' => 405,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			'TRUE' => 400,
			"(" => 395
		},
		GOTOS => {
			'scoped_name' => 406,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 560,
			'literal' => 412,
			'wide_string_literal' => 394
		}
	},
	{#State 422
		DEFAULT => -65
	},
	{#State 423
		DEFAULT => -64
	},
	{#State 424
		DEFAULT => -227
	},
	{#State 425
		ACTIONS => {
			">" => 561
		}
	},
	{#State 426
		ACTIONS => {
			">" => 562
		}
	},
	{#State 427
		DEFAULT => -119
	},
	{#State 428
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 564,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 417,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'const_exp' => 563,
			'and_expr' => 415,
			'or_expr' => 398,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'wide_string_literal' => 394,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 429
		DEFAULT => -476
	},
	{#State 430
		DEFAULT => -85
	},
	{#State 431
		DEFAULT => -40
	},
	{#State 432
		ACTIONS => {
			'error' => 566,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 511,
			'interface_name' => 513,
			'interface_names' => 565
		}
	},
	{#State 433
		DEFAULT => -34
	},
	{#State 434
		DEFAULT => -33
	},
	{#State 435
		ACTIONS => {
			'error' => 568,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 567
		}
	},
	{#State 436
		DEFAULT => -431
	},
	{#State 437
		DEFAULT => -84
	},
	{#State 438
		DEFAULT => -82
	},
	{#State 439
		DEFAULT => -81
	},
	{#State 440
		DEFAULT => -470
	},
	{#State 441
		DEFAULT => -469
	},
	{#State 442
		DEFAULT => -293
	},
	{#State 443
		DEFAULT => -294
	},
	{#State 444
		DEFAULT => -433
	},
	{#State 445
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -435
	},
	{#State 446
		DEFAULT => -436
	},
	{#State 447
		DEFAULT => -409
	},
	{#State 448
		DEFAULT => -408
	},
	{#State 449
		DEFAULT => -404
	},
	{#State 450
		DEFAULT => -405
	},
	{#State 451
		ACTIONS => {
			'error' => 570,
			'OBJECT' => 462,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 460,
			'interface_type' => 569
		}
	},
	{#State 452
		DEFAULT => -419
	},
	{#State 453
		DEFAULT => -410
	},
	{#State 454
		DEFAULT => -407
	},
	{#State 455
		ACTIONS => {
			'error' => 571,
			'IDENTIFIER' => 572,
			"::" => 241
		}
	},
	{#State 456
		DEFAULT => -423
	},
	{#State 457
		DEFAULT => -392
	},
	{#State 458
		DEFAULT => -393
	},
	{#State 459
		ACTIONS => {
			'error' => 573,
			'IDENTIFIER' => 574
		}
	},
	{#State 460
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -414
	},
	{#State 461
		DEFAULT => -413
	},
	{#State 462
		DEFAULT => -415
	},
	{#State 463
		ACTIONS => {
			'error' => 575,
			'IDENTIFIER' => 576,
			"::" => 241
		}
	},
	{#State 464
		DEFAULT => -426
	},
	{#State 465
		DEFAULT => -406
	},
	{#State 466
		ACTIONS => {
			'error' => 577,
			'IDENTIFIER' => 578,
			"::" => 241
		}
	},
	{#State 467
		DEFAULT => -429
	},
	{#State 468
		DEFAULT => -449
	},
	{#State 469
		DEFAULT => -462
	},
	{#State 470
		DEFAULT => -461
	},
	{#State 471
		DEFAULT => -445
	},
	{#State 472
		DEFAULT => -442
	},
	{#State 473
		DEFAULT => -448
	},
	{#State 474
		DEFAULT => -447
	},
	{#State 475
		DEFAULT => -455
	},
	{#State 476
		DEFAULT => -454
	},
	{#State 477
		DEFAULT => -443
	},
	{#State 478
		ACTIONS => {
			'error' => 581,
			")" => 579,
			'IN' => 524
		},
		GOTOS => {
			'init_param_decls' => 580,
			'init_param_attribute' => 526,
			'init_param_decl' => 528
		}
	},
	{#State 479
		DEFAULT => -460
	},
	{#State 480
		DEFAULT => -456
	},
	{#State 481
		ACTIONS => {
			'error' => 584,
			")" => 582,
			'IN' => 524
		},
		GOTOS => {
			'init_param_decls' => 583,
			'init_param_attribute' => 526,
			'init_param_decl' => 528
		}
	},
	{#State 482
		DEFAULT => -453
	},
	{#State 483
		DEFAULT => -24
	},
	{#State 484
		DEFAULT => -25
	},
	{#State 485
		ACTIONS => {
			">" => 585
		}
	},
	{#State 486
		ACTIONS => {
			">" => 587,
			"," => 586
		}
	},
	{#State 487
		ACTIONS => {
			"," => 588
		}
	},
	{#State 488
		ACTIONS => {
			">" => 589
		}
	},
	{#State 489
		DEFAULT => -272
	},
	{#State 490
		ACTIONS => {
			'IDENTIFIER' => 320
		},
		DEFAULT => -271,
		GOTOS => {
			'enumerators' => 590,
			'enumerator' => 317
		}
	},
	{#State 491
		DEFAULT => -264
	},
	{#State 492
		DEFAULT => -265
	},
	{#State 493
		DEFAULT => -249
	},
	{#State 494
		ACTIONS => {
			")" => 591
		}
	},
	{#State 495
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -252
	},
	{#State 496
		DEFAULT => -251
	},
	{#State 497
		ACTIONS => {
			")" => 592
		}
	},
	{#State 498
		DEFAULT => -250
	},
	{#State 499
		DEFAULT => -248
	},
	{#State 500
		ACTIONS => {
			'LONG' => 245
		},
		DEFAULT => -220
	},
	{#State 501
		DEFAULT => -394
	},
	{#State 502
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -399
	},
	{#State 503
		DEFAULT => -400
	},
	{#State 504
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 339
		},
		GOTOS => {
			'declarators' => 593,
			'declarator' => 337,
			'simple_declarator' => 338,
			'array_declarator' => 336,
			'complex_declarator' => 335
		}
	},
	{#State 505
		ACTIONS => {
			"[" => 507
		},
		DEFAULT => -286,
		GOTOS => {
			'fixed_array_sizes' => 594,
			'fixed_array_size' => 505
		}
	},
	{#State 506
		DEFAULT => -285
	},
	{#State 507
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 596,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'primary_expr' => 414,
			'and_expr' => 415,
			'scoped_name' => 406,
			'positive_int_const' => 595,
			'wide_string_literal' => 394,
			'boolean_literal' => 396,
			'mult_expr' => 417,
			'const_exp' => 397,
			'or_expr' => 398,
			'unary_expr' => 419,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 508
		DEFAULT => -475
	},
	{#State 509
		DEFAULT => -474
	},
	{#State 510
		DEFAULT => -396
	},
	{#State 511
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -60
	},
	{#State 512
		DEFAULT => -397
	},
	{#State 513
		ACTIONS => {
			"," => 597
		},
		DEFAULT => -58
	},
	{#State 514
		ACTIONS => {
			'error' => 600,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 599,
			'value_name' => 598,
			'value_names' => 601
		}
	},
	{#State 515
		DEFAULT => -92
	},
	{#State 516
		ACTIONS => {
			'error' => 604,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 603,
			'exception_names' => 602,
			'exception_name' => 605
		}
	},
	{#State 517
		DEFAULT => -325
	},
	{#State 518
		DEFAULT => -105
	},
	{#State 519
		DEFAULT => -301
	},
	{#State 520
		DEFAULT => -300
	},
	{#State 521
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 606
		}
	},
	{#State 522
		ACTIONS => {
			";" => 607,
			"," => 324
		}
	},
	{#State 523
		DEFAULT => -102
	},
	{#State 524
		DEFAULT => -116
	},
	{#State 525
		DEFAULT => -106
	},
	{#State 526
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 384,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'error' => 609,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'wide_string_type' => 352,
			'integer_type' => 167,
			'boolean_type' => 166,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 354,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'signed_short_int' => 91,
			'string_type' => 355,
			'op_param_type_spec' => 381,
			'struct_type' => 150,
			'union_type' => 151,
			'struct_header' => 9,
			'sequence_type' => 385,
			'base_type_spec' => 356,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'unsigned_long_int' => 111,
			'param_type_spec' => 608,
			'enum_header' => 47,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'constr_type_spec' => 382,
			'fixed_pt_type' => 386,
			'signed_longlong_int' => 86
		}
	},
	{#State 527
		ACTIONS => {
			")" => 610
		}
	},
	{#State 528
		ACTIONS => {
			"," => 611
		},
		DEFAULT => -112
	},
	{#State 529
		ACTIONS => {
			")" => 612
		}
	},
	{#State 530
		DEFAULT => -319
	},
	{#State 531
		DEFAULT => -321
	},
	{#State 532
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 384,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'wide_string_type' => 352,
			'integer_type' => 167,
			'boolean_type' => 166,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 354,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'signed_short_int' => 91,
			'string_type' => 355,
			'op_param_type_spec' => 381,
			'struct_type' => 150,
			'union_type' => 151,
			'struct_header' => 9,
			'sequence_type' => 385,
			'base_type_spec' => 356,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'unsigned_long_int' => 111,
			'param_type_spec' => 613,
			'enum_header' => 47,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'constr_type_spec' => 382,
			'fixed_pt_type' => 386,
			'signed_longlong_int' => 86
		}
	},
	{#State 533
		DEFAULT => -312
	},
	{#State 534
		DEFAULT => -320
	},
	{#State 535
		ACTIONS => {
			")" => 614
		}
	},
	{#State 536
		ACTIONS => {
			")" => 615
		}
	},
	{#State 537
		ACTIONS => {
			")" => 617,
			"," => 616
		}
	},
	{#State 538
		ACTIONS => {
			";" => 618
		},
		DEFAULT => -315
	},
	{#State 539
		ACTIONS => {
			'CONTEXT' => 619
		},
		DEFAULT => -333,
		GOTOS => {
			'context_expr' => 620
		}
	},
	{#State 540
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 180
		},
		GOTOS => {
			'simple_declarator' => 622,
			'readonly_attr_declarator' => 621
		}
	},
	{#State 541
		DEFAULT => -367
	},
	{#State 542
		ACTIONS => {
			'GETRAISES' => 627,
			'SETRAISES' => 626,
			"," => 624
		},
		DEFAULT => -380,
		GOTOS => {
			'set_except_expr' => 628,
			'get_except_expr' => 623,
			'attr_raises_expr' => 625
		}
	},
	{#State 543
		DEFAULT => -373
	},
	{#State 544
		DEFAULT => -240
	},
	{#State 545
		ACTIONS => {
			")" => 629
		}
	},
	{#State 546
		ACTIONS => {
			")" => 630
		}
	},
	{#State 547
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 417,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'and_expr' => 415,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'xor_expr' => 631,
			'shift_expr' => 410,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 548
		DEFAULT => -169
	},
	{#State 549
		DEFAULT => -282
	},
	{#State 550
		DEFAULT => -284
	},
	{#State 551
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 417,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'and_expr' => 632,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'shift_expr' => 410,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 552
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 417,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 633
		}
	},
	{#State 553
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 417,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 634
		}
	},
	{#State 554
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 635,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421
		}
	},
	{#State 555
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 636,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421
		}
	},
	{#State 556
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 417,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'shift_expr' => 637,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 557
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'unary_expr' => 638,
			'scoped_name' => 406,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421
		}
	},
	{#State 558
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'unary_expr' => 639,
			'scoped_name' => 406,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421
		}
	},
	{#State 559
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'CHARACTER_LITERAL' => 405,
			"+" => 418,
			'FIXED_PT_LITERAL' => 403,
			'WIDE_CHARACTER_LITERAL' => 393,
			"-" => 404,
			"::" => 90,
			'FALSE' => 411,
			'WIDE_STRING_LITERAL' => 399,
			'INTEGER_LITERAL' => 416,
			"~" => 420,
			"(" => 395,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'unary_expr' => 640,
			'scoped_name' => 406,
			'wide_string_literal' => 394,
			'literal' => 412,
			'unary_operator' => 421
		}
	},
	{#State 560
		DEFAULT => -149
	},
	{#State 561
		DEFAULT => -279
	},
	{#State 562
		DEFAULT => -281
	},
	{#State 563
		DEFAULT => -117
	},
	{#State 564
		DEFAULT => -118
	},
	{#State 565
		DEFAULT => -55
	},
	{#State 566
		DEFAULT => -56
	},
	{#State 567
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -438
	},
	{#State 568
		DEFAULT => -439
	},
	{#State 569
		ACTIONS => {
			'error' => 641,
			'IDENTIFIER' => 642
		}
	},
	{#State 570
		DEFAULT => -418
	},
	{#State 571
		DEFAULT => -422
	},
	{#State 572
		DEFAULT => -421
	},
	{#State 573
		DEFAULT => -412
	},
	{#State 574
		DEFAULT => -411
	},
	{#State 575
		DEFAULT => -425
	},
	{#State 576
		DEFAULT => -424
	},
	{#State 577
		DEFAULT => -428
	},
	{#State 578
		DEFAULT => -427
	},
	{#State 579
		DEFAULT => -457
	},
	{#State 580
		ACTIONS => {
			")" => 643
		}
	},
	{#State 581
		ACTIONS => {
			")" => 644
		}
	},
	{#State 582
		DEFAULT => -450
	},
	{#State 583
		ACTIONS => {
			")" => 645
		}
	},
	{#State 584
		ACTIONS => {
			")" => 646
		}
	},
	{#State 585
		DEFAULT => -277
	},
	{#State 586
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 648,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'primary_expr' => 414,
			'and_expr' => 415,
			'scoped_name' => 406,
			'positive_int_const' => 647,
			'wide_string_literal' => 394,
			'boolean_literal' => 396,
			'mult_expr' => 417,
			'const_exp' => 397,
			'or_expr' => 398,
			'unary_expr' => 419,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 587
		DEFAULT => -276
	},
	{#State 588
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 650,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'string_literal' => 401,
			'primary_expr' => 414,
			'and_expr' => 415,
			'scoped_name' => 406,
			'positive_int_const' => 649,
			'wide_string_literal' => 394,
			'boolean_literal' => 396,
			'mult_expr' => 417,
			'const_exp' => 397,
			'or_expr' => 398,
			'unary_expr' => 419,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 589
		DEFAULT => -347
	},
	{#State 590
		DEFAULT => -270
	},
	{#State 591
		ACTIONS => {
			'error' => 652,
			"{" => 651
		}
	},
	{#State 592
		DEFAULT => -244
	},
	{#State 593
		DEFAULT => -204
	},
	{#State 594
		DEFAULT => -287
	},
	{#State 595
		ACTIONS => {
			"]" => 653
		}
	},
	{#State 596
		ACTIONS => {
			"]" => 654
		}
	},
	{#State 597
		ACTIONS => {
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 511,
			'interface_name' => 513,
			'interface_names' => 655
		}
	},
	{#State 598
		ACTIONS => {
			"," => 656
		},
		DEFAULT => -94
	},
	{#State 599
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -96
	},
	{#State 600
		DEFAULT => -90
	},
	{#State 601
		ACTIONS => {
			'SUPPORTS' => 345
		},
		DEFAULT => -398,
		GOTOS => {
			'supported_interface_spec' => 657
		}
	},
	{#State 602
		ACTIONS => {
			")" => 658
		}
	},
	{#State 603
		ACTIONS => {
			"::" => 241
		},
		DEFAULT => -329
	},
	{#State 604
		ACTIONS => {
			")" => 659
		}
	},
	{#State 605
		ACTIONS => {
			"," => 660
		},
		DEFAULT => -327
	},
	{#State 606
		DEFAULT => -100
	},
	{#State 607
		ACTIONS => {
			";" => -209,
			"," => -209,
			'error' => -209
		},
		DEFAULT => -101
	},
	{#State 608
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 180
		},
		GOTOS => {
			'simple_declarator' => 661
		}
	},
	{#State 609
		DEFAULT => -115
	},
	{#State 610
		DEFAULT => -107
	},
	{#State 611
		ACTIONS => {
			'IN' => 524
		},
		GOTOS => {
			'init_param_decls' => 662,
			'init_param_attribute' => 526,
			'init_param_decl' => 528
		}
	},
	{#State 612
		DEFAULT => -108
	},
	{#State 613
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 180
		},
		GOTOS => {
			'simple_declarator' => 663
		}
	},
	{#State 614
		DEFAULT => -313
	},
	{#State 615
		DEFAULT => -314
	},
	{#State 616
		ACTIONS => {
			'IN' => 530,
			"..." => 665,
			")" => 664,
			'OUT' => 534,
			'INOUT' => 531
		},
		DEFAULT => -322,
		GOTOS => {
			'param_dcl' => 666,
			'param_attribute' => 532
		}
	},
	{#State 617
		DEFAULT => -309
	},
	{#State 618
		DEFAULT => -317
	},
	{#State 619
		ACTIONS => {
			'error' => 668,
			"(" => 667
		}
	},
	{#State 620
		DEFAULT => -298
	},
	{#State 621
		DEFAULT => -366
	},
	{#State 622
		ACTIONS => {
			'RAISES' => 350,
			"," => 669
		},
		DEFAULT => -326,
		GOTOS => {
			'raises_expr' => 670
		}
	},
	{#State 623
		ACTIONS => {
			'SETRAISES' => 626
		},
		DEFAULT => -378,
		GOTOS => {
			'set_except_expr' => 671
		}
	},
	{#State 624
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 180
		},
		GOTOS => {
			'simple_declarators' => 673,
			'simple_declarator' => 672
		}
	},
	{#State 625
		DEFAULT => -375
	},
	{#State 626
		ACTIONS => {
			'error' => 675,
			"(" => 674
		},
		GOTOS => {
			'exception_list' => 676
		}
	},
	{#State 627
		ACTIONS => {
			'error' => 677,
			"(" => 674
		},
		GOTOS => {
			'exception_list' => 678
		}
	},
	{#State 628
		DEFAULT => -379
	},
	{#State 629
		DEFAULT => -156
	},
	{#State 630
		DEFAULT => -157
	},
	{#State 631
		ACTIONS => {
			"^" => 551
		},
		DEFAULT => -134
	},
	{#State 632
		ACTIONS => {
			"&" => 556
		},
		DEFAULT => -136
	},
	{#State 633
		ACTIONS => {
			"+" => 555,
			"-" => 554
		},
		DEFAULT => -141
	},
	{#State 634
		ACTIONS => {
			"+" => 555,
			"-" => 554
		},
		DEFAULT => -140
	},
	{#State 635
		ACTIONS => {
			"%" => 557,
			"*" => 558,
			"/" => 559
		},
		DEFAULT => -144
	},
	{#State 636
		ACTIONS => {
			"%" => 557,
			"*" => 558,
			"/" => 559
		},
		DEFAULT => -143
	},
	{#State 637
		ACTIONS => {
			"<<" => 552,
			">>" => 553
		},
		DEFAULT => -138
	},
	{#State 638
		DEFAULT => -148
	},
	{#State 639
		DEFAULT => -146
	},
	{#State 640
		DEFAULT => -147
	},
	{#State 641
		DEFAULT => -417
	},
	{#State 642
		DEFAULT => -416
	},
	{#State 643
		DEFAULT => -458
	},
	{#State 644
		DEFAULT => -459
	},
	{#State 645
		DEFAULT => -451
	},
	{#State 646
		DEFAULT => -452
	},
	{#State 647
		ACTIONS => {
			">" => 679
		}
	},
	{#State 648
		ACTIONS => {
			">" => 680
		}
	},
	{#State 649
		ACTIONS => {
			">" => 681
		}
	},
	{#State 650
		ACTIONS => {
			">" => 682
		}
	},
	{#State 651
		ACTIONS => {
			'error' => 688,
			'CASE' => 686,
			'DEFAULT' => 687
		},
		GOTOS => {
			'case_labels' => 684,
			'switch_body' => 689,
			'case' => 683,
			'case_label' => 685
		}
	},
	{#State 652
		DEFAULT => -243
	},
	{#State 653
		DEFAULT => -288
	},
	{#State 654
		DEFAULT => -289
	},
	{#State 655
		DEFAULT => -59
	},
	{#State 656
		ACTIONS => {
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 599,
			'value_name' => 598,
			'value_names' => 690
		}
	},
	{#State 657
		DEFAULT => -89
	},
	{#State 658
		DEFAULT => -323
	},
	{#State 659
		DEFAULT => -324
	},
	{#State 660
		ACTIONS => {
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 603,
			'exception_names' => 691,
			'exception_name' => 605
		}
	},
	{#State 661
		DEFAULT => -114
	},
	{#State 662
		DEFAULT => -113
	},
	{#State 663
		DEFAULT => -318
	},
	{#State 664
		DEFAULT => -311
	},
	{#State 665
		ACTIONS => {
			")" => 692
		}
	},
	{#State 666
		DEFAULT => -316
	},
	{#State 667
		ACTIONS => {
			'error' => 695,
			'STRING_LITERAL' => 189
		},
		GOTOS => {
			'string_literal' => 693,
			'string_literals' => 694
		}
	},
	{#State 668
		DEFAULT => -332
	},
	{#State 669
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 180
		},
		GOTOS => {
			'simple_declarators' => 696,
			'simple_declarator' => 672
		}
	},
	{#State 670
		DEFAULT => -369
	},
	{#State 671
		DEFAULT => -377
	},
	{#State 672
		ACTIONS => {
			"," => 697
		},
		DEFAULT => -371
	},
	{#State 673
		DEFAULT => -376
	},
	{#State 674
		ACTIONS => {
			'error' => 699,
			'IDENTIFIER' => 110,
			"::" => 90
		},
		GOTOS => {
			'scoped_name' => 603,
			'exception_names' => 698,
			'exception_name' => 605
		}
	},
	{#State 675
		DEFAULT => -384
	},
	{#State 676
		DEFAULT => -383
	},
	{#State 677
		DEFAULT => -382
	},
	{#State 678
		DEFAULT => -381
	},
	{#State 679
		DEFAULT => -274
	},
	{#State 680
		DEFAULT => -275
	},
	{#State 681
		DEFAULT => -345
	},
	{#State 682
		DEFAULT => -346
	},
	{#State 683
		ACTIONS => {
			'CASE' => 686,
			'DEFAULT' => 687
		},
		DEFAULT => -253,
		GOTOS => {
			'case_labels' => 684,
			'switch_body' => 700,
			'case' => 683,
			'case_label' => 685
		}
	},
	{#State 684
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 164,
			'FIXED' => 155,
			'VALUEBASE' => 147,
			'VOID' => 165,
			'SEQUENCE' => 142,
			'STRUCT' => 149,
			'DOUBLE' => 106,
			'LONG' => 107,
			'STRING' => 108,
			"::" => 90,
			'WSTRING' => 92,
			'UNSIGNED' => 99,
			'SHORT' => 101,
			'BOOLEAN' => 93,
			'IDENTIFIER' => 110,
			'UNION' => 152,
			'WCHAR' => 82,
			'FLOAT' => 85,
			'OCTET' => 84,
			'ENUM' => 16,
			'ANY' => 163
		},
		GOTOS => {
			'unsigned_int' => 78,
			'floating_pt_type' => 141,
			'signed_int' => 95,
			'value_base_type' => 156,
			'char_type' => 143,
			'object_type' => 157,
			'scoped_name' => 158,
			'octet_type' => 144,
			'wide_char_type' => 159,
			'signed_long_int' => 98,
			'type_spec' => 701,
			'string_type' => 160,
			'struct_header' => 9,
			'element_spec' => 702,
			'base_type_spec' => 161,
			'unsigned_longlong_int' => 83,
			'any_type' => 146,
			'enum_type' => 162,
			'enum_header' => 47,
			'unsigned_short_int' => 103,
			'union_header' => 49,
			'signed_longlong_int' => 86,
			'wide_string_type' => 148,
			'boolean_type' => 166,
			'integer_type' => 167,
			'signed_short_int' => 91,
			'struct_type' => 150,
			'union_type' => 151,
			'sequence_type' => 168,
			'unsigned_long_int' => 111,
			'template_type_spec' => 153,
			'constr_type_spec' => 154,
			'simple_type_spec' => 169,
			'fixed_pt_type' => 170
		}
	},
	{#State 685
		ACTIONS => {
			'CASE' => 686,
			'DEFAULT' => 687
		},
		DEFAULT => -256,
		GOTOS => {
			'case_labels' => 703,
			'case_label' => 685
		}
	},
	{#State 686
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 402,
			'CHARACTER_LITERAL' => 405,
			'WIDE_CHARACTER_LITERAL' => 393,
			"::" => 90,
			'INTEGER_LITERAL' => 416,
			"(" => 395,
			'IDENTIFIER' => 110,
			'STRING_LITERAL' => 189,
			'FIXED_PT_LITERAL' => 403,
			"+" => 418,
			'error' => 705,
			"-" => 404,
			'WIDE_STRING_LITERAL' => 399,
			'FALSE' => 411,
			"~" => 420,
			'TRUE' => 400
		},
		GOTOS => {
			'mult_expr' => 417,
			'string_literal' => 401,
			'boolean_literal' => 396,
			'primary_expr' => 414,
			'const_exp' => 704,
			'and_expr' => 415,
			'or_expr' => 398,
			'unary_expr' => 419,
			'scoped_name' => 406,
			'xor_expr' => 409,
			'shift_expr' => 410,
			'literal' => 412,
			'wide_string_literal' => 394,
			'unary_operator' => 421,
			'add_expr' => 413
		}
	},
	{#State 687
		ACTIONS => {
			'error' => 706,
			":" => 707
		}
	},
	{#State 688
		ACTIONS => {
			"}" => 708
		}
	},
	{#State 689
		ACTIONS => {
			"}" => 709
		}
	},
	{#State 690
		DEFAULT => -95
	},
	{#State 691
		DEFAULT => -328
	},
	{#State 692
		DEFAULT => -310
	},
	{#State 693
		ACTIONS => {
			"," => 710
		},
		DEFAULT => -334
	},
	{#State 694
		ACTIONS => {
			")" => 711
		}
	},
	{#State 695
		ACTIONS => {
			")" => 712
		}
	},
	{#State 696
		DEFAULT => -370
	},
	{#State 697
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 180
		},
		GOTOS => {
			'simple_declarators' => 713,
			'simple_declarator' => 672
		}
	},
	{#State 698
		ACTIONS => {
			")" => 714
		}
	},
	{#State 699
		ACTIONS => {
			")" => 715
		}
	},
	{#State 700
		DEFAULT => -254
	},
	{#State 701
		ACTIONS => {
			'error' => 178,
			'IDENTIFIER' => 339
		},
		GOTOS => {
			'declarator' => 716,
			'simple_declarator' => 338,
			'array_declarator' => 336,
			'complex_declarator' => 335
		}
	},
	{#State 702
		ACTIONS => {
			'error' => 71,
			";" => 70
		},
		GOTOS => {
			'check_semicolon' => 717
		}
	},
	{#State 703
		DEFAULT => -257
	},
	{#State 704
		ACTIONS => {
			'error' => 718,
			":" => 719
		}
	},
	{#State 705
		DEFAULT => -260
	},
	{#State 706
		DEFAULT => -262
	},
	{#State 707
		DEFAULT => -261
	},
	{#State 708
		DEFAULT => -242
	},
	{#State 709
		DEFAULT => -241
	},
	{#State 710
		ACTIONS => {
			'STRING_LITERAL' => 189
		},
		GOTOS => {
			'string_literal' => 693,
			'string_literals' => 720
		}
	},
	{#State 711
		DEFAULT => -330
	},
	{#State 712
		DEFAULT => -331
	},
	{#State 713
		DEFAULT => -372
	},
	{#State 714
		DEFAULT => -385
	},
	{#State 715
		DEFAULT => -386
	},
	{#State 716
		DEFAULT => -263
	},
	{#State 717
		DEFAULT => -255
	},
	{#State 718
		DEFAULT => -259
	},
	{#State 719
		DEFAULT => -258
	},
	{#State 720
		DEFAULT => -335
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
#line 86 "parser30.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 2,
sub
#line 92 "parser30.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_import'		=>	$_[1],
					'list_decl'			=>	$_[2],
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
		 'definition', 3,
sub
#line 163 "parser30.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 22
		 'check_semicolon', 1, undef
	],
	[#Rule 23
		 'check_semicolon', 1,
sub
#line 177 "parser30.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 24
		 'module', 4,
sub
#line 186 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 25
		 'module', 4,
sub
#line 193 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 26
		 'module', 3,
sub
#line 199 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 27
		 'module', 3,
sub
#line 205 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'module_header', 2,
sub
#line 214 "parser30.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 29
		 'module_header', 2,
sub
#line 220 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 30
		 'interface', 1, undef
	],
	[#Rule 31
		 'interface', 1, undef
	],
	[#Rule 32
		 'interface_dcl', 3,
sub
#line 237 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 33
		 'interface_dcl', 4,
sub
#line 245 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 34
		 'interface_dcl', 4,
sub
#line 253 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 35
		 'forward_dcl', 3,
sub
#line 264 "parser30.yp"
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
	[#Rule 36
		 'forward_dcl', 3,
sub
#line 280 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 37
		 'interface_mod', 1, undef
	],
	[#Rule 38
		 'interface_mod', 1, undef
	],
	[#Rule 39
		 'interface_mod', 0, undef
	],
	[#Rule 40
		 'interface_header', 4,
sub
#line 298 "parser30.yp"
{
			if (defined $_[1] and $_[1] eq 'abstract') {
				new AbstractInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$_[4]
				);
			} elsif (defined $_[1] and $_[1] eq 'local') {
				new LocalInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$_[4]
				);
			} else {
				new RegularInterface($_[0],
						'idf'					=>	$_[3],
						'inheritance'			=>	$_[4]
				);
			}
		}
	],
	[#Rule 41
		 'interface_header', 3,
sub
#line 317 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 42
		 'interface_body', 1, undef
	],
	[#Rule 43
		 'exports', 1,
sub
#line 331 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 44
		 'exports', 2,
sub
#line 335 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 45
		 '_export', 1, undef
	],
	[#Rule 46
		 '_export', 1,
sub
#line 346 "parser30.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 47
		 '_export', 1,
sub
#line 351 "parser30.yp"
{
			$_[0]->Error("initializer unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 48
		 'export', 2, undef
	],
	[#Rule 49
		 'export', 2, undef
	],
	[#Rule 50
		 'export', 2, undef
	],
	[#Rule 51
		 'export', 2, undef
	],
	[#Rule 52
		 'export', 2, undef
	],
	[#Rule 53
		 'export', 2, undef
	],
	[#Rule 54
		 'export', 2, undef
	],
	[#Rule 55
		 'interface_inheritance_spec', 2,
sub
#line 377 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 56
		 'interface_inheritance_spec', 2,
sub
#line 383 "parser30.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 58
		 'interface_names', 1,
sub
#line 393 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 59
		 'interface_names', 3,
sub
#line 397 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 60
		 'interface_name', 1,
sub
#line 406 "parser30.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 61
		 'scoped_name', 1, undef
	],
	[#Rule 62
		 'scoped_name', 2,
sub
#line 416 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 63
		 'scoped_name', 2,
sub
#line 420 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 64
		 'scoped_name', 3,
sub
#line 426 "parser30.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 65
		 'scoped_name', 3,
sub
#line 430 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 66
		 'value', 1, undef
	],
	[#Rule 67
		 'value', 1, undef
	],
	[#Rule 68
		 'value', 1, undef
	],
	[#Rule 69
		 'value', 1, undef
	],
	[#Rule 70
		 'value_forward_dcl', 3,
sub
#line 452 "parser30.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 71
		 'value_forward_dcl', 3,
sub
#line 460 "parser30.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 72
		 'value_box_dcl', 2,
sub
#line 470 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 73
		 'value_box_header', 3,
sub
#line 481 "parser30.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new BoxedValue($_[0],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 74
		 'value_abs_dcl', 3,
sub
#line 493 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 75
		 'value_abs_dcl', 4,
sub
#line 501 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 76
		 'value_abs_dcl', 4,
sub
#line 509 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 77
		 'value_abs_header', 4,
sub
#line 519 "parser30.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 78
		 'value_abs_header', 3,
sub
#line 526 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 79
		 'value_abs_header', 2,
sub
#line 531 "parser30.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 80
		 'value_dcl', 3,
sub
#line 540 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 81
		 'value_dcl', 4,
sub
#line 548 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 82
		 'value_dcl', 4,
sub
#line 556 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 83
		 'value_elements', 1,
sub
#line 566 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 84
		 'value_elements', 2,
sub
#line 570 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 85
		 'value_header', 4,
sub
#line 579 "parser30.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 86
		 'value_header', 3,
sub
#line 587 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 87
		 'value_mod', 1, undef
	],
	[#Rule 88
		 'value_mod', 0, undef
	],
	[#Rule 89
		 'value_inheritance_spec', 4,
sub
#line 603 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 90
		 'value_inheritance_spec', 3,
sub
#line 611 "parser30.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 91
		 'value_inheritance_spec', 1,
sub
#line 616 "parser30.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 92
		 'inheritance_mod', 1, undef
	],
	[#Rule 93
		 'inheritance_mod', 0, undef
	],
	[#Rule 94
		 'value_names', 1,
sub
#line 632 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 95
		 'value_names', 3,
sub
#line 636 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 96
		 'value_name', 1,
sub
#line 645 "parser30.yp"
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
#line 663 "parser30.yp"
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
#line 671 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 102
		 'state_member', 3,
sub
#line 676 "parser30.yp"
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
		 'init_dcl', 3,
sub
#line 692 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 106
		 'init_header_param', 3,
sub
#line 701 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 107
		 'init_header_param', 4,
sub
#line 707 "parser30.yp"
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
#line 715 "parser30.yp"
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
#line 722 "parser30.yp"
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
#line 732 "parser30.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 111
		 'init_header', 2,
sub
#line 738 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 112
		 'init_param_decls', 1,
sub
#line 747 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 113
		 'init_param_decls', 3,
sub
#line 751 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 114
		 'init_param_decl', 3,
sub
#line 760 "parser30.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 115
		 'init_param_decl', 2,
sub
#line 768 "parser30.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 116
		 'init_param_attribute', 1, undef
	],
	[#Rule 117
		 'const_dcl', 5,
sub
#line 783 "parser30.yp"
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
#line 791 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 119
		 'const_dcl', 4,
sub
#line 796 "parser30.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 120
		 'const_dcl', 3,
sub
#line 801 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 121
		 'const_dcl', 2,
sub
#line 806 "parser30.yp"
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
#line 831 "parser30.yp"
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
#line 849 "parser30.yp"
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
#line 859 "parser30.yp"
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
#line 869 "parser30.yp"
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
#line 879 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 141
		 'shift_expr', 3,
sub
#line 883 "parser30.yp"
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
#line 893 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 144
		 'add_expr', 3,
sub
#line 897 "parser30.yp"
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
#line 907 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'mult_expr', 3,
sub
#line 911 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 148
		 'mult_expr', 3,
sub
#line 915 "parser30.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 149
		 'unary_expr', 2,
sub
#line 923 "parser30.yp"
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
#line 943 "parser30.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 155
		 'primary_expr', 1,
sub
#line 949 "parser30.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 156
		 'primary_expr', 3,
sub
#line 953 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 157
		 'primary_expr', 3,
sub
#line 957 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 158
		 'literal', 1,
sub
#line 966 "parser30.yp"
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
#line 973 "parser30.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 979 "parser30.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 985 "parser30.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 991 "parser30.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'literal', 1,
sub
#line 997 "parser30.yp"
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
#line 1004 "parser30.yp"
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
#line 1018 "parser30.yp"
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
#line 1027 "parser30.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 170
		 'boolean_literal', 1,
sub
#line 1035 "parser30.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 171
		 'boolean_literal', 1,
sub
#line 1041 "parser30.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 172
		 'positive_int_const', 1,
sub
#line 1051 "parser30.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 173
		 'type_dcl', 2,
sub
#line 1061 "parser30.yp"
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
#line 1071 "parser30.yp"
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
#line 1080 "parser30.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 180
		 'type_declarator', 2,
sub
#line 1089 "parser30.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
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
#line 1112 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 186
		 'simple_type_spec', 1,
sub
#line 1116 "parser30.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
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
#line 1171 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 204
		 'declarators', 3,
sub
#line 1175 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 205
		 'declarator', 1,
sub
#line 1184 "parser30.yp"
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
		 'simple_declarator', 2,
sub
#line 1196 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 209
		 'simple_declarator', 2,
sub
#line 1201 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 210
		 'complex_declarator', 1, undef
	],
	[#Rule 211
		 'floating_pt_type', 1,
sub
#line 1216 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 212
		 'floating_pt_type', 1,
sub
#line 1222 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 213
		 'floating_pt_type', 2,
sub
#line 1228 "parser30.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 214
		 'integer_type', 1, undef
	],
	[#Rule 215
		 'integer_type', 1, undef
	],
	[#Rule 216
		 'signed_int', 1, undef
	],
	[#Rule 217
		 'signed_int', 1, undef
	],
	[#Rule 218
		 'signed_int', 1, undef
	],
	[#Rule 219
		 'signed_short_int', 1,
sub
#line 1256 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 220
		 'signed_long_int', 1,
sub
#line 1266 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 221
		 'signed_longlong_int', 2,
sub
#line 1276 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 222
		 'unsigned_int', 1, undef
	],
	[#Rule 223
		 'unsigned_int', 1, undef
	],
	[#Rule 224
		 'unsigned_int', 1, undef
	],
	[#Rule 225
		 'unsigned_short_int', 2,
sub
#line 1296 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 226
		 'unsigned_long_int', 2,
sub
#line 1306 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 227
		 'unsigned_longlong_int', 3,
sub
#line 1316 "parser30.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 228
		 'char_type', 1,
sub
#line 1326 "parser30.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 229
		 'wide_char_type', 1,
sub
#line 1336 "parser30.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 230
		 'boolean_type', 1,
sub
#line 1346 "parser30.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 231
		 'octet_type', 1,
sub
#line 1356 "parser30.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 232
		 'any_type', 1,
sub
#line 1366 "parser30.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 233
		 'object_type', 1,
sub
#line 1376 "parser30.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 234
		 'struct_type', 4,
sub
#line 1386 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 235
		 'struct_type', 4,
sub
#line 1393 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 236
		 'struct_header', 2,
sub
#line 1402 "parser30.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 237
		 'struct_header', 2,
sub
#line 1408 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 238
		 'member_list', 1,
sub
#line 1417 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 239
		 'member_list', 2,
sub
#line 1421 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 240
		 'member', 3,
sub
#line 1430 "parser30.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 241
		 'union_type', 8,
sub
#line 1441 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 242
		 'union_type', 8,
sub
#line 1449 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'union_type', 6,
sub
#line 1455 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 244
		 'union_type', 5,
sub
#line 1461 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 245
		 'union_type', 3,
sub
#line 1467 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 246
		 'union_header', 2,
sub
#line 1476 "parser30.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 247
		 'union_header', 2,
sub
#line 1482 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
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
#line 1499 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 253
		 'switch_body', 1,
sub
#line 1507 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 254
		 'switch_body', 2,
sub
#line 1511 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 255
		 'case', 3,
sub
#line 1520 "parser30.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 256
		 'case_labels', 1,
sub
#line 1530 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 257
		 'case_labels', 2,
sub
#line 1534 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 258
		 'case_label', 3,
sub
#line 1543 "parser30.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 259
		 'case_label', 3,
sub
#line 1547 "parser30.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 260
		 'case_label', 2,
sub
#line 1553 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 261
		 'case_label', 2,
sub
#line 1558 "parser30.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 262
		 'case_label', 2,
sub
#line 1562 "parser30.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 263
		 'element_spec', 2,
sub
#line 1572 "parser30.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 264
		 'enum_type', 4,
sub
#line 1583 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 265
		 'enum_type', 4,
sub
#line 1589 "parser30.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'enum_type', 2,
sub
#line 1594 "parser30.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'enum_header', 2,
sub
#line 1602 "parser30.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 268
		 'enum_header', 2,
sub
#line 1608 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 269
		 'enumerators', 1,
sub
#line 1616 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 270
		 'enumerators', 3,
sub
#line 1620 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 271
		 'enumerators', 2,
sub
#line 1625 "parser30.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 272
		 'enumerators', 2,
sub
#line 1630 "parser30.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 273
		 'enumerator', 1,
sub
#line 1639 "parser30.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 274
		 'sequence_type', 6,
sub
#line 1649 "parser30.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 275
		 'sequence_type', 6,
sub
#line 1657 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 276
		 'sequence_type', 4,
sub
#line 1662 "parser30.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 277
		 'sequence_type', 4,
sub
#line 1669 "parser30.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'sequence_type', 2,
sub
#line 1674 "parser30.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'string_type', 4,
sub
#line 1683 "parser30.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 280
		 'string_type', 1,
sub
#line 1690 "parser30.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 281
		 'string_type', 4,
sub
#line 1696 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 282
		 'wide_string_type', 4,
sub
#line 1705 "parser30.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 283
		 'wide_string_type', 1,
sub
#line 1712 "parser30.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 284
		 'wide_string_type', 4,
sub
#line 1718 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 285
		 'array_declarator', 2,
sub
#line 1727 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 286
		 'fixed_array_sizes', 1,
sub
#line 1735 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 287
		 'fixed_array_sizes', 2,
sub
#line 1739 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 288
		 'fixed_array_size', 3,
sub
#line 1748 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 289
		 'fixed_array_size', 3,
sub
#line 1752 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 290
		 'attr_dcl', 1, undef
	],
	[#Rule 291
		 'attr_dcl', 1, undef
	],
	[#Rule 292
		 'except_dcl', 3,
sub
#line 1769 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 293
		 'except_dcl', 4,
sub
#line 1774 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 294
		 'except_dcl', 4,
sub
#line 1781 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 295
		 'except_dcl', 2,
sub
#line 1787 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 296
		 'exception_header', 2,
sub
#line 1796 "parser30.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 297
		 'exception_header', 2,
sub
#line 1802 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 298
		 'op_dcl', 4,
sub
#line 1811 "parser30.yp"
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
	[#Rule 299
		 'op_dcl', 2,
sub
#line 1821 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 300
		 'op_header', 3,
sub
#line 1831 "parser30.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 301
		 'op_header', 3,
sub
#line 1839 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 302
		 'op_mod', 1, undef
	],
	[#Rule 303
		 'op_mod', 0, undef
	],
	[#Rule 304
		 'op_attribute', 1, undef
	],
	[#Rule 305
		 'op_type_spec', 1, undef
	],
	[#Rule 306
		 'op_type_spec', 1,
sub
#line 1863 "parser30.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 307
		 'op_type_spec', 1,
sub
#line 1869 "parser30.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 308
		 'op_type_spec', 1,
sub
#line 1874 "parser30.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 309
		 'parameter_dcls', 3,
sub
#line 1883 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 310
		 'parameter_dcls', 5,
sub
#line 1887 "parser30.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 311
		 'parameter_dcls', 4,
sub
#line 1892 "parser30.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 312
		 'parameter_dcls', 2,
sub
#line 1897 "parser30.yp"
{
			undef;
		}
	],
	[#Rule 313
		 'parameter_dcls', 3,
sub
#line 1901 "parser30.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 314
		 'parameter_dcls', 3,
sub
#line 1906 "parser30.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 315
		 'param_dcls', 1,
sub
#line 1914 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 316
		 'param_dcls', 3,
sub
#line 1918 "parser30.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 317
		 'param_dcls', 2,
sub
#line 1923 "parser30.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 318
		 'param_dcl', 3,
sub
#line 1932 "parser30.yp"
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
		 'param_attribute', 0,
sub
#line 1950 "parser30.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 323
		 'raises_expr', 4,
sub
#line 1959 "parser30.yp"
{
			$_[3];
		}
	],
	[#Rule 324
		 'raises_expr', 4,
sub
#line 1963 "parser30.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 325
		 'raises_expr', 2,
sub
#line 1968 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 326
		 'raises_expr', 0, undef
	],
	[#Rule 327
		 'exception_names', 1,
sub
#line 1978 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 328
		 'exception_names', 3,
sub
#line 1982 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 329
		 'exception_name', 1,
sub
#line 1990 "parser30.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 330
		 'context_expr', 4,
sub
#line 1998 "parser30.yp"
{
			$_[3];
		}
	],
	[#Rule 331
		 'context_expr', 4,
sub
#line 2002 "parser30.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 332
		 'context_expr', 2,
sub
#line 2007 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 333
		 'context_expr', 0, undef
	],
	[#Rule 334
		 'string_literals', 1,
sub
#line 2017 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 335
		 'string_literals', 3,
sub
#line 2021 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 336
		 'param_type_spec', 1, undef
	],
	[#Rule 337
		 'param_type_spec', 1,
sub
#line 2032 "parser30.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 338
		 'param_type_spec', 1,
sub
#line 2037 "parser30.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 339
		 'param_type_spec', 1,
sub
#line 2042 "parser30.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 340
		 'param_type_spec', 1,
sub
#line 2047 "parser30.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 341
		 'op_param_type_spec', 1, undef
	],
	[#Rule 342
		 'op_param_type_spec', 1, undef
	],
	[#Rule 343
		 'op_param_type_spec', 1, undef
	],
	[#Rule 344
		 'op_param_type_spec', 1,
sub
#line 2061 "parser30.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 345
		 'fixed_pt_type', 6,
sub
#line 2069 "parser30.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 346
		 'fixed_pt_type', 6,
sub
#line 2077 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 347
		 'fixed_pt_type', 4,
sub
#line 2082 "parser30.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 348
		 'fixed_pt_type', 2,
sub
#line 2087 "parser30.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 349
		 'fixed_pt_const_type', 1,
sub
#line 2096 "parser30.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 350
		 'value_base_type', 1,
sub
#line 2106 "parser30.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 351
		 'constr_forward_decl', 2,
sub
#line 2116 "parser30.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 352
		 'constr_forward_decl', 2,
sub
#line 2122 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 353
		 'constr_forward_decl', 2,
sub
#line 2127 "parser30.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 354
		 'constr_forward_decl', 2,
sub
#line 2133 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 355
		 'import', 3,
sub
#line 2142 "parser30.yp"
{
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 356
		 'import', 2,
sub
#line 2148 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 357
		 'imported_scope', 1, undef
	],
	[#Rule 358
		 'imported_scope', 1, undef
	],
	[#Rule 359
		 'type_id_dcl', 3,
sub
#line 2165 "parser30.yp"
{
			new TypeId($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 360
		 'type_id_dcl', 3,
sub
#line 2172 "parser30.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 361
		 'type_id_dcl', 2,
sub
#line 2177 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 362
		 'type_prefix_dcl', 3,
sub
#line 2186 "parser30.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 363
		 'type_prefix_dcl', 3,
sub
#line 2193 "parser30.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 364
		 'type_prefix_dcl', 3,
sub
#line 2198 "parser30.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	'',
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 365
		 'type_prefix_dcl', 2,
sub
#line 2205 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 366
		 'readonly_attr_spec', 4,
sub
#line 2214 "parser30.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]->{list_expr},
					'list_getraise'		=>	$_[4]->{list_getraise},
			);
		}
	],
	[#Rule 367
		 'readonly_attr_spec', 3,
sub
#line 2223 "parser30.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 368
		 'readonly_attr_spec', 2,
sub
#line 2228 "parser30.yp"
{
			$_[0]->Error("'attribute' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 369
		 'readonly_attr_declarator', 2,
sub
#line 2237 "parser30.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]
			};
		}
	],
	[#Rule 370
		 'readonly_attr_declarator', 3,
sub
#line 2244 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			{
				'list_expr'			=> $_[3]
			};
		}
	],
	[#Rule 371
		 'simple_declarators', 1,
sub
#line 2254 "parser30.yp"
{
			[$_[1]];
		}
	],
	[#Rule 372
		 'simple_declarators', 3,
sub
#line 2258 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 373
		 'attr_spec', 3,
sub
#line 2267 "parser30.yp"
{
			new Attributes($_[0],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]->{list_expr},
					'list_getraise'		=>	$_[3]->{list_getraise},
					'list_setraise'		=>	$_[3]->{list_setraise},
			);
		}
	],
	[#Rule 374
		 'attr_spec', 2,
sub
#line 2276 "parser30.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 375
		 'attr_declarator', 2,
sub
#line 2285 "parser30.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]->{list_getraise},
				'list_setraise'		=> $_[2]->{list_setraise}
			};
		}
	],
	[#Rule 376
		 'attr_declarator', 3,
sub
#line 2293 "parser30.yp"
{
			unshift(@{$_[3]},$_[1]);
			{
				'list_expr'			=> $_[3]
			};
		}
	],
	[#Rule 377
		 'attr_raises_expr', 2,
sub
#line 2304 "parser30.yp"
{
			{
				'list_getraise'		=> $_[1],
				'list_setraise'		=> $_[2]
			};
		}
	],
	[#Rule 378
		 'attr_raises_expr', 1,
sub
#line 2311 "parser30.yp"
{
			{
				'list_getraise'		=> $_[1],
			};
		}
	],
	[#Rule 379
		 'attr_raises_expr', 1,
sub
#line 2317 "parser30.yp"
{
			{
				'list_setraise'		=> $_[1]
			};
		}
	],
	[#Rule 380
		 'attr_raises_expr', 0, undef
	],
	[#Rule 381
		 'get_except_expr', 2,
sub
#line 2329 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 382
		 'get_except_expr', 2,
sub
#line 2333 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 383
		 'set_except_expr', 2,
sub
#line 2342 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 384
		 'set_except_expr', 2,
sub
#line 2346 "parser30.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 385
		 'exception_list', 3,
sub
#line 2355 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 386
		 'exception_list', 3,
sub
#line 2359 "parser30.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 387
		 'component', 1, undef
	],
	[#Rule 388
		 'component', 1, undef
	],
	[#Rule 389
		 'component_forward_dcl', 2,
sub
#line 2376 "parser30.yp"
{
			new ForwardComponent($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 390
		 'component_forward_dcl', 2,
sub
#line 2382 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 391
		 'component_dcl', 3,
sub
#line 2391 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 392
		 'component_dcl', 4,
sub
#line 2399 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 393
		 'component_dcl', 4,
sub
#line 2407 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 394
		 'component_header', 4,
sub
#line 2418 "parser30.yp"
{
			new Component($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3],
					'list_support'			=>	$_[4],
			);
		}
	],
	[#Rule 395
		 'component_header', 2,
sub
#line 2426 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 396
		 'supported_interface_spec', 2,
sub
#line 2435 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 397
		 'supported_interface_spec', 2,
sub
#line 2439 "parser30.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 398
		 'supported_interface_spec', 0, undef
	],
	[#Rule 399
		 'component_inheritance_spec', 2,
sub
#line 2450 "parser30.yp"
{
			Component->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 400
		 'component_inheritance_spec', 2,
sub
#line 2454 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 401
		 'component_inheritance_spec', 0, undef
	],
	[#Rule 402
		 'component_body', 1, undef
	],
	[#Rule 403
		 'component_exports', 1,
sub
#line 2470 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 404
		 'component_exports', 2,
sub
#line 2474 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 405
		 'component_export', 2, undef
	],
	[#Rule 406
		 'component_export', 2, undef
	],
	[#Rule 407
		 'component_export', 2, undef
	],
	[#Rule 408
		 'component_export', 2, undef
	],
	[#Rule 409
		 'component_export', 2, undef
	],
	[#Rule 410
		 'component_export', 2, undef
	],
	[#Rule 411
		 'provides_dcl', 3,
sub
#line 2499 "parser30.yp"
{
			new Provides($_[0],
					'idf'					=>	$_[3],
					'type'					=>	$_[2],
			);
		}
	],
	[#Rule 412
		 'provides_dcl', 3,
sub
#line 2506 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 413
		 'provides_dcl', 2,
sub
#line 2511 "parser30.yp"
{
			$_[0]->Error("Interface type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 414
		 'interface_type', 1,
sub
#line 2520 "parser30.yp"
{
			BaseInterface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 415
		 'interface_type', 1, undef
	],
	[#Rule 416
		 'uses_dcl', 4,
sub
#line 2530 "parser30.yp"
{
			new Uses($_[0],
					'modifier'				=>	$_[2],
					'idf'					=>	$_[4],
					'type'					=>	$_[3],
			);
		}
	],
	[#Rule 417
		 'uses_dcl', 4,
sub
#line 2538 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 418
		 'uses_dcl', 3,
sub
#line 2543 "parser30.yp"
{
			$_[0]->Error("Interface type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 419
		 'uses_mod', 1, undef
	],
	[#Rule 420
		 'uses_mod', 0, undef
	],
	[#Rule 421
		 'emits_dcl', 3,
sub
#line 2559 "parser30.yp"
{
			new Emits($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 422
		 'emits_dcl', 3,
sub
#line 2566 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 423
		 'emits_dcl', 2,
sub
#line 2571 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 424
		 'publishes_dcl', 3,
sub
#line 2580 "parser30.yp"
{
			new Publishes($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 425
		 'publishes_dcl', 3,
sub
#line 2587 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 426
		 'publishes_dcl', 2,
sub
#line 2592 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 427
		 'consumes_dcl', 3,
sub
#line 2601 "parser30.yp"
{
			new Consumes($_[0],
					'idf'					=>	$_[3],
					'type'					=>	Event->Lookup($_[0],$_[2]),
			);
		}
	],
	[#Rule 428
		 'consumes_dcl', 3,
sub
#line 2608 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 429
		 'consumes_dcl', 2,
sub
#line 2613 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 430
		 'home_dcl', 2,
sub
#line 2622 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[2],
			) if (defined $_[1]);
		}
	],
	[#Rule 431
		 'home_header', 4,
sub
#line 2634 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'manage'			=>	Component->Lookup($_[0],$_[3]),
					'primarykey'		=>	$_[4],
			) if (defined $_[1]);
		}
	],
	[#Rule 432
		 'home_header', 3,
sub
#line 2641 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 433
		 'home_header_spec', 4,
sub
#line 2650 "parser30.yp"
{
			new Home($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3],
					'list_support'		=>	$_[4],
			);
		}
	],
	[#Rule 434
		 'home_header_spec', 2,
sub
#line 2658 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 435
		 'home_inheritance_spec', 2,
sub
#line 2667 "parser30.yp"
{
			Home->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 436
		 'home_inheritance_spec', 2,
sub
#line 2671 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 437
		 'home_inheritance_spec', 0, undef
	],
	[#Rule 438
		 'primary_key_spec', 2,
sub
#line 2682 "parser30.yp"
{
			Value->Lookup($_[0],$_[2]);
		}
	],
	[#Rule 439
		 'primary_key_spec', 2,
sub
#line 2686 "parser30.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 440
		 'primary_key_spec', 0, undef
	],
	[#Rule 441
		 'home_body', 2,
sub
#line 2697 "parser30.yp"
{
			[];
		}
	],
	[#Rule 442
		 'home_body', 3,
sub
#line 2701 "parser30.yp"
{
			$_[2];
		}
	],
	[#Rule 443
		 'home_body', 3,
sub
#line 2705 "parser30.yp"
{
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 444
		 'home_exports', 1,
sub
#line 2713 "parser30.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 445
		 'home_exports', 2,
sub
#line 2717 "parser30.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 446
		 'home_export', 1, undef
	],
	[#Rule 447
		 'home_export', 2, undef
	],
	[#Rule 448
		 'home_export', 2, undef
	],
	[#Rule 449
		 'factory_dcl', 2,
sub
#line 2736 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 450
		 'factory_header_param', 3,
sub
#line 2745 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 451
		 'factory_header_param', 4,
sub
#line 2751 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'		=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 452
		 'factory_header_param', 4,
sub
#line 2759 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 453
		 'factory_header_param', 2,
sub
#line 2766 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 454
		 'factory_header', 2,
sub
#line 2776 "parser30.yp"
{
			new Factory($_[0],							# like Operation
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 455
		 'factory_header', 2,
sub
#line 2782 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 456
		 'finder_dcl', 2,
sub
#line 2791 "parser30.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 457
		 'finder_header_param', 3,
sub
#line 2800 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 458
		 'finder_header_param', 4,
sub
#line 2806 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'		=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 459
		 'finder_header_param', 4,
sub
#line 2814 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 460
		 'finder_header_param', 2,
sub
#line 2821 "parser30.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 461
		 'finder_header', 2,
sub
#line 2831 "parser30.yp"
{
			new Finder($_[0],							# like Operation
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 462
		 'finder_header', 2,
sub
#line 2837 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 463
		 'event', 1, undef
	],
	[#Rule 464
		 'event', 1, undef
	],
	[#Rule 465
		 'event', 1, undef
	],
	[#Rule 466
		 'event_forward_dcl', 3,
sub
#line 2856 "parser30.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[1]);
			new ForwardRegularEvent($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 467
		 'event_forward_dcl', 3,
sub
#line 2864 "parser30.yp"
{
			new ForwardAbstractEvent($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 468
		 'event_abs_dcl', 3,
sub
#line 2874 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 469
		 'event_abs_dcl', 4,
sub
#line 2882 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 470
		 'event_abs_dcl', 4,
sub
#line 2890 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 471
		 'event_abs_header', 4,
sub
#line 2900 "parser30.yp"
{
			new AbstractEvent($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 472
		 'event_abs_header', 3,
sub
#line 2907 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 473
		 'event_dcl', 3,
sub
#line 2916 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 474
		 'event_dcl', 4,
sub
#line 2924 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 475
		 'event_dcl', 4,
sub
#line 2932 "parser30.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 476
		 'event_header', 4,
sub
#line 2943 "parser30.yp"
{
			new RegularEvent($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 477
		 'event_header', 3,
sub
#line 2951 "parser30.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 2957 "parser30.yp"


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
