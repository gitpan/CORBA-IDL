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
			'MODULE' => 13,
			'UNION' => 15,
			'STRUCT' => 5,
			'error' => 18,
			'CONST' => 21,
			'EXCEPTION' => 22,
			'ENUM' => 27,
			'INTERFACE' => 28
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
			'interface_dcl' => 14,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'module' => 20,
			'enum_header' => 19,
			'union_header' => 23,
			'type_dcl' => 24,
			'definitions' => 25,
			'definition' => 26
		}
	},
	{#State 1
		ACTIONS => {
			'error' => 30,
			";" => 29
		}
	},
	{#State 2
		ACTIONS => {
			"{" => 31
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 33,
			";" => 32
		}
	},
	{#State 4
		ACTIONS => {
			'' => 34
		}
	},
	{#State 5
		ACTIONS => {
			'IDENTIFIER' => 35
		}
	},
	{#State 6
		ACTIONS => {
			"{" => 37,
			'error' => 36
		}
	},
	{#State 7
		ACTIONS => {
			'error' => 39,
			";" => 38
		}
	},
	{#State 8
		DEFAULT => -102
	},
	{#State 9
		ACTIONS => {
			"{" => 41,
			'error' => 40
		}
	},
	{#State 10
		DEFAULT => -103
	},
	{#State 11
		ACTIONS => {
			'CHAR' => 63,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 66,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'UNION' => 15,
			'error' => 58,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 27,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'boolean_type' => 65,
			'integer_type' => 64,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'signed_long_int' => 49,
			'type_spec' => 50,
			'signed_short_int' => 70,
			'type_declarator' => 51,
			'string_type' => 53,
			'struct_type' => 71,
			'union_type' => 72,
			'struct_header' => 12,
			'sequence_type' => 75,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 76,
			'template_type_spec' => 77,
			'enum_header' => 19,
			'constr_type_spec' => 78,
			'union_header' => 23,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 79
		}
	},
	{#State 12
		ACTIONS => {
			"{" => 80
		}
	},
	{#State 13
		ACTIONS => {
			'error' => 81,
			'IDENTIFIER' => 82
		}
	},
	{#State 14
		DEFAULT => -21
	},
	{#State 15
		ACTIONS => {
			'IDENTIFIER' => 83
		}
	},
	{#State 16
		DEFAULT => -104
	},
	{#State 17
		DEFAULT => -22
	},
	{#State 18
		DEFAULT => -3
	},
	{#State 19
		ACTIONS => {
			"{" => 85,
			'error' => 84
		}
	},
	{#State 20
		ACTIONS => {
			'error' => 87,
			";" => 86
		}
	},
	{#State 21
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'DOUBLE' => 66,
			'error' => 92,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'FLOAT' => 61,
			'UNSIGNED' => 52
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 88,
			'signed_int' => 44,
			'integer_type' => 94,
			'boolean_type' => 93,
			'char_type' => 89,
			'unsigned_long_int' => 76,
			'scoped_name' => 90,
			'signed_long_int' => 49,
			'unsigned_short_int' => 60,
			'signed_short_int' => 70,
			'const_type' => 95,
			'string_type' => 91
		}
	},
	{#State 22
		ACTIONS => {
			'error' => 96,
			'IDENTIFIER' => 97
		}
	},
	{#State 23
		ACTIONS => {
			'SWITCH' => 98
		}
	},
	{#State 24
		ACTIONS => {
			'error' => 100,
			";" => 99
		}
	},
	{#State 25
		DEFAULT => -1
	},
	{#State 26
		ACTIONS => {
			'TYPEDEF' => 11,
			'MODULE' => 13,
			'UNION' => 15,
			'STRUCT' => 5,
			'CONST' => 21,
			'EXCEPTION' => 22,
			'ENUM' => 27,
			'INTERFACE' => 28
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
			'interface_dcl' => 14,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'enum_header' => 19,
			'module' => 20,
			'union_header' => 23,
			'definitions' => 101,
			'type_dcl' => 24,
			'definition' => 26
		}
	},
	{#State 27
		ACTIONS => {
			'error' => 102,
			'IDENTIFIER' => 103
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 104,
			'IDENTIFIER' => 105
		}
	},
	{#State 29
		DEFAULT => -7
	},
	{#State 30
		DEFAULT => -12
	},
	{#State 31
		ACTIONS => {
			'CHAR' => -220,
			'ONEWAY' => 106,
			'VOID' => -220,
			'STRUCT' => 5,
			'DOUBLE' => -220,
			'LONG' => -220,
			'STRING' => -220,
			"::" => -220,
			'UNSIGNED' => -220,
			'SHORT' => -220,
			'TYPEDEF' => 11,
			'BOOLEAN' => -220,
			'IDENTIFIER' => -220,
			'UNION' => 15,
			'READONLY' => 117,
			'ATTRIBUTE' => -203,
			'error' => 111,
			'CONST' => 21,
			"}" => 112,
			'EXCEPTION' => 22,
			'OCTET' => -220,
			'FLOAT' => -220,
			'ENUM' => 27,
			'ANY' => -220
		},
		GOTOS => {
			'const_dcl' => 113,
			'op_mod' => 107,
			'except_dcl' => 108,
			'op_attribute' => 109,
			'attr_mod' => 110,
			'exports' => 114,
			'export' => 115,
			'struct_type' => 8,
			'op_header' => 116,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 16,
			'op_dcl' => 118,
			'enum_header' => 19,
			'attr_dcl' => 119,
			'type_dcl' => 120,
			'union_header' => 23,
			'interface_body' => 121
		}
	},
	{#State 32
		DEFAULT => -8
	},
	{#State 33
		DEFAULT => -13
	},
	{#State 34
		DEFAULT => 0
	},
	{#State 35
		DEFAULT => -148
	},
	{#State 36
		DEFAULT => -18
	},
	{#State 37
		ACTIONS => {
			'TYPEDEF' => 11,
			'MODULE' => 13,
			'UNION' => 15,
			'STRUCT' => 5,
			'error' => 122,
			'CONST' => 21,
			'EXCEPTION' => 22,
			'ENUM' => 27,
			'INTERFACE' => 28
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
			'interface_dcl' => 14,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'enum_header' => 19,
			'module' => 20,
			'union_header' => 23,
			'definitions' => 123,
			'type_dcl' => 24,
			'definition' => 26
		}
	},
	{#State 38
		DEFAULT => -9
	},
	{#State 39
		DEFAULT => -14
	},
	{#State 40
		DEFAULT => -209
	},
	{#State 41
		ACTIONS => {
			'CHAR' => 63,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 66,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'UNION' => 15,
			'error' => 125,
			"}" => 127,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 27,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 64,
			'boolean_type' => 65,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'type_spec' => 124,
			'signed_long_int' => 49,
			'signed_short_int' => 70,
			'string_type' => 53,
			'member' => 128,
			'struct_type' => 71,
			'union_type' => 72,
			'struct_header' => 12,
			'sequence_type' => 75,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 76,
			'template_type_spec' => 77,
			'enum_header' => 19,
			'member_list' => 126,
			'constr_type_spec' => 78,
			'union_header' => 23,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 79
		}
	},
	{#State 42
		DEFAULT => -133
	},
	{#State 43
		DEFAULT => -113
	},
	{#State 44
		DEFAULT => -132
	},
	{#State 45
		ACTIONS => {
			"<" => 130,
			'error' => 129
		}
	},
	{#State 46
		DEFAULT => -115
	},
	{#State 47
		DEFAULT => -117
	},
	{#State 48
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -112
	},
	{#State 49
		DEFAULT => -135
	},
	{#State 50
		ACTIONS => {
			'error' => 134,
			'IDENTIFIER' => 138
		},
		GOTOS => {
			'declarators' => 132,
			'declarator' => 133,
			'simple_declarator' => 136,
			'array_declarator' => 137,
			'complex_declarator' => 135
		}
	},
	{#State 51
		DEFAULT => -101
	},
	{#State 52
		ACTIONS => {
			'SHORT' => 139,
			'LONG' => 140
		}
	},
	{#State 53
		DEFAULT => -120
	},
	{#State 54
		DEFAULT => -137
	},
	{#State 55
		DEFAULT => -118
	},
	{#State 56
		DEFAULT => -110
	},
	{#State 57
		DEFAULT => -123
	},
	{#State 58
		DEFAULT => -105
	},
	{#State 59
		DEFAULT => -144
	},
	{#State 60
		DEFAULT => -138
	},
	{#State 61
		DEFAULT => -130
	},
	{#State 62
		DEFAULT => -145
	},
	{#State 63
		DEFAULT => -142
	},
	{#State 64
		DEFAULT => -114
	},
	{#State 65
		DEFAULT => -116
	},
	{#State 66
		DEFAULT => -131
	},
	{#State 67
		DEFAULT => -136
	},
	{#State 68
		ACTIONS => {
			"<" => 141
		},
		DEFAULT => -192
	},
	{#State 69
		ACTIONS => {
			'error' => 142,
			'IDENTIFIER' => 143
		}
	},
	{#State 70
		DEFAULT => -134
	},
	{#State 71
		DEFAULT => -121
	},
	{#State 72
		DEFAULT => -122
	},
	{#State 73
		DEFAULT => -143
	},
	{#State 74
		DEFAULT => -49
	},
	{#State 75
		DEFAULT => -119
	},
	{#State 76
		DEFAULT => -139
	},
	{#State 77
		DEFAULT => -111
	},
	{#State 78
		DEFAULT => -109
	},
	{#State 79
		DEFAULT => -108
	},
	{#State 80
		ACTIONS => {
			'CHAR' => 63,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 66,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'UNION' => 15,
			'error' => 144,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 27,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 64,
			'boolean_type' => 65,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'type_spec' => 124,
			'signed_long_int' => 49,
			'signed_short_int' => 70,
			'string_type' => 53,
			'member' => 128,
			'struct_type' => 71,
			'union_type' => 72,
			'struct_header' => 12,
			'sequence_type' => 75,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 76,
			'template_type_spec' => 77,
			'enum_header' => 19,
			'member_list' => 145,
			'constr_type_spec' => 78,
			'union_header' => 23,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 79
		}
	},
	{#State 81
		DEFAULT => -20
	},
	{#State 82
		DEFAULT => -19
	},
	{#State 83
		DEFAULT => -158
	},
	{#State 84
		DEFAULT => -178
	},
	{#State 85
		ACTIONS => {
			'error' => 146,
			'IDENTIFIER' => 148
		},
		GOTOS => {
			'enumerators' => 149,
			'enumerator' => 147
		}
	},
	{#State 86
		DEFAULT => -10
	},
	{#State 87
		DEFAULT => -15
	},
	{#State 88
		DEFAULT => -62
	},
	{#State 89
		DEFAULT => -60
	},
	{#State 90
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -64
	},
	{#State 91
		DEFAULT => -63
	},
	{#State 92
		DEFAULT => -58
	},
	{#State 93
		DEFAULT => -61
	},
	{#State 94
		DEFAULT => -59
	},
	{#State 95
		ACTIONS => {
			'error' => 150,
			'IDENTIFIER' => 151
		}
	},
	{#State 96
		DEFAULT => -211
	},
	{#State 97
		DEFAULT => -210
	},
	{#State 98
		ACTIONS => {
			'error' => 153,
			"(" => 152
		}
	},
	{#State 99
		DEFAULT => -6
	},
	{#State 100
		DEFAULT => -11
	},
	{#State 101
		DEFAULT => -5
	},
	{#State 102
		DEFAULT => -180
	},
	{#State 103
		DEFAULT => -179
	},
	{#State 104
		ACTIONS => {
			"{" => -30
		},
		DEFAULT => -27
	},
	{#State 105
		ACTIONS => {
			"{" => -28,
			":" => 154
		},
		DEFAULT => -26,
		GOTOS => {
			'interface_inheritance_spec' => 155
		}
	},
	{#State 106
		DEFAULT => -221
	},
	{#State 107
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'VOID' => 160,
			'DOUBLE' => 66,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'OCTET' => 59,
			'FLOAT' => 61,
			'UNSIGNED' => 52,
			'ANY' => 62
		},
		GOTOS => {
			'op_type_spec' => 161,
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 64,
			'boolean_type' => 65,
			'any_type' => 55,
			'base_type_spec' => 158,
			'char_type' => 46,
			'unsigned_long_int' => 76,
			'param_type_spec' => 159,
			'octet_type' => 47,
			'scoped_name' => 156,
			'unsigned_short_int' => 60,
			'signed_long_int' => 49,
			'signed_short_int' => 70,
			'string_type' => 157
		}
	},
	{#State 108
		ACTIONS => {
			'error' => 163,
			";" => 162
		}
	},
	{#State 109
		DEFAULT => -219
	},
	{#State 110
		ACTIONS => {
			'ATTRIBUTE' => 164
		}
	},
	{#State 111
		ACTIONS => {
			"}" => 165
		}
	},
	{#State 112
		DEFAULT => -23
	},
	{#State 113
		ACTIONS => {
			'error' => 167,
			";" => 166
		}
	},
	{#State 114
		DEFAULT => -31
	},
	{#State 115
		ACTIONS => {
			'ONEWAY' => 106,
			'STRUCT' => 5,
			'TYPEDEF' => 11,
			'UNION' => 15,
			'READONLY' => 117,
			'ATTRIBUTE' => -203,
			'CONST' => 21,
			"}" => -32,
			'EXCEPTION' => 22,
			'ENUM' => 27
		},
		DEFAULT => -220,
		GOTOS => {
			'const_dcl' => 113,
			'op_mod' => 107,
			'except_dcl' => 108,
			'op_attribute' => 109,
			'attr_mod' => 110,
			'exports' => 168,
			'export' => 115,
			'struct_type' => 8,
			'op_header' => 116,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 16,
			'op_dcl' => 118,
			'enum_header' => 19,
			'attr_dcl' => 119,
			'type_dcl' => 120,
			'union_header' => 23
		}
	},
	{#State 116
		ACTIONS => {
			'error' => 170,
			"(" => 169
		},
		GOTOS => {
			'parameter_dcls' => 171
		}
	},
	{#State 117
		DEFAULT => -202
	},
	{#State 118
		ACTIONS => {
			'error' => 173,
			";" => 172
		}
	},
	{#State 119
		ACTIONS => {
			'error' => 175,
			";" => 174
		}
	},
	{#State 120
		ACTIONS => {
			'error' => 177,
			";" => 176
		}
	},
	{#State 121
		ACTIONS => {
			"}" => 178
		}
	},
	{#State 122
		ACTIONS => {
			"}" => 179
		}
	},
	{#State 123
		ACTIONS => {
			"}" => 180
		}
	},
	{#State 124
		ACTIONS => {
			'IDENTIFIER' => 138
		},
		GOTOS => {
			'declarators' => 181,
			'declarator' => 133,
			'simple_declarator' => 136,
			'array_declarator' => 137,
			'complex_declarator' => 135
		}
	},
	{#State 125
		ACTIONS => {
			"}" => 182
		}
	},
	{#State 126
		ACTIONS => {
			"}" => 183
		}
	},
	{#State 127
		DEFAULT => -206
	},
	{#State 128
		ACTIONS => {
			'CHAR' => 63,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 66,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'UNION' => 15,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 27,
			'ANY' => 62
		},
		DEFAULT => -149,
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 64,
			'boolean_type' => 65,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'type_spec' => 124,
			'signed_long_int' => 49,
			'signed_short_int' => 70,
			'string_type' => 53,
			'member' => 128,
			'struct_type' => 71,
			'union_type' => 72,
			'struct_header' => 12,
			'sequence_type' => 75,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 76,
			'template_type_spec' => 77,
			'enum_header' => 19,
			'member_list' => 184,
			'constr_type_spec' => 78,
			'union_header' => 23,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 79
		}
	},
	{#State 129
		DEFAULT => -190
	},
	{#State 130
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'SEQUENCE' => 45,
			'DOUBLE' => 66,
			'error' => 185,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'OCTET' => 59,
			'FLOAT' => 61,
			'UNSIGNED' => 52,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 64,
			'boolean_type' => 65,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'signed_long_int' => 49,
			'signed_short_int' => 70,
			'string_type' => 53,
			'any_type' => 55,
			'base_type_spec' => 56,
			'sequence_type' => 75,
			'unsigned_long_int' => 76,
			'template_type_spec' => 77,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 186
		}
	},
	{#State 131
		ACTIONS => {
			'error' => 187,
			'IDENTIFIER' => 188
		}
	},
	{#State 132
		DEFAULT => -106
	},
	{#State 133
		ACTIONS => {
			"," => 189
		},
		DEFAULT => -124
	},
	{#State 134
		DEFAULT => -107
	},
	{#State 135
		DEFAULT => -127
	},
	{#State 136
		DEFAULT => -126
	},
	{#State 137
		DEFAULT => -129
	},
	{#State 138
		ACTIONS => {
			"[" => 192
		},
		DEFAULT => -128,
		GOTOS => {
			'fixed_array_sizes' => 190,
			'fixed_array_size' => 191
		}
	},
	{#State 139
		DEFAULT => -141
	},
	{#State 140
		DEFAULT => -140
	},
	{#State 141
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			'error' => 200,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'const_exp' => 198,
			'and_expr' => 210,
			'or_expr' => 199,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'xor_expr' => 201,
			'shift_expr' => 202,
			'positive_int_const' => 195,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 142
		DEFAULT => -51
	},
	{#State 143
		DEFAULT => -50
	},
	{#State 144
		ACTIONS => {
			"}" => 219
		}
	},
	{#State 145
		ACTIONS => {
			"}" => 220
		}
	},
	{#State 146
		ACTIONS => {
			"}" => 221
		}
	},
	{#State 147
		ACTIONS => {
			";" => 222,
			"," => 223
		},
		DEFAULT => -181
	},
	{#State 148
		DEFAULT => -185
	},
	{#State 149
		ACTIONS => {
			"}" => 224
		}
	},
	{#State 150
		DEFAULT => -57
	},
	{#State 151
		ACTIONS => {
			'error' => 225,
			"=" => 226
		}
	},
	{#State 152
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'error' => 230,
			'LONG' => 67,
			"::" => 69,
			'ENUM' => 27,
			'UNSIGNED' => 52
		},
		GOTOS => {
			'switch_type_spec' => 231,
			'unsigned_int' => 42,
			'signed_int' => 44,
			'integer_type' => 233,
			'boolean_type' => 232,
			'char_type' => 227,
			'enum_type' => 229,
			'unsigned_long_int' => 76,
			'scoped_name' => 228,
			'enum_header' => 19,
			'signed_long_int' => 49,
			'unsigned_short_int' => 60,
			'signed_short_int' => 70
		}
	},
	{#State 153
		DEFAULT => -157
	},
	{#State 154
		ACTIONS => {
			'error' => 235,
			'IDENTIFIER' => 74,
			"::" => 69
		},
		GOTOS => {
			'scoped_name' => 234,
			'interface_names' => 237,
			'interface_name' => 236
		}
	},
	{#State 155
		DEFAULT => -29
	},
	{#State 156
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -248
	},
	{#State 157
		DEFAULT => -247
	},
	{#State 158
		DEFAULT => -246
	},
	{#State 159
		DEFAULT => -222
	},
	{#State 160
		DEFAULT => -223
	},
	{#State 161
		ACTIONS => {
			'error' => 238,
			'IDENTIFIER' => 239
		}
	},
	{#State 162
		DEFAULT => -36
	},
	{#State 163
		DEFAULT => -41
	},
	{#State 164
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'DOUBLE' => 66,
			'error' => 240,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'OCTET' => 59,
			'FLOAT' => 61,
			'UNSIGNED' => 52,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 64,
			'boolean_type' => 65,
			'any_type' => 55,
			'base_type_spec' => 158,
			'char_type' => 46,
			'unsigned_long_int' => 76,
			'param_type_spec' => 241,
			'octet_type' => 47,
			'scoped_name' => 156,
			'unsigned_short_int' => 60,
			'signed_long_int' => 49,
			'signed_short_int' => 70,
			'string_type' => 157
		}
	},
	{#State 165
		DEFAULT => -25
	},
	{#State 166
		DEFAULT => -35
	},
	{#State 167
		DEFAULT => -40
	},
	{#State 168
		DEFAULT => -33
	},
	{#State 169
		ACTIONS => {
			'error' => 243,
			")" => 247,
			'OUT' => 248,
			'INOUT' => 244,
			'IN' => 242
		},
		GOTOS => {
			'param_dcl' => 249,
			'param_dcls' => 246,
			'param_attribute' => 245
		}
	},
	{#State 170
		DEFAULT => -216
	},
	{#State 171
		ACTIONS => {
			'RAISES' => 253,
			'CONTEXT' => 250
		},
		DEFAULT => -212,
		GOTOS => {
			'context_expr' => 252,
			'raises_expr' => 251
		}
	},
	{#State 172
		DEFAULT => -38
	},
	{#State 173
		DEFAULT => -43
	},
	{#State 174
		DEFAULT => -37
	},
	{#State 175
		DEFAULT => -42
	},
	{#State 176
		DEFAULT => -34
	},
	{#State 177
		DEFAULT => -39
	},
	{#State 178
		DEFAULT => -24
	},
	{#State 179
		DEFAULT => -17
	},
	{#State 180
		DEFAULT => -16
	},
	{#State 181
		ACTIONS => {
			'error' => 255,
			";" => 254
		}
	},
	{#State 182
		DEFAULT => -208
	},
	{#State 183
		DEFAULT => -207
	},
	{#State 184
		DEFAULT => -150
	},
	{#State 185
		ACTIONS => {
			">" => 256
		}
	},
	{#State 186
		ACTIONS => {
			">" => 258,
			"," => 257
		}
	},
	{#State 187
		DEFAULT => -53
	},
	{#State 188
		DEFAULT => -52
	},
	{#State 189
		ACTIONS => {
			'IDENTIFIER' => 138
		},
		GOTOS => {
			'declarators' => 259,
			'declarator' => 133,
			'simple_declarator' => 136,
			'array_declarator' => 137,
			'complex_declarator' => 135
		}
	},
	{#State 190
		DEFAULT => -194
	},
	{#State 191
		ACTIONS => {
			"[" => 192
		},
		DEFAULT => -195,
		GOTOS => {
			'fixed_array_sizes' => 260,
			'fixed_array_size' => 191
		}
	},
	{#State 192
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			'error' => 262,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'const_exp' => 198,
			'and_expr' => 210,
			'or_expr' => 199,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'xor_expr' => 201,
			'shift_expr' => 202,
			'positive_int_const' => 261,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 193
		DEFAULT => -93
	},
	{#State 194
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -87
	},
	{#State 195
		ACTIONS => {
			">" => 263
		}
	},
	{#State 196
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			'error' => 265,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'const_exp' => 264,
			'and_expr' => 210,
			'or_expr' => 199,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'xor_expr' => 201,
			'shift_expr' => 202,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 197
		DEFAULT => -95
	},
	{#State 198
		DEFAULT => -100
	},
	{#State 199
		ACTIONS => {
			"|" => 266
		},
		DEFAULT => -65
	},
	{#State 200
		ACTIONS => {
			">" => 267
		}
	},
	{#State 201
		ACTIONS => {
			"^" => 268
		},
		DEFAULT => -66
	},
	{#State 202
		ACTIONS => {
			"<<" => 269,
			">>" => 270
		},
		DEFAULT => -70
	},
	{#State 203
		DEFAULT => -99
	},
	{#State 204
		DEFAULT => -88
	},
	{#State 205
		DEFAULT => -98
	},
	{#State 206
		ACTIONS => {
			"+" => 271,
			"-" => 272
		},
		DEFAULT => -72
	},
	{#State 207
		DEFAULT => -92
	},
	{#State 208
		DEFAULT => -94
	},
	{#State 209
		DEFAULT => -83
	},
	{#State 210
		ACTIONS => {
			"&" => 273
		},
		DEFAULT => -68
	},
	{#State 211
		DEFAULT => -91
	},
	{#State 212
		ACTIONS => {
			"%" => 275,
			"*" => 274,
			"/" => 276
		},
		DEFAULT => -75
	},
	{#State 213
		ACTIONS => {
			'STRING_LITERAL' => 213
		},
		DEFAULT => -96,
		GOTOS => {
			'string_literal' => 277
		}
	},
	{#State 214
		DEFAULT => -85
	},
	{#State 215
		DEFAULT => -78
	},
	{#State 216
		DEFAULT => -84
	},
	{#State 217
		DEFAULT => -86
	},
	{#State 218
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			"::" => 69,
			'STRING_LITERAL' => 213,
			'FALSE' => 203,
			'CHARACTER_LITERAL' => 193,
			'INTEGER_LITERAL' => 211,
			'TRUE' => 205,
			"(" => 196
		},
		GOTOS => {
			'string_literal' => 207,
			'boolean_literal' => 197,
			'scoped_name' => 194,
			'primary_expr' => 278,
			'literal' => 204
		}
	},
	{#State 219
		DEFAULT => -147
	},
	{#State 220
		DEFAULT => -146
	},
	{#State 221
		DEFAULT => -177
	},
	{#State 222
		DEFAULT => -184
	},
	{#State 223
		ACTIONS => {
			'IDENTIFIER' => 148
		},
		DEFAULT => -183,
		GOTOS => {
			'enumerators' => 279,
			'enumerator' => 147
		}
	},
	{#State 224
		DEFAULT => -176
	},
	{#State 225
		DEFAULT => -56
	},
	{#State 226
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			'error' => 281,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'const_exp' => 280,
			'and_expr' => 210,
			'or_expr' => 199,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'xor_expr' => 201,
			'shift_expr' => 202,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 227
		DEFAULT => -160
	},
	{#State 228
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -163
	},
	{#State 229
		DEFAULT => -162
	},
	{#State 230
		ACTIONS => {
			")" => 282
		}
	},
	{#State 231
		ACTIONS => {
			")" => 283
		}
	},
	{#State 232
		DEFAULT => -161
	},
	{#State 233
		DEFAULT => -159
	},
	{#State 234
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -48
	},
	{#State 235
		DEFAULT => -45
	},
	{#State 236
		ACTIONS => {
			"," => 284
		},
		DEFAULT => -46
	},
	{#State 237
		DEFAULT => -44
	},
	{#State 238
		DEFAULT => -218
	},
	{#State 239
		DEFAULT => -217
	},
	{#State 240
		DEFAULT => -201
	},
	{#State 241
		ACTIONS => {
			'error' => 285,
			'IDENTIFIER' => 288
		},
		GOTOS => {
			'simple_declarators' => 287,
			'simple_declarator' => 286
		}
	},
	{#State 242
		DEFAULT => -232
	},
	{#State 243
		ACTIONS => {
			")" => 289
		}
	},
	{#State 244
		DEFAULT => -234
	},
	{#State 245
		ACTIONS => {
			'CHAR' => 63,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'DOUBLE' => 66,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'OCTET' => 59,
			'FLOAT' => 61,
			'UNSIGNED' => 52,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 64,
			'boolean_type' => 65,
			'any_type' => 55,
			'base_type_spec' => 158,
			'char_type' => 46,
			'unsigned_long_int' => 76,
			'param_type_spec' => 290,
			'octet_type' => 47,
			'scoped_name' => 156,
			'unsigned_short_int' => 60,
			'signed_long_int' => 49,
			'signed_short_int' => 70,
			'string_type' => 157
		}
	},
	{#State 246
		ACTIONS => {
			")" => 291
		}
	},
	{#State 247
		DEFAULT => -225
	},
	{#State 248
		DEFAULT => -233
	},
	{#State 249
		ACTIONS => {
			";" => 292,
			"," => 293
		},
		DEFAULT => -227
	},
	{#State 250
		ACTIONS => {
			'error' => 295,
			"(" => 294
		}
	},
	{#State 251
		ACTIONS => {
			'CONTEXT' => 250
		},
		DEFAULT => -213,
		GOTOS => {
			'context_expr' => 296
		}
	},
	{#State 252
		DEFAULT => -215
	},
	{#State 253
		ACTIONS => {
			'error' => 298,
			"(" => 297
		}
	},
	{#State 254
		DEFAULT => -151
	},
	{#State 255
		DEFAULT => -152
	},
	{#State 256
		DEFAULT => -189
	},
	{#State 257
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			'error' => 300,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'const_exp' => 198,
			'and_expr' => 210,
			'or_expr' => 199,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'xor_expr' => 201,
			'shift_expr' => 202,
			'positive_int_const' => 299,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 258
		DEFAULT => -188
	},
	{#State 259
		DEFAULT => -125
	},
	{#State 260
		DEFAULT => -196
	},
	{#State 261
		ACTIONS => {
			"]" => 301
		}
	},
	{#State 262
		ACTIONS => {
			"]" => 302
		}
	},
	{#State 263
		DEFAULT => -191
	},
	{#State 264
		ACTIONS => {
			")" => 303
		}
	},
	{#State 265
		ACTIONS => {
			")" => 304
		}
	},
	{#State 266
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'and_expr' => 210,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'xor_expr' => 305,
			'shift_expr' => 202,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 267
		DEFAULT => -193
	},
	{#State 268
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'and_expr' => 306,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'shift_expr' => 202,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 269
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 307
		}
	},
	{#State 270
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 308
		}
	},
	{#State 271
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 309,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'literal' => 204,
			'unary_operator' => 218
		}
	},
	{#State 272
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 310,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'literal' => 204,
			'unary_operator' => 218
		}
	},
	{#State 273
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'shift_expr' => 311,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 274
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'string_literal' => 207,
			'boolean_literal' => 197,
			'scoped_name' => 194,
			'primary_expr' => 209,
			'literal' => 204,
			'unary_operator' => 218,
			'unary_expr' => 312
		}
	},
	{#State 275
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'string_literal' => 207,
			'boolean_literal' => 197,
			'scoped_name' => 194,
			'primary_expr' => 209,
			'literal' => 204,
			'unary_operator' => 218,
			'unary_expr' => 313
		}
	},
	{#State 276
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'string_literal' => 207,
			'boolean_literal' => 197,
			'scoped_name' => 194,
			'primary_expr' => 209,
			'literal' => 204,
			'unary_operator' => 218,
			'unary_expr' => 314
		}
	},
	{#State 277
		DEFAULT => -97
	},
	{#State 278
		DEFAULT => -82
	},
	{#State 279
		DEFAULT => -182
	},
	{#State 280
		DEFAULT => -54
	},
	{#State 281
		DEFAULT => -55
	},
	{#State 282
		DEFAULT => -156
	},
	{#State 283
		ACTIONS => {
			"{" => 316,
			'error' => 315
		}
	},
	{#State 284
		ACTIONS => {
			'IDENTIFIER' => 74,
			"::" => 69
		},
		GOTOS => {
			'scoped_name' => 234,
			'interface_names' => 317,
			'interface_name' => 236
		}
	},
	{#State 285
		DEFAULT => -200
	},
	{#State 286
		ACTIONS => {
			"," => 318
		},
		DEFAULT => -204
	},
	{#State 287
		DEFAULT => -199
	},
	{#State 288
		DEFAULT => -128
	},
	{#State 289
		DEFAULT => -226
	},
	{#State 290
		ACTIONS => {
			'IDENTIFIER' => 288
		},
		GOTOS => {
			'simple_declarator' => 319
		}
	},
	{#State 291
		DEFAULT => -224
	},
	{#State 292
		DEFAULT => -230
	},
	{#State 293
		ACTIONS => {
			'OUT' => 248,
			'INOUT' => 244,
			'IN' => 242
		},
		DEFAULT => -229,
		GOTOS => {
			'param_dcl' => 249,
			'param_dcls' => 320,
			'param_attribute' => 245
		}
	},
	{#State 294
		ACTIONS => {
			'error' => 321,
			'STRING_LITERAL' => 213
		},
		GOTOS => {
			'string_literal' => 322,
			'string_literals' => 323
		}
	},
	{#State 295
		DEFAULT => -243
	},
	{#State 296
		DEFAULT => -214
	},
	{#State 297
		ACTIONS => {
			'error' => 325,
			'IDENTIFIER' => 74,
			"::" => 69
		},
		GOTOS => {
			'scoped_name' => 324,
			'exception_names' => 326,
			'exception_name' => 327
		}
	},
	{#State 298
		DEFAULT => -237
	},
	{#State 299
		ACTIONS => {
			">" => 328
		}
	},
	{#State 300
		ACTIONS => {
			">" => 329
		}
	},
	{#State 301
		DEFAULT => -197
	},
	{#State 302
		DEFAULT => -198
	},
	{#State 303
		DEFAULT => -89
	},
	{#State 304
		DEFAULT => -90
	},
	{#State 305
		ACTIONS => {
			"^" => 268
		},
		DEFAULT => -67
	},
	{#State 306
		ACTIONS => {
			"&" => 273
		},
		DEFAULT => -69
	},
	{#State 307
		ACTIONS => {
			"+" => 271,
			"-" => 272
		},
		DEFAULT => -74
	},
	{#State 308
		ACTIONS => {
			"+" => 271,
			"-" => 272
		},
		DEFAULT => -73
	},
	{#State 309
		ACTIONS => {
			"%" => 275,
			"*" => 274,
			"/" => 276
		},
		DEFAULT => -76
	},
	{#State 310
		ACTIONS => {
			"%" => 275,
			"*" => 274,
			"/" => 276
		},
		DEFAULT => -77
	},
	{#State 311
		ACTIONS => {
			"<<" => 269,
			">>" => 270
		},
		DEFAULT => -71
	},
	{#State 312
		DEFAULT => -79
	},
	{#State 313
		DEFAULT => -81
	},
	{#State 314
		DEFAULT => -80
	},
	{#State 315
		DEFAULT => -155
	},
	{#State 316
		ACTIONS => {
			'error' => 333,
			'CASE' => 330,
			'DEFAULT' => 332
		},
		GOTOS => {
			'case_labels' => 335,
			'switch_body' => 334,
			'case' => 331,
			'case_label' => 336
		}
	},
	{#State 317
		DEFAULT => -47
	},
	{#State 318
		ACTIONS => {
			'IDENTIFIER' => 288
		},
		GOTOS => {
			'simple_declarators' => 337,
			'simple_declarator' => 286
		}
	},
	{#State 319
		DEFAULT => -231
	},
	{#State 320
		DEFAULT => -228
	},
	{#State 321
		ACTIONS => {
			")" => 338
		}
	},
	{#State 322
		ACTIONS => {
			"," => 339
		},
		DEFAULT => -244
	},
	{#State 323
		ACTIONS => {
			")" => 340
		}
	},
	{#State 324
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -240
	},
	{#State 325
		ACTIONS => {
			")" => 341
		}
	},
	{#State 326
		ACTIONS => {
			")" => 342
		}
	},
	{#State 327
		ACTIONS => {
			"," => 343
		},
		DEFAULT => -238
	},
	{#State 328
		DEFAULT => -186
	},
	{#State 329
		DEFAULT => -187
	},
	{#State 330
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 208,
			'IDENTIFIER' => 74,
			'STRING_LITERAL' => 213,
			'CHARACTER_LITERAL' => 193,
			"+" => 214,
			'error' => 345,
			"-" => 216,
			"::" => 69,
			'FALSE' => 203,
			'INTEGER_LITERAL' => 211,
			"~" => 217,
			"(" => 196,
			'TRUE' => 205
		},
		GOTOS => {
			'mult_expr' => 212,
			'string_literal' => 207,
			'boolean_literal' => 197,
			'primary_expr' => 209,
			'const_exp' => 344,
			'and_expr' => 210,
			'or_expr' => 199,
			'unary_expr' => 215,
			'scoped_name' => 194,
			'xor_expr' => 201,
			'shift_expr' => 202,
			'literal' => 204,
			'unary_operator' => 218,
			'add_expr' => 206
		}
	},
	{#State 331
		ACTIONS => {
			'CASE' => 330,
			'DEFAULT' => 332
		},
		DEFAULT => -164,
		GOTOS => {
			'case_labels' => 335,
			'switch_body' => 346,
			'case' => 331,
			'case_label' => 336
		}
	},
	{#State 332
		ACTIONS => {
			'error' => 347,
			":" => 348
		}
	},
	{#State 333
		ACTIONS => {
			"}" => 349
		}
	},
	{#State 334
		ACTIONS => {
			"}" => 350
		}
	},
	{#State 335
		ACTIONS => {
			'CHAR' => 63,
			'SEQUENCE' => 45,
			'STRUCT' => 5,
			'DOUBLE' => 66,
			'LONG' => 67,
			'STRING' => 68,
			"::" => 69,
			'UNSIGNED' => 52,
			'SHORT' => 54,
			'BOOLEAN' => 73,
			'IDENTIFIER' => 74,
			'UNION' => 15,
			'FLOAT' => 61,
			'OCTET' => 59,
			'ENUM' => 27,
			'ANY' => 62
		},
		GOTOS => {
			'unsigned_int' => 42,
			'floating_pt_type' => 43,
			'signed_int' => 44,
			'integer_type' => 64,
			'boolean_type' => 65,
			'char_type' => 46,
			'octet_type' => 47,
			'scoped_name' => 48,
			'type_spec' => 351,
			'signed_long_int' => 49,
			'signed_short_int' => 70,
			'string_type' => 53,
			'struct_type' => 71,
			'union_type' => 72,
			'struct_header' => 12,
			'element_spec' => 352,
			'sequence_type' => 75,
			'any_type' => 55,
			'base_type_spec' => 56,
			'enum_type' => 57,
			'unsigned_long_int' => 76,
			'template_type_spec' => 77,
			'enum_header' => 19,
			'constr_type_spec' => 78,
			'union_header' => 23,
			'unsigned_short_int' => 60,
			'simple_type_spec' => 79
		}
	},
	{#State 336
		ACTIONS => {
			'CASE' => 330,
			'DEFAULT' => 332
		},
		DEFAULT => -168,
		GOTOS => {
			'case_labels' => 353,
			'case_label' => 336
		}
	},
	{#State 337
		DEFAULT => -205
	},
	{#State 338
		DEFAULT => -242
	},
	{#State 339
		ACTIONS => {
			'STRING_LITERAL' => 213
		},
		GOTOS => {
			'string_literal' => 322,
			'string_literals' => 354
		}
	},
	{#State 340
		DEFAULT => -241
	},
	{#State 341
		DEFAULT => -236
	},
	{#State 342
		DEFAULT => -235
	},
	{#State 343
		ACTIONS => {
			'IDENTIFIER' => 74,
			"::" => 69
		},
		GOTOS => {
			'scoped_name' => 324,
			'exception_names' => 355,
			'exception_name' => 327
		}
	},
	{#State 344
		ACTIONS => {
			'error' => 356,
			":" => 357
		}
	},
	{#State 345
		DEFAULT => -172
	},
	{#State 346
		DEFAULT => -165
	},
	{#State 347
		DEFAULT => -174
	},
	{#State 348
		DEFAULT => -173
	},
	{#State 349
		DEFAULT => -154
	},
	{#State 350
		DEFAULT => -153
	},
	{#State 351
		ACTIONS => {
			'IDENTIFIER' => 138
		},
		GOTOS => {
			'declarator' => 358,
			'simple_declarator' => 136,
			'array_declarator' => 137,
			'complex_declarator' => 135
		}
	},
	{#State 352
		ACTIONS => {
			'error' => 360,
			";" => 359
		}
	},
	{#State 353
		DEFAULT => -169
	},
	{#State 354
		DEFAULT => -245
	},
	{#State 355
		DEFAULT => -239
	},
	{#State 356
		DEFAULT => -171
	},
	{#State 357
		DEFAULT => -170
	},
	{#State 358
		DEFAULT => -175
	},
	{#State 359
		DEFAULT => -166
	},
	{#State 360
		DEFAULT => -167
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
		 'definition', 2,
sub
#line 92 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 12
		 'definition', 2,
sub
#line 98 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 104 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 110 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 116 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'module', 4,
sub
#line 126 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 17
		 'module', 4,
sub
#line 133 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module', 2,
sub
#line 139 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 148 "parser20.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 154 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'interface', 1, undef
	],
	[#Rule 22
		 'interface', 1, undef
	],
	[#Rule 23
		 'interface_dcl', 3,
sub
#line 171 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 179 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 187 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 198 "parser20.yp"
{
			new ForwardRegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 27
		 'forward_dcl', 2,
sub
#line 204 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 213 "parser20.yp"
{
			new RegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 29
		 'interface_header', 3,
sub
#line 219 "parser20.yp"
{
			my $inheritance = new InheritanceSpec($_[0],
					'list_interface'		=>	$_[4]
			);
			new RegularInterface($_[0],
					'idf'					=>	$_[3],
					'inheritance'			=>	$inheritance
			);
		}
	],
	[#Rule 30
		 'interface_header', 2,
sub
#line 229 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 31
		 'interface_body', 1, undef
	],
	[#Rule 32
		 'exports', 1,
sub
#line 243 "parser20.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 33
		 'exports', 2,
sub
#line 247 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
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
		 'export', 2, undef
	],
	[#Rule 38
		 'export', 2, undef
	],
	[#Rule 39
		 'export', 2,
sub
#line 266 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 40
		 'export', 2,
sub
#line 272 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 41
		 'export', 2,
sub
#line 278 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 42
		 'export', 2,
sub
#line 284 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'export', 2,
sub
#line 290 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 300 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 45
		 'interface_inheritance_spec', 2,
sub
#line 304 "parser20.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 46
		 'interface_names', 1,
sub
#line 312 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 47
		 'interface_names', 3,
sub
#line 316 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 48
		 'interface_name', 1,
sub
#line 324 "parser20.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 49
		 'scoped_name', 1, undef
	],
	[#Rule 50
		 'scoped_name', 2,
sub
#line 334 "parser20.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 51
		 'scoped_name', 2,
sub
#line 338 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 52
		 'scoped_name', 3,
sub
#line 344 "parser20.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 53
		 'scoped_name', 3,
sub
#line 348 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 54
		 'const_dcl', 5,
sub
#line 358 "parser20.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 55
		 'const_dcl', 5,
sub
#line 366 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 56
		 'const_dcl', 4,
sub
#line 371 "parser20.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'const_dcl', 3,
sub
#line 376 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 58
		 'const_dcl', 2,
sub
#line 381 "parser20.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 59
		 'const_type', 1, undef
	],
	[#Rule 60
		 'const_type', 1, undef
	],
	[#Rule 61
		 'const_type', 1, undef
	],
	[#Rule 62
		 'const_type', 1, undef
	],
	[#Rule 63
		 'const_type', 1, undef
	],
	[#Rule 64
		 'const_type', 1,
sub
#line 400 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 65
		 'const_exp', 1, undef
	],
	[#Rule 66
		 'or_expr', 1, undef
	],
	[#Rule 67
		 'or_expr', 3,
sub
#line 416 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 68
		 'xor_expr', 1, undef
	],
	[#Rule 69
		 'xor_expr', 3,
sub
#line 426 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 70
		 'and_expr', 1, undef
	],
	[#Rule 71
		 'and_expr', 3,
sub
#line 436 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 72
		 'shift_expr', 1, undef
	],
	[#Rule 73
		 'shift_expr', 3,
sub
#line 446 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 74
		 'shift_expr', 3,
sub
#line 450 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 75
		 'add_expr', 1, undef
	],
	[#Rule 76
		 'add_expr', 3,
sub
#line 460 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 77
		 'add_expr', 3,
sub
#line 464 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 78
		 'mult_expr', 1, undef
	],
	[#Rule 79
		 'mult_expr', 3,
sub
#line 474 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 80
		 'mult_expr', 3,
sub
#line 478 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 81
		 'mult_expr', 3,
sub
#line 482 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 82
		 'unary_expr', 2,
sub
#line 490 "parser20.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 83
		 'unary_expr', 1, undef
	],
	[#Rule 84
		 'unary_operator', 1, undef
	],
	[#Rule 85
		 'unary_operator', 1, undef
	],
	[#Rule 86
		 'unary_operator', 1, undef
	],
	[#Rule 87
		 'primary_expr', 1,
sub
#line 510 "parser20.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 88
		 'primary_expr', 1,
sub
#line 516 "parser20.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 89
		 'primary_expr', 3,
sub
#line 520 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 90
		 'primary_expr', 3,
sub
#line 524 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 91
		 'literal', 1,
sub
#line 533 "parser20.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 92
		 'literal', 1,
sub
#line 540 "parser20.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 93
		 'literal', 1,
sub
#line 546 "parser20.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 94
		 'literal', 1,
sub
#line 552 "parser20.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 95
		 'literal', 1, undef
	],
	[#Rule 96
		 'string_literal', 1, undef
	],
	[#Rule 97
		 'string_literal', 2,
sub
#line 566 "parser20.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 98
		 'boolean_literal', 1,
sub
#line 574 "parser20.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 99
		 'boolean_literal', 1,
sub
#line 580 "parser20.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 100
		 'positive_int_const', 1,
sub
#line 590 "parser20.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 101
		 'type_dcl', 2,
sub
#line 600 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 102
		 'type_dcl', 1, undef
	],
	[#Rule 103
		 'type_dcl', 1, undef
	],
	[#Rule 104
		 'type_dcl', 1, undef
	],
	[#Rule 105
		 'type_dcl', 2,
sub
#line 610 "parser20.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 106
		 'type_declarator', 2,
sub
#line 619 "parser20.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 107
		 'type_declarator', 2,
sub
#line 626 "parser20.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 108
		 'type_spec', 1, undef
	],
	[#Rule 109
		 'type_spec', 1, undef
	],
	[#Rule 110
		 'simple_type_spec', 1, undef
	],
	[#Rule 111
		 'simple_type_spec', 1, undef
	],
	[#Rule 112
		 'simple_type_spec', 1,
sub
#line 647 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 113
		 'base_type_spec', 1, undef
	],
	[#Rule 114
		 'base_type_spec', 1, undef
	],
	[#Rule 115
		 'base_type_spec', 1, undef
	],
	[#Rule 116
		 'base_type_spec', 1, undef
	],
	[#Rule 117
		 'base_type_spec', 1, undef
	],
	[#Rule 118
		 'base_type_spec', 1, undef
	],
	[#Rule 119
		 'template_type_spec', 1, undef
	],
	[#Rule 120
		 'template_type_spec', 1, undef
	],
	[#Rule 121
		 'constr_type_spec', 1, undef
	],
	[#Rule 122
		 'constr_type_spec', 1, undef
	],
	[#Rule 123
		 'constr_type_spec', 1, undef
	],
	[#Rule 124
		 'declarators', 1,
sub
#line 689 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 125
		 'declarators', 3,
sub
#line 693 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 126
		 'declarator', 1,
sub
#line 702 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 127
		 'declarator', 1, undef
	],
	[#Rule 128
		 'simple_declarator', 1, undef
	],
	[#Rule 129
		 'complex_declarator', 1, undef
	],
	[#Rule 130
		 'floating_pt_type', 1,
sub
#line 724 "parser20.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 131
		 'floating_pt_type', 1,
sub
#line 730 "parser20.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 132
		 'integer_type', 1, undef
	],
	[#Rule 133
		 'integer_type', 1, undef
	],
	[#Rule 134
		 'signed_int', 1, undef
	],
	[#Rule 135
		 'signed_int', 1, undef
	],
	[#Rule 136
		 'signed_long_int', 1,
sub
#line 756 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 137
		 'signed_short_int', 1,
sub
#line 766 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 138
		 'unsigned_int', 1, undef
	],
	[#Rule 139
		 'unsigned_int', 1, undef
	],
	[#Rule 140
		 'unsigned_long_int', 2,
sub
#line 784 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 141
		 'unsigned_short_int', 2,
sub
#line 794 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 142
		 'char_type', 1,
sub
#line 804 "parser20.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 143
		 'boolean_type', 1,
sub
#line 814 "parser20.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 144
		 'octet_type', 1,
sub
#line 824 "parser20.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 145
		 'any_type', 1,
sub
#line 834 "parser20.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 146
		 'struct_type', 4,
sub
#line 844 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 147
		 'struct_type', 4,
sub
#line 851 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 148
		 'struct_header', 2,
sub
#line 860 "parser20.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 149
		 'member_list', 1,
sub
#line 870 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 150
		 'member_list', 2,
sub
#line 874 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 151
		 'member', 3,
sub
#line 883 "parser20.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 152
		 'member', 3,
sub
#line 890 "parser20.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 153
		 'union_type', 8,
sub
#line 903 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 154
		 'union_type', 8,
sub
#line 911 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 155
		 'union_type', 6,
sub
#line 917 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 156
		 'union_type', 5,
sub
#line 923 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 157
		 'union_type', 3,
sub
#line 929 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 158
		 'union_header', 2,
sub
#line 938 "parser20.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 159
		 'switch_type_spec', 1, undef
	],
	[#Rule 160
		 'switch_type_spec', 1, undef
	],
	[#Rule 161
		 'switch_type_spec', 1, undef
	],
	[#Rule 162
		 'switch_type_spec', 1, undef
	],
	[#Rule 163
		 'switch_type_spec', 1,
sub
#line 956 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 164
		 'switch_body', 1,
sub
#line 964 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 165
		 'switch_body', 2,
sub
#line 968 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 166
		 'case', 3,
sub
#line 977 "parser20.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 167
		 'case', 3,
sub
#line 984 "parser20.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 168
		 'case_labels', 1,
sub
#line 996 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 169
		 'case_labels', 2,
sub
#line 1000 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 170
		 'case_label', 3,
sub
#line 1009 "parser20.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 171
		 'case_label', 3,
sub
#line 1013 "parser20.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 172
		 'case_label', 2,
sub
#line 1019 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 173
		 'case_label', 2,
sub
#line 1024 "parser20.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 174
		 'case_label', 2,
sub
#line 1028 "parser20.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 175
		 'element_spec', 2,
sub
#line 1038 "parser20.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 176
		 'enum_type', 4,
sub
#line 1049 "parser20.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 177
		 'enum_type', 4,
sub
#line 1055 "parser20.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'enum_type', 2,
sub
#line 1060 "parser20.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 179
		 'enum_header', 2,
sub
#line 1069 "parser20.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 180
		 'enum_header', 2,
sub
#line 1075 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 181
		 'enumerators', 1,
sub
#line 1083 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 182
		 'enumerators', 3,
sub
#line 1087 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 183
		 'enumerators', 2,
sub
#line 1092 "parser20.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 184
		 'enumerators', 2,
sub
#line 1097 "parser20.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 185
		 'enumerator', 1,
sub
#line 1106 "parser20.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 186
		 'sequence_type', 6,
sub
#line 1116 "parser20.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 187
		 'sequence_type', 6,
sub
#line 1124 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 188
		 'sequence_type', 4,
sub
#line 1129 "parser20.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 189
		 'sequence_type', 4,
sub
#line 1136 "parser20.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 190
		 'sequence_type', 2,
sub
#line 1141 "parser20.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 191
		 'string_type', 4,
sub
#line 1150 "parser20.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 192
		 'string_type', 1,
sub
#line 1157 "parser20.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 193
		 'string_type', 4,
sub
#line 1163 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 194
		 'array_declarator', 2,
sub
#line 1172 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 195
		 'fixed_array_sizes', 1,
sub
#line 1180 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 196
		 'fixed_array_sizes', 2,
sub
#line 1184 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 197
		 'fixed_array_size', 3,
sub
#line 1193 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 198
		 'fixed_array_size', 3,
sub
#line 1197 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 199
		 'attr_dcl', 4,
sub
#line 1206 "parser20.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 200
		 'attr_dcl', 4,
sub
#line 1214 "parser20.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 201
		 'attr_dcl', 3,
sub
#line 1219 "parser20.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 202
		 'attr_mod', 1, undef
	],
	[#Rule 203
		 'attr_mod', 0, undef
	],
	[#Rule 204
		 'simple_declarators', 1,
sub
#line 1234 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 205
		 'simple_declarators', 3,
sub
#line 1238 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 206
		 'except_dcl', 3,
sub
#line 1247 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 207
		 'except_dcl', 4,
sub
#line 1252 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 208
		 'except_dcl', 4,
sub
#line 1259 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 209
		 'except_dcl', 2,
sub
#line 1265 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 210
		 'exception_header', 2,
sub
#line 1274 "parser20.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 211
		 'exception_header', 2,
sub
#line 1280 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 212
		 'op_dcl', 2,
sub
#line 1289 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 213
		 'op_dcl', 3,
sub
#line 1297 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 214
		 'op_dcl', 4,
sub
#line 1306 "parser20.yp"
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
	[#Rule 215
		 'op_dcl', 3,
sub
#line 1316 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 216
		 'op_dcl', 2,
sub
#line 1325 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 217
		 'op_header', 3,
sub
#line 1335 "parser20.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 218
		 'op_header', 3,
sub
#line 1343 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 219
		 'op_mod', 1, undef
	],
	[#Rule 220
		 'op_mod', 0, undef
	],
	[#Rule 221
		 'op_attribute', 1, undef
	],
	[#Rule 222
		 'op_type_spec', 1, undef
	],
	[#Rule 223
		 'op_type_spec', 1,
sub
#line 1367 "parser20.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 224
		 'parameter_dcls', 3,
sub
#line 1377 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 225
		 'parameter_dcls', 2,
sub
#line 1381 "parser20.yp"
{
			undef;
		}
	],
	[#Rule 226
		 'parameter_dcls', 3,
sub
#line 1385 "parser20.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 227
		 'param_dcls', 1,
sub
#line 1393 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 228
		 'param_dcls', 3,
sub
#line 1397 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 229
		 'param_dcls', 2,
sub
#line 1402 "parser20.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 230
		 'param_dcls', 2,
sub
#line 1407 "parser20.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 231
		 'param_dcl', 3,
sub
#line 1416 "parser20.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 232
		 'param_attribute', 1, undef
	],
	[#Rule 233
		 'param_attribute', 1, undef
	],
	[#Rule 234
		 'param_attribute', 1, undef
	],
	[#Rule 235
		 'raises_expr', 4,
sub
#line 1438 "parser20.yp"
{
			$_[3];
		}
	],
	[#Rule 236
		 'raises_expr', 4,
sub
#line 1442 "parser20.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 237
		 'raises_expr', 2,
sub
#line 1447 "parser20.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 238
		 'exception_names', 1,
sub
#line 1455 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 239
		 'exception_names', 3,
sub
#line 1459 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 240
		 'exception_name', 1,
sub
#line 1467 "parser20.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 241
		 'context_expr', 4,
sub
#line 1475 "parser20.yp"
{
			$_[3];
		}
	],
	[#Rule 242
		 'context_expr', 4,
sub
#line 1479 "parser20.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'context_expr', 2,
sub
#line 1484 "parser20.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 244
		 'string_literals', 1,
sub
#line 1492 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 245
		 'string_literals', 3,
sub
#line 1496 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 246
		 'param_type_spec', 1, undef
	],
	[#Rule 247
		 'param_type_spec', 1, undef
	],
	[#Rule 248
		 'param_type_spec', 1,
sub
#line 1509 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1514 "parser20.yp"


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
