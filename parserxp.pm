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
			'ENUM' => -392,
			'INTERFACE' => -392,
			'VALUETYPE' => -392,
			'CUSTOM' => -392,
			'IMPORT' => 21,
			'UNION' => -392,
			'NATIVE' => -392,
			'CODE_FRAGMENT' => -392,
			'TYPEDEF' => -392,
			'EXCEPTION' => -392,
			'error' => 23,
			"[" => -392,
			'LOCAL' => -392,
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'MODULE' => -392,
			'STRUCT' => -392,
			'CONST' => -392,
			'ABSTRACT' => -392,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 18,
			'module_header' => 20,
			'definition' => 19,
			'value_box_header' => 4,
			'specification' => 22,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'imports' => 26,
			'value' => 13,
			'value_abs_dcl' => 27,
			'import' => 28,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 1
		DEFAULT => -65
	},
	{#State 2
		DEFAULT => -18
	},
	{#State 3
		DEFAULT => -67
	},
	{#State 4
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		DEFAULT => -394,
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 66,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 5
		ACTIONS => {
			'MODULE' => 96,
			'CONST' => 97,
			'CODE_FRAGMENT' => 90,
			'EXCEPTION' => 91,
			"[" => 42
		},
		DEFAULT => -394,
		GOTOS => {
			'union_type' => 88,
			'enum_type' => 92,
			'enum_header' => 35,
			'type_dcl_def' => 93,
			'struct_type' => 89,
			'union_header' => 39,
			'props' => 94,
			'struct_header' => 40,
			'constr_forward_decl' => 95
		}
	},
	{#State 6
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 98
		}
	},
	{#State 7
		ACTIONS => {
			"{" => 101
		}
	},
	{#State 8
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 102
		}
	},
	{#State 9
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 103
		}
	},
	{#State 10
		DEFAULT => -68
	},
	{#State 11
		ACTIONS => {
			"{" => 104
		}
	},
	{#State 12
		ACTIONS => {
			'error' => 105
		}
	},
	{#State 13
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 106
		}
	},
	{#State 14
		ACTIONS => {
			"{" => 107
		}
	},
	{#State 15
		ACTIONS => {
			"{" => 109,
			'error' => 108
		}
	},
	{#State 16
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 110
		}
	},
	{#State 17
		DEFAULT => -28
	},
	{#State 18
		DEFAULT => -1
	},
	{#State 19
		ACTIONS => {
			'' => -7,
			"}" => -7,
			'IMPORT' => 21,
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -392,
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 111,
			'definition' => 19,
			'module_header' => 20,
			'value_box_header' => 4,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'imports' => 112,
			'value' => 13,
			'value_abs_dcl' => 27,
			'import' => 28,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 20
		ACTIONS => {
			"{" => 114,
			'error' => 113
		}
	},
	{#State 21
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'STRING_LITERAL' => 119,
			'error' => 118
		},
		GOTOS => {
			'imported_scope' => 117,
			'scoped_name' => 116,
			'string_literal' => 115
		}
	},
	{#State 22
		ACTIONS => {
			'' => 120
		}
	},
	{#State 23
		DEFAULT => -4
	},
	{#State 24
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 121
		}
	},
	{#State 25
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 123
		},
		GOTOS => {
			'scoped_name' => 122
		}
	},
	{#State 26
		ACTIONS => {
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -392,
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 124,
			'definition' => 19,
			'module_header' => 20,
			'value_box_header' => 4,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'value' => 13,
			'value_abs_dcl' => 27,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 27
		DEFAULT => -66
	},
	{#State 28
		ACTIONS => {
			'IMPORT' => 21
		},
		DEFAULT => -5,
		GOTOS => {
			'imports' => 125,
			'import' => 28
		}
	},
	{#State 29
		DEFAULT => -393
	},
	{#State 30
		DEFAULT => -29
	},
	{#State 31
		ACTIONS => {
			"::" => 127,
			'IDENTIFIER' => 49,
			'error' => 128
		},
		GOTOS => {
			'scoped_name' => 126
		}
	},
	{#State 32
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 129
		}
	},
	{#State 33
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 130
		}
	},
	{#State 34
		DEFAULT => -206
	},
	{#State 35
		ACTIONS => {
			"{" => 132,
			'error' => 131
		}
	},
	{#State 36
		DEFAULT => -227
	},
	{#State 37
		DEFAULT => -236
	},
	{#State 38
		DEFAULT => -205
	},
	{#State 39
		ACTIONS => {
			'SWITCH' => 133
		}
	},
	{#State 40
		ACTIONS => {
			"{" => 134
		}
	},
	{#State 41
		ACTIONS => {
			'SHORT' => 136,
			'LONG' => 135
		}
	},
	{#State 42
		DEFAULT => -395,
		GOTOS => {
			'@2-1' => 137
		}
	},
	{#State 43
		DEFAULT => -237
	},
	{#State 44
		ACTIONS => {
			'DOUBLE' => 139,
			'LONG' => 138
		},
		DEFAULT => -225
	},
	{#State 45
		DEFAULT => -223
	},
	{#State 46
		DEFAULT => -207
	},
	{#State 47
		DEFAULT => -198
	},
	{#State 48
		DEFAULT => -189
	},
	{#State 49
		DEFAULT => -60
	},
	{#State 50
		DEFAULT => -228
	},
	{#State 51
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -190
	},
	{#State 52
		DEFAULT => -202
	},
	{#State 53
		ACTIONS => {
			'UNION' => 143,
			'ENUM' => 142,
			'STRUCT' => 141
		}
	},
	{#State 54
		DEFAULT => -194
	},
	{#State 55
		DEFAULT => -191
	},
	{#State 56
		DEFAULT => -222
	},
	{#State 57
		DEFAULT => -221
	},
	{#State 58
		DEFAULT => -204
	},
	{#State 59
		DEFAULT => -195
	},
	{#State 60
		DEFAULT => -234
	},
	{#State 61
		DEFAULT => -197
	},
	{#State 62
		DEFAULT => -203
	},
	{#State 63
		ACTIONS => {
			'IDENTIFIER' => 144,
			'error' => 145
		}
	},
	{#State 64
		DEFAULT => -233
	},
	{#State 65
		DEFAULT => -199
	},
	{#State 66
		DEFAULT => -71
	},
	{#State 67
		DEFAULT => -193
	},
	{#State 68
		DEFAULT => -238
	},
	{#State 69
		DEFAULT => -220
	},
	{#State 70
		DEFAULT => -201
	},
	{#State 71
		ACTIONS => {
			"<" => 146
		},
		DEFAULT => -285
	},
	{#State 72
		DEFAULT => -229
	},
	{#State 73
		ACTIONS => {
			"<" => 147
		},
		DEFAULT => -288
	},
	{#State 74
		DEFAULT => -187
	},
	{#State 75
		DEFAULT => -192
	},
	{#State 76
		DEFAULT => -216
	},
	{#State 77
		DEFAULT => -200
	},
	{#State 78
		ACTIONS => {
			"<" => 148,
			'error' => 149
		}
	},
	{#State 79
		DEFAULT => -217
	},
	{#State 80
		DEFAULT => -224
	},
	{#State 81
		DEFAULT => -188
	},
	{#State 82
		DEFAULT => -235
	},
	{#State 83
		DEFAULT => -219
	},
	{#State 84
		DEFAULT => -186
	},
	{#State 85
		ACTIONS => {
			"<" => 150,
			'error' => 151
		}
	},
	{#State 86
		DEFAULT => -196
	},
	{#State 87
		DEFAULT => -354
	},
	{#State 88
		DEFAULT => -178
	},
	{#State 89
		DEFAULT => -177
	},
	{#State 90
		DEFAULT => -391
	},
	{#State 91
		ACTIONS => {
			'IDENTIFIER' => 152,
			'error' => 153
		}
	},
	{#State 92
		DEFAULT => -179
	},
	{#State 93
		DEFAULT => -175
	},
	{#State 94
		ACTIONS => {
			'ENUM' => 142,
			'VALUETYPE' => -87,
			'CUSTOM' => 154,
			'STRUCT' => 159,
			'ABSTRACT' => 160,
			'UNION' => 161,
			'NATIVE' => 155,
			'TYPEDEF' => 156,
			'LOCAL' => 162
		},
		DEFAULT => -37,
		GOTOS => {
			'value_mod' => 158,
			'interface_mod' => 157
		}
	},
	{#State 95
		DEFAULT => -183
	},
	{#State 96
		ACTIONS => {
			'IDENTIFIER' => 163,
			'error' => 164
		}
	},
	{#State 97
		ACTIONS => {
			'DOUBLE' => 79,
			"::" => 63,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'CHAR' => 64,
			'BOOLEAN' => 82,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'FIXED' => 176,
			'error' => 173,
			'FLOAT' => 76,
			'LONG' => 44,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 170,
			'integer_type' => 171,
			'unsigned_int' => 69,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 172,
			'const_type' => 174,
			'signed_longlong_int' => 45,
			'unsigned_long_int' => 50,
			'scoped_name' => 165,
			'string_type' => 166,
			'signed_int' => 83,
			'fixed_pt_const_type' => 175,
			'char_type' => 167,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'boolean_type' => 177,
			'wide_char_type' => 168,
			'octet_type' => 169
		}
	},
	{#State 98
		DEFAULT => -12
	},
	{#State 99
		DEFAULT => -20
	},
	{#State 100
		DEFAULT => -21
	},
	{#State 101
		ACTIONS => {
			"}" => 178,
			'OCTET' => -392,
			'NATIVE' => -392,
			'UNSIGNED' => -392,
			'CODE_FRAGMENT' => -392,
			'TYPEDEF' => -392,
			'EXCEPTION' => -392,
			"[" => -392,
			'ANY' => -392,
			'LONG' => -392,
			'IDENTIFIER' => -392,
			'STRUCT' => -392,
			'VOID' => -392,
			'WCHAR' => -392,
			'FACTORY' => -392,
			'ENUM' => -392,
			"::" => -392,
			'PRIVATE' => -392,
			'CHAR' => -392,
			'OBJECT' => -392,
			'ONEWAY' => -392,
			'STRING' => -392,
			'WSTRING' => -392,
			'UNION' => -392,
			'error' => 193,
			'FLOAT' => -392,
			'ATTRIBUTE' => -392,
			'PUBLIC' => -392,
			'SEQUENCE' => -392,
			'DOUBLE' => -392,
			'SHORT' => -392,
			'TYPEID' => 25,
			'BOOLEAN' => -392,
			'CONST' => -392,
			'READONLY' => -392,
			'DECLSPEC' => 29,
			'FIXED' => -392,
			'TYPEPREFIX' => 31,
			'VALUEBASE' => -392
		},
		GOTOS => {
			'op_header' => 188,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 194,
			'export' => 183,
			'type_dcl' => 184,
			'value_elements' => 195,
			'value_element' => 185,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'type_id_dcl' => 198,
			'init_dcl' => 197
		}
	},
	{#State 102
		DEFAULT => -13
	},
	{#State 103
		DEFAULT => -10
	},
	{#State 104
		ACTIONS => {
			"}" => 199,
			'OCTET' => -392,
			'NATIVE' => -392,
			'UNSIGNED' => -392,
			'CODE_FRAGMENT' => -392,
			'TYPEDEF' => -392,
			'EXCEPTION' => -392,
			"[" => -392,
			'ANY' => -392,
			'LONG' => -392,
			'IDENTIFIER' => -392,
			'STRUCT' => -392,
			'VOID' => -392,
			'WCHAR' => -392,
			'FACTORY' => -392,
			'ENUM' => -392,
			"::" => -392,
			'PRIVATE' => -392,
			'CHAR' => -392,
			'OBJECT' => -392,
			'ONEWAY' => -392,
			'STRING' => -392,
			'WSTRING' => -392,
			'UNION' => -392,
			'error' => 204,
			'FLOAT' => -392,
			'ATTRIBUTE' => -392,
			'PUBLIC' => -392,
			'SEQUENCE' => -392,
			'DOUBLE' => -392,
			'SHORT' => -392,
			'TYPEID' => 25,
			'BOOLEAN' => -392,
			'CONST' => -392,
			'READONLY' => -392,
			'DECLSPEC' => 29,
			'FIXED' => -392,
			'TYPEPREFIX' => 31,
			'VALUEBASE' => -392
		},
		GOTOS => {
			'op_header' => 188,
			'interface_body' => 202,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'exports' => 203,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 205,
			'type_dcl' => 184,
			'export' => 200,
			'_export' => 201,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'init_dcl' => 206,
			'type_id_dcl' => 198
		}
	},
	{#State 105
		ACTIONS => {
			";" => 207
		}
	},
	{#State 106
		DEFAULT => -15
	},
	{#State 107
		ACTIONS => {
			"}" => 208,
			'OCTET' => -392,
			'NATIVE' => -392,
			'UNSIGNED' => -392,
			'CODE_FRAGMENT' => -392,
			'TYPEDEF' => -392,
			'EXCEPTION' => -392,
			"[" => -392,
			'ANY' => -392,
			'LONG' => -392,
			'IDENTIFIER' => -392,
			'STRUCT' => -392,
			'VOID' => -392,
			'WCHAR' => -392,
			'FACTORY' => -392,
			'ENUM' => -392,
			"::" => -392,
			'PRIVATE' => -392,
			'CHAR' => -392,
			'OBJECT' => -392,
			'ONEWAY' => -392,
			'STRING' => -392,
			'WSTRING' => -392,
			'UNION' => -392,
			'error' => 210,
			'FLOAT' => -392,
			'ATTRIBUTE' => -392,
			'PUBLIC' => -392,
			'SEQUENCE' => -392,
			'DOUBLE' => -392,
			'SHORT' => -392,
			'TYPEID' => 25,
			'BOOLEAN' => -392,
			'CONST' => -392,
			'READONLY' => -392,
			'DECLSPEC' => 29,
			'FIXED' => -392,
			'TYPEPREFIX' => 31,
			'VALUEBASE' => -392
		},
		GOTOS => {
			'op_header' => 188,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'exports' => 209,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 205,
			'type_dcl' => 184,
			'export' => 200,
			'_export' => 201,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'init_dcl' => 206,
			'type_id_dcl' => 198
		}
	},
	{#State 108
		DEFAULT => -300
	},
	{#State 109
		ACTIONS => {
			"}" => 211,
			'ENUM' => -394,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNION' => -394,
			'UNSIGNED' => 41,
			'error' => 215,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'STRUCT' => -394,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'member_list' => 212,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'member' => 213,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 214,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 110
		DEFAULT => -11
	},
	{#State 111
		DEFAULT => -8
	},
	{#State 112
		ACTIONS => {
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -392,
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 216,
			'definition' => 19,
			'module_header' => 20,
			'value_box_header' => 4,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'value' => 13,
			'value_abs_dcl' => 27,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 113
		ACTIONS => {
			"}" => 217
		}
	},
	{#State 114
		ACTIONS => {
			"}" => 218,
			'ENUM' => -392,
			'INTERFACE' => -392,
			'VALUETYPE' => -392,
			'CUSTOM' => -392,
			'UNION' => -392,
			'NATIVE' => -392,
			'CODE_FRAGMENT' => -392,
			'TYPEDEF' => -392,
			'EXCEPTION' => -392,
			'error' => 220,
			"[" => -392,
			'LOCAL' => -392,
			'IDENTIFIER' => 12,
			'TYPEID' => 25,
			'MODULE' => -392,
			'STRUCT' => -392,
			'CONST' => -392,
			'ABSTRACT' => -392,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		GOTOS => {
			'value_dcl' => 1,
			'code_frag' => 2,
			'value_box_dcl' => 3,
			'definitions' => 219,
			'definition' => 19,
			'module_header' => 20,
			'value_box_header' => 4,
			'declspec' => 5,
			'except_dcl' => 6,
			'value_header' => 7,
			'interface' => 8,
			'type_dcl' => 9,
			'module' => 24,
			'interface_header' => 11,
			'value_forward_dcl' => 10,
			'value' => 13,
			'value_abs_dcl' => 27,
			'value_abs_header' => 14,
			'forward_dcl' => 30,
			'exception_header' => 15,
			'const_dcl' => 16,
			'type_prefix_dcl' => 32,
			'interface_dcl' => 17,
			'type_id_dcl' => 33
		}
	},
	{#State 115
		DEFAULT => -362
	},
	{#State 116
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -361
	},
	{#State 117
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 221
		}
	},
	{#State 118
		DEFAULT => -360
	},
	{#State 119
		ACTIONS => {
			'STRING_LITERAL' => 119
		},
		DEFAULT => -168,
		GOTOS => {
			'string_literal' => 222
		}
	},
	{#State 120
		DEFAULT => 0
	},
	{#State 121
		DEFAULT => -14
	},
	{#State 122
		ACTIONS => {
			"::" => 140,
			'STRING_LITERAL' => 119,
			'error' => 224
		},
		GOTOS => {
			'string_literal' => 223
		}
	},
	{#State 123
		DEFAULT => -365
	},
	{#State 124
		DEFAULT => -2
	},
	{#State 125
		DEFAULT => -6
	},
	{#State 126
		ACTIONS => {
			"::" => 140,
			'STRING_LITERAL' => 119,
			'error' => 226
		},
		GOTOS => {
			'string_literal' => 225
		}
	},
	{#State 127
		ACTIONS => {
			'IDENTIFIER' => 144,
			'STRING_LITERAL' => 119,
			'error' => 145
		},
		GOTOS => {
			'string_literal' => 227
		}
	},
	{#State 128
		DEFAULT => -369
	},
	{#State 129
		DEFAULT => -17
	},
	{#State 130
		DEFAULT => -16
	},
	{#State 131
		DEFAULT => -271
	},
	{#State 132
		ACTIONS => {
			'IDENTIFIER' => 228,
			'error' => 230
		},
		GOTOS => {
			'enumerators' => 231,
			'enumerator' => 229
		}
	},
	{#State 133
		ACTIONS => {
			"(" => 232,
			'error' => 233
		}
	},
	{#State 134
		ACTIONS => {
			'ENUM' => -394,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNION' => -394,
			'UNSIGNED' => 41,
			'error' => 235,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'STRUCT' => -394,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'member_list' => 234,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'member' => 213,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 214,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 135
		ACTIONS => {
			'LONG' => 236
		},
		DEFAULT => -231
	},
	{#State 136
		DEFAULT => -230
	},
	{#State 137
		ACTIONS => {
			'PROP_KEY' => 237
		},
		GOTOS => {
			'prop_list' => 238
		}
	},
	{#State 138
		DEFAULT => -226
	},
	{#State 139
		DEFAULT => -218
	},
	{#State 140
		ACTIONS => {
			'IDENTIFIER' => 239,
			'error' => 240
		}
	},
	{#State 141
		ACTIONS => {
			'IDENTIFIER' => 241,
			'error' => 242
		}
	},
	{#State 142
		ACTIONS => {
			'IDENTIFIER' => 243,
			'error' => 244
		}
	},
	{#State 143
		ACTIONS => {
			'IDENTIFIER' => 245,
			'error' => 246
		}
	},
	{#State 144
		DEFAULT => -61
	},
	{#State 145
		DEFAULT => -62
	},
	{#State 146
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 265,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'shift_expr' => 263,
			'literal' => 249,
			'const_exp' => 251,
			'unary_operator' => 252,
			'string_literal' => 253,
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'positive_int_const' => 272,
			'unary_expr' => 258,
			'primary_expr' => 273,
			'wide_string_literal' => 274,
			'xor_expr' => 275
		}
	},
	{#State 147
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 276,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'shift_expr' => 263,
			'literal' => 249,
			'const_exp' => 251,
			'unary_operator' => 252,
			'string_literal' => 253,
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'positive_int_const' => 277,
			'unary_expr' => 258,
			'primary_expr' => 273,
			'wide_string_literal' => 274,
			'xor_expr' => 275
		}
	},
	{#State 148
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'error' => 278,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 62,
			'object_type' => 65,
			'integer_type' => 67,
			'sequence_type' => 70,
			'unsigned_int' => 69,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'template_type_spec' => 48,
			'base_type_spec' => 81,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'signed_int' => 83,
			'string_type' => 52,
			'simple_type_spec' => 279,
			'char_type' => 54,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'fixed_pt_type' => 58,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 149
		DEFAULT => -283
	},
	{#State 150
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 280,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'shift_expr' => 263,
			'literal' => 249,
			'const_exp' => 251,
			'unary_operator' => 252,
			'string_literal' => 253,
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'positive_int_const' => 281,
			'unary_expr' => 258,
			'primary_expr' => 273,
			'wide_string_literal' => 274,
			'xor_expr' => 275
		}
	},
	{#State 151
		DEFAULT => -352
	},
	{#State 152
		DEFAULT => -301
	},
	{#State 153
		DEFAULT => -302
	},
	{#State 154
		DEFAULT => -86
	},
	{#State 155
		ACTIONS => {
			'IDENTIFIER' => 283,
			'error' => 284
		},
		GOTOS => {
			'simple_declarator' => 282
		}
	},
	{#State 156
		ACTIONS => {
			'ENUM' => -394,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNION' => -394,
			'UNSIGNED' => 41,
			'error' => 287,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'STRUCT' => -394,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'type_declarator' => 285,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 286,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 157
		ACTIONS => {
			'INTERFACE' => 288
		}
	},
	{#State 158
		ACTIONS => {
			'VALUETYPE' => 289
		}
	},
	{#State 159
		ACTIONS => {
			'IDENTIFIER' => 290,
			'error' => 291
		}
	},
	{#State 160
		ACTIONS => {
			'INTERFACE' => -35,
			'VALUETYPE' => 292,
			'error' => 293
		}
	},
	{#State 161
		ACTIONS => {
			'IDENTIFIER' => 294,
			'error' => 295
		}
	},
	{#State 162
		DEFAULT => -36
	},
	{#State 163
		DEFAULT => -26
	},
	{#State 164
		DEFAULT => -27
	},
	{#State 165
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -132
	},
	{#State 166
		DEFAULT => -129
	},
	{#State 167
		DEFAULT => -125
	},
	{#State 168
		DEFAULT => -126
	},
	{#State 169
		DEFAULT => -133
	},
	{#State 170
		DEFAULT => -130
	},
	{#State 171
		DEFAULT => -124
	},
	{#State 172
		DEFAULT => -128
	},
	{#State 173
		DEFAULT => -123
	},
	{#State 174
		ACTIONS => {
			'IDENTIFIER' => 296,
			'error' => 297
		}
	},
	{#State 175
		DEFAULT => -131
	},
	{#State 176
		DEFAULT => -353
	},
	{#State 177
		DEFAULT => -127
	},
	{#State 178
		DEFAULT => -79
	},
	{#State 179
		DEFAULT => -53
	},
	{#State 180
		DEFAULT => -295
	},
	{#State 181
		ACTIONS => {
			'CODE_FRAGMENT' => 90,
			'EXCEPTION' => 91,
			"[" => 42,
			'CONST' => 97
		},
		DEFAULT => -394,
		GOTOS => {
			'union_type' => 88,
			'enum_type' => 92,
			'enum_header' => 35,
			'type_dcl_def' => 93,
			'struct_type' => 89,
			'union_header' => 39,
			'props' => 298,
			'struct_header' => 40,
			'constr_forward_decl' => 95
		}
	},
	{#State 182
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 299
		}
	},
	{#State 183
		DEFAULT => -99
	},
	{#State 184
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 300
		}
	},
	{#State 185
		ACTIONS => {
			"}" => -82,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -392,
		GOTOS => {
			'op_header' => 188,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 194,
			'export' => 183,
			'type_dcl' => 184,
			'value_elements' => 301,
			'value_element' => 185,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'type_id_dcl' => 198,
			'init_dcl' => 197
		}
	},
	{#State 186
		DEFAULT => -296
	},
	{#State 187
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 302
		}
	},
	{#State 188
		ACTIONS => {
			"(" => 303,
			'error' => 304
		},
		GOTOS => {
			'parameter_dcls' => 305
		}
	},
	{#State 189
		ACTIONS => {
			'RAISES' => 306
		},
		DEFAULT => -331,
		GOTOS => {
			'raises_expr' => 307
		}
	},
	{#State 190
		ACTIONS => {
			"(" => 308,
			'error' => 309
		}
	},
	{#State 191
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 310
		}
	},
	{#State 192
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 311
		}
	},
	{#State 193
		ACTIONS => {
			"}" => 312
		}
	},
	{#State 194
		DEFAULT => -100
	},
	{#State 195
		ACTIONS => {
			"}" => 313
		}
	},
	{#State 196
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 314
		}
	},
	{#State 197
		DEFAULT => -101
	},
	{#State 198
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 315
		}
	},
	{#State 199
		DEFAULT => -30
	},
	{#State 200
		DEFAULT => -43
	},
	{#State 201
		ACTIONS => {
			"}" => -41,
			'TYPEID' => 25,
			'DECLSPEC' => 29,
			'TYPEPREFIX' => 31
		},
		DEFAULT => -392,
		GOTOS => {
			'op_header' => 188,
			'init_header_param' => 189,
			'code_frag' => 179,
			'readonly_attr_spec' => 180,
			'init_header' => 190,
			'op_dcl' => 191,
			'exports' => 316,
			'attr_dcl' => 192,
			'declspec' => 181,
			'except_dcl' => 182,
			'state_member' => 205,
			'type_dcl' => 184,
			'export' => 200,
			'_export' => 201,
			'exception_header' => 15,
			'attr_spec' => 186,
			'const_dcl' => 187,
			'type_prefix_dcl' => 196,
			'init_dcl' => 206,
			'type_id_dcl' => 198
		}
	},
	{#State 202
		ACTIONS => {
			"}" => 317
		}
	},
	{#State 203
		DEFAULT => -40
	},
	{#State 204
		ACTIONS => {
			"}" => 318
		}
	},
	{#State 205
		DEFAULT => -44
	},
	{#State 206
		DEFAULT => -45
	},
	{#State 207
		DEFAULT => -19
	},
	{#State 208
		DEFAULT => -73
	},
	{#State 209
		ACTIONS => {
			"}" => 319
		}
	},
	{#State 210
		ACTIONS => {
			"}" => 320
		}
	},
	{#State 211
		DEFAULT => -297
	},
	{#State 212
		ACTIONS => {
			"}" => 321
		}
	},
	{#State 213
		ACTIONS => {
			"}" => -243,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		DEFAULT => -394,
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'member_list' => 322,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'member' => 213,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 214,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 214
		ACTIONS => {
			'IDENTIFIER' => 324,
			'error' => 284
		},
		GOTOS => {
			'declarators' => 326,
			'array_declarator' => 327,
			'simple_declarator' => 323,
			'declarator' => 325,
			'complex_declarator' => 328
		}
	},
	{#State 215
		ACTIONS => {
			"}" => 329
		}
	},
	{#State 216
		DEFAULT => -9
	},
	{#State 217
		DEFAULT => -25
	},
	{#State 218
		DEFAULT => -24
	},
	{#State 219
		ACTIONS => {
			"}" => 330
		}
	},
	{#State 220
		ACTIONS => {
			"}" => 331
		}
	},
	{#State 221
		DEFAULT => -359
	},
	{#State 222
		DEFAULT => -169
	},
	{#State 223
		DEFAULT => -363
	},
	{#State 224
		DEFAULT => -364
	},
	{#State 225
		DEFAULT => -366
	},
	{#State 226
		DEFAULT => -367
	},
	{#State 227
		DEFAULT => -368
	},
	{#State 228
		DEFAULT => -278
	},
	{#State 229
		ACTIONS => {
			";" => 332,
			"," => 333
		},
		DEFAULT => -274
	},
	{#State 230
		ACTIONS => {
			"}" => 334
		}
	},
	{#State 231
		ACTIONS => {
			"}" => 335
		}
	},
	{#State 232
		ACTIONS => {
			'ENUM' => -394,
			"::" => 63,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'CHAR' => 64,
			'BOOLEAN' => 82,
			'UNSIGNED' => 41,
			'error' => 342,
			"[" => 42,
			'LONG' => 336
		},
		GOTOS => {
			'signed_longlong_int' => 45,
			'enum_type' => 337,
			'integer_type' => 341,
			'unsigned_long_int' => 50,
			'unsigned_int' => 69,
			'scoped_name' => 338,
			'enum_header' => 35,
			'signed_int' => 83,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'props' => 339,
			'char_type' => 340,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'boolean_type' => 344,
			'switch_type_spec' => 343
		}
	},
	{#State 233
		DEFAULT => -250
	},
	{#State 234
		ACTIONS => {
			"}" => 345
		}
	},
	{#State 235
		ACTIONS => {
			"}" => 346
		}
	},
	{#State 236
		DEFAULT => -232
	},
	{#State 237
		ACTIONS => {
			'PROP_VALUE' => 347
		},
		DEFAULT => -399
	},
	{#State 238
		ACTIONS => {
			"," => 349,
			"]" => 348
		}
	},
	{#State 239
		DEFAULT => -63
	},
	{#State 240
		DEFAULT => -64
	},
	{#State 241
		DEFAULT => -241
	},
	{#State 242
		DEFAULT => -242
	},
	{#State 243
		DEFAULT => -272
	},
	{#State 244
		DEFAULT => -273
	},
	{#State 245
		DEFAULT => -251
	},
	{#State 246
		DEFAULT => -252
	},
	{#State 247
		DEFAULT => -153
	},
	{#State 248
		DEFAULT => -155
	},
	{#State 249
		DEFAULT => -157
	},
	{#State 250
		DEFAULT => -173
	},
	{#State 251
		DEFAULT => -174
	},
	{#State 252
		ACTIONS => {
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'literal' => 249,
			'primary_expr' => 350,
			'scoped_name' => 256,
			'wide_string_literal' => 274,
			'boolean_literal' => 269,
			'string_literal' => 253
		}
	},
	{#State 253
		DEFAULT => -161
	},
	{#State 254
		ACTIONS => {
			"&" => 351
		},
		DEFAULT => -137
	},
	{#State 255
		ACTIONS => {
			"|" => 352
		},
		DEFAULT => -134
	},
	{#State 256
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -156
	},
	{#State 257
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 354,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'shift_expr' => 263,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 258,
			'unary_operator' => 252,
			'const_exp' => 353,
			'xor_expr' => 275,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 258
		DEFAULT => -147
	},
	{#State 259
		DEFAULT => -164
	},
	{#State 260
		DEFAULT => -172
	},
	{#State 261
		DEFAULT => -154
	},
	{#State 262
		DEFAULT => -160
	},
	{#State 263
		ACTIONS => {
			"<<" => 356,
			">>" => 355
		},
		DEFAULT => -139
	},
	{#State 264
		DEFAULT => -166
	},
	{#State 265
		ACTIONS => {
			">" => 357
		}
	},
	{#State 266
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 266
		},
		DEFAULT => -170,
		GOTOS => {
			'wide_string_literal' => 358
		}
	},
	{#State 267
		DEFAULT => -163
	},
	{#State 268
		ACTIONS => {
			"%" => 359,
			"*" => 360,
			"/" => 361
		},
		DEFAULT => -144
	},
	{#State 269
		DEFAULT => -167
	},
	{#State 270
		ACTIONS => {
			"-" => 362,
			"+" => 363
		},
		DEFAULT => -141
	},
	{#State 271
		DEFAULT => -165
	},
	{#State 272
		ACTIONS => {
			">" => 364
		}
	},
	{#State 273
		DEFAULT => -152
	},
	{#State 274
		DEFAULT => -162
	},
	{#State 275
		ACTIONS => {
			"^" => 365
		},
		DEFAULT => -135
	},
	{#State 276
		ACTIONS => {
			">" => 366
		}
	},
	{#State 277
		ACTIONS => {
			">" => 367
		}
	},
	{#State 278
		ACTIONS => {
			">" => 368
		}
	},
	{#State 279
		ACTIONS => {
			"," => 370,
			">" => 369
		}
	},
	{#State 280
		ACTIONS => {
			">" => 371
		}
	},
	{#State 281
		ACTIONS => {
			"," => 372
		}
	},
	{#State 282
		ACTIONS => {
			"(" => 373
		},
		DEFAULT => -180
	},
	{#State 283
		DEFAULT => -212
	},
	{#State 284
		ACTIONS => {
			";" => 374,
			"," => 375
		}
	},
	{#State 285
		DEFAULT => -176
	},
	{#State 286
		ACTIONS => {
			'IDENTIFIER' => 324,
			'error' => 284
		},
		GOTOS => {
			'declarators' => 376,
			'array_declarator' => 327,
			'simple_declarator' => 323,
			'declarator' => 325,
			'complex_declarator' => 328
		}
	},
	{#State 287
		DEFAULT => -184
	},
	{#State 288
		ACTIONS => {
			'IDENTIFIER' => 377,
			'error' => 378
		}
	},
	{#State 289
		ACTIONS => {
			'IDENTIFIER' => 379,
			'error' => 380
		}
	},
	{#State 290
		ACTIONS => {
			"{" => -241
		},
		DEFAULT => -355
	},
	{#State 291
		ACTIONS => {
			"{" => -242
		},
		DEFAULT => -356
	},
	{#State 292
		ACTIONS => {
			'IDENTIFIER' => 381,
			'error' => 382
		}
	},
	{#State 293
		DEFAULT => -78
	},
	{#State 294
		ACTIONS => {
			'SWITCH' => -251
		},
		DEFAULT => -357
	},
	{#State 295
		ACTIONS => {
			'SWITCH' => -252
		},
		DEFAULT => -358
	},
	{#State 296
		ACTIONS => {
			'error' => 383,
			"=" => 384
		}
	},
	{#State 297
		DEFAULT => -122
	},
	{#State 298
		ACTIONS => {
			'FACTORY' => 387,
			'ENUM' => 142,
			'PRIVATE' => 388,
			'ONEWAY' => 389,
			'UNION' => 161,
			'NATIVE' => 155,
			'TYPEDEF' => 156,
			'ATTRIBUTE' => 390,
			'PUBLIC' => 392,
			'STRUCT' => 159,
			'READONLY' => 393
		},
		DEFAULT => -308,
		GOTOS => {
			'op_mod' => 386,
			'op_attribute' => 385,
			'state_mod' => 391
		}
	},
	{#State 299
		DEFAULT => -48
	},
	{#State 300
		DEFAULT => -46
	},
	{#State 301
		DEFAULT => -83
	},
	{#State 302
		DEFAULT => -47
	},
	{#State 303
		ACTIONS => {
			"::" => -394,
			'CHAR' => -394,
			'OBJECT' => -394,
			'STRING' => -394,
			'OCTET' => -394,
			'WSTRING' => -394,
			'UNSIGNED' => -394,
			'error' => 397,
			"[" => 42,
			'ANY' => -394,
			'FLOAT' => -394,
			")" => 398,
			'LONG' => -394,
			'SEQUENCE' => -394,
			'DOUBLE' => -394,
			'IDENTIFIER' => -394,
			'SHORT' => -394,
			'BOOLEAN' => -394,
			'INOUT' => -394,
			"..." => 399,
			'OUT' => -394,
			'IN' => -394,
			'VOID' => -394,
			'FIXED' => -394,
			'VALUEBASE' => -394,
			'WCHAR' => -394
		},
		GOTOS => {
			'props' => 395,
			'param_dcl' => 394,
			'param_dcls' => 396
		}
	},
	{#State 304
		DEFAULT => -304
	},
	{#State 305
		ACTIONS => {
			'RAISES' => 306
		},
		DEFAULT => -331,
		GOTOS => {
			'raises_expr' => 400
		}
	},
	{#State 306
		ACTIONS => {
			"(" => 401,
			'error' => 402
		}
	},
	{#State 307
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 403
		}
	},
	{#State 308
		ACTIONS => {
			'error' => 406,
			")" => 407,
			'IN' => 409
		},
		GOTOS => {
			'init_param_decl' => 405,
			'init_param_decls' => 408,
			'init_param_attribute' => 404
		}
	},
	{#State 309
		DEFAULT => -111
	},
	{#State 310
		DEFAULT => -50
	},
	{#State 311
		DEFAULT => -49
	},
	{#State 312
		DEFAULT => -81
	},
	{#State 313
		DEFAULT => -80
	},
	{#State 314
		DEFAULT => -52
	},
	{#State 315
		DEFAULT => -51
	},
	{#State 316
		DEFAULT => -42
	},
	{#State 317
		DEFAULT => -31
	},
	{#State 318
		DEFAULT => -32
	},
	{#State 319
		DEFAULT => -74
	},
	{#State 320
		DEFAULT => -75
	},
	{#State 321
		DEFAULT => -298
	},
	{#State 322
		DEFAULT => -244
	},
	{#State 323
		DEFAULT => -210
	},
	{#State 324
		ACTIONS => {
			"[" => 411
		},
		DEFAULT => -212,
		GOTOS => {
			'fixed_array_sizes' => 410,
			'fixed_array_size' => 412
		}
	},
	{#State 325
		ACTIONS => {
			"," => 413
		},
		DEFAULT => -208
	},
	{#State 326
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 414
		}
	},
	{#State 327
		DEFAULT => -215
	},
	{#State 328
		DEFAULT => -211
	},
	{#State 329
		DEFAULT => -299
	},
	{#State 330
		DEFAULT => -22
	},
	{#State 331
		DEFAULT => -23
	},
	{#State 332
		DEFAULT => -277
	},
	{#State 333
		ACTIONS => {
			'IDENTIFIER' => 228
		},
		DEFAULT => -276,
		GOTOS => {
			'enumerators' => 415,
			'enumerator' => 229
		}
	},
	{#State 334
		DEFAULT => -270
	},
	{#State 335
		DEFAULT => -269
	},
	{#State 336
		ACTIONS => {
			'LONG' => 138
		},
		DEFAULT => -225
	},
	{#State 337
		DEFAULT => -256
	},
	{#State 338
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -257
	},
	{#State 339
		ACTIONS => {
			'ENUM' => 142
		}
	},
	{#State 340
		DEFAULT => -254
	},
	{#State 341
		DEFAULT => -253
	},
	{#State 342
		ACTIONS => {
			")" => 416
		}
	},
	{#State 343
		ACTIONS => {
			")" => 417
		}
	},
	{#State 344
		DEFAULT => -255
	},
	{#State 345
		DEFAULT => -239
	},
	{#State 346
		DEFAULT => -240
	},
	{#State 347
		DEFAULT => -397
	},
	{#State 348
		DEFAULT => -396
	},
	{#State 349
		ACTIONS => {
			'PROP_KEY' => 418
		}
	},
	{#State 350
		DEFAULT => -151
	},
	{#State 351
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'mult_expr' => 268,
			'shift_expr' => 419,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 258,
			'unary_operator' => 252,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 352
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'and_expr' => 254,
			'mult_expr' => 268,
			'shift_expr' => 263,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 258,
			'unary_operator' => 252,
			'xor_expr' => 420,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 353
		ACTIONS => {
			")" => 421
		}
	},
	{#State 354
		ACTIONS => {
			")" => 422
		}
	},
	{#State 355
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'mult_expr' => 268,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'literal' => 249,
			'add_expr' => 423,
			'primary_expr' => 273,
			'unary_expr' => 258,
			'unary_operator' => 252,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 356
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'mult_expr' => 268,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'literal' => 249,
			'add_expr' => 424,
			'primary_expr' => 273,
			'unary_expr' => 258,
			'unary_operator' => 252,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 357
		DEFAULT => -286
	},
	{#State 358
		DEFAULT => -171
	},
	{#State 359
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 425,
			'unary_operator' => 252,
			'scoped_name' => 256,
			'wide_string_literal' => 274,
			'boolean_literal' => 269,
			'string_literal' => 253
		}
	},
	{#State 360
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 426,
			'unary_operator' => 252,
			'scoped_name' => 256,
			'wide_string_literal' => 274,
			'boolean_literal' => 269,
			'string_literal' => 253
		}
	},
	{#State 361
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 427,
			'unary_operator' => 252,
			'scoped_name' => 256,
			'wide_string_literal' => 274,
			'boolean_literal' => 269,
			'string_literal' => 253
		}
	},
	{#State 362
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'mult_expr' => 428,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'literal' => 249,
			'unary_expr' => 258,
			'primary_expr' => 273,
			'unary_operator' => 252,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 363
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'mult_expr' => 429,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'literal' => 249,
			'unary_expr' => 258,
			'primary_expr' => 273,
			'unary_operator' => 252,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 364
		DEFAULT => -284
	},
	{#State 365
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			'IDENTIFIER' => 49,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FIXED_PT_LITERAL' => 271,
			"(" => 257,
			'FALSE' => 250,
			'STRING_LITERAL' => 119,
			'WIDE_STRING_LITERAL' => 266,
			'WIDE_CHARACTER_LITERAL' => 259,
			'CHARACTER_LITERAL' => 267
		},
		GOTOS => {
			'and_expr' => 430,
			'mult_expr' => 268,
			'shift_expr' => 263,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 258,
			'unary_operator' => 252,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 366
		DEFAULT => -289
	},
	{#State 367
		DEFAULT => -287
	},
	{#State 368
		DEFAULT => -282
	},
	{#State 369
		DEFAULT => -281
	},
	{#State 370
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 431,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'shift_expr' => 263,
			'literal' => 249,
			'const_exp' => 251,
			'unary_operator' => 252,
			'string_literal' => 253,
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'positive_int_const' => 432,
			'unary_expr' => 258,
			'primary_expr' => 273,
			'wide_string_literal' => 274,
			'xor_expr' => 275
		}
	},
	{#State 371
		DEFAULT => -351
	},
	{#State 372
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 433,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'shift_expr' => 263,
			'literal' => 249,
			'const_exp' => 251,
			'unary_operator' => 252,
			'string_literal' => 253,
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'positive_int_const' => 434,
			'unary_expr' => 258,
			'primary_expr' => 273,
			'wide_string_literal' => 274,
			'xor_expr' => 275
		}
	},
	{#State 373
		DEFAULT => -181,
		GOTOS => {
			'@1-4' => 435
		}
	},
	{#State 374
		DEFAULT => -214
	},
	{#State 375
		DEFAULT => -213
	},
	{#State 376
		DEFAULT => -185
	},
	{#State 377
		ACTIONS => {
			":" => 436,
			"{" => -56
		},
		DEFAULT => -33,
		GOTOS => {
			'interface_inheritance_spec' => 437
		}
	},
	{#State 378
		ACTIONS => {
			"{" => -39
		},
		DEFAULT => -34
	},
	{#State 379
		ACTIONS => {
			":" => 438,
			'SUPPORTS' => 439,
			";" => -69,
			'error' => -69,
			"{" => -97
		},
		DEFAULT => -72,
		GOTOS => {
			'supported_interface_spec' => 441,
			'value_inheritance_spec' => 440
		}
	},
	{#State 380
		DEFAULT => -85
	},
	{#State 381
		ACTIONS => {
			":" => 438,
			'SUPPORTS' => 439,
			"{" => -97
		},
		DEFAULT => -70,
		GOTOS => {
			'supported_interface_spec' => 441,
			'value_inheritance_spec' => 442
		}
	},
	{#State 382
		DEFAULT => -77
	},
	{#State 383
		DEFAULT => -121
	},
	{#State 384
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 444,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'shift_expr' => 263,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 258,
			'unary_operator' => 252,
			'const_exp' => 443,
			'xor_expr' => 275,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 385
		DEFAULT => -307
	},
	{#State 386
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 447,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 449,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 450,
			'op_param_type_spec' => 451,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 452,
			'unsigned_long_int' => 50,
			'scoped_name' => 445,
			'signed_int' => 83,
			'string_type' => 446,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 448,
			'signed_short_int' => 57,
			'op_type_spec' => 453,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 387
		ACTIONS => {
			'IDENTIFIER' => 454,
			'error' => 455
		}
	},
	{#State 388
		DEFAULT => -106
	},
	{#State 389
		DEFAULT => -309
	},
	{#State 390
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'error' => 461,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 456,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 449,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 459,
			'op_param_type_spec' => 460,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 452,
			'unsigned_long_int' => 50,
			'scoped_name' => 445,
			'signed_int' => 83,
			'string_type' => 446,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 457,
			'signed_short_int' => 57,
			'param_type_spec' => 458,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 391
		ACTIONS => {
			'ENUM' => -394,
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNION' => -394,
			'UNSIGNED' => 41,
			'error' => 463,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'STRUCT' => -394,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 462,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 392
		DEFAULT => -105
	},
	{#State 393
		ACTIONS => {
			'error' => 464,
			'ATTRIBUTE' => 465
		}
	},
	{#State 394
		ACTIONS => {
			";" => 466
		},
		DEFAULT => -320
	},
	{#State 395
		ACTIONS => {
			'INOUT' => 468,
			'OUT' => 469,
			'IN' => 470
		},
		DEFAULT => -327,
		GOTOS => {
			'param_attribute' => 467
		}
	},
	{#State 396
		ACTIONS => {
			"," => 471,
			")" => 472
		}
	},
	{#State 397
		ACTIONS => {
			")" => 473
		}
	},
	{#State 398
		DEFAULT => -317
	},
	{#State 399
		ACTIONS => {
			")" => 474
		}
	},
	{#State 400
		ACTIONS => {
			'CONTEXT' => 476
		},
		DEFAULT => -338,
		GOTOS => {
			'context_expr' => 475
		}
	},
	{#State 401
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 478
		},
		GOTOS => {
			'exception_names' => 479,
			'scoped_name' => 477,
			'exception_name' => 480
		}
	},
	{#State 402
		DEFAULT => -330
	},
	{#State 403
		DEFAULT => -107
	},
	{#State 404
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'error' => 482,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 456,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 449,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 459,
			'op_param_type_spec' => 460,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 452,
			'unsigned_long_int' => 50,
			'scoped_name' => 445,
			'signed_int' => 83,
			'string_type' => 446,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 457,
			'signed_short_int' => 57,
			'param_type_spec' => 481,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 405
		ACTIONS => {
			"," => 483
		},
		DEFAULT => -114
	},
	{#State 406
		ACTIONS => {
			")" => 484
		}
	},
	{#State 407
		DEFAULT => -108
	},
	{#State 408
		ACTIONS => {
			")" => 485
		}
	},
	{#State 409
		DEFAULT => -118
	},
	{#State 410
		DEFAULT => -290
	},
	{#State 411
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 486,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'shift_expr' => 263,
			'literal' => 249,
			'const_exp' => 251,
			'unary_operator' => 252,
			'string_literal' => 253,
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'positive_int_const' => 487,
			'unary_expr' => 258,
			'primary_expr' => 273,
			'wide_string_literal' => 274,
			'xor_expr' => 275
		}
	},
	{#State 412
		ACTIONS => {
			"[" => 411
		},
		DEFAULT => -291,
		GOTOS => {
			'fixed_array_sizes' => 488,
			'fixed_array_size' => 412
		}
	},
	{#State 413
		ACTIONS => {
			'IDENTIFIER' => 324,
			'error' => 284
		},
		GOTOS => {
			'declarators' => 489,
			'array_declarator' => 327,
			'simple_declarator' => 323,
			'declarator' => 325,
			'complex_declarator' => 328
		}
	},
	{#State 414
		DEFAULT => -245
	},
	{#State 415
		DEFAULT => -275
	},
	{#State 416
		DEFAULT => -249
	},
	{#State 417
		ACTIONS => {
			"{" => 491,
			'error' => 490
		}
	},
	{#State 418
		ACTIONS => {
			'PROP_VALUE' => 492
		},
		DEFAULT => -400
	},
	{#State 419
		ACTIONS => {
			"<<" => 356,
			">>" => 355
		},
		DEFAULT => -140
	},
	{#State 420
		ACTIONS => {
			"^" => 365
		},
		DEFAULT => -136
	},
	{#State 421
		DEFAULT => -158
	},
	{#State 422
		DEFAULT => -159
	},
	{#State 423
		ACTIONS => {
			"-" => 362,
			"+" => 363
		},
		DEFAULT => -142
	},
	{#State 424
		ACTIONS => {
			"-" => 362,
			"+" => 363
		},
		DEFAULT => -143
	},
	{#State 425
		DEFAULT => -150
	},
	{#State 426
		DEFAULT => -148
	},
	{#State 427
		DEFAULT => -149
	},
	{#State 428
		ACTIONS => {
			"%" => 359,
			"*" => 360,
			"/" => 361
		},
		DEFAULT => -146
	},
	{#State 429
		ACTIONS => {
			"%" => 359,
			"*" => 360,
			"/" => 361
		},
		DEFAULT => -145
	},
	{#State 430
		ACTIONS => {
			"&" => 351
		},
		DEFAULT => -138
	},
	{#State 431
		ACTIONS => {
			">" => 493
		}
	},
	{#State 432
		ACTIONS => {
			">" => 494
		}
	},
	{#State 433
		ACTIONS => {
			">" => 495
		}
	},
	{#State 434
		ACTIONS => {
			">" => 496
		}
	},
	{#State 435
		ACTIONS => {
			'NATIVE_TYPE' => 497
		}
	},
	{#State 436
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 499
		},
		GOTOS => {
			'interface_name' => 501,
			'interface_names' => 500,
			'scoped_name' => 498
		}
	},
	{#State 437
		DEFAULT => -38
	},
	{#State 438
		ACTIONS => {
			'TRUNCATABLE' => 503
		},
		DEFAULT => -92,
		GOTOS => {
			'inheritance_mod' => 502
		}
	},
	{#State 439
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 504
		},
		GOTOS => {
			'interface_name' => 501,
			'interface_names' => 505,
			'scoped_name' => 498
		}
	},
	{#State 440
		DEFAULT => -84
	},
	{#State 441
		DEFAULT => -90
	},
	{#State 442
		DEFAULT => -76
	},
	{#State 443
		DEFAULT => -119
	},
	{#State 444
		DEFAULT => -120
	},
	{#State 445
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -348
	},
	{#State 446
		DEFAULT => -346
	},
	{#State 447
		DEFAULT => -311
	},
	{#State 448
		DEFAULT => -313
	},
	{#State 449
		DEFAULT => -347
	},
	{#State 450
		DEFAULT => -312
	},
	{#State 451
		DEFAULT => -310
	},
	{#State 452
		DEFAULT => -345
	},
	{#State 453
		ACTIONS => {
			'IDENTIFIER' => 506,
			'error' => 507
		}
	},
	{#State 454
		DEFAULT => -112
	},
	{#State 455
		DEFAULT => -113
	},
	{#State 456
		DEFAULT => -342
	},
	{#State 457
		DEFAULT => -344
	},
	{#State 458
		ACTIONS => {
			'IDENTIFIER' => 283,
			'error' => 284
		},
		GOTOS => {
			'attr_declarator' => 509,
			'simple_declarator' => 508
		}
	},
	{#State 459
		DEFAULT => -343
	},
	{#State 460
		DEFAULT => -341
	},
	{#State 461
		DEFAULT => -378
	},
	{#State 462
		ACTIONS => {
			'IDENTIFIER' => 324,
			'error' => 510
		},
		GOTOS => {
			'declarators' => 511,
			'array_declarator' => 327,
			'simple_declarator' => 323,
			'declarator' => 325,
			'complex_declarator' => 328
		}
	},
	{#State 463
		ACTIONS => {
			";" => 512
		}
	},
	{#State 464
		DEFAULT => -372
	},
	{#State 465
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'error' => 514,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 456,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 449,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 459,
			'op_param_type_spec' => 460,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 452,
			'unsigned_long_int' => 50,
			'scoped_name' => 445,
			'signed_int' => 83,
			'string_type' => 446,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 457,
			'signed_short_int' => 57,
			'param_type_spec' => 513,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 466
		DEFAULT => -322
	},
	{#State 467
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'IDENTIFIER' => 49,
			'DOUBLE' => 79,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 456,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		GOTOS => {
			'wide_string_type' => 449,
			'object_type' => 65,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 459,
			'op_param_type_spec' => 460,
			'unsigned_short_int' => 36,
			'unsigned_longlong_int' => 72,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'signed_longlong_int' => 45,
			'any_type' => 47,
			'base_type_spec' => 452,
			'unsigned_long_int' => 50,
			'scoped_name' => 445,
			'signed_int' => 83,
			'string_type' => 446,
			'char_type' => 54,
			'signed_long_int' => 56,
			'fixed_pt_type' => 457,
			'signed_short_int' => 57,
			'param_type_spec' => 515,
			'boolean_type' => 86,
			'wide_char_type' => 59,
			'octet_type' => 61
		}
	},
	{#State 468
		DEFAULT => -326
	},
	{#State 469
		DEFAULT => -325
	},
	{#State 470
		DEFAULT => -324
	},
	{#State 471
		ACTIONS => {
			"[" => 42,
			")" => 517,
			"..." => 518
		},
		DEFAULT => -394,
		GOTOS => {
			'props' => 395,
			'param_dcl' => 516
		}
	},
	{#State 472
		DEFAULT => -314
	},
	{#State 473
		DEFAULT => -319
	},
	{#State 474
		DEFAULT => -318
	},
	{#State 475
		DEFAULT => -303
	},
	{#State 476
		ACTIONS => {
			"(" => 519,
			'error' => 520
		}
	},
	{#State 477
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -334
	},
	{#State 478
		ACTIONS => {
			")" => 521
		}
	},
	{#State 479
		ACTIONS => {
			")" => 522
		}
	},
	{#State 480
		ACTIONS => {
			"," => 523
		},
		DEFAULT => -332
	},
	{#State 481
		ACTIONS => {
			'IDENTIFIER' => 283,
			'error' => 284
		},
		GOTOS => {
			'simple_declarator' => 524
		}
	},
	{#State 482
		DEFAULT => -117
	},
	{#State 483
		ACTIONS => {
			'IN' => 409
		},
		GOTOS => {
			'init_param_decl' => 405,
			'init_param_decls' => 525,
			'init_param_attribute' => 404
		}
	},
	{#State 484
		DEFAULT => -110
	},
	{#State 485
		DEFAULT => -109
	},
	{#State 486
		ACTIONS => {
			"]" => 526
		}
	},
	{#State 487
		ACTIONS => {
			"]" => 527
		}
	},
	{#State 488
		DEFAULT => -292
	},
	{#State 489
		DEFAULT => -209
	},
	{#State 490
		DEFAULT => -248
	},
	{#State 491
		ACTIONS => {
			'DEFAULT' => 533,
			'error' => 531,
			'CASE' => 528
		},
		GOTOS => {
			'case_label' => 534,
			'switch_body' => 529,
			'case' => 530,
			'case_labels' => 532
		}
	},
	{#State 492
		DEFAULT => -398
	},
	{#State 493
		DEFAULT => -280
	},
	{#State 494
		DEFAULT => -279
	},
	{#State 495
		DEFAULT => -350
	},
	{#State 496
		DEFAULT => -349
	},
	{#State 497
		DEFAULT => -182
	},
	{#State 498
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -59
	},
	{#State 499
		DEFAULT => -55
	},
	{#State 500
		DEFAULT => -54
	},
	{#State 501
		ACTIONS => {
			"," => 535
		},
		DEFAULT => -57
	},
	{#State 502
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 539
		},
		GOTOS => {
			'value_name' => 536,
			'value_names' => 537,
			'scoped_name' => 538
		}
	},
	{#State 503
		DEFAULT => -91
	},
	{#State 504
		DEFAULT => -96
	},
	{#State 505
		DEFAULT => -95
	},
	{#State 506
		DEFAULT => -305
	},
	{#State 507
		DEFAULT => -306
	},
	{#State 508
		ACTIONS => {
			'SETRAISES' => 545,
			'GETRAISES' => 541,
			"," => 542
		},
		DEFAULT => -384,
		GOTOS => {
			'get_except_expr' => 543,
			'attr_raises_expr' => 540,
			'set_except_expr' => 544
		}
	},
	{#State 509
		DEFAULT => -377
	},
	{#State 510
		ACTIONS => {
			";" => 546,
			"," => 375
		}
	},
	{#State 511
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 547
		}
	},
	{#State 512
		DEFAULT => -104
	},
	{#State 513
		ACTIONS => {
			'IDENTIFIER' => 283,
			'error' => 284
		},
		GOTOS => {
			'readonly_attr_declarator' => 548,
			'simple_declarator' => 549
		}
	},
	{#State 514
		DEFAULT => -371
	},
	{#State 515
		ACTIONS => {
			'IDENTIFIER' => 283,
			'error' => 284
		},
		GOTOS => {
			'simple_declarator' => 550
		}
	},
	{#State 516
		DEFAULT => -321
	},
	{#State 517
		DEFAULT => -316
	},
	{#State 518
		ACTIONS => {
			")" => 551
		}
	},
	{#State 519
		ACTIONS => {
			'STRING_LITERAL' => 119,
			'error' => 554
		},
		GOTOS => {
			'string_literals' => 553,
			'string_literal' => 552
		}
	},
	{#State 520
		DEFAULT => -337
	},
	{#State 521
		DEFAULT => -329
	},
	{#State 522
		DEFAULT => -328
	},
	{#State 523
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49
		},
		GOTOS => {
			'exception_names' => 555,
			'scoped_name' => 477,
			'exception_name' => 480
		}
	},
	{#State 524
		DEFAULT => -116
	},
	{#State 525
		DEFAULT => -115
	},
	{#State 526
		DEFAULT => -294
	},
	{#State 527
		DEFAULT => -293
	},
	{#State 528
		ACTIONS => {
			"-" => 247,
			"::" => 63,
			'TRUE' => 260,
			"+" => 261,
			"~" => 248,
			'INTEGER_LITERAL' => 262,
			'FLOATING_PT_LITERAL' => 264,
			'FALSE' => 250,
			'error' => 557,
			'WIDE_STRING_LITERAL' => 266,
			'CHARACTER_LITERAL' => 267,
			'IDENTIFIER' => 49,
			"(" => 257,
			'FIXED_PT_LITERAL' => 271,
			'STRING_LITERAL' => 119,
			'WIDE_CHARACTER_LITERAL' => 259
		},
		GOTOS => {
			'and_expr' => 254,
			'or_expr' => 255,
			'mult_expr' => 268,
			'shift_expr' => 263,
			'scoped_name' => 256,
			'boolean_literal' => 269,
			'add_expr' => 270,
			'literal' => 249,
			'primary_expr' => 273,
			'unary_expr' => 258,
			'unary_operator' => 252,
			'const_exp' => 556,
			'xor_expr' => 275,
			'wide_string_literal' => 274,
			'string_literal' => 253
		}
	},
	{#State 529
		ACTIONS => {
			"}" => 558
		}
	},
	{#State 530
		ACTIONS => {
			'DEFAULT' => 533,
			'CASE' => 528
		},
		DEFAULT => -258,
		GOTOS => {
			'case_label' => 534,
			'switch_body' => 559,
			'case' => 530,
			'case_labels' => 532
		}
	},
	{#State 531
		ACTIONS => {
			"}" => 560
		}
	},
	{#State 532
		ACTIONS => {
			"::" => 63,
			'CHAR' => 64,
			'OBJECT' => 68,
			'STRING' => 71,
			'OCTET' => 37,
			'WSTRING' => 73,
			'UNSIGNED' => 41,
			"[" => 42,
			'ANY' => 43,
			'FLOAT' => 76,
			'LONG' => 44,
			'SEQUENCE' => 78,
			'DOUBLE' => 79,
			'IDENTIFIER' => 49,
			'SHORT' => 80,
			'BOOLEAN' => 82,
			'VOID' => 55,
			'FIXED' => 85,
			'VALUEBASE' => 87,
			'WCHAR' => 60
		},
		DEFAULT => -394,
		GOTOS => {
			'union_type' => 34,
			'enum_header' => 35,
			'unsigned_short_int' => 36,
			'struct_type' => 38,
			'union_header' => 39,
			'struct_header' => 40,
			'signed_longlong_int' => 45,
			'enum_type' => 46,
			'any_type' => 47,
			'template_type_spec' => 48,
			'element_spec' => 561,
			'unsigned_long_int' => 50,
			'scoped_name' => 51,
			'string_type' => 52,
			'props' => 53,
			'char_type' => 54,
			'fixed_pt_type' => 58,
			'signed_short_int' => 57,
			'signed_long_int' => 56,
			'wide_char_type' => 59,
			'octet_type' => 61,
			'wide_string_type' => 62,
			'object_type' => 65,
			'type_spec' => 562,
			'integer_type' => 67,
			'unsigned_int' => 69,
			'sequence_type' => 70,
			'unsigned_longlong_int' => 72,
			'constr_type_spec' => 74,
			'floating_pt_type' => 75,
			'value_base_type' => 77,
			'base_type_spec' => 81,
			'signed_int' => 83,
			'simple_type_spec' => 84,
			'boolean_type' => 86
		}
	},
	{#State 533
		ACTIONS => {
			":" => 563,
			'error' => 564
		}
	},
	{#State 534
		ACTIONS => {
			'CASE' => 528,
			'DEFAULT' => 533
		},
		DEFAULT => -261,
		GOTOS => {
			'case_label' => 534,
			'case_labels' => 565
		}
	},
	{#State 535
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49
		},
		GOTOS => {
			'interface_name' => 501,
			'interface_names' => 566,
			'scoped_name' => 498
		}
	},
	{#State 536
		ACTIONS => {
			"," => 567
		},
		DEFAULT => -93
	},
	{#State 537
		ACTIONS => {
			'SUPPORTS' => 439
		},
		DEFAULT => -97,
		GOTOS => {
			'supported_interface_spec' => 568
		}
	},
	{#State 538
		ACTIONS => {
			"::" => 140
		},
		DEFAULT => -98
	},
	{#State 539
		DEFAULT => -89
	},
	{#State 540
		DEFAULT => -379
	},
	{#State 541
		ACTIONS => {
			"(" => 570,
			'error' => 571
		},
		GOTOS => {
			'exception_list' => 569
		}
	},
	{#State 542
		ACTIONS => {
			'IDENTIFIER' => 283,
			'error' => 284
		},
		GOTOS => {
			'simple_declarators' => 573,
			'simple_declarator' => 572
		}
	},
	{#State 543
		ACTIONS => {
			'SETRAISES' => 545
		},
		DEFAULT => -382,
		GOTOS => {
			'set_except_expr' => 574
		}
	},
	{#State 544
		DEFAULT => -383
	},
	{#State 545
		ACTIONS => {
			"(" => 570,
			'error' => 576
		},
		GOTOS => {
			'exception_list' => 575
		}
	},
	{#State 546
		ACTIONS => {
			";" => -214,
			"," => -214,
			'error' => -214
		},
		DEFAULT => -103
	},
	{#State 547
		DEFAULT => -102
	},
	{#State 548
		DEFAULT => -370
	},
	{#State 549
		ACTIONS => {
			'RAISES' => 306,
			"," => 577
		},
		DEFAULT => -331,
		GOTOS => {
			'raises_expr' => 578
		}
	},
	{#State 550
		DEFAULT => -323
	},
	{#State 551
		DEFAULT => -315
	},
	{#State 552
		ACTIONS => {
			"," => 579
		},
		DEFAULT => -339
	},
	{#State 553
		ACTIONS => {
			")" => 580
		}
	},
	{#State 554
		ACTIONS => {
			")" => 581
		}
	},
	{#State 555
		DEFAULT => -333
	},
	{#State 556
		ACTIONS => {
			":" => 582,
			'error' => 583
		}
	},
	{#State 557
		DEFAULT => -265
	},
	{#State 558
		DEFAULT => -246
	},
	{#State 559
		DEFAULT => -259
	},
	{#State 560
		DEFAULT => -247
	},
	{#State 561
		ACTIONS => {
			";" => 99,
			'error' => 100
		},
		GOTOS => {
			'check_semicolon' => 584
		}
	},
	{#State 562
		ACTIONS => {
			'IDENTIFIER' => 324,
			'error' => 284
		},
		GOTOS => {
			'array_declarator' => 327,
			'simple_declarator' => 323,
			'declarator' => 585,
			'complex_declarator' => 328
		}
	},
	{#State 563
		DEFAULT => -266
	},
	{#State 564
		DEFAULT => -267
	},
	{#State 565
		DEFAULT => -262
	},
	{#State 566
		DEFAULT => -58
	},
	{#State 567
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49
		},
		GOTOS => {
			'value_name' => 536,
			'value_names' => 586,
			'scoped_name' => 538
		}
	},
	{#State 568
		DEFAULT => -88
	},
	{#State 569
		DEFAULT => -385
	},
	{#State 570
		ACTIONS => {
			"::" => 63,
			'IDENTIFIER' => 49,
			'error' => 587
		},
		GOTOS => {
			'exception_names' => 588,
			'scoped_name' => 477,
			'exception_name' => 480
		}
	},
	{#State 571
		DEFAULT => -386
	},
	{#State 572
		ACTIONS => {
			"," => 589
		},
		DEFAULT => -375
	},
	{#State 573
		DEFAULT => -380
	},
	{#State 574
		DEFAULT => -381
	},
	{#State 575
		DEFAULT => -387
	},
	{#State 576
		DEFAULT => -388
	},
	{#State 577
		ACTIONS => {
			'IDENTIFIER' => 283,
			'error' => 284
		},
		GOTOS => {
			'simple_declarators' => 590,
			'simple_declarator' => 572
		}
	},
	{#State 578
		DEFAULT => -373
	},
	{#State 579
		ACTIONS => {
			'STRING_LITERAL' => 119
		},
		GOTOS => {
			'string_literals' => 591,
			'string_literal' => 552
		}
	},
	{#State 580
		DEFAULT => -335
	},
	{#State 581
		DEFAULT => -336
	},
	{#State 582
		DEFAULT => -263
	},
	{#State 583
		DEFAULT => -264
	},
	{#State 584
		DEFAULT => -260
	},
	{#State 585
		DEFAULT => -268
	},
	{#State 586
		DEFAULT => -94
	},
	{#State 587
		ACTIONS => {
			")" => 592
		}
	},
	{#State 588
		ACTIONS => {
			")" => 593
		}
	},
	{#State 589
		ACTIONS => {
			'IDENTIFIER' => 283,
			'error' => 284
		},
		GOTOS => {
			'simple_declarators' => 594,
			'simple_declarator' => 572
		}
	},
	{#State 590
		DEFAULT => -374
	},
	{#State 591
		DEFAULT => -340
	},
	{#State 592
		DEFAULT => -390
	},
	{#State 593
		DEFAULT => -389
	},
	{#State 594
		DEFAULT => -376
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
#line 79 "parserxp.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 2,
sub
#line 85 "parserxp.yp"
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
#line 92 "parserxp.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 4
		 'specification', 1,
sub
#line 96 "parserxp.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 5
		 'imports', 1,
sub
#line 103 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 6
		 'imports', 2,
sub
#line 107 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 7
		 'definitions', 1,
sub
#line 115 "parserxp.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 8
		 'definitions', 2,
sub
#line 119 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 9
		 'definitions', 3,
sub
#line 124 "parserxp.yp"
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
		 'definition', 1, undef
	],
	[#Rule 19
		 'definition', 3,
sub
#line 152 "parserxp.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new CORBA::IDL::node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 20
		 'check_semicolon', 1, undef
	],
	[#Rule 21
		 'check_semicolon', 1,
sub
#line 166 "parserxp.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 22
		 'module', 4,
sub
#line 175 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 23
		 'module', 4,
sub
#line 182 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 24
		 'module', 3,
sub
#line 189 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 25
		 'module', 3,
sub
#line 196 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 26
		 'module_header', 3,
sub
#line 206 "parserxp.yp"
{
			new Module($_[0],
					'declspec'			=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 27
		 'module_header', 3,
sub
#line 213 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface', 1, undef
	],
	[#Rule 29
		 'interface', 1, undef
	],
	[#Rule 30
		 'interface_dcl', 3,
sub
#line 230 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 31
		 'interface_dcl', 4,
sub
#line 238 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 32
		 'interface_dcl', 4,
sub
#line 246 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 33
		 'forward_dcl', 5,
sub
#line 258 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[2]);
			if (defined $_[3] and $_[3] eq 'abstract') {
				new ForwardAbstractInterface($_[0],
						'declspec'				=>	$_[1],
						'idf'					=>	$_[5]
				);
			} elsif (defined $_[3] and $_[3] eq 'local') {
				new ForwardLocalInterface($_[0],
						'declspec'				=>	$_[1],
						'idf'					=>	$_[5]
				);
			} else {
				new ForwardRegularInterface($_[0],
						'declspec'				=>	$_[1],
						'idf'					=>	$_[5]
				);
			}
		}
	],
	[#Rule 34
		 'forward_dcl', 5,
sub
#line 279 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 35
		 'interface_mod', 1, undef
	],
	[#Rule 36
		 'interface_mod', 1, undef
	],
	[#Rule 37
		 'interface_mod', 0, undef
	],
	[#Rule 38
		 'interface_header', 6,
sub
#line 297 "parserxp.yp"
{
			if (defined $_[3] and $_[3] eq 'abstract') {
				new AbstractInterface($_[0],
						'declspec'				=>	$_[1],
						'props'					=>	$_[2],
						'idf'					=>	$_[5],
						'inheritance'			=>	$_[6]
				);
			} elsif (defined $_[3] and $_[3] eq 'local') {
				new LocalInterface($_[0],
						'declspec'				=>	$_[1],
						'props'					=>	$_[2],
						'idf'					=>	$_[5],
						'inheritance'			=>	$_[6]
				);
			} else {
				new RegularInterface($_[0],
						'declspec'				=>	$_[1],
						'props'					=>	$_[2],
						'idf'					=>	$_[5],
						'inheritance'			=>	$_[6]
				);
			}
		}
	],
	[#Rule 39
		 'interface_header', 5,
sub
#line 322 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 40
		 'interface_body', 1, undef
	],
	[#Rule 41
		 'exports', 1,
sub
#line 336 "parserxp.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 42
		 'exports', 2,
sub
#line 340 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 43
		 '_export', 1, undef
	],
	[#Rule 44
		 '_export', 1,
sub
#line 351 "parserxp.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 45
		 '_export', 1,
sub
#line 356 "parserxp.yp"
{
			$_[0]->Error("initializer unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 46
		 'export', 2, undef
	],
	[#Rule 47
		 'export', 2, undef
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
		 'export', 1, undef
	],
	[#Rule 54
		 'interface_inheritance_spec', 2,
sub
#line 384 "parserxp.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 55
		 'interface_inheritance_spec', 2,
sub
#line 390 "parserxp.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 56
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 57
		 'interface_names', 1,
sub
#line 400 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 58
		 'interface_names', 3,
sub
#line 404 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 59
		 'interface_name', 1,
sub
#line 413 "parserxp.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 60
		 'scoped_name', 1, undef
	],
	[#Rule 61
		 'scoped_name', 2,
sub
#line 423 "parserxp.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 62
		 'scoped_name', 2,
sub
#line 427 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 63
		 'scoped_name', 3,
sub
#line 433 "parserxp.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 64
		 'scoped_name', 3,
sub
#line 437 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 65
		 'value', 1, undef
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
		 'value_forward_dcl', 5,
sub
#line 459 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[2]);
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[3]);
			new ForwardRegularValue($_[0],
					'declspec'			=>	$_[1],
					'idf'				=>	$_[4]
			);
		}
	],
	[#Rule 70
		 'value_forward_dcl', 5,
sub
#line 470 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[2]);
			new ForwardAbstractValue($_[0],
					'declspec'			=>	$_[1],
					'idf'				=>	$_[5]
			);
		}
	],
	[#Rule 71
		 'value_box_dcl', 2,
sub
#line 483 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 72
		 'value_box_header', 5,
sub
#line 494 "parserxp.yp"
{
			$_[0]->Warning("CUSTOM unexpected.\n")
					if (defined $_[3]);
			new BoxedValue($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'idf'				=>	$_[4],
			);
		}
	],
	[#Rule 73
		 'value_abs_dcl', 3,
sub
#line 508 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 74
		 'value_abs_dcl', 4,
sub
#line 516 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 75
		 'value_abs_dcl', 4,
sub
#line 524 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 76
		 'value_abs_header', 6,
sub
#line 535 "parserxp.yp"
{
			new AbstractValue($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'idf'				=>	$_[5],
					'inheritance'		=>	$_[6]
			);
		}
	],
	[#Rule 77
		 'value_abs_header', 5,
sub
#line 544 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 78
		 'value_abs_header', 4,
sub
#line 549 "parserxp.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 79
		 'value_dcl', 3,
sub
#line 558 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 80
		 'value_dcl', 4,
sub
#line 566 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 81
		 'value_dcl', 4,
sub
#line 574 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 82
		 'value_elements', 1,
sub
#line 585 "parserxp.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 83
		 'value_elements', 2,
sub
#line 589 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 84
		 'value_header', 6,
sub
#line 598 "parserxp.yp"
{
			new RegularValue($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'modifier'			=>	$_[3],
					'idf'				=>	$_[5],
					'inheritance'		=>	$_[6]
			);
		}
	],
	[#Rule 85
		 'value_header', 5,
sub
#line 608 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 86
		 'value_mod', 1, undef
	],
	[#Rule 87
		 'value_mod', 0, undef
	],
	[#Rule 88
		 'value_inheritance_spec', 4,
sub
#line 624 "parserxp.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 89
		 'value_inheritance_spec', 3,
sub
#line 632 "parserxp.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 90
		 'value_inheritance_spec', 1,
sub
#line 637 "parserxp.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 91
		 'inheritance_mod', 1, undef
	],
	[#Rule 92
		 'inheritance_mod', 0, undef
	],
	[#Rule 93
		 'value_names', 1,
sub
#line 653 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 94
		 'value_names', 3,
sub
#line 657 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 95
		 'supported_interface_spec', 2,
sub
#line 665 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 96
		 'supported_interface_spec', 2,
sub
#line 669 "parserxp.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 97
		 'supported_interface_spec', 0, undef
	],
	[#Rule 98
		 'value_name', 1,
sub
#line 680 "parserxp.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 99
		 'value_element', 1, undef
	],
	[#Rule 100
		 'value_element', 1, undef
	],
	[#Rule 101
		 'value_element', 1, undef
	],
	[#Rule 102
		 'state_member', 6,
sub
#line 698 "parserxp.yp"
{
			new StateMembers($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'modifier'			=>	$_[3],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 103
		 'state_member', 6,
sub
#line 708 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 104
		 'state_member', 5,
sub
#line 713 "parserxp.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 105
		 'state_mod', 1, undef
	],
	[#Rule 106
		 'state_mod', 1, undef
	],
	[#Rule 107
		 'init_dcl', 3,
sub
#line 729 "parserxp.yp"
{
			$_[1]->Configure($_[0],
					'list_raise'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 108
		 'init_header_param', 3,
sub
#line 738 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 109
		 'init_header_param', 4,
sub
#line 744 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 110
		 'init_header_param', 4,
sub
#line 752 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 111
		 'init_header_param', 2,
sub
#line 760 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 112
		 'init_header', 4,
sub
#line 771 "parserxp.yp"
{
			new Initializer($_[0],						# like Operation
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'idf'				=>	$_[4]
			);
		}
	],
	[#Rule 113
		 'init_header', 4,
sub
#line 779 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 114
		 'init_param_decls', 1,
sub
#line 788 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 115
		 'init_param_decls', 3,
sub
#line 792 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 116
		 'init_param_decl', 3,
sub
#line 801 "parserxp.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 117
		 'init_param_decl', 2,
sub
#line 809 "parserxp.yp"
{
			$_[0]->Error("Type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 118
		 'init_param_attribute', 1, undef
	],
	[#Rule 119
		 'const_dcl', 6,
sub
#line 824 "parserxp.yp"
{
			new Constant($_[0],
					'declspec'			=>	$_[1],
					'type'				=>	$_[3],
					'idf'				=>	$_[4],
					'list_expr'			=>	$_[6]
			);
		}
	],
	[#Rule 120
		 'const_dcl', 6,
sub
#line 833 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 121
		 'const_dcl', 5,
sub
#line 838 "parserxp.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 122
		 'const_dcl', 4,
sub
#line 843 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 123
		 'const_dcl', 3,
sub
#line 848 "parserxp.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
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
		 'const_type', 1, undef
	],
	[#Rule 131
		 'const_type', 1, undef
	],
	[#Rule 132
		 'const_type', 1,
sub
#line 873 "parserxp.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 133
		 'const_type', 1, undef
	],
	[#Rule 134
		 'const_exp', 1, undef
	],
	[#Rule 135
		 'or_expr', 1, undef
	],
	[#Rule 136
		 'or_expr', 3,
sub
#line 891 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 137
		 'xor_expr', 1, undef
	],
	[#Rule 138
		 'xor_expr', 3,
sub
#line 901 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 139
		 'and_expr', 1, undef
	],
	[#Rule 140
		 'and_expr', 3,
sub
#line 911 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 141
		 'shift_expr', 1, undef
	],
	[#Rule 142
		 'shift_expr', 3,
sub
#line 921 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 143
		 'shift_expr', 3,
sub
#line 925 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 144
		 'add_expr', 1, undef
	],
	[#Rule 145
		 'add_expr', 3,
sub
#line 935 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 146
		 'add_expr', 3,
sub
#line 939 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 147
		 'mult_expr', 1, undef
	],
	[#Rule 148
		 'mult_expr', 3,
sub
#line 949 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 149
		 'mult_expr', 3,
sub
#line 953 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 150
		 'mult_expr', 3,
sub
#line 957 "parserxp.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 151
		 'unary_expr', 2,
sub
#line 965 "parserxp.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 152
		 'unary_expr', 1, undef
	],
	[#Rule 153
		 'unary_operator', 1, undef
	],
	[#Rule 154
		 'unary_operator', 1, undef
	],
	[#Rule 155
		 'unary_operator', 1, undef
	],
	[#Rule 156
		 'primary_expr', 1,
sub
#line 985 "parserxp.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 157
		 'primary_expr', 1,
sub
#line 991 "parserxp.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 158
		 'primary_expr', 3,
sub
#line 995 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 159
		 'primary_expr', 3,
sub
#line 999 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 160
		 'literal', 1,
sub
#line 1008 "parserxp.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 161
		 'literal', 1,
sub
#line 1015 "parserxp.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1021 "parserxp.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'literal', 1,
sub
#line 1027 "parserxp.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'literal', 1,
sub
#line 1033 "parserxp.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'literal', 1,
sub
#line 1039 "parserxp.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 166
		 'literal', 1,
sub
#line 1046 "parserxp.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 167
		 'literal', 1, undef
	],
	[#Rule 168
		 'string_literal', 1, undef
	],
	[#Rule 169
		 'string_literal', 2,
sub
#line 1060 "parserxp.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 170
		 'wide_string_literal', 1, undef
	],
	[#Rule 171
		 'wide_string_literal', 2,
sub
#line 1069 "parserxp.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 172
		 'boolean_literal', 1,
sub
#line 1077 "parserxp.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 173
		 'boolean_literal', 1,
sub
#line 1083 "parserxp.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 174
		 'positive_int_const', 1,
sub
#line 1093 "parserxp.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 175
		 'type_dcl', 2,
sub
#line 1103 "parserxp.yp"
{
			$_[2]->configure(
					'declspec'			=>	$_[1]
			) if ($_[2]);
		}
	],
	[#Rule 176
		 'type_dcl_def', 3,
sub
#line 1112 "parserxp.yp"
{
			$_[3]->configure(
					'props'				=>	$_[1]
			);
		}
	],
	[#Rule 177
		 'type_dcl_def', 1, undef
	],
	[#Rule 178
		 'type_dcl_def', 1, undef
	],
	[#Rule 179
		 'type_dcl_def', 1, undef
	],
	[#Rule 180
		 'type_dcl_def', 3,
sub
#line 1124 "parserxp.yp"
{
			new NativeType($_[0],
					'props'				=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 181
		 '@1-4', 0,
sub
#line 1131 "parserxp.yp"
{
			$_[0]->YYData->{native} = 1;
		}
	],
	[#Rule 182
		 'type_dcl_def', 6,
sub
#line 1135 "parserxp.yp"
{
			$_[0]->YYData->{native} = 0;
			new NativeType($_[0],
					'props'				=>	$_[1],
					'idf'				=>	$_[3],
					'native'			=>	$_[6],
			);
		}
	],
	[#Rule 183
		 'type_dcl_def', 1, undef
	],
	[#Rule 184
		 'type_dcl_def', 3,
sub
#line 1146 "parserxp.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 185
		 'type_declarator', 2,
sub
#line 1155 "parserxp.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 186
		 'type_spec', 1, undef
	],
	[#Rule 187
		 'type_spec', 1, undef
	],
	[#Rule 188
		 'simple_type_spec', 1, undef
	],
	[#Rule 189
		 'simple_type_spec', 1, undef
	],
	[#Rule 190
		 'simple_type_spec', 1,
sub
#line 1178 "parserxp.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 191
		 'simple_type_spec', 1,
sub
#line 1182 "parserxp.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
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
		 'base_type_spec', 1, undef
	],
	[#Rule 200
		 'base_type_spec', 1, undef
	],
	[#Rule 201
		 'template_type_spec', 1, undef
	],
	[#Rule 202
		 'template_type_spec', 1, undef
	],
	[#Rule 203
		 'template_type_spec', 1, undef
	],
	[#Rule 204
		 'template_type_spec', 1, undef
	],
	[#Rule 205
		 'constr_type_spec', 1, undef
	],
	[#Rule 206
		 'constr_type_spec', 1, undef
	],
	[#Rule 207
		 'constr_type_spec', 1, undef
	],
	[#Rule 208
		 'declarators', 1,
sub
#line 1237 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 209
		 'declarators', 3,
sub
#line 1241 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 210
		 'declarator', 1,
sub
#line 1250 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 211
		 'declarator', 1, undef
	],
	[#Rule 212
		 'simple_declarator', 1, undef
	],
	[#Rule 213
		 'simple_declarator', 2,
sub
#line 1262 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 214
		 'simple_declarator', 2,
sub
#line 1267 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 215
		 'complex_declarator', 1, undef
	],
	[#Rule 216
		 'floating_pt_type', 1,
sub
#line 1282 "parserxp.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 217
		 'floating_pt_type', 1,
sub
#line 1288 "parserxp.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 218
		 'floating_pt_type', 2,
sub
#line 1294 "parserxp.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 219
		 'integer_type', 1, undef
	],
	[#Rule 220
		 'integer_type', 1, undef
	],
	[#Rule 221
		 'signed_int', 1, undef
	],
	[#Rule 222
		 'signed_int', 1, undef
	],
	[#Rule 223
		 'signed_int', 1, undef
	],
	[#Rule 224
		 'signed_short_int', 1,
sub
#line 1322 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 225
		 'signed_long_int', 1,
sub
#line 1332 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 226
		 'signed_longlong_int', 2,
sub
#line 1342 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 227
		 'unsigned_int', 1, undef
	],
	[#Rule 228
		 'unsigned_int', 1, undef
	],
	[#Rule 229
		 'unsigned_int', 1, undef
	],
	[#Rule 230
		 'unsigned_short_int', 2,
sub
#line 1362 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 231
		 'unsigned_long_int', 2,
sub
#line 1372 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 232
		 'unsigned_longlong_int', 3,
sub
#line 1382 "parserxp.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 233
		 'char_type', 1,
sub
#line 1392 "parserxp.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 234
		 'wide_char_type', 1,
sub
#line 1402 "parserxp.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 235
		 'boolean_type', 1,
sub
#line 1412 "parserxp.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 236
		 'octet_type', 1,
sub
#line 1422 "parserxp.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 237
		 'any_type', 1,
sub
#line 1432 "parserxp.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 238
		 'object_type', 1,
sub
#line 1442 "parserxp.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 239
		 'struct_type', 4,
sub
#line 1452 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 240
		 'struct_type', 4,
sub
#line 1459 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 241
		 'struct_header', 3,
sub
#line 1469 "parserxp.yp"
{
			new StructType($_[0],
					'props'				=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 242
		 'struct_header', 3,
sub
#line 1476 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'member_list', 1,
sub
#line 1485 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 244
		 'member_list', 2,
sub
#line 1489 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 245
		 'member', 3,
sub
#line 1498 "parserxp.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 246
		 'union_type', 8,
sub
#line 1509 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 247
		 'union_type', 8,
sub
#line 1517 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 248
		 'union_type', 6,
sub
#line 1524 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 249
		 'union_type', 5,
sub
#line 1531 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 250
		 'union_type', 3,
sub
#line 1538 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 251
		 'union_header', 3,
sub
#line 1548 "parserxp.yp"
{
			new UnionType($_[0],
					'props'				=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 252
		 'union_header', 3,
sub
#line 1555 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 253
		 'switch_type_spec', 1, undef
	],
	[#Rule 254
		 'switch_type_spec', 1, undef
	],
	[#Rule 255
		 'switch_type_spec', 1, undef
	],
	[#Rule 256
		 'switch_type_spec', 1, undef
	],
	[#Rule 257
		 'switch_type_spec', 1,
sub
#line 1572 "parserxp.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 258
		 'switch_body', 1,
sub
#line 1580 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 259
		 'switch_body', 2,
sub
#line 1584 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 260
		 'case', 3,
sub
#line 1593 "parserxp.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 261
		 'case_labels', 1,
sub
#line 1603 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 262
		 'case_labels', 2,
sub
#line 1607 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 263
		 'case_label', 3,
sub
#line 1616 "parserxp.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 264
		 'case_label', 3,
sub
#line 1620 "parserxp.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 265
		 'case_label', 2,
sub
#line 1626 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'case_label', 2,
sub
#line 1631 "parserxp.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 267
		 'case_label', 2,
sub
#line 1635 "parserxp.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 268
		 'element_spec', 2,
sub
#line 1645 "parserxp.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 269
		 'enum_type', 4,
sub
#line 1656 "parserxp.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 270
		 'enum_type', 4,
sub
#line 1662 "parserxp.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 271
		 'enum_type', 2,
sub
#line 1668 "parserxp.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 272
		 'enum_header', 3,
sub
#line 1677 "parserxp.yp"
{
			new EnumType($_[0],
					'props'				=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 273
		 'enum_header', 3,
sub
#line 1684 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 274
		 'enumerators', 1,
sub
#line 1692 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 275
		 'enumerators', 3,
sub
#line 1696 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 276
		 'enumerators', 2,
sub
#line 1701 "parserxp.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 277
		 'enumerators', 2,
sub
#line 1706 "parserxp.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 278
		 'enumerator', 1,
sub
#line 1715 "parserxp.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 279
		 'sequence_type', 6,
sub
#line 1725 "parserxp.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 280
		 'sequence_type', 6,
sub
#line 1733 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 281
		 'sequence_type', 4,
sub
#line 1738 "parserxp.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 282
		 'sequence_type', 4,
sub
#line 1745 "parserxp.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 283
		 'sequence_type', 2,
sub
#line 1750 "parserxp.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 284
		 'string_type', 4,
sub
#line 1759 "parserxp.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 285
		 'string_type', 1,
sub
#line 1766 "parserxp.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 286
		 'string_type', 4,
sub
#line 1772 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 287
		 'wide_string_type', 4,
sub
#line 1781 "parserxp.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 288
		 'wide_string_type', 1,
sub
#line 1788 "parserxp.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 289
		 'wide_string_type', 4,
sub
#line 1794 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 290
		 'array_declarator', 2,
sub
#line 1803 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 291
		 'fixed_array_sizes', 1,
sub
#line 1811 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 292
		 'fixed_array_sizes', 2,
sub
#line 1815 "parserxp.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 293
		 'fixed_array_size', 3,
sub
#line 1824 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 294
		 'fixed_array_size', 3,
sub
#line 1828 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 295
		 'attr_dcl', 1, undef
	],
	[#Rule 296
		 'attr_dcl', 1, undef
	],
	[#Rule 297
		 'except_dcl', 3,
sub
#line 1845 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 298
		 'except_dcl', 4,
sub
#line 1850 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 299
		 'except_dcl', 4,
sub
#line 1857 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 300
		 'except_dcl', 2,
sub
#line 1864 "parserxp.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 301
		 'exception_header', 3,
sub
#line 1874 "parserxp.yp"
{
			new Exception($_[0],
					'declspec'			=>	$_[1],
					'idf'				=>	$_[3],
			);
		}
	],
	[#Rule 302
		 'exception_header', 3,
sub
#line 1881 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 303
		 'op_dcl', 4,
sub
#line 1890 "parserxp.yp"
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
		 'op_dcl', 2,
sub
#line 1900 "parserxp.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 305
		 'op_header', 5,
sub
#line 1911 "parserxp.yp"
{
			new Operation($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'modifier'			=>	$_[3],
					'type'				=>	$_[4],
					'idf'				=>	$_[5]
			);
		}
	],
	[#Rule 306
		 'op_header', 5,
sub
#line 1921 "parserxp.yp"
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
#line 1945 "parserxp.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 312
		 'op_type_spec', 1,
sub
#line 1951 "parserxp.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 313
		 'op_type_spec', 1,
sub
#line 1956 "parserxp.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 314
		 'parameter_dcls', 3,
sub
#line 1965 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 315
		 'parameter_dcls', 5,
sub
#line 1969 "parserxp.yp"
{
			push(@{$_[2]},new Ellipsis($_[0]));
			$_[2];
		}
	],
	[#Rule 316
		 'parameter_dcls', 4,
sub
#line 1974 "parserxp.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 317
		 'parameter_dcls', 2,
sub
#line 1979 "parserxp.yp"
{
			undef;
		}
	],
	[#Rule 318
		 'parameter_dcls', 3,
sub
#line 1983 "parserxp.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 319
		 'parameter_dcls', 3,
sub
#line 1988 "parserxp.yp"
{
			new Ellipsis($_[0]);
		}
	],
	[#Rule 320
		 'param_dcls', 1,
sub
#line 1995 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 321
		 'param_dcls', 3,
sub
#line 1999 "parserxp.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 322
		 'param_dcls', 2,
sub
#line 2004 "parserxp.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 323
		 'param_dcl', 4,
sub
#line 2013 "parserxp.yp"
{
			new Parameter($_[0],
					'props'				=>	$_[1],
					'attr'				=>	$_[2],
					'type'				=>	$_[3],
					'idf'				=>	$_[4]
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
		 'param_attribute', 0,
sub
#line 2032 "parserxp.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 328
		 'raises_expr', 4,
sub
#line 2041 "parserxp.yp"
{
			$_[3];
		}
	],
	[#Rule 329
		 'raises_expr', 4,
sub
#line 2045 "parserxp.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 330
		 'raises_expr', 2,
sub
#line 2050 "parserxp.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 331
		 'raises_expr', 0, undef
	],
	[#Rule 332
		 'exception_names', 1,
sub
#line 2060 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 333
		 'exception_names', 3,
sub
#line 2064 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 334
		 'exception_name', 1,
sub
#line 2072 "parserxp.yp"
{
			Interface->Lookup($_[0],$_[1],1);
		}
	],
	[#Rule 335
		 'context_expr', 4,
sub
#line 2080 "parserxp.yp"
{
			$_[3];
		}
	],
	[#Rule 336
		 'context_expr', 4,
sub
#line 2084 "parserxp.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 337
		 'context_expr', 2,
sub
#line 2089 "parserxp.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 338
		 'context_expr', 0, undef
	],
	[#Rule 339
		 'string_literals', 1,
sub
#line 2099 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 340
		 'string_literals', 3,
sub
#line 2103 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 341
		 'param_type_spec', 1, undef
	],
	[#Rule 342
		 'param_type_spec', 1,
sub
#line 2114 "parserxp.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 343
		 'param_type_spec', 1,
sub
#line 2119 "parserxp.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 344
		 'param_type_spec', 1,
sub
#line 2124 "parserxp.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 345
		 'op_param_type_spec', 1, undef
	],
	[#Rule 346
		 'op_param_type_spec', 1, undef
	],
	[#Rule 347
		 'op_param_type_spec', 1, undef
	],
	[#Rule 348
		 'op_param_type_spec', 1,
sub
#line 2138 "parserxp.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 349
		 'fixed_pt_type', 6,
sub
#line 2146 "parserxp.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 350
		 'fixed_pt_type', 6,
sub
#line 2154 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 351
		 'fixed_pt_type', 4,
sub
#line 2159 "parserxp.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 352
		 'fixed_pt_type', 2,
sub
#line 2164 "parserxp.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 353
		 'fixed_pt_const_type', 1,
sub
#line 2173 "parserxp.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 354
		 'value_base_type', 1,
sub
#line 2183 "parserxp.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 355
		 'constr_forward_decl', 3,
sub
#line 2193 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[1]);
			new ForwardStructType($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 356
		 'constr_forward_decl', 3,
sub
#line 2201 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 357
		 'constr_forward_decl', 3,
sub
#line 2206 "parserxp.yp"
{
			$_[0]->Warning("Ignoring properties for forward declaration.\n")
					if (defined $_[1]);
			new ForwardUnionType($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 358
		 'constr_forward_decl', 3,
sub
#line 2214 "parserxp.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 359
		 'import', 3,
sub
#line 2223 "parserxp.yp"
{
			new Import($_[0],
					'value'				=>	$_[2]
			);
		}
	],
	[#Rule 360
		 'import', 2,
sub
#line 2229 "parserxp.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 361
		 'imported_scope', 1, undef
	],
	[#Rule 362
		 'imported_scope', 1, undef
	],
	[#Rule 363
		 'type_id_dcl', 3,
sub
#line 2246 "parserxp.yp"
{
			new TypeId($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 364
		 'type_id_dcl', 3,
sub
#line 2253 "parserxp.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 365
		 'type_id_dcl', 2,
sub
#line 2258 "parserxp.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 366
		 'type_prefix_dcl', 3,
sub
#line 2267 "parserxp.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	$_[2],
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 367
		 'type_prefix_dcl', 3,
sub
#line 2274 "parserxp.yp"
{
			$_[0]->Error("String literal expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 368
		 'type_prefix_dcl', 3,
sub
#line 2279 "parserxp.yp"
{
			new TypePrefix($_[0],
					'idf'				=>	'',
					'value'				=>	$_[3]
			);
		}
	],
	[#Rule 369
		 'type_prefix_dcl', 2,
sub
#line 2286 "parserxp.yp"
{
			$_[0]->Error("Scoped name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 370
		 'readonly_attr_spec', 6,
sub
#line 2295 "parserxp.yp"
{
			new Attributes($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'modifier'			=>	$_[3],
					'type'				=>	$_[5],
					'list_expr'			=>	$_[6]->{list_expr},
					'list_getraise'		=>	$_[6]->{list_getraise},
			);
		}
	],
	[#Rule 371
		 'readonly_attr_spec', 5,
sub
#line 2306 "parserxp.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 372
		 'readonly_attr_spec', 4,
sub
#line 2311 "parserxp.yp"
{
			$_[0]->Error("'attribute' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 373
		 'readonly_attr_declarator', 2,
sub
#line 2320 "parserxp.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]
			};
		}
	],
	[#Rule 374
		 'readonly_attr_declarator', 3,
sub
#line 2327 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			{
				'list_expr'			=> $_[3]
			};
		}
	],
	[#Rule 375
		 'simple_declarators', 1,
sub
#line 2337 "parserxp.yp"
{
			[$_[1]];
		}
	],
	[#Rule 376
		 'simple_declarators', 3,
sub
#line 2341 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 377
		 'attr_spec', 5,
sub
#line 2350 "parserxp.yp"
{
			new Attributes($_[0],
					'declspec'			=>	$_[1],
					'props'				=>	$_[2],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[5]->{list_expr},
					'list_getraise'		=>	$_[5]->{list_getraise},
					'list_setraise'		=>	$_[5]->{list_setraise},
			);
		}
	],
	[#Rule 378
		 'attr_spec', 4,
sub
#line 2361 "parserxp.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 379
		 'attr_declarator', 2,
sub
#line 2370 "parserxp.yp"
{
			{
				'list_expr'			=> [$_[1]],
				'list_getraise'		=> $_[2]->{list_getraise},
				'list_setraise'		=> $_[2]->{list_setraise}
			};
		}
	],
	[#Rule 380
		 'attr_declarator', 3,
sub
#line 2378 "parserxp.yp"
{
			unshift(@{$_[3]},$_[1]);
			{
				'list_expr'			=> $_[3]
			};
		}
	],
	[#Rule 381
		 'attr_raises_expr', 2,
sub
#line 2389 "parserxp.yp"
{
			{
				'list_getraise'		=> $_[1],
				'list_setraise'		=> $_[2]
			};
		}
	],
	[#Rule 382
		 'attr_raises_expr', 1,
sub
#line 2396 "parserxp.yp"
{
			{
				'list_getraise'		=> $_[1],
			};
		}
	],
	[#Rule 383
		 'attr_raises_expr', 1,
sub
#line 2402 "parserxp.yp"
{
			{
				'list_setraise'		=> $_[1]
			};
		}
	],
	[#Rule 384
		 'attr_raises_expr', 0, undef
	],
	[#Rule 385
		 'get_except_expr', 2,
sub
#line 2414 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 386
		 'get_except_expr', 2,
sub
#line 2418 "parserxp.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 387
		 'set_except_expr', 2,
sub
#line 2427 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 388
		 'set_except_expr', 2,
sub
#line 2431 "parserxp.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 389
		 'exception_list', 3,
sub
#line 2440 "parserxp.yp"
{
			$_[2];
		}
	],
	[#Rule 390
		 'exception_list', 3,
sub
#line 2444 "parserxp.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 391
		 'code_frag', 2,
sub
#line 2454 "parserxp.yp"
{
			new CodeFragment($_[0],
					'declspec'			=>	$_[1],
					'value'				=>	$_[2],
			);
		}
	],
	[#Rule 392
		 'declspec', 0, undef
	],
	[#Rule 393
		 'declspec', 1, undef
	],
	[#Rule 394
		 'props', 0, undef
	],
	[#Rule 395
		 '@2-1', 0,
sub
#line 2473 "parserxp.yp"
{
			$_[0]->YYData->{prop} = 1;
		}
	],
	[#Rule 396
		 'props', 4,
sub
#line 2477 "parserxp.yp"
{
			$_[0]->YYData->{prop} = 0;
			$_[3];
		}
	],
	[#Rule 397
		 'prop_list', 2,
sub
#line 2485 "parserxp.yp"
{
			my $hash = {};
			$hash->{$_[1]} = $_[2];
			$hash;
		}
	],
	[#Rule 398
		 'prop_list', 4,
sub
#line 2491 "parserxp.yp"
{
			$_[1]->{$_[3]} = $_[4];
			$_[1];
		}
	],
	[#Rule 399
		 'prop_list', 1,
sub
#line 2496 "parserxp.yp"
{
			my $hash = {};
			$hash->{$_[1]} = undef;
			$hash;
		}
	],
	[#Rule 400
		 'prop_list', 3,
sub
#line 2502 "parserxp.yp"
{
			$_[1]->{$_[3]} = undef;
			$_[1];
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 2508 "parserxp.yp"


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
