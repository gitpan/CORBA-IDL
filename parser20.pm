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
			'TYPEDEF' => 11,
			'MODULE' => 14,
			'IDENTIFIER' => 13,
			'UNION' => 16,
			'STRUCT' => 5,
			'error' => 19,
			'CONST' => 22,
			'EXCEPTION' => 23,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		GOTOS => {
			'const_dcl' => 1,
			'except_dcl' => 3,
			'interface_header' => 2,
			'specification' => 4,
			'module_header' => 6,
			'interface' => 7,
			'struct_type' => 8,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'interface_dcl' => 15,
			'enum_type' => 17,
			'forward_dcl' => 18,
			'module' => 21,
			'enum_header' => 20,
			'union_header' => 24,
			'type_dcl' => 25,
			'definitions' => 26,
			'definition' => 27
		}
	},
	{#State 1
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 30
		}
	},
	{#State 2
		ACTIONS => {
			"{" => 33
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 34
		}
	},
	{#State 4
		ACTIONS => {
			'' => 35
		}
	},
	{#State 5
		ACTIONS => {
			'IDENTIFIER' => 36
		}
	},
	{#State 6
		ACTIONS => {
			"{" => 38,
			'error' => 37
		}
	},
	{#State 7
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 39
		}
	},
	{#State 8
		DEFAULT => -96
	},
	{#State 9
		ACTIONS => {
			"{" => 41,
			'error' => 40
		}
	},
	{#State 10
		DEFAULT => -97
	},
	{#State 11
		ACTIONS => {
			'CHAR' => 63,
			'VOID' => 64,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'error' => 58,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 28,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'boolean_type' => 66,
			'integer_type' => 65,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'signed_long_int' => 49,
			'type_spec' => 50,
			'signed_short_int' => 71,
			'type_declarator' => 51,
			'string_type' => 53,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 76,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 80
		}
	},
	{#State 12
		ACTIONS => {
			"{" => 81
		}
	},
	{#State 13
		ACTIONS => {
			'error' => 82
		}
	},
	{#State 14
		ACTIONS => {
			'error' => 83,
			'IDENTIFIER' => 84
		}
	},
	{#State 15
		DEFAULT => -20
	},
	{#State 16
		ACTIONS => {
			'error' => 85,
			'IDENTIFIER' => 86
		}
	},
	{#State 17
		DEFAULT => -98
	},
	{#State 18
		DEFAULT => -21
	},
	{#State 19
		DEFAULT => -3
	},
	{#State 20
		ACTIONS => {
			"{" => 88,
			'error' => 87
		}
	},
	{#State 21
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 89
		}
	},
	{#State 22
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'DOUBLE' => 67,
			'error' => 94,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'FLOAT' => 61,
			'UNSIGNED' => 52
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 90,
			'signed_int' => 44,
			'integer_type' => 96,
			'boolean_type' => 95,
			'char_type' => 91,
			'unsigned_long_int' => 77,
			'scoped_name' => 92,
			'signed_long_int' => 49,
			'unsigned_short_int' => 60,
			'signed_short_int' => 71,
			'const_type' => 97,
			'string_type' => 93
		}
	},
	{#State 23
		ACTIONS => {
			'error' => 98,
			'IDENTIFIER' => 99
		}
	},
	{#State 24
		ACTIONS => {
			'SWITCH' => 100
		}
	},
	{#State 25
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 101
		}
	},
	{#State 26
		DEFAULT => -1
	},
	{#State 27
		ACTIONS => {
			'TYPEDEF' => 11,
			'IDENTIFIER' => 13,
			'MODULE' => 14,
			'UNION' => 16,
			'STRUCT' => 5,
			'CONST' => 22,
			'EXCEPTION' => 23,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		DEFAULT => -4,
		GOTOS => {
			'const_dcl' => 1,
			'interface_header' => 2,
			'except_dcl' => 3,
			'module_header' => 6,
			'interface' => 7,
			'struct_type' => 8,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'interface_dcl' => 15,
			'enum_type' => 17,
			'forward_dcl' => 18,
			'enum_header' => 20,
			'module' => 21,
			'union_header' => 24,
			'definitions' => 102,
			'type_dcl' => 25,
			'definition' => 27
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 103,
			'IDENTIFIER' => 104
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 105,
			'IDENTIFIER' => 106
		}
	},
	{#State 30
		DEFAULT => -7
	},
	{#State 31
		DEFAULT => -12
	},
	{#State 32
		DEFAULT => -13
	},
	{#State 33
		ACTIONS => {
			'CHAR' => -212,
			'ONEWAY' => 107,
			'VOID' => -212,
			'SEQUENCE' => -212,
			'STRUCT' => 5,
			'DOUBLE' => -212,
			'LONG' => -212,
			'STRING' => -212,
			"::" => -212,
			'UNSIGNED' => -212,
			'SHORT' => -212,
			'TYPEDEF' => 11,
			'BOOLEAN' => -212,
			'IDENTIFIER' => -212,
			'UNION' => 16,
			'READONLY' => 118,
			'ATTRIBUTE' => -198,
			'error' => 112,
			'CONST' => 22,
			"}" => 113,
			'EXCEPTION' => 23,
			'OCTET' => -212,
			'FLOAT' => -212,
			'ENUM' => 28,
			'ANY' => -212
		},
		GOTOS => {
			'const_dcl' => 114,
			'op_mod' => 108,
			'except_dcl' => 109,
			'op_attribute' => 110,
			'attr_mod' => 111,
			'exports' => 115,
			'export' => 116,
			'struct_type' => 8,
			'op_header' => 117,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 17,
			'op_dcl' => 119,
			'enum_header' => 20,
			'attr_dcl' => 120,
			'type_dcl' => 121,
			'union_header' => 24,
			'interface_body' => 122
		}
	},
	{#State 34
		DEFAULT => -8
	},
	{#State 35
		DEFAULT => 0
	},
	{#State 36
		DEFAULT => -144
	},
	{#State 37
		ACTIONS => {
			"}" => 123
		}
	},
	{#State 38
		ACTIONS => {
			'TYPEDEF' => 11,
			'IDENTIFIER' => 13,
			'MODULE' => 14,
			'UNION' => 16,
			'STRUCT' => 5,
			'error' => 124,
			'CONST' => 22,
			'EXCEPTION' => 23,
			"}" => 125,
			'ENUM' => 28,
			'INTERFACE' => 29
		},
		GOTOS => {
			'const_dcl' => 1,
			'interface_header' => 2,
			'except_dcl' => 3,
			'module_header' => 6,
			'interface' => 7,
			'struct_type' => 8,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'interface_dcl' => 15,
			'enum_type' => 17,
			'forward_dcl' => 18,
			'enum_header' => 20,
			'module' => 21,
			'union_header' => 24,
			'definitions' => 126,
			'type_dcl' => 25,
			'definition' => 27
		}
	},
	{#State 39
		DEFAULT => -9
	},
	{#State 40
		DEFAULT => -204
	},
	{#State 41
		ACTIONS => {
			'CHAR' => 63,
			'VOID' => 64,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'error' => 128,
			"}" => 130,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 28,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'type_spec' => 127,
			'signed_long_int' => 49,
			'signed_short_int' => 71,
			'string_type' => 53,
			'member' => 131,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 76,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'member_list' => 129,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 80
		}
	},
	{#State 42
		DEFAULT => -129
	},
	{#State 43
		DEFAULT => -107
	},
	{#State 44
		DEFAULT => -128
	},
	{#State 45
		ACTIONS => {
			"<" => 133,
			'error' => 132
		}
	},
	{#State 46
		DEFAULT => -109
	},
	{#State 47
		DEFAULT => -111
	},
	{#State 48
		ACTIONS => {
			"::" => 134
		},
		DEFAULT => -105
	},
	{#State 49
		DEFAULT => -131
	},
	{#State 50
		ACTIONS => {
			'error' => 137,
			'IDENTIFIER' => 141
		},
		GOTOS => {
			'declarators' => 135,
			'declarator' => 136,
			'simple_declarator' => 139,
			'array_declarator' => 140,
			'complex_declarator' => 138
		}
	},
	{#State 51
		DEFAULT => -95
	},
	{#State 52
		ACTIONS => {
			'SHORT' => 142,
			'LONG' => 143
		}
	},
	{#State 53
		DEFAULT => -114
	},
	{#State 54
		DEFAULT => -133
	},
	{#State 55
		DEFAULT => -112
	},
	{#State 56
		DEFAULT => -103
	},
	{#State 57
		DEFAULT => -117
	},
	{#State 58
		DEFAULT => -99
	},
	{#State 59
		DEFAULT => -140
	},
	{#State 60
		DEFAULT => -134
	},
	{#State 61
		DEFAULT => -126
	},
	{#State 62
		DEFAULT => -141
	},
	{#State 63
		DEFAULT => -138
	},
	{#State 64
		DEFAULT => -106
	},
	{#State 65
		DEFAULT => -108
	},
	{#State 66
		DEFAULT => -110
	},
	{#State 67
		DEFAULT => -127
	},
	{#State 68
		DEFAULT => -132
	},
	{#State 69
		ACTIONS => {
			"<" => 144
		},
		DEFAULT => -188
	},
	{#State 70
		ACTIONS => {
			'error' => 145,
			'IDENTIFIER' => 146
		}
	},
	{#State 71
		DEFAULT => -130
	},
	{#State 72
		DEFAULT => -115
	},
	{#State 73
		DEFAULT => -116
	},
	{#State 74
		DEFAULT => -139
	},
	{#State 75
		DEFAULT => -43
	},
	{#State 76
		DEFAULT => -113
	},
	{#State 77
		DEFAULT => -135
	},
	{#State 78
		DEFAULT => -104
	},
	{#State 79
		DEFAULT => -102
	},
	{#State 80
		DEFAULT => -101
	},
	{#State 81
		ACTIONS => {
			'CHAR' => 63,
			'VOID' => 64,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'error' => 147,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 28,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'type_spec' => 127,
			'signed_long_int' => 49,
			'signed_short_int' => 71,
			'string_type' => 53,
			'member' => 131,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 76,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'member_list' => 148,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 80
		}
	},
	{#State 82
		ACTIONS => {
			";" => 149
		}
	},
	{#State 83
		DEFAULT => -19
	},
	{#State 84
		DEFAULT => -18
	},
	{#State 85
		DEFAULT => -155
	},
	{#State 86
		DEFAULT => -154
	},
	{#State 87
		DEFAULT => -174
	},
	{#State 88
		ACTIONS => {
			'error' => 150,
			'IDENTIFIER' => 152
		},
		GOTOS => {
			'enumerators' => 153,
			'enumerator' => 151
		}
	},
	{#State 89
		DEFAULT => -10
	},
	{#State 90
		DEFAULT => -56
	},
	{#State 91
		DEFAULT => -54
	},
	{#State 92
		ACTIONS => {
			"::" => 134
		},
		DEFAULT => -58
	},
	{#State 93
		DEFAULT => -57
	},
	{#State 94
		DEFAULT => -52
	},
	{#State 95
		DEFAULT => -55
	},
	{#State 96
		DEFAULT => -53
	},
	{#State 97
		ACTIONS => {
			'error' => 154,
			'IDENTIFIER' => 155
		}
	},
	{#State 98
		DEFAULT => -206
	},
	{#State 99
		DEFAULT => -205
	},
	{#State 100
		ACTIONS => {
			'error' => 157,
			"(" => 156
		}
	},
	{#State 101
		DEFAULT => -6
	},
	{#State 102
		DEFAULT => -5
	},
	{#State 103
		DEFAULT => -176
	},
	{#State 104
		DEFAULT => -175
	},
	{#State 105
		ACTIONS => {
			"{" => -28
		},
		DEFAULT => -26
	},
	{#State 106
		ACTIONS => {
			"{" => -39,
			":" => 158
		},
		DEFAULT => -25,
		GOTOS => {
			'interface_inheritance_spec' => 159
		}
	},
	{#State 107
		DEFAULT => -213
	},
	{#State 108
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'VOID' => 163,
			'SEQUENCE' => 45,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'OCTET' => 59,
			'FLOAT' => 61,
			'UNSIGNED' => 52,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 160,
			'signed_long_int' => 49,
			'signed_short_int' => 71,
			'string_type' => 161,
			'op_param_type_spec' => 164,
			'op_type_spec' => 165,
			'base_type_spec' => 162,
			'any_type' => 55,
			'sequence_type' => 166,
			'unsigned_long_int' => 77,
			'unsigned_short_int' => 60
		}
	},
	{#State 109
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 167
		}
	},
	{#State 110
		DEFAULT => -211
	},
	{#State 111
		ACTIONS => {
			'ATTRIBUTE' => 168
		}
	},
	{#State 112
		ACTIONS => {
			"}" => 169
		}
	},
	{#State 113
		DEFAULT => -22
	},
	{#State 114
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 170
		}
	},
	{#State 115
		DEFAULT => -29
	},
	{#State 116
		ACTIONS => {
			'ONEWAY' => 107,
			'STRUCT' => 5,
			'TYPEDEF' => 11,
			'UNION' => 16,
			'READONLY' => 118,
			'ATTRIBUTE' => -198,
			'CONST' => 22,
			"}" => -30,
			'EXCEPTION' => 23,
			'ENUM' => 28
		},
		DEFAULT => -212,
		GOTOS => {
			'const_dcl' => 114,
			'op_mod' => 108,
			'except_dcl' => 109,
			'op_attribute' => 110,
			'attr_mod' => 111,
			'exports' => 171,
			'export' => 116,
			'struct_type' => 8,
			'op_header' => 117,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 17,
			'op_dcl' => 119,
			'enum_header' => 20,
			'attr_dcl' => 120,
			'type_dcl' => 121,
			'union_header' => 24
		}
	},
	{#State 117
		ACTIONS => {
			'error' => 173,
			"(" => 172
		},
		GOTOS => {
			'parameter_dcls' => 174
		}
	},
	{#State 118
		DEFAULT => -197
	},
	{#State 119
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 175
		}
	},
	{#State 120
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 176
		}
	},
	{#State 121
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 177
		}
	},
	{#State 122
		ACTIONS => {
			"}" => 178
		}
	},
	{#State 123
		DEFAULT => -17
	},
	{#State 124
		ACTIONS => {
			"}" => 179
		}
	},
	{#State 125
		DEFAULT => -16
	},
	{#State 126
		ACTIONS => {
			"}" => 180
		}
	},
	{#State 127
		ACTIONS => {
			'error' => 137,
			'IDENTIFIER' => 141
		},
		GOTOS => {
			'declarators' => 181,
			'declarator' => 136,
			'simple_declarator' => 139,
			'array_declarator' => 140,
			'complex_declarator' => 138
		}
	},
	{#State 128
		ACTIONS => {
			"}" => 182
		}
	},
	{#State 129
		ACTIONS => {
			"}" => 183
		}
	},
	{#State 130
		DEFAULT => -201
	},
	{#State 131
		ACTIONS => {
			'CHAR' => 63,
			'VOID' => 64,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 28,
			'ANY' => 62
		},
		DEFAULT => -146,
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'type_spec' => 127,
			'signed_long_int' => 49,
			'signed_short_int' => 71,
			'string_type' => 53,
			'member' => 131,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 76,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'member_list' => 184,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 80
		}
	},
	{#State 132
		DEFAULT => -186
	},
	{#State 133
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'VOID' => 64,
			'SEQUENCE' => 45,
			'DOUBLE' => 67,
			'error' => 185,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'OCTET' => 59,
			'FLOAT' => 61,
			'UNSIGNED' => 52,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'signed_long_int' => 49,
			'signed_short_int' => 71,
			'string_type' => 53,
			'any_type' => 55,
			'base_type_spec' => 56,
			'sequence_type' => 76,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 186
		}
	},
	{#State 134
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 188
		}
	},
	{#State 135
		DEFAULT => -100
	},
	{#State 136
		ACTIONS => {
			"," => 189
		},
		DEFAULT => -118
	},
	{#State 137
		ACTIONS => {
			";" => 190,
			"," => 191
		}
	},
	{#State 138
		DEFAULT => -121
	},
	{#State 139
		DEFAULT => -120
	},
	{#State 140
		DEFAULT => -125
	},
	{#State 141
		ACTIONS => {
			"[" => 194
		},
		DEFAULT => -122,
		GOTOS => {
			'fixed_array_sizes' => 192,
			'fixed_array_size' => 193
		}
	},
	{#State 142
		DEFAULT => -137
	},
	{#State 143
		DEFAULT => -136
	},
	{#State 144
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			'error' => 202,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'const_exp' => 200,
			'and_expr' => 212,
			'or_expr' => 201,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'xor_expr' => 203,
			'shift_expr' => 204,
			'positive_int_const' => 197,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 145
		DEFAULT => -45
	},
	{#State 146
		DEFAULT => -44
	},
	{#State 147
		ACTIONS => {
			"}" => 221
		}
	},
	{#State 148
		ACTIONS => {
			"}" => 222
		}
	},
	{#State 149
		DEFAULT => -11
	},
	{#State 150
		ACTIONS => {
			"}" => 223
		}
	},
	{#State 151
		ACTIONS => {
			";" => 224,
			"," => 225
		},
		DEFAULT => -177
	},
	{#State 152
		DEFAULT => -181
	},
	{#State 153
		ACTIONS => {
			"}" => 226
		}
	},
	{#State 154
		DEFAULT => -51
	},
	{#State 155
		ACTIONS => {
			'error' => 227,
			"=" => 228
		}
	},
	{#State 156
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'error' => 232,
			'LONG' => 68,
			"::" => 70,
			'ENUM' => 28,
			'UNSIGNED' => 52
		},
		GOTOS => {
			'switch_type_spec' => 233,
			'unsigned_int' => 42,
			'signed_int' => 44,
			'integer_type' => 235,
			'boolean_type' => 234,
			'char_type' => 229,
			'enum_type' => 231,
			'unsigned_long_int' => 77,
			'scoped_name' => 230,
			'enum_header' => 20,
			'signed_long_int' => 49,
			'unsigned_short_int' => 60,
			'signed_short_int' => 71
		}
	},
	{#State 157
		DEFAULT => -153
	},
	{#State 158
		ACTIONS => {
			'error' => 237,
			'IDENTIFIER' => 75,
			"::" => 70
		},
		GOTOS => {
			'scoped_name' => 236,
			'interface_names' => 239,
			'interface_name' => 238
		}
	},
	{#State 159
		DEFAULT => -27
	},
	{#State 160
		ACTIONS => {
			"::" => 134
		},
		DEFAULT => -250
	},
	{#State 161
		DEFAULT => -249
	},
	{#State 162
		DEFAULT => -248
	},
	{#State 163
		DEFAULT => -215
	},
	{#State 164
		DEFAULT => -214
	},
	{#State 165
		ACTIONS => {
			'error' => 240,
			'IDENTIFIER' => 241
		}
	},
	{#State 166
		DEFAULT => -216
	},
	{#State 167
		DEFAULT => -34
	},
	{#State 168
		ACTIONS => {
			'CHAR' => 63,
			'VOID' => 244,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'error' => 242,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 28,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 160,
			'signed_long_int' => 49,
			'signed_short_int' => 71,
			'string_type' => 161,
			'op_param_type_spec' => 245,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 246,
			'base_type_spec' => 162,
			'any_type' => 55,
			'enum_type' => 57,
			'unsigned_long_int' => 77,
			'param_type_spec' => 243,
			'enum_header' => 20,
			'constr_type_spec' => 247,
			'union_header' => 24,
			'unsigned_short_int' => 60
		}
	},
	{#State 169
		DEFAULT => -24
	},
	{#State 170
		DEFAULT => -33
	},
	{#State 171
		DEFAULT => -31
	},
	{#State 172
		ACTIONS => {
			'CHAR' => -230,
			'VOID' => -230,
			'IN' => 248,
			'SEQUENCE' => -230,
			'STRUCT' => -230,
			'DOUBLE' => -230,
			'LONG' => -230,
			'STRING' => -230,
			"::" => -230,
			"..." => 249,
			'UNSIGNED' => -230,
			'SHORT' => -230,
			")" => 254,
			'OUT' => 255,
			'BOOLEAN' => -230,
			'IDENTIFIER' => -230,
			'UNION' => -230,
			'error' => 250,
			'INOUT' => 251,
			'OCTET' => -230,
			'FLOAT' => -230,
			'ENUM' => -230,
			'ANY' => -230
		},
		GOTOS => {
			'param_dcl' => 256,
			'param_dcls' => 253,
			'param_attribute' => 252
		}
	},
	{#State 173
		DEFAULT => -208
	},
	{#State 174
		ACTIONS => {
			'RAISES' => 258
		},
		DEFAULT => -234,
		GOTOS => {
			'raises_expr' => 257
		}
	},
	{#State 175
		DEFAULT => -36
	},
	{#State 176
		DEFAULT => -35
	},
	{#State 177
		DEFAULT => -32
	},
	{#State 178
		DEFAULT => -23
	},
	{#State 179
		DEFAULT => -15
	},
	{#State 180
		DEFAULT => -14
	},
	{#State 181
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 259
		}
	},
	{#State 182
		DEFAULT => -203
	},
	{#State 183
		DEFAULT => -202
	},
	{#State 184
		DEFAULT => -147
	},
	{#State 185
		ACTIONS => {
			">" => 260
		}
	},
	{#State 186
		ACTIONS => {
			">" => 262,
			"," => 261
		}
	},
	{#State 187
		DEFAULT => -47
	},
	{#State 188
		DEFAULT => -46
	},
	{#State 189
		ACTIONS => {
			'error' => 137,
			'IDENTIFIER' => 141
		},
		GOTOS => {
			'declarators' => 263,
			'declarator' => 136,
			'simple_declarator' => 139,
			'array_declarator' => 140,
			'complex_declarator' => 138
		}
	},
	{#State 190
		DEFAULT => -124
	},
	{#State 191
		DEFAULT => -123
	},
	{#State 192
		DEFAULT => -190
	},
	{#State 193
		ACTIONS => {
			"[" => 194
		},
		DEFAULT => -191,
		GOTOS => {
			'fixed_array_sizes' => 264,
			'fixed_array_size' => 193
		}
	},
	{#State 194
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			'error' => 266,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'const_exp' => 200,
			'and_expr' => 212,
			'or_expr' => 201,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'xor_expr' => 203,
			'shift_expr' => 204,
			'positive_int_const' => 265,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 195
		DEFAULT => -87
	},
	{#State 196
		ACTIONS => {
			"::" => 134
		},
		DEFAULT => -81
	},
	{#State 197
		ACTIONS => {
			">" => 267
		}
	},
	{#State 198
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			'error' => 269,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'const_exp' => 268,
			'and_expr' => 212,
			'or_expr' => 201,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'xor_expr' => 203,
			'shift_expr' => 204,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 199
		DEFAULT => -89
	},
	{#State 200
		DEFAULT => -94
	},
	{#State 201
		ACTIONS => {
			"|" => 270
		},
		DEFAULT => -59
	},
	{#State 202
		ACTIONS => {
			">" => 271
		}
	},
	{#State 203
		ACTIONS => {
			"^" => 272
		},
		DEFAULT => -60
	},
	{#State 204
		ACTIONS => {
			"<<" => 273,
			">>" => 274
		},
		DEFAULT => -64
	},
	{#State 205
		DEFAULT => -93
	},
	{#State 206
		DEFAULT => -82
	},
	{#State 207
		DEFAULT => -92
	},
	{#State 208
		ACTIONS => {
			"+" => 275,
			"-" => 276
		},
		DEFAULT => -66
	},
	{#State 209
		DEFAULT => -86
	},
	{#State 210
		DEFAULT => -88
	},
	{#State 211
		DEFAULT => -77
	},
	{#State 212
		ACTIONS => {
			"&" => 277
		},
		DEFAULT => -62
	},
	{#State 213
		DEFAULT => -85
	},
	{#State 214
		ACTIONS => {
			"%" => 279,
			"*" => 278,
			"/" => 280
		},
		DEFAULT => -69
	},
	{#State 215
		ACTIONS => {
			'STRING_LITERAL' => 215
		},
		DEFAULT => -90,
		GOTOS => {
			'string_literal' => 281
		}
	},
	{#State 216
		DEFAULT => -79
	},
	{#State 217
		DEFAULT => -72
	},
	{#State 218
		DEFAULT => -78
	},
	{#State 219
		DEFAULT => -80
	},
	{#State 220
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			"::" => 70,
			'STRING_LITERAL' => 215,
			'FALSE' => 205,
			'CHARACTER_LITERAL' => 195,
			'INTEGER_LITERAL' => 213,
			'TRUE' => 207,
			"(" => 198
		},
		GOTOS => {
			'string_literal' => 209,
			'boolean_literal' => 199,
			'scoped_name' => 196,
			'primary_expr' => 282,
			'literal' => 206
		}
	},
	{#State 221
		ACTIONS => {
			"{" => -145
		},
		DEFAULT => -143
	},
	{#State 222
		DEFAULT => -142
	},
	{#State 223
		DEFAULT => -173
	},
	{#State 224
		DEFAULT => -180
	},
	{#State 225
		ACTIONS => {
			'IDENTIFIER' => 152
		},
		DEFAULT => -179,
		GOTOS => {
			'enumerators' => 283,
			'enumerator' => 151
		}
	},
	{#State 226
		DEFAULT => -172
	},
	{#State 227
		DEFAULT => -50
	},
	{#State 228
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			'error' => 285,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'const_exp' => 284,
			'and_expr' => 212,
			'or_expr' => 201,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'xor_expr' => 203,
			'shift_expr' => 204,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 229
		DEFAULT => -157
	},
	{#State 230
		ACTIONS => {
			"::" => 134
		},
		DEFAULT => -160
	},
	{#State 231
		DEFAULT => -159
	},
	{#State 232
		ACTIONS => {
			")" => 286
		}
	},
	{#State 233
		ACTIONS => {
			")" => 287
		}
	},
	{#State 234
		DEFAULT => -158
	},
	{#State 235
		DEFAULT => -156
	},
	{#State 236
		ACTIONS => {
			"::" => 134
		},
		DEFAULT => -42
	},
	{#State 237
		DEFAULT => -38
	},
	{#State 238
		ACTIONS => {
			"," => 288
		},
		DEFAULT => -40
	},
	{#State 239
		DEFAULT => -37
	},
	{#State 240
		DEFAULT => -210
	},
	{#State 241
		DEFAULT => -209
	},
	{#State 242
		DEFAULT => -196
	},
	{#State 243
		ACTIONS => {
			'error' => 137,
			'IDENTIFIER' => 291
		},
		GOTOS => {
			'simple_declarators' => 290,
			'simple_declarator' => 289
		}
	},
	{#State 244
		DEFAULT => -245
	},
	{#State 245
		DEFAULT => -244
	},
	{#State 246
		DEFAULT => -246
	},
	{#State 247
		DEFAULT => -247
	},
	{#State 248
		DEFAULT => -227
	},
	{#State 249
		ACTIONS => {
			")" => 292
		}
	},
	{#State 250
		ACTIONS => {
			")" => 293
		}
	},
	{#State 251
		DEFAULT => -229
	},
	{#State 252
		ACTIONS => {
			'CHAR' => 63,
			'VOID' => 244,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 28,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 160,
			'signed_long_int' => 49,
			'signed_short_int' => 71,
			'string_type' => 161,
			'op_param_type_spec' => 245,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 246,
			'base_type_spec' => 162,
			'any_type' => 55,
			'enum_type' => 57,
			'unsigned_long_int' => 77,
			'param_type_spec' => 294,
			'enum_header' => 20,
			'constr_type_spec' => 247,
			'union_header' => 24,
			'unsigned_short_int' => 60
		}
	},
	{#State 253
		ACTIONS => {
			")" => 296,
			"," => 295
		}
	},
	{#State 254
		DEFAULT => -220
	},
	{#State 255
		DEFAULT => -228
	},
	{#State 256
		ACTIONS => {
			";" => 297
		},
		DEFAULT => -223
	},
	{#State 257
		ACTIONS => {
			'CONTEXT' => 298
		},
		DEFAULT => -241,
		GOTOS => {
			'context_expr' => 299
		}
	},
	{#State 258
		ACTIONS => {
			'error' => 301,
			"(" => 300
		}
	},
	{#State 259
		DEFAULT => -148
	},
	{#State 260
		DEFAULT => -185
	},
	{#State 261
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			'error' => 303,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'const_exp' => 200,
			'and_expr' => 212,
			'or_expr' => 201,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'xor_expr' => 203,
			'shift_expr' => 204,
			'positive_int_const' => 302,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 262
		DEFAULT => -184
	},
	{#State 263
		DEFAULT => -119
	},
	{#State 264
		DEFAULT => -192
	},
	{#State 265
		ACTIONS => {
			"]" => 304
		}
	},
	{#State 266
		ACTIONS => {
			"]" => 305
		}
	},
	{#State 267
		DEFAULT => -187
	},
	{#State 268
		ACTIONS => {
			")" => 306
		}
	},
	{#State 269
		ACTIONS => {
			")" => 307
		}
	},
	{#State 270
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'and_expr' => 212,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'xor_expr' => 308,
			'shift_expr' => 204,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 271
		DEFAULT => -189
	},
	{#State 272
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'and_expr' => 309,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'shift_expr' => 204,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 273
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 310
		}
	},
	{#State 274
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 311
		}
	},
	{#State 275
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 312,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'literal' => 206,
			'unary_operator' => 220
		}
	},
	{#State 276
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 313,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'literal' => 206,
			'unary_operator' => 220
		}
	},
	{#State 277
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'shift_expr' => 314,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 278
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'string_literal' => 209,
			'boolean_literal' => 199,
			'scoped_name' => 196,
			'primary_expr' => 211,
			'literal' => 206,
			'unary_operator' => 220,
			'unary_expr' => 315
		}
	},
	{#State 279
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'string_literal' => 209,
			'boolean_literal' => 199,
			'scoped_name' => 196,
			'primary_expr' => 211,
			'literal' => 206,
			'unary_operator' => 220,
			'unary_expr' => 316
		}
	},
	{#State 280
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'string_literal' => 209,
			'boolean_literal' => 199,
			'scoped_name' => 196,
			'primary_expr' => 211,
			'literal' => 206,
			'unary_operator' => 220,
			'unary_expr' => 317
		}
	},
	{#State 281
		DEFAULT => -91
	},
	{#State 282
		DEFAULT => -76
	},
	{#State 283
		DEFAULT => -178
	},
	{#State 284
		DEFAULT => -48
	},
	{#State 285
		DEFAULT => -49
	},
	{#State 286
		DEFAULT => -152
	},
	{#State 287
		ACTIONS => {
			"{" => 319,
			'error' => 318
		}
	},
	{#State 288
		ACTIONS => {
			'IDENTIFIER' => 75,
			"::" => 70
		},
		GOTOS => {
			'scoped_name' => 236,
			'interface_names' => 320,
			'interface_name' => 238
		}
	},
	{#State 289
		ACTIONS => {
			"," => 321
		},
		DEFAULT => -199
	},
	{#State 290
		DEFAULT => -195
	},
	{#State 291
		DEFAULT => -122
	},
	{#State 292
		DEFAULT => -221
	},
	{#State 293
		DEFAULT => -222
	},
	{#State 294
		ACTIONS => {
			'error' => 137,
			'IDENTIFIER' => 291
		},
		GOTOS => {
			'simple_declarator' => 322
		}
	},
	{#State 295
		ACTIONS => {
			'IN' => 248,
			"..." => 323,
			")" => 324,
			'OUT' => 255,
			'INOUT' => 251
		},
		DEFAULT => -230,
		GOTOS => {
			'param_dcl' => 325,
			'param_attribute' => 252
		}
	},
	{#State 296
		DEFAULT => -217
	},
	{#State 297
		DEFAULT => -225
	},
	{#State 298
		ACTIONS => {
			'error' => 327,
			"(" => 326
		}
	},
	{#State 299
		DEFAULT => -207
	},
	{#State 300
		ACTIONS => {
			'error' => 329,
			'IDENTIFIER' => 75,
			"::" => 70
		},
		GOTOS => {
			'scoped_name' => 328,
			'exception_names' => 330,
			'exception_name' => 331
		}
	},
	{#State 301
		DEFAULT => -233
	},
	{#State 302
		ACTIONS => {
			">" => 332
		}
	},
	{#State 303
		ACTIONS => {
			">" => 333
		}
	},
	{#State 304
		DEFAULT => -193
	},
	{#State 305
		DEFAULT => -194
	},
	{#State 306
		DEFAULT => -83
	},
	{#State 307
		DEFAULT => -84
	},
	{#State 308
		ACTIONS => {
			"^" => 272
		},
		DEFAULT => -61
	},
	{#State 309
		ACTIONS => {
			"&" => 277
		},
		DEFAULT => -63
	},
	{#State 310
		ACTIONS => {
			"+" => 275,
			"-" => 276
		},
		DEFAULT => -68
	},
	{#State 311
		ACTIONS => {
			"+" => 275,
			"-" => 276
		},
		DEFAULT => -67
	},
	{#State 312
		ACTIONS => {
			"%" => 279,
			"*" => 278,
			"/" => 280
		},
		DEFAULT => -70
	},
	{#State 313
		ACTIONS => {
			"%" => 279,
			"*" => 278,
			"/" => 280
		},
		DEFAULT => -71
	},
	{#State 314
		ACTIONS => {
			"<<" => 273,
			">>" => 274
		},
		DEFAULT => -65
	},
	{#State 315
		DEFAULT => -73
	},
	{#State 316
		DEFAULT => -75
	},
	{#State 317
		DEFAULT => -74
	},
	{#State 318
		DEFAULT => -151
	},
	{#State 319
		ACTIONS => {
			'error' => 337,
			'CASE' => 334,
			'DEFAULT' => 336
		},
		GOTOS => {
			'case_labels' => 339,
			'switch_body' => 338,
			'case' => 335,
			'case_label' => 340
		}
	},
	{#State 320
		DEFAULT => -41
	},
	{#State 321
		ACTIONS => {
			'error' => 137,
			'IDENTIFIER' => 291
		},
		GOTOS => {
			'simple_declarators' => 341,
			'simple_declarator' => 289
		}
	},
	{#State 322
		DEFAULT => -226
	},
	{#State 323
		ACTIONS => {
			")" => 342
		}
	},
	{#State 324
		DEFAULT => -219
	},
	{#State 325
		DEFAULT => -224
	},
	{#State 326
		ACTIONS => {
			'error' => 343,
			'STRING_LITERAL' => 215
		},
		GOTOS => {
			'string_literal' => 344,
			'string_literals' => 345
		}
	},
	{#State 327
		DEFAULT => -240
	},
	{#State 328
		ACTIONS => {
			"::" => 134
		},
		DEFAULT => -237
	},
	{#State 329
		ACTIONS => {
			")" => 346
		}
	},
	{#State 330
		ACTIONS => {
			")" => 347
		}
	},
	{#State 331
		ACTIONS => {
			"," => 348
		},
		DEFAULT => -235
	},
	{#State 332
		DEFAULT => -182
	},
	{#State 333
		DEFAULT => -183
	},
	{#State 334
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 210,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 215,
			'CHARACTER_LITERAL' => 195,
			"+" => 216,
			'error' => 350,
			"-" => 218,
			"::" => 70,
			'FALSE' => 205,
			'INTEGER_LITERAL' => 213,
			"~" => 219,
			"(" => 198,
			'TRUE' => 207
		},
		GOTOS => {
			'mult_expr' => 214,
			'string_literal' => 209,
			'boolean_literal' => 199,
			'primary_expr' => 211,
			'const_exp' => 349,
			'and_expr' => 212,
			'or_expr' => 201,
			'unary_expr' => 217,
			'scoped_name' => 196,
			'xor_expr' => 203,
			'shift_expr' => 204,
			'literal' => 206,
			'unary_operator' => 220,
			'add_expr' => 208
		}
	},
	{#State 335
		ACTIONS => {
			'CASE' => 334,
			'DEFAULT' => 336
		},
		DEFAULT => -161,
		GOTOS => {
			'case_labels' => 339,
			'switch_body' => 351,
			'case' => 335,
			'case_label' => 340
		}
	},
	{#State 336
		ACTIONS => {
			'error' => 352,
			":" => 353
		}
	},
	{#State 337
		ACTIONS => {
			"}" => 354
		}
	},
	{#State 338
		ACTIONS => {
			"}" => 355
		}
	},
	{#State 339
		ACTIONS => {
			'CHAR' => 63,
			'VOID' => 64,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 28,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'type_spec' => 356,
			'signed_long_int' => 49,
			'signed_short_int' => 71,
			'string_type' => 53,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'element_spec' => 357,
			'sequence_type' => 76,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 80
		}
	},
	{#State 340
		ACTIONS => {
			'CASE' => 334,
			'DEFAULT' => 336
		},
		DEFAULT => -164,
		GOTOS => {
			'case_labels' => 358,
			'case_label' => 340
		}
	},
	{#State 341
		DEFAULT => -200
	},
	{#State 342
		DEFAULT => -218
	},
	{#State 343
		ACTIONS => {
			")" => 359
		}
	},
	{#State 344
		ACTIONS => {
			"," => 360
		},
		DEFAULT => -242
	},
	{#State 345
		ACTIONS => {
			")" => 361
		}
	},
	{#State 346
		DEFAULT => -232
	},
	{#State 347
		DEFAULT => -231
	},
	{#State 348
		ACTIONS => {
			'IDENTIFIER' => 75,
			"::" => 70
		},
		GOTOS => {
			'scoped_name' => 328,
			'exception_names' => 362,
			'exception_name' => 331
		}
	},
	{#State 349
		ACTIONS => {
			'error' => 363,
			":" => 364
		}
	},
	{#State 350
		DEFAULT => -168
	},
	{#State 351
		DEFAULT => -162
	},
	{#State 352
		DEFAULT => -170
	},
	{#State 353
		DEFAULT => -169
	},
	{#State 354
		DEFAULT => -150
	},
	{#State 355
		DEFAULT => -149
	},
	{#State 356
		ACTIONS => {
			'error' => 137,
			'IDENTIFIER' => 141
		},
		GOTOS => {
			'declarator' => 365,
			'simple_declarator' => 139,
			'array_declarator' => 140,
			'complex_declarator' => 138
		}
	},
	{#State 357
		ACTIONS => {
			'error' => 32,
			";" => 31
		},
		GOTOS => {
			'check_semicolon' => 366
		}
	},
	{#State 358
		DEFAULT => -165
	},
	{#State 359
		DEFAULT => -239
	},
	{#State 360
		ACTIONS => {
			'STRING_LITERAL' => 215
		},
		GOTOS => {
			'string_literal' => 344,
			'string_literals' => 367
		}
	},
	{#State 361
		DEFAULT => -238
	},
	{#State 362
		DEFAULT => -236
	},
	{#State 363
		DEFAULT => -167
	},
	{#State 364
		DEFAULT => -166
	},
	{#State 365
		DEFAULT => -171
	},
	{#State 366
		DEFAULT => -163
	},
	{#State 367
		DEFAULT => -243
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
#line 52 "parser20.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 0,
sub
#line 58 "parser20.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 62 "parser20.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 69 "parser20.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 73 "parser20.yp"
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
		 'definition', 3,
sub
#line 92 "parser20.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 12
		 'check_semicolon', 1, undef
	],
	[#Rule 13
		 'check_semicolon', 1,
sub
#line 106 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 14
		 'module', 4,
sub
#line 115 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 15
		 'module', 4,
sub
#line 122 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 16
		 'module', 3,
sub
#line 128 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("Empty module.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 17
		 'module', 3,
sub
#line 134 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module_header', 2,
sub
#line 143 "parser20.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 149 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'interface', 1, undef
	],
	[#Rule 21
		 'interface', 1, undef
	],
	[#Rule 22
		 'interface_dcl', 3,
sub
#line 166 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 23
		 'interface_dcl', 4,
sub
#line 174 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 182 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 25
		 'forward_dcl', 2,
sub
#line 193 "parser20.yp"
{
			new ForwardRegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 199 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 27
		 'interface_header', 3,
sub
#line 208 "parser20.yp"
{
			new RegularInterface($_[0],
					'idf'					=>	$_[2],
					'inheritance'			=>	$_[3]
			);
		}
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 215 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 29
		 'interface_body', 1, undef
	],
	[#Rule 30
		 'exports', 1,
sub
#line 229 "parser20.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 31
		 'exports', 2,
sub
#line 233 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 32
		 'export', 2, undef
	],
	[#Rule 33
		 'export', 2, undef
	],
	[#Rule 34
		 'export', 2, undef
	],
	[#Rule 35
		 'export', 2, undef
	],
	[#Rule 36
		 'export', 2, undef
	],
	[#Rule 37
		 'interface_inheritance_spec', 2,
sub
#line 256 "parser20.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'		=>	$_[2]
			);
		}
	],
	[#Rule 38
		 'interface_inheritance_spec', 2,
sub
#line 262 "parser20.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 39
		 'interface_inheritance_spec', 0, undef
	],
	[#Rule 40
		 'interface_names', 1,
sub
#line 272 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 41
		 'interface_names', 3,
sub
#line 276 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 42
		 'interface_name', 1,
sub
#line 284 "parser20.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 43
		 'scoped_name', 1, undef
	],
	[#Rule 44
		 'scoped_name', 2,
sub
#line 294 "parser20.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 45
		 'scoped_name', 2,
sub
#line 298 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 46
		 'scoped_name', 3,
sub
#line 304 "parser20.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 47
		 'scoped_name', 3,
sub
#line 308 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 48
		 'const_dcl', 5,
sub
#line 318 "parser20.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 49
		 'const_dcl', 5,
sub
#line 326 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 50
		 'const_dcl', 4,
sub
#line 331 "parser20.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 51
		 'const_dcl', 3,
sub
#line 336 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 52
		 'const_dcl', 2,
sub
#line 341 "parser20.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 53
		 'const_type', 1, undef
	],
	[#Rule 54
		 'const_type', 1, undef
	],
	[#Rule 55
		 'const_type', 1, undef
	],
	[#Rule 56
		 'const_type', 1, undef
	],
	[#Rule 57
		 'const_type', 1, undef
	],
	[#Rule 58
		 'const_type', 1,
sub
#line 360 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 59
		 'const_exp', 1, undef
	],
	[#Rule 60
		 'or_expr', 1, undef
	],
	[#Rule 61
		 'or_expr', 3,
sub
#line 376 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 62
		 'xor_expr', 1, undef
	],
	[#Rule 63
		 'xor_expr', 3,
sub
#line 386 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 64
		 'and_expr', 1, undef
	],
	[#Rule 65
		 'and_expr', 3,
sub
#line 396 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 66
		 'shift_expr', 1, undef
	],
	[#Rule 67
		 'shift_expr', 3,
sub
#line 406 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 68
		 'shift_expr', 3,
sub
#line 410 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 69
		 'add_expr', 1, undef
	],
	[#Rule 70
		 'add_expr', 3,
sub
#line 420 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 71
		 'add_expr', 3,
sub
#line 424 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 72
		 'mult_expr', 1, undef
	],
	[#Rule 73
		 'mult_expr', 3,
sub
#line 434 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 74
		 'mult_expr', 3,
sub
#line 438 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 75
		 'mult_expr', 3,
sub
#line 442 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 76
		 'unary_expr', 2,
sub
#line 450 "parser20.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 77
		 'unary_expr', 1, undef
	],
	[#Rule 78
		 'unary_operator', 1, undef
	],
	[#Rule 79
		 'unary_operator', 1, undef
	],
	[#Rule 80
		 'unary_operator', 1, undef
	],
	[#Rule 81
		 'primary_expr', 1,
sub
#line 470 "parser20.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 82
		 'primary_expr', 1,
sub
#line 476 "parser20.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 83
		 'primary_expr', 3,
sub
#line 480 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 84
		 'primary_expr', 3,
sub
#line 484 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 85
		 'literal', 1,
sub
#line 493 "parser20.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 86
		 'literal', 1,
sub
#line 500 "parser20.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 87
		 'literal', 1,
sub
#line 506 "parser20.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 88
		 'literal', 1,
sub
#line 512 "parser20.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 89
		 'literal', 1, undef
	],
	[#Rule 90
		 'string_literal', 1, undef
	],
	[#Rule 91
		 'string_literal', 2,
sub
#line 526 "parser20.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 92
		 'boolean_literal', 1,
sub
#line 534 "parser20.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 93
		 'boolean_literal', 1,
sub
#line 540 "parser20.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 94
		 'positive_int_const', 1,
sub
#line 550 "parser20.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 95
		 'type_dcl', 2,
sub
#line 560 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 96
		 'type_dcl', 1, undef
	],
	[#Rule 97
		 'type_dcl', 1, undef
	],
	[#Rule 98
		 'type_dcl', 1, undef
	],
	[#Rule 99
		 'type_dcl', 2,
sub
#line 570 "parser20.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 100
		 'type_declarator', 2,
sub
#line 579 "parser20.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 101
		 'type_spec', 1, undef
	],
	[#Rule 102
		 'type_spec', 1, undef
	],
	[#Rule 103
		 'simple_type_spec', 1, undef
	],
	[#Rule 104
		 'simple_type_spec', 1, undef
	],
	[#Rule 105
		 'simple_type_spec', 1,
sub
#line 602 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 106
		 'simple_type_spec', 1,
sub
#line 606 "parser20.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 107
		 'base_type_spec', 1, undef
	],
	[#Rule 108
		 'base_type_spec', 1, undef
	],
	[#Rule 109
		 'base_type_spec', 1, undef
	],
	[#Rule 110
		 'base_type_spec', 1, undef
	],
	[#Rule 111
		 'base_type_spec', 1, undef
	],
	[#Rule 112
		 'base_type_spec', 1, undef
	],
	[#Rule 113
		 'template_type_spec', 1, undef
	],
	[#Rule 114
		 'template_type_spec', 1, undef
	],
	[#Rule 115
		 'constr_type_spec', 1, undef
	],
	[#Rule 116
		 'constr_type_spec', 1, undef
	],
	[#Rule 117
		 'constr_type_spec', 1, undef
	],
	[#Rule 118
		 'declarators', 1,
sub
#line 651 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 119
		 'declarators', 3,
sub
#line 655 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 120
		 'declarator', 1,
sub
#line 664 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 121
		 'declarator', 1, undef
	],
	[#Rule 122
		 'simple_declarator', 1, undef
	],
	[#Rule 123
		 'simple_declarator', 2,
sub
#line 676 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 124
		 'simple_declarator', 2,
sub
#line 681 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 125
		 'complex_declarator', 1, undef
	],
	[#Rule 126
		 'floating_pt_type', 1,
sub
#line 696 "parser20.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 127
		 'floating_pt_type', 1,
sub
#line 702 "parser20.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 128
		 'integer_type', 1, undef
	],
	[#Rule 129
		 'integer_type', 1, undef
	],
	[#Rule 130
		 'signed_int', 1, undef
	],
	[#Rule 131
		 'signed_int', 1, undef
	],
	[#Rule 132
		 'signed_long_int', 1,
sub
#line 728 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 133
		 'signed_short_int', 1,
sub
#line 738 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 134
		 'unsigned_int', 1, undef
	],
	[#Rule 135
		 'unsigned_int', 1, undef
	],
	[#Rule 136
		 'unsigned_long_int', 2,
sub
#line 756 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 137
		 'unsigned_short_int', 2,
sub
#line 766 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 138
		 'char_type', 1,
sub
#line 776 "parser20.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 139
		 'boolean_type', 1,
sub
#line 786 "parser20.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 140
		 'octet_type', 1,
sub
#line 796 "parser20.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 141
		 'any_type', 1,
sub
#line 806 "parser20.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 142
		 'struct_type', 4,
sub
#line 816 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 143
		 'struct_type', 4,
sub
#line 823 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 144
		 'struct_header', 2,
sub
#line 832 "parser20.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 145
		 'struct_header', 4,
sub
#line 838 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 146
		 'member_list', 1,
sub
#line 848 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 147
		 'member_list', 2,
sub
#line 852 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 148
		 'member', 3,
sub
#line 861 "parser20.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 149
		 'union_type', 8,
sub
#line 872 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 150
		 'union_type', 8,
sub
#line 880 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 151
		 'union_type', 6,
sub
#line 886 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 152
		 'union_type', 5,
sub
#line 892 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 153
		 'union_type', 3,
sub
#line 898 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 154
		 'union_header', 2,
sub
#line 907 "parser20.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 155
		 'union_header', 2,
sub
#line 913 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 156
		 'switch_type_spec', 1, undef
	],
	[#Rule 157
		 'switch_type_spec', 1, undef
	],
	[#Rule 158
		 'switch_type_spec', 1, undef
	],
	[#Rule 159
		 'switch_type_spec', 1, undef
	],
	[#Rule 160
		 'switch_type_spec', 1,
sub
#line 930 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 161
		 'switch_body', 1,
sub
#line 938 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 162
		 'switch_body', 2,
sub
#line 942 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 163
		 'case', 3,
sub
#line 951 "parser20.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 164
		 'case_labels', 1,
sub
#line 961 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 165
		 'case_labels', 2,
sub
#line 965 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 166
		 'case_label', 3,
sub
#line 974 "parser20.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 167
		 'case_label', 3,
sub
#line 978 "parser20.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 168
		 'case_label', 2,
sub
#line 984 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 169
		 'case_label', 2,
sub
#line 989 "parser20.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 170
		 'case_label', 2,
sub
#line 993 "parser20.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 171
		 'element_spec', 2,
sub
#line 1003 "parser20.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 172
		 'enum_type', 4,
sub
#line 1014 "parser20.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 173
		 'enum_type', 4,
sub
#line 1020 "parser20.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 174
		 'enum_type', 2,
sub
#line 1025 "parser20.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 175
		 'enum_header', 2,
sub
#line 1034 "parser20.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 176
		 'enum_header', 2,
sub
#line 1040 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 177
		 'enumerators', 1,
sub
#line 1048 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 178
		 'enumerators', 3,
sub
#line 1052 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 179
		 'enumerators', 2,
sub
#line 1057 "parser20.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 180
		 'enumerators', 2,
sub
#line 1062 "parser20.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 181
		 'enumerator', 1,
sub
#line 1071 "parser20.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 182
		 'sequence_type', 6,
sub
#line 1081 "parser20.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 183
		 'sequence_type', 6,
sub
#line 1089 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 184
		 'sequence_type', 4,
sub
#line 1094 "parser20.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 185
		 'sequence_type', 4,
sub
#line 1101 "parser20.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 186
		 'sequence_type', 2,
sub
#line 1106 "parser20.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 187
		 'string_type', 4,
sub
#line 1115 "parser20.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 188
		 'string_type', 1,
sub
#line 1122 "parser20.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 189
		 'string_type', 4,
sub
#line 1128 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 190
		 'array_declarator', 2,
sub
#line 1137 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 191
		 'fixed_array_sizes', 1,
sub
#line 1145 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 192
		 'fixed_array_sizes', 2,
sub
#line 1149 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 193
		 'fixed_array_size', 3,
sub
#line 1158 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 194
		 'fixed_array_size', 3,
sub
#line 1162 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 195
		 'attr_dcl', 4,
sub
#line 1171 "parser20.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 196
		 'attr_dcl', 3,
sub
#line 1179 "parser20.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 197
		 'attr_mod', 1, undef
	],
	[#Rule 198
		 'attr_mod', 0, undef
	],
	[#Rule 199
		 'simple_declarators', 1,
sub
#line 1194 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 200
		 'simple_declarators', 3,
sub
#line 1198 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 201
		 'except_dcl', 3,
sub
#line 1207 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 202
		 'except_dcl', 4,
sub
#line 1212 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 203
		 'except_dcl', 4,
sub
#line 1219 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 204
		 'except_dcl', 2,
sub
#line 1225 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 205
		 'exception_header', 2,
sub
#line 1234 "parser20.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 206
		 'exception_header', 2,
sub
#line 1240 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 207
		 'op_dcl', 4,
sub
#line 1249 "parser20.yp"
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
	[#Rule 208
		 'op_dcl', 2,
sub
#line 1259 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 209
		 'op_header', 3,
sub
#line 1269 "parser20.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 210
		 'op_header', 3,
sub
#line 1277 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 211
		 'op_mod', 1, undef
	],
	[#Rule 212
		 'op_mod', 0, undef
	],
	[#Rule 213
		 'op_attribute', 1, undef
	],
	[#Rule 214
		 'op_type_spec', 1, undef
	],
	[#Rule 215
		 'op_type_spec', 1,
sub
#line 1301 "parser20.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 216
		 'op_type_spec', 1,
sub
#line 1307 "parser20.yp"
{
			$_[0]->Error("op_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 217
		 'parameter_dcls', 3,
sub
#line 1316 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 218
		 'parameter_dcls', 5,
sub
#line 1320 "parser20.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 219
		 'parameter_dcls', 4,
sub
#line 1325 "parser20.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			$_[2];
		}
	],
	[#Rule 220
		 'parameter_dcls', 2,
sub
#line 1330 "parser20.yp"
{
			undef;
		}
	],
	[#Rule 221
		 'parameter_dcls', 3,
sub
#line 1334 "parser20.yp"
{
			$_[0]->Error("'...' unexpected.\n");
			undef;
		}
	],
	[#Rule 222
		 'parameter_dcls', 3,
sub
#line 1339 "parser20.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 223
		 'param_dcls', 1,
sub
#line 1347 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 224
		 'param_dcls', 3,
sub
#line 1351 "parser20.yp"
{
			push(@{$_[1]},$_[3]);
			$_[1];
		}
	],
	[#Rule 225
		 'param_dcls', 2,
sub
#line 1356 "parser20.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 226
		 'param_dcl', 3,
sub
#line 1365 "parser20.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 227
		 'param_attribute', 1, undef
	],
	[#Rule 228
		 'param_attribute', 1, undef
	],
	[#Rule 229
		 'param_attribute', 1, undef
	],
	[#Rule 230
		 'param_attribute', 0,
sub
#line 1383 "parser20.yp"
{
			$_[0]->Error("(in|out|inout) expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 231
		 'raises_expr', 4,
sub
#line 1392 "parser20.yp"
{
			$_[3];
		}
	],
	[#Rule 232
		 'raises_expr', 4,
sub
#line 1396 "parser20.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'raises_expr', 2,
sub
#line 1401 "parser20.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 234
		 'raises_expr', 0, undef
	],
	[#Rule 235
		 'exception_names', 1,
sub
#line 1411 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 236
		 'exception_names', 3,
sub
#line 1415 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 237
		 'exception_name', 1,
sub
#line 1423 "parser20.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 238
		 'context_expr', 4,
sub
#line 1431 "parser20.yp"
{
			$_[3];
		}
	],
	[#Rule 239
		 'context_expr', 4,
sub
#line 1435 "parser20.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 240
		 'context_expr', 2,
sub
#line 1440 "parser20.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 241
		 'context_expr', 0, undef
	],
	[#Rule 242
		 'string_literals', 1,
sub
#line 1450 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 243
		 'string_literals', 3,
sub
#line 1454 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 244
		 'param_type_spec', 1, undef
	],
	[#Rule 245
		 'param_type_spec', 1,
sub
#line 1465 "parser20.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 246
		 'param_type_spec', 1,
sub
#line 1470 "parser20.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 247
		 'param_type_spec', 1,
sub
#line 1475 "parser20.yp"
{
			$_[0]->Error("param_type_spec expected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 248
		 'op_param_type_spec', 1, undef
	],
	[#Rule 249
		 'op_param_type_spec', 1, undef
	],
	[#Rule 250
		 'op_param_type_spec', 1,
sub
#line 1487 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1492 "parser20.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '2.0';

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
