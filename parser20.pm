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
			'error' => 31,
			";" => 30
		}
	},
	{#State 2
		ACTIONS => {
			"{" => 32
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 34,
			";" => 33
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
			'error' => 40,
			";" => 39
		}
	},
	{#State 8
		DEFAULT => -103
	},
	{#State 9
		ACTIONS => {
			"{" => 42,
			'error' => 41
		}
	},
	{#State 10
		DEFAULT => -104
	},
	{#State 11
		ACTIONS => {
			'CHAR' => 64,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 53,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'error' => 59,
			'FLOAT' => 62,
			'OCTET' => 60,
			'ENUM' => 28,
			'ANY' => 63
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'boolean_type' => 66,
			'integer_type' => 65,
			'char_type' => 47,
			'octet_type' => 48,
			'scoped_name' => 49,
			'signed_long_int' => 50,
			'type_spec' => 51,
			'signed_short_int' => 71,
			'type_declarator' => 52,
			'string_type' => 54,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 76,
			'any_type' => 56,
			'base_type_spec' => 57,
			'enum_type' => 58,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 61,
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
		DEFAULT => -22
	},
	{#State 16
		ACTIONS => {
			'IDENTIFIER' => 85
		}
	},
	{#State 17
		DEFAULT => -105
	},
	{#State 18
		DEFAULT => -23
	},
	{#State 19
		DEFAULT => -3
	},
	{#State 20
		ACTIONS => {
			"{" => 87,
			'error' => 86
		}
	},
	{#State 21
		ACTIONS => {
			'error' => 89,
			";" => 88
		}
	},
	{#State 22
		ACTIONS => {
			'CHAR' => 64,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'DOUBLE' => 67,
			'error' => 94,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'FLOAT' => 62,
			'UNSIGNED' => 53
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 90,
			'signed_int' => 45,
			'integer_type' => 96,
			'boolean_type' => 95,
			'char_type' => 91,
			'unsigned_long_int' => 77,
			'scoped_name' => 92,
			'signed_long_int' => 50,
			'unsigned_short_int' => 61,
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
			'error' => 102,
			";" => 101
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
			'definitions' => 103,
			'type_dcl' => 25,
			'definition' => 27
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 104,
			'IDENTIFIER' => 105
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 106,
			'IDENTIFIER' => 107
		}
	},
	{#State 30
		DEFAULT => -7
	},
	{#State 31
		DEFAULT => -12
	},
	{#State 32
		ACTIONS => {
			'CHAR' => -221,
			'ONEWAY' => 108,
			'VOID' => -221,
			'STRUCT' => 5,
			'DOUBLE' => -221,
			'LONG' => -221,
			'STRING' => -221,
			"::" => -221,
			'UNSIGNED' => -221,
			'SHORT' => -221,
			'TYPEDEF' => 11,
			'BOOLEAN' => -221,
			'IDENTIFIER' => -221,
			'UNION' => 16,
			'READONLY' => 119,
			'ATTRIBUTE' => -204,
			'error' => 113,
			'CONST' => 22,
			"}" => 114,
			'EXCEPTION' => 23,
			'OCTET' => -221,
			'FLOAT' => -221,
			'ENUM' => 28,
			'ANY' => -221
		},
		GOTOS => {
			'const_dcl' => 115,
			'op_mod' => 109,
			'except_dcl' => 110,
			'op_attribute' => 111,
			'attr_mod' => 112,
			'exports' => 116,
			'export' => 117,
			'struct_type' => 8,
			'op_header' => 118,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 17,
			'op_dcl' => 120,
			'enum_header' => 20,
			'attr_dcl' => 121,
			'type_dcl' => 122,
			'union_header' => 24,
			'interface_body' => 123
		}
	},
	{#State 33
		DEFAULT => -8
	},
	{#State 34
		DEFAULT => -13
	},
	{#State 35
		DEFAULT => 0
	},
	{#State 36
		DEFAULT => -149
	},
	{#State 37
		DEFAULT => -19
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
			'definitions' => 125,
			'type_dcl' => 25,
			'definition' => 27
		}
	},
	{#State 39
		DEFAULT => -9
	},
	{#State 40
		DEFAULT => -14
	},
	{#State 41
		DEFAULT => -210
	},
	{#State 42
		ACTIONS => {
			'CHAR' => 64,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 53,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'error' => 127,
			"}" => 129,
			'FLOAT' => 62,
			'OCTET' => 60,
			'ENUM' => 28,
			'ANY' => 63
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 47,
			'octet_type' => 48,
			'scoped_name' => 49,
			'type_spec' => 126,
			'signed_long_int' => 50,
			'signed_short_int' => 71,
			'string_type' => 54,
			'member' => 130,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 76,
			'any_type' => 56,
			'base_type_spec' => 57,
			'enum_type' => 58,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'member_list' => 128,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 61,
			'simple_type_spec' => 80
		}
	},
	{#State 43
		DEFAULT => -134
	},
	{#State 44
		DEFAULT => -114
	},
	{#State 45
		DEFAULT => -133
	},
	{#State 46
		ACTIONS => {
			"<" => 132,
			'error' => 131
		}
	},
	{#State 47
		DEFAULT => -116
	},
	{#State 48
		DEFAULT => -118
	},
	{#State 49
		ACTIONS => {
			"::" => 133
		},
		DEFAULT => -113
	},
	{#State 50
		DEFAULT => -136
	},
	{#State 51
		ACTIONS => {
			'error' => 136,
			'IDENTIFIER' => 140
		},
		GOTOS => {
			'declarators' => 134,
			'declarator' => 135,
			'simple_declarator' => 138,
			'array_declarator' => 139,
			'complex_declarator' => 137
		}
	},
	{#State 52
		DEFAULT => -102
	},
	{#State 53
		ACTIONS => {
			'SHORT' => 141,
			'LONG' => 142
		}
	},
	{#State 54
		DEFAULT => -121
	},
	{#State 55
		DEFAULT => -138
	},
	{#State 56
		DEFAULT => -119
	},
	{#State 57
		DEFAULT => -111
	},
	{#State 58
		DEFAULT => -124
	},
	{#State 59
		DEFAULT => -106
	},
	{#State 60
		DEFAULT => -145
	},
	{#State 61
		DEFAULT => -139
	},
	{#State 62
		DEFAULT => -131
	},
	{#State 63
		DEFAULT => -146
	},
	{#State 64
		DEFAULT => -143
	},
	{#State 65
		DEFAULT => -115
	},
	{#State 66
		DEFAULT => -117
	},
	{#State 67
		DEFAULT => -132
	},
	{#State 68
		DEFAULT => -137
	},
	{#State 69
		ACTIONS => {
			"<" => 143
		},
		DEFAULT => -193
	},
	{#State 70
		ACTIONS => {
			'error' => 144,
			'IDENTIFIER' => 145
		}
	},
	{#State 71
		DEFAULT => -135
	},
	{#State 72
		DEFAULT => -122
	},
	{#State 73
		DEFAULT => -123
	},
	{#State 74
		DEFAULT => -144
	},
	{#State 75
		DEFAULT => -50
	},
	{#State 76
		DEFAULT => -120
	},
	{#State 77
		DEFAULT => -140
	},
	{#State 78
		DEFAULT => -112
	},
	{#State 79
		DEFAULT => -110
	},
	{#State 80
		DEFAULT => -109
	},
	{#State 81
		ACTIONS => {
			'CHAR' => 64,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 53,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'error' => 146,
			'FLOAT' => 62,
			'OCTET' => 60,
			'ENUM' => 28,
			'ANY' => 63
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 47,
			'octet_type' => 48,
			'scoped_name' => 49,
			'type_spec' => 126,
			'signed_long_int' => 50,
			'signed_short_int' => 71,
			'string_type' => 54,
			'member' => 130,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 76,
			'any_type' => 56,
			'base_type_spec' => 57,
			'enum_type' => 58,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'member_list' => 147,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 61,
			'simple_type_spec' => 80
		}
	},
	{#State 82
		ACTIONS => {
			";" => 148
		}
	},
	{#State 83
		DEFAULT => -21
	},
	{#State 84
		DEFAULT => -20
	},
	{#State 85
		DEFAULT => -159
	},
	{#State 86
		DEFAULT => -179
	},
	{#State 87
		ACTIONS => {
			'error' => 149,
			'IDENTIFIER' => 151
		},
		GOTOS => {
			'enumerators' => 152,
			'enumerator' => 150
		}
	},
	{#State 88
		DEFAULT => -10
	},
	{#State 89
		DEFAULT => -15
	},
	{#State 90
		DEFAULT => -63
	},
	{#State 91
		DEFAULT => -61
	},
	{#State 92
		ACTIONS => {
			"::" => 133
		},
		DEFAULT => -65
	},
	{#State 93
		DEFAULT => -64
	},
	{#State 94
		DEFAULT => -59
	},
	{#State 95
		DEFAULT => -62
	},
	{#State 96
		DEFAULT => -60
	},
	{#State 97
		ACTIONS => {
			'error' => 153,
			'IDENTIFIER' => 154
		}
	},
	{#State 98
		DEFAULT => -212
	},
	{#State 99
		DEFAULT => -211
	},
	{#State 100
		ACTIONS => {
			'error' => 156,
			"(" => 155
		}
	},
	{#State 101
		DEFAULT => -6
	},
	{#State 102
		DEFAULT => -11
	},
	{#State 103
		DEFAULT => -5
	},
	{#State 104
		DEFAULT => -181
	},
	{#State 105
		DEFAULT => -180
	},
	{#State 106
		ACTIONS => {
			"{" => -31
		},
		DEFAULT => -28
	},
	{#State 107
		ACTIONS => {
			"{" => -29,
			":" => 157
		},
		DEFAULT => -27,
		GOTOS => {
			'interface_inheritance_spec' => 158
		}
	},
	{#State 108
		DEFAULT => -222
	},
	{#State 109
		ACTIONS => {
			'CHAR' => 64,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'VOID' => 163,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'OCTET' => 60,
			'FLOAT' => 62,
			'UNSIGNED' => 53,
			'ANY' => 63
		},
		GOTOS => {
			'op_type_spec' => 164,
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'integer_type' => 65,
			'boolean_type' => 66,
			'any_type' => 56,
			'base_type_spec' => 161,
			'char_type' => 47,
			'unsigned_long_int' => 77,
			'param_type_spec' => 162,
			'octet_type' => 48,
			'scoped_name' => 159,
			'unsigned_short_int' => 61,
			'signed_long_int' => 50,
			'signed_short_int' => 71,
			'string_type' => 160
		}
	},
	{#State 110
		ACTIONS => {
			'error' => 166,
			";" => 165
		}
	},
	{#State 111
		DEFAULT => -220
	},
	{#State 112
		ACTIONS => {
			'ATTRIBUTE' => 167
		}
	},
	{#State 113
		ACTIONS => {
			"}" => 168
		}
	},
	{#State 114
		DEFAULT => -24
	},
	{#State 115
		ACTIONS => {
			'error' => 170,
			";" => 169
		}
	},
	{#State 116
		DEFAULT => -32
	},
	{#State 117
		ACTIONS => {
			'ONEWAY' => 108,
			'STRUCT' => 5,
			'TYPEDEF' => 11,
			'UNION' => 16,
			'READONLY' => 119,
			'ATTRIBUTE' => -204,
			'CONST' => 22,
			"}" => -33,
			'EXCEPTION' => 23,
			'ENUM' => 28
		},
		DEFAULT => -221,
		GOTOS => {
			'const_dcl' => 115,
			'op_mod' => 109,
			'except_dcl' => 110,
			'op_attribute' => 111,
			'attr_mod' => 112,
			'exports' => 171,
			'export' => 117,
			'struct_type' => 8,
			'op_header' => 118,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 17,
			'op_dcl' => 120,
			'enum_header' => 20,
			'attr_dcl' => 121,
			'type_dcl' => 122,
			'union_header' => 24
		}
	},
	{#State 118
		ACTIONS => {
			'error' => 173,
			"(" => 172
		},
		GOTOS => {
			'parameter_dcls' => 174
		}
	},
	{#State 119
		DEFAULT => -203
	},
	{#State 120
		ACTIONS => {
			'error' => 176,
			";" => 175
		}
	},
	{#State 121
		ACTIONS => {
			'error' => 178,
			";" => 177
		}
	},
	{#State 122
		ACTIONS => {
			'error' => 180,
			";" => 179
		}
	},
	{#State 123
		ACTIONS => {
			"}" => 181
		}
	},
	{#State 124
		ACTIONS => {
			"}" => 182
		}
	},
	{#State 125
		ACTIONS => {
			"}" => 183
		}
	},
	{#State 126
		ACTIONS => {
			'IDENTIFIER' => 140
		},
		GOTOS => {
			'declarators' => 184,
			'declarator' => 135,
			'simple_declarator' => 138,
			'array_declarator' => 139,
			'complex_declarator' => 137
		}
	},
	{#State 127
		ACTIONS => {
			"}" => 185
		}
	},
	{#State 128
		ACTIONS => {
			"}" => 186
		}
	},
	{#State 129
		DEFAULT => -207
	},
	{#State 130
		ACTIONS => {
			'CHAR' => 64,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 53,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'FLOAT' => 62,
			'OCTET' => 60,
			'ENUM' => 28,
			'ANY' => 63
		},
		DEFAULT => -150,
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 47,
			'octet_type' => 48,
			'scoped_name' => 49,
			'type_spec' => 126,
			'signed_long_int' => 50,
			'signed_short_int' => 71,
			'string_type' => 54,
			'member' => 130,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'sequence_type' => 76,
			'any_type' => 56,
			'base_type_spec' => 57,
			'enum_type' => 58,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'member_list' => 187,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 61,
			'simple_type_spec' => 80
		}
	},
	{#State 131
		DEFAULT => -191
	},
	{#State 132
		ACTIONS => {
			'CHAR' => 64,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'SEQUENCE' => 46,
			'DOUBLE' => 67,
			'error' => 188,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'OCTET' => 60,
			'FLOAT' => 62,
			'UNSIGNED' => 53,
			'ANY' => 63
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 47,
			'octet_type' => 48,
			'scoped_name' => 49,
			'signed_long_int' => 50,
			'signed_short_int' => 71,
			'string_type' => 54,
			'any_type' => 56,
			'base_type_spec' => 57,
			'sequence_type' => 76,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'unsigned_short_int' => 61,
			'simple_type_spec' => 189
		}
	},
	{#State 133
		ACTIONS => {
			'error' => 190,
			'IDENTIFIER' => 191
		}
	},
	{#State 134
		DEFAULT => -107
	},
	{#State 135
		ACTIONS => {
			"," => 192
		},
		DEFAULT => -125
	},
	{#State 136
		DEFAULT => -108
	},
	{#State 137
		DEFAULT => -128
	},
	{#State 138
		DEFAULT => -127
	},
	{#State 139
		DEFAULT => -130
	},
	{#State 140
		ACTIONS => {
			"[" => 195
		},
		DEFAULT => -129,
		GOTOS => {
			'fixed_array_sizes' => 193,
			'fixed_array_size' => 194
		}
	},
	{#State 141
		DEFAULT => -142
	},
	{#State 142
		DEFAULT => -141
	},
	{#State 143
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			'error' => 203,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'const_exp' => 201,
			'and_expr' => 213,
			'or_expr' => 202,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'xor_expr' => 204,
			'shift_expr' => 205,
			'positive_int_const' => 198,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 144
		DEFAULT => -52
	},
	{#State 145
		DEFAULT => -51
	},
	{#State 146
		ACTIONS => {
			"}" => 222
		}
	},
	{#State 147
		ACTIONS => {
			"}" => 223
		}
	},
	{#State 148
		DEFAULT => -16
	},
	{#State 149
		ACTIONS => {
			"}" => 224
		}
	},
	{#State 150
		ACTIONS => {
			";" => 225,
			"," => 226
		},
		DEFAULT => -182
	},
	{#State 151
		DEFAULT => -186
	},
	{#State 152
		ACTIONS => {
			"}" => 227
		}
	},
	{#State 153
		DEFAULT => -58
	},
	{#State 154
		ACTIONS => {
			'error' => 228,
			"=" => 229
		}
	},
	{#State 155
		ACTIONS => {
			'CHAR' => 64,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'error' => 233,
			'LONG' => 68,
			"::" => 70,
			'ENUM' => 28,
			'UNSIGNED' => 53
		},
		GOTOS => {
			'switch_type_spec' => 234,
			'unsigned_int' => 43,
			'signed_int' => 45,
			'integer_type' => 236,
			'boolean_type' => 235,
			'char_type' => 230,
			'enum_type' => 232,
			'unsigned_long_int' => 77,
			'scoped_name' => 231,
			'enum_header' => 20,
			'signed_long_int' => 50,
			'unsigned_short_int' => 61,
			'signed_short_int' => 71
		}
	},
	{#State 156
		DEFAULT => -158
	},
	{#State 157
		ACTIONS => {
			'error' => 238,
			'IDENTIFIER' => 75,
			"::" => 70
		},
		GOTOS => {
			'scoped_name' => 237,
			'interface_names' => 240,
			'interface_name' => 239
		}
	},
	{#State 158
		DEFAULT => -30
	},
	{#State 159
		ACTIONS => {
			"::" => 133
		},
		DEFAULT => -249
	},
	{#State 160
		DEFAULT => -248
	},
	{#State 161
		DEFAULT => -247
	},
	{#State 162
		DEFAULT => -223
	},
	{#State 163
		DEFAULT => -224
	},
	{#State 164
		ACTIONS => {
			'error' => 241,
			'IDENTIFIER' => 242
		}
	},
	{#State 165
		DEFAULT => -37
	},
	{#State 166
		DEFAULT => -42
	},
	{#State 167
		ACTIONS => {
			'CHAR' => 64,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'DOUBLE' => 67,
			'error' => 243,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'OCTET' => 60,
			'FLOAT' => 62,
			'UNSIGNED' => 53,
			'ANY' => 63
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'integer_type' => 65,
			'boolean_type' => 66,
			'any_type' => 56,
			'base_type_spec' => 161,
			'char_type' => 47,
			'unsigned_long_int' => 77,
			'param_type_spec' => 244,
			'octet_type' => 48,
			'scoped_name' => 159,
			'unsigned_short_int' => 61,
			'signed_long_int' => 50,
			'signed_short_int' => 71,
			'string_type' => 160
		}
	},
	{#State 168
		DEFAULT => -26
	},
	{#State 169
		DEFAULT => -36
	},
	{#State 170
		DEFAULT => -41
	},
	{#State 171
		DEFAULT => -34
	},
	{#State 172
		ACTIONS => {
			'error' => 246,
			")" => 250,
			'OUT' => 251,
			'INOUT' => 247,
			'IN' => 245
		},
		GOTOS => {
			'param_dcl' => 252,
			'param_dcls' => 249,
			'param_attribute' => 248
		}
	},
	{#State 173
		DEFAULT => -217
	},
	{#State 174
		ACTIONS => {
			'RAISES' => 256,
			'CONTEXT' => 253
		},
		DEFAULT => -213,
		GOTOS => {
			'context_expr' => 255,
			'raises_expr' => 254
		}
	},
	{#State 175
		DEFAULT => -39
	},
	{#State 176
		DEFAULT => -44
	},
	{#State 177
		DEFAULT => -38
	},
	{#State 178
		DEFAULT => -43
	},
	{#State 179
		DEFAULT => -35
	},
	{#State 180
		DEFAULT => -40
	},
	{#State 181
		DEFAULT => -25
	},
	{#State 182
		DEFAULT => -18
	},
	{#State 183
		DEFAULT => -17
	},
	{#State 184
		ACTIONS => {
			'error' => 258,
			";" => 257
		}
	},
	{#State 185
		DEFAULT => -209
	},
	{#State 186
		DEFAULT => -208
	},
	{#State 187
		DEFAULT => -151
	},
	{#State 188
		ACTIONS => {
			">" => 259
		}
	},
	{#State 189
		ACTIONS => {
			">" => 261,
			"," => 260
		}
	},
	{#State 190
		DEFAULT => -54
	},
	{#State 191
		DEFAULT => -53
	},
	{#State 192
		ACTIONS => {
			'IDENTIFIER' => 140
		},
		GOTOS => {
			'declarators' => 262,
			'declarator' => 135,
			'simple_declarator' => 138,
			'array_declarator' => 139,
			'complex_declarator' => 137
		}
	},
	{#State 193
		DEFAULT => -195
	},
	{#State 194
		ACTIONS => {
			"[" => 195
		},
		DEFAULT => -196,
		GOTOS => {
			'fixed_array_sizes' => 263,
			'fixed_array_size' => 194
		}
	},
	{#State 195
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			'error' => 265,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'const_exp' => 201,
			'and_expr' => 213,
			'or_expr' => 202,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'xor_expr' => 204,
			'shift_expr' => 205,
			'positive_int_const' => 264,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 196
		DEFAULT => -94
	},
	{#State 197
		ACTIONS => {
			"::" => 133
		},
		DEFAULT => -88
	},
	{#State 198
		ACTIONS => {
			">" => 266
		}
	},
	{#State 199
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			'error' => 268,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'const_exp' => 267,
			'and_expr' => 213,
			'or_expr' => 202,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'xor_expr' => 204,
			'shift_expr' => 205,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 200
		DEFAULT => -96
	},
	{#State 201
		DEFAULT => -101
	},
	{#State 202
		ACTIONS => {
			"|" => 269
		},
		DEFAULT => -66
	},
	{#State 203
		ACTIONS => {
			">" => 270
		}
	},
	{#State 204
		ACTIONS => {
			"^" => 271
		},
		DEFAULT => -67
	},
	{#State 205
		ACTIONS => {
			"<<" => 272,
			">>" => 273
		},
		DEFAULT => -71
	},
	{#State 206
		DEFAULT => -100
	},
	{#State 207
		DEFAULT => -89
	},
	{#State 208
		DEFAULT => -99
	},
	{#State 209
		ACTIONS => {
			"+" => 274,
			"-" => 275
		},
		DEFAULT => -73
	},
	{#State 210
		DEFAULT => -93
	},
	{#State 211
		DEFAULT => -95
	},
	{#State 212
		DEFAULT => -84
	},
	{#State 213
		ACTIONS => {
			"&" => 276
		},
		DEFAULT => -69
	},
	{#State 214
		DEFAULT => -92
	},
	{#State 215
		ACTIONS => {
			"%" => 278,
			"*" => 277,
			"/" => 279
		},
		DEFAULT => -76
	},
	{#State 216
		ACTIONS => {
			'STRING_LITERAL' => 216
		},
		DEFAULT => -97,
		GOTOS => {
			'string_literal' => 280
		}
	},
	{#State 217
		DEFAULT => -86
	},
	{#State 218
		DEFAULT => -79
	},
	{#State 219
		DEFAULT => -85
	},
	{#State 220
		DEFAULT => -87
	},
	{#State 221
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			"::" => 70,
			'STRING_LITERAL' => 216,
			'FALSE' => 206,
			'CHARACTER_LITERAL' => 196,
			'INTEGER_LITERAL' => 214,
			'TRUE' => 208,
			"(" => 199
		},
		GOTOS => {
			'string_literal' => 210,
			'boolean_literal' => 200,
			'scoped_name' => 197,
			'primary_expr' => 281,
			'literal' => 207
		}
	},
	{#State 222
		DEFAULT => -148
	},
	{#State 223
		DEFAULT => -147
	},
	{#State 224
		DEFAULT => -178
	},
	{#State 225
		DEFAULT => -185
	},
	{#State 226
		ACTIONS => {
			'IDENTIFIER' => 151
		},
		DEFAULT => -184,
		GOTOS => {
			'enumerators' => 282,
			'enumerator' => 150
		}
	},
	{#State 227
		DEFAULT => -177
	},
	{#State 228
		DEFAULT => -57
	},
	{#State 229
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			'error' => 284,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'const_exp' => 283,
			'and_expr' => 213,
			'or_expr' => 202,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'xor_expr' => 204,
			'shift_expr' => 205,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 230
		DEFAULT => -161
	},
	{#State 231
		ACTIONS => {
			"::" => 133
		},
		DEFAULT => -164
	},
	{#State 232
		DEFAULT => -163
	},
	{#State 233
		ACTIONS => {
			")" => 285
		}
	},
	{#State 234
		ACTIONS => {
			")" => 286
		}
	},
	{#State 235
		DEFAULT => -162
	},
	{#State 236
		DEFAULT => -160
	},
	{#State 237
		ACTIONS => {
			"::" => 133
		},
		DEFAULT => -49
	},
	{#State 238
		DEFAULT => -46
	},
	{#State 239
		ACTIONS => {
			"," => 287
		},
		DEFAULT => -47
	},
	{#State 240
		DEFAULT => -45
	},
	{#State 241
		DEFAULT => -219
	},
	{#State 242
		DEFAULT => -218
	},
	{#State 243
		DEFAULT => -202
	},
	{#State 244
		ACTIONS => {
			'error' => 288,
			'IDENTIFIER' => 291
		},
		GOTOS => {
			'simple_declarators' => 290,
			'simple_declarator' => 289
		}
	},
	{#State 245
		DEFAULT => -233
	},
	{#State 246
		ACTIONS => {
			")" => 292
		}
	},
	{#State 247
		DEFAULT => -235
	},
	{#State 248
		ACTIONS => {
			'CHAR' => 64,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'OCTET' => 60,
			'FLOAT' => 62,
			'UNSIGNED' => 53,
			'ANY' => 63
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'integer_type' => 65,
			'boolean_type' => 66,
			'any_type' => 56,
			'base_type_spec' => 161,
			'char_type' => 47,
			'unsigned_long_int' => 77,
			'param_type_spec' => 293,
			'octet_type' => 48,
			'scoped_name' => 159,
			'unsigned_short_int' => 61,
			'signed_long_int' => 50,
			'signed_short_int' => 71,
			'string_type' => 160
		}
	},
	{#State 249
		ACTIONS => {
			")" => 294
		}
	},
	{#State 250
		DEFAULT => -226
	},
	{#State 251
		DEFAULT => -234
	},
	{#State 252
		ACTIONS => {
			";" => 295,
			"," => 296
		},
		DEFAULT => -228
	},
	{#State 253
		ACTIONS => {
			'error' => 298,
			"(" => 297
		}
	},
	{#State 254
		ACTIONS => {
			'CONTEXT' => 253
		},
		DEFAULT => -214,
		GOTOS => {
			'context_expr' => 299
		}
	},
	{#State 255
		DEFAULT => -216
	},
	{#State 256
		ACTIONS => {
			'error' => 301,
			"(" => 300
		}
	},
	{#State 257
		DEFAULT => -152
	},
	{#State 258
		DEFAULT => -153
	},
	{#State 259
		DEFAULT => -190
	},
	{#State 260
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			'error' => 303,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'const_exp' => 201,
			'and_expr' => 213,
			'or_expr' => 202,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'xor_expr' => 204,
			'shift_expr' => 205,
			'positive_int_const' => 302,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 261
		DEFAULT => -189
	},
	{#State 262
		DEFAULT => -126
	},
	{#State 263
		DEFAULT => -197
	},
	{#State 264
		ACTIONS => {
			"]" => 304
		}
	},
	{#State 265
		ACTIONS => {
			"]" => 305
		}
	},
	{#State 266
		DEFAULT => -192
	},
	{#State 267
		ACTIONS => {
			")" => 306
		}
	},
	{#State 268
		ACTIONS => {
			")" => 307
		}
	},
	{#State 269
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'and_expr' => 213,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'xor_expr' => 308,
			'shift_expr' => 205,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 270
		DEFAULT => -194
	},
	{#State 271
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'and_expr' => 309,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'shift_expr' => 205,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 272
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 310
		}
	},
	{#State 273
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 311
		}
	},
	{#State 274
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 312,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'literal' => 207,
			'unary_operator' => 221
		}
	},
	{#State 275
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 313,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'literal' => 207,
			'unary_operator' => 221
		}
	},
	{#State 276
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'shift_expr' => 314,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 277
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'string_literal' => 210,
			'boolean_literal' => 200,
			'scoped_name' => 197,
			'primary_expr' => 212,
			'literal' => 207,
			'unary_operator' => 221,
			'unary_expr' => 315
		}
	},
	{#State 278
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'string_literal' => 210,
			'boolean_literal' => 200,
			'scoped_name' => 197,
			'primary_expr' => 212,
			'literal' => 207,
			'unary_operator' => 221,
			'unary_expr' => 316
		}
	},
	{#State 279
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'string_literal' => 210,
			'boolean_literal' => 200,
			'scoped_name' => 197,
			'primary_expr' => 212,
			'literal' => 207,
			'unary_operator' => 221,
			'unary_expr' => 317
		}
	},
	{#State 280
		DEFAULT => -98
	},
	{#State 281
		DEFAULT => -83
	},
	{#State 282
		DEFAULT => -183
	},
	{#State 283
		DEFAULT => -55
	},
	{#State 284
		DEFAULT => -56
	},
	{#State 285
		DEFAULT => -157
	},
	{#State 286
		ACTIONS => {
			"{" => 319,
			'error' => 318
		}
	},
	{#State 287
		ACTIONS => {
			'IDENTIFIER' => 75,
			"::" => 70
		},
		GOTOS => {
			'scoped_name' => 237,
			'interface_names' => 320,
			'interface_name' => 239
		}
	},
	{#State 288
		DEFAULT => -201
	},
	{#State 289
		ACTIONS => {
			"," => 321
		},
		DEFAULT => -205
	},
	{#State 290
		DEFAULT => -200
	},
	{#State 291
		DEFAULT => -129
	},
	{#State 292
		DEFAULT => -227
	},
	{#State 293
		ACTIONS => {
			'IDENTIFIER' => 291
		},
		GOTOS => {
			'simple_declarator' => 322
		}
	},
	{#State 294
		DEFAULT => -225
	},
	{#State 295
		DEFAULT => -231
	},
	{#State 296
		ACTIONS => {
			'OUT' => 251,
			'INOUT' => 247,
			'IN' => 245
		},
		DEFAULT => -230,
		GOTOS => {
			'param_dcl' => 252,
			'param_dcls' => 323,
			'param_attribute' => 248
		}
	},
	{#State 297
		ACTIONS => {
			'error' => 324,
			'STRING_LITERAL' => 216
		},
		GOTOS => {
			'string_literal' => 325,
			'string_literals' => 326
		}
	},
	{#State 298
		DEFAULT => -244
	},
	{#State 299
		DEFAULT => -215
	},
	{#State 300
		ACTIONS => {
			'error' => 328,
			'IDENTIFIER' => 75,
			"::" => 70
		},
		GOTOS => {
			'scoped_name' => 327,
			'exception_names' => 329,
			'exception_name' => 330
		}
	},
	{#State 301
		DEFAULT => -238
	},
	{#State 302
		ACTIONS => {
			">" => 331
		}
	},
	{#State 303
		ACTIONS => {
			">" => 332
		}
	},
	{#State 304
		DEFAULT => -198
	},
	{#State 305
		DEFAULT => -199
	},
	{#State 306
		DEFAULT => -90
	},
	{#State 307
		DEFAULT => -91
	},
	{#State 308
		ACTIONS => {
			"^" => 271
		},
		DEFAULT => -68
	},
	{#State 309
		ACTIONS => {
			"&" => 276
		},
		DEFAULT => -70
	},
	{#State 310
		ACTIONS => {
			"+" => 274,
			"-" => 275
		},
		DEFAULT => -75
	},
	{#State 311
		ACTIONS => {
			"+" => 274,
			"-" => 275
		},
		DEFAULT => -74
	},
	{#State 312
		ACTIONS => {
			"%" => 278,
			"*" => 277,
			"/" => 279
		},
		DEFAULT => -77
	},
	{#State 313
		ACTIONS => {
			"%" => 278,
			"*" => 277,
			"/" => 279
		},
		DEFAULT => -78
	},
	{#State 314
		ACTIONS => {
			"<<" => 272,
			">>" => 273
		},
		DEFAULT => -72
	},
	{#State 315
		DEFAULT => -80
	},
	{#State 316
		DEFAULT => -82
	},
	{#State 317
		DEFAULT => -81
	},
	{#State 318
		DEFAULT => -156
	},
	{#State 319
		ACTIONS => {
			'error' => 336,
			'CASE' => 333,
			'DEFAULT' => 335
		},
		GOTOS => {
			'case_labels' => 338,
			'switch_body' => 337,
			'case' => 334,
			'case_label' => 339
		}
	},
	{#State 320
		DEFAULT => -48
	},
	{#State 321
		ACTIONS => {
			'IDENTIFIER' => 291
		},
		GOTOS => {
			'simple_declarators' => 340,
			'simple_declarator' => 289
		}
	},
	{#State 322
		DEFAULT => -232
	},
	{#State 323
		DEFAULT => -229
	},
	{#State 324
		ACTIONS => {
			")" => 341
		}
	},
	{#State 325
		ACTIONS => {
			"," => 342
		},
		DEFAULT => -245
	},
	{#State 326
		ACTIONS => {
			")" => 343
		}
	},
	{#State 327
		ACTIONS => {
			"::" => 133
		},
		DEFAULT => -241
	},
	{#State 328
		ACTIONS => {
			")" => 344
		}
	},
	{#State 329
		ACTIONS => {
			")" => 345
		}
	},
	{#State 330
		ACTIONS => {
			"," => 346
		},
		DEFAULT => -239
	},
	{#State 331
		DEFAULT => -187
	},
	{#State 332
		DEFAULT => -188
	},
	{#State 333
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 211,
			'IDENTIFIER' => 75,
			'STRING_LITERAL' => 216,
			'CHARACTER_LITERAL' => 196,
			"+" => 217,
			'error' => 348,
			"-" => 219,
			"::" => 70,
			'FALSE' => 206,
			'INTEGER_LITERAL' => 214,
			"~" => 220,
			"(" => 199,
			'TRUE' => 208
		},
		GOTOS => {
			'mult_expr' => 215,
			'string_literal' => 210,
			'boolean_literal' => 200,
			'primary_expr' => 212,
			'const_exp' => 347,
			'and_expr' => 213,
			'or_expr' => 202,
			'unary_expr' => 218,
			'scoped_name' => 197,
			'xor_expr' => 204,
			'shift_expr' => 205,
			'literal' => 207,
			'unary_operator' => 221,
			'add_expr' => 209
		}
	},
	{#State 334
		ACTIONS => {
			'CASE' => 333,
			'DEFAULT' => 335
		},
		DEFAULT => -165,
		GOTOS => {
			'case_labels' => 338,
			'switch_body' => 349,
			'case' => 334,
			'case_label' => 339
		}
	},
	{#State 335
		ACTIONS => {
			'error' => 350,
			":" => 351
		}
	},
	{#State 336
		ACTIONS => {
			"}" => 352
		}
	},
	{#State 337
		ACTIONS => {
			"}" => 353
		}
	},
	{#State 338
		ACTIONS => {
			'CHAR' => 64,
			'SEQUENCE' => 46,
			'STRUCT' => 5,
			'DOUBLE' => 67,
			'LONG' => 68,
			'STRING' => 69,
			"::" => 70,
			'UNSIGNED' => 53,
			'SHORT' => 55,
			'BOOLEAN' => 74,
			'IDENTIFIER' => 75,
			'UNION' => 16,
			'FLOAT' => 62,
			'OCTET' => 60,
			'ENUM' => 28,
			'ANY' => 63
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 45,
			'integer_type' => 65,
			'boolean_type' => 66,
			'char_type' => 47,
			'octet_type' => 48,
			'scoped_name' => 49,
			'type_spec' => 354,
			'signed_long_int' => 50,
			'signed_short_int' => 71,
			'string_type' => 54,
			'struct_type' => 72,
			'union_type' => 73,
			'struct_header' => 12,
			'element_spec' => 355,
			'sequence_type' => 76,
			'any_type' => 56,
			'base_type_spec' => 57,
			'enum_type' => 58,
			'unsigned_long_int' => 77,
			'template_type_spec' => 78,
			'enum_header' => 20,
			'constr_type_spec' => 79,
			'union_header' => 24,
			'unsigned_short_int' => 61,
			'simple_type_spec' => 80
		}
	},
	{#State 339
		ACTIONS => {
			'CASE' => 333,
			'DEFAULT' => 335
		},
		DEFAULT => -169,
		GOTOS => {
			'case_labels' => 356,
			'case_label' => 339
		}
	},
	{#State 340
		DEFAULT => -206
	},
	{#State 341
		DEFAULT => -243
	},
	{#State 342
		ACTIONS => {
			'STRING_LITERAL' => 216
		},
		GOTOS => {
			'string_literal' => 325,
			'string_literals' => 357
		}
	},
	{#State 343
		DEFAULT => -242
	},
	{#State 344
		DEFAULT => -237
	},
	{#State 345
		DEFAULT => -236
	},
	{#State 346
		ACTIONS => {
			'IDENTIFIER' => 75,
			"::" => 70
		},
		GOTOS => {
			'scoped_name' => 327,
			'exception_names' => 358,
			'exception_name' => 330
		}
	},
	{#State 347
		ACTIONS => {
			'error' => 359,
			":" => 360
		}
	},
	{#State 348
		DEFAULT => -173
	},
	{#State 349
		DEFAULT => -166
	},
	{#State 350
		DEFAULT => -175
	},
	{#State 351
		DEFAULT => -174
	},
	{#State 352
		DEFAULT => -155
	},
	{#State 353
		DEFAULT => -154
	},
	{#State 354
		ACTIONS => {
			'IDENTIFIER' => 140
		},
		GOTOS => {
			'declarator' => 361,
			'simple_declarator' => 138,
			'array_declarator' => 139,
			'complex_declarator' => 137
		}
	},
	{#State 355
		ACTIONS => {
			'error' => 363,
			";" => 362
		}
	},
	{#State 356
		DEFAULT => -170
	},
	{#State 357
		DEFAULT => -246
	},
	{#State 358
		DEFAULT => -240
	},
	{#State 359
		DEFAULT => -172
	},
	{#State 360
		DEFAULT => -171
	},
	{#State 361
		DEFAULT => -176
	},
	{#State 362
		DEFAULT => -167
	},
	{#State 363
		DEFAULT => -168
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
		 'definition', 3,
sub
#line 122 "parser20.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 17
		 'module', 4,
sub
#line 135 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 18
		 'module', 4,
sub
#line 142 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module', 2,
sub
#line 148 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 157 "parser20.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 21
		 'module_header', 2,
sub
#line 163 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 22
		 'interface', 1, undef
	],
	[#Rule 23
		 'interface', 1, undef
	],
	[#Rule 24
		 'interface_dcl', 3,
sub
#line 180 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 188 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 26
		 'interface_dcl', 4,
sub
#line 196 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 27
		 'forward_dcl', 2,
sub
#line 207 "parser20.yp"
{
			new ForwardRegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 28
		 'forward_dcl', 2,
sub
#line 213 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 29
		 'interface_header', 2,
sub
#line 222 "parser20.yp"
{
			new RegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 30
		 'interface_header', 3,
sub
#line 228 "parser20.yp"
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
	[#Rule 31
		 'interface_header', 2,
sub
#line 238 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 32
		 'interface_body', 1, undef
	],
	[#Rule 33
		 'exports', 1,
sub
#line 252 "parser20.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 34
		 'exports', 2,
sub
#line 256 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
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
		 'export', 2, undef
	],
	[#Rule 40
		 'export', 2,
sub
#line 275 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 41
		 'export', 2,
sub
#line 281 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 42
		 'export', 2,
sub
#line 287 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'export', 2,
sub
#line 293 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 44
		 'export', 2,
sub
#line 299 "parser20.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 45
		 'interface_inheritance_spec', 2,
sub
#line 309 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 46
		 'interface_inheritance_spec', 2,
sub
#line 313 "parser20.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 47
		 'interface_names', 1,
sub
#line 321 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 48
		 'interface_names', 3,
sub
#line 325 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 49
		 'interface_name', 1,
sub
#line 333 "parser20.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 50
		 'scoped_name', 1, undef
	],
	[#Rule 51
		 'scoped_name', 2,
sub
#line 343 "parser20.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 52
		 'scoped_name', 2,
sub
#line 347 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 53
		 'scoped_name', 3,
sub
#line 353 "parser20.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 54
		 'scoped_name', 3,
sub
#line 357 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 55
		 'const_dcl', 5,
sub
#line 367 "parser20.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 56
		 'const_dcl', 5,
sub
#line 375 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'const_dcl', 4,
sub
#line 380 "parser20.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 58
		 'const_dcl', 3,
sub
#line 385 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 59
		 'const_dcl', 2,
sub
#line 390 "parser20.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
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
		 'const_type', 1, undef
	],
	[#Rule 65
		 'const_type', 1,
sub
#line 409 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 66
		 'const_exp', 1, undef
	],
	[#Rule 67
		 'or_expr', 1, undef
	],
	[#Rule 68
		 'or_expr', 3,
sub
#line 425 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 69
		 'xor_expr', 1, undef
	],
	[#Rule 70
		 'xor_expr', 3,
sub
#line 435 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 71
		 'and_expr', 1, undef
	],
	[#Rule 72
		 'and_expr', 3,
sub
#line 445 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 73
		 'shift_expr', 1, undef
	],
	[#Rule 74
		 'shift_expr', 3,
sub
#line 455 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 75
		 'shift_expr', 3,
sub
#line 459 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 76
		 'add_expr', 1, undef
	],
	[#Rule 77
		 'add_expr', 3,
sub
#line 469 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 78
		 'add_expr', 3,
sub
#line 473 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 79
		 'mult_expr', 1, undef
	],
	[#Rule 80
		 'mult_expr', 3,
sub
#line 483 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 81
		 'mult_expr', 3,
sub
#line 487 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 82
		 'mult_expr', 3,
sub
#line 491 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 83
		 'unary_expr', 2,
sub
#line 499 "parser20.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 84
		 'unary_expr', 1, undef
	],
	[#Rule 85
		 'unary_operator', 1, undef
	],
	[#Rule 86
		 'unary_operator', 1, undef
	],
	[#Rule 87
		 'unary_operator', 1, undef
	],
	[#Rule 88
		 'primary_expr', 1,
sub
#line 519 "parser20.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 89
		 'primary_expr', 1,
sub
#line 525 "parser20.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 90
		 'primary_expr', 3,
sub
#line 529 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 91
		 'primary_expr', 3,
sub
#line 533 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 92
		 'literal', 1,
sub
#line 542 "parser20.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 93
		 'literal', 1,
sub
#line 549 "parser20.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 94
		 'literal', 1,
sub
#line 555 "parser20.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 95
		 'literal', 1,
sub
#line 561 "parser20.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 96
		 'literal', 1, undef
	],
	[#Rule 97
		 'string_literal', 1, undef
	],
	[#Rule 98
		 'string_literal', 2,
sub
#line 575 "parser20.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 99
		 'boolean_literal', 1,
sub
#line 583 "parser20.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 100
		 'boolean_literal', 1,
sub
#line 589 "parser20.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 101
		 'positive_int_const', 1,
sub
#line 599 "parser20.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 102
		 'type_dcl', 2,
sub
#line 609 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 103
		 'type_dcl', 1, undef
	],
	[#Rule 104
		 'type_dcl', 1, undef
	],
	[#Rule 105
		 'type_dcl', 1, undef
	],
	[#Rule 106
		 'type_dcl', 2,
sub
#line 619 "parser20.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 107
		 'type_declarator', 2,
sub
#line 628 "parser20.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 108
		 'type_declarator', 2,
sub
#line 635 "parser20.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 109
		 'type_spec', 1, undef
	],
	[#Rule 110
		 'type_spec', 1, undef
	],
	[#Rule 111
		 'simple_type_spec', 1, undef
	],
	[#Rule 112
		 'simple_type_spec', 1, undef
	],
	[#Rule 113
		 'simple_type_spec', 1,
sub
#line 656 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
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
		 'base_type_spec', 1, undef
	],
	[#Rule 120
		 'template_type_spec', 1, undef
	],
	[#Rule 121
		 'template_type_spec', 1, undef
	],
	[#Rule 122
		 'constr_type_spec', 1, undef
	],
	[#Rule 123
		 'constr_type_spec', 1, undef
	],
	[#Rule 124
		 'constr_type_spec', 1, undef
	],
	[#Rule 125
		 'declarators', 1,
sub
#line 698 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 126
		 'declarators', 3,
sub
#line 702 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 127
		 'declarator', 1,
sub
#line 711 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 128
		 'declarator', 1, undef
	],
	[#Rule 129
		 'simple_declarator', 1, undef
	],
	[#Rule 130
		 'complex_declarator', 1, undef
	],
	[#Rule 131
		 'floating_pt_type', 1,
sub
#line 733 "parser20.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 132
		 'floating_pt_type', 1,
sub
#line 739 "parser20.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 133
		 'integer_type', 1, undef
	],
	[#Rule 134
		 'integer_type', 1, undef
	],
	[#Rule 135
		 'signed_int', 1, undef
	],
	[#Rule 136
		 'signed_int', 1, undef
	],
	[#Rule 137
		 'signed_long_int', 1,
sub
#line 765 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 138
		 'signed_short_int', 1,
sub
#line 775 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 139
		 'unsigned_int', 1, undef
	],
	[#Rule 140
		 'unsigned_int', 1, undef
	],
	[#Rule 141
		 'unsigned_long_int', 2,
sub
#line 793 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 142
		 'unsigned_short_int', 2,
sub
#line 803 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 143
		 'char_type', 1,
sub
#line 813 "parser20.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 144
		 'boolean_type', 1,
sub
#line 823 "parser20.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 145
		 'octet_type', 1,
sub
#line 833 "parser20.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 146
		 'any_type', 1,
sub
#line 843 "parser20.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 147
		 'struct_type', 4,
sub
#line 853 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 148
		 'struct_type', 4,
sub
#line 860 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 149
		 'struct_header', 2,
sub
#line 869 "parser20.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 150
		 'member_list', 1,
sub
#line 879 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 151
		 'member_list', 2,
sub
#line 883 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 152
		 'member', 3,
sub
#line 892 "parser20.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 153
		 'member', 3,
sub
#line 899 "parser20.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 154
		 'union_type', 8,
sub
#line 912 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 155
		 'union_type', 8,
sub
#line 920 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 156
		 'union_type', 6,
sub
#line 926 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 157
		 'union_type', 5,
sub
#line 932 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 158
		 'union_type', 3,
sub
#line 938 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 159
		 'union_header', 2,
sub
#line 947 "parser20.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
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
		 'switch_type_spec', 1, undef
	],
	[#Rule 164
		 'switch_type_spec', 1,
sub
#line 965 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 165
		 'switch_body', 1,
sub
#line 973 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 166
		 'switch_body', 2,
sub
#line 977 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 167
		 'case', 3,
sub
#line 986 "parser20.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 168
		 'case', 3,
sub
#line 993 "parser20.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 169
		 'case_labels', 1,
sub
#line 1005 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 170
		 'case_labels', 2,
sub
#line 1009 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 171
		 'case_label', 3,
sub
#line 1018 "parser20.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 172
		 'case_label', 3,
sub
#line 1022 "parser20.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 173
		 'case_label', 2,
sub
#line 1028 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 174
		 'case_label', 2,
sub
#line 1033 "parser20.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 175
		 'case_label', 2,
sub
#line 1037 "parser20.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 176
		 'element_spec', 2,
sub
#line 1047 "parser20.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 177
		 'enum_type', 4,
sub
#line 1058 "parser20.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 178
		 'enum_type', 4,
sub
#line 1064 "parser20.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 179
		 'enum_type', 2,
sub
#line 1069 "parser20.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 180
		 'enum_header', 2,
sub
#line 1078 "parser20.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 181
		 'enum_header', 2,
sub
#line 1084 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 182
		 'enumerators', 1,
sub
#line 1092 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 183
		 'enumerators', 3,
sub
#line 1096 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 184
		 'enumerators', 2,
sub
#line 1101 "parser20.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 185
		 'enumerators', 2,
sub
#line 1106 "parser20.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 186
		 'enumerator', 1,
sub
#line 1115 "parser20.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 187
		 'sequence_type', 6,
sub
#line 1125 "parser20.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 188
		 'sequence_type', 6,
sub
#line 1133 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 189
		 'sequence_type', 4,
sub
#line 1138 "parser20.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 190
		 'sequence_type', 4,
sub
#line 1145 "parser20.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 191
		 'sequence_type', 2,
sub
#line 1150 "parser20.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 192
		 'string_type', 4,
sub
#line 1159 "parser20.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 193
		 'string_type', 1,
sub
#line 1166 "parser20.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 194
		 'string_type', 4,
sub
#line 1172 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 195
		 'array_declarator', 2,
sub
#line 1181 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 196
		 'fixed_array_sizes', 1,
sub
#line 1189 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 197
		 'fixed_array_sizes', 2,
sub
#line 1193 "parser20.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 198
		 'fixed_array_size', 3,
sub
#line 1202 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 199
		 'fixed_array_size', 3,
sub
#line 1206 "parser20.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 200
		 'attr_dcl', 4,
sub
#line 1215 "parser20.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 201
		 'attr_dcl', 4,
sub
#line 1223 "parser20.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 202
		 'attr_dcl', 3,
sub
#line 1228 "parser20.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 203
		 'attr_mod', 1, undef
	],
	[#Rule 204
		 'attr_mod', 0, undef
	],
	[#Rule 205
		 'simple_declarators', 1,
sub
#line 1243 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 206
		 'simple_declarators', 3,
sub
#line 1247 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 207
		 'except_dcl', 3,
sub
#line 1256 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 208
		 'except_dcl', 4,
sub
#line 1261 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 209
		 'except_dcl', 4,
sub
#line 1268 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 210
		 'except_dcl', 2,
sub
#line 1274 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 211
		 'exception_header', 2,
sub
#line 1283 "parser20.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 212
		 'exception_header', 2,
sub
#line 1289 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 213
		 'op_dcl', 2,
sub
#line 1298 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 214
		 'op_dcl', 3,
sub
#line 1306 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 215
		 'op_dcl', 4,
sub
#line 1315 "parser20.yp"
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
	[#Rule 216
		 'op_dcl', 3,
sub
#line 1325 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 217
		 'op_dcl', 2,
sub
#line 1334 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 218
		 'op_header', 3,
sub
#line 1344 "parser20.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 219
		 'op_header', 3,
sub
#line 1352 "parser20.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 220
		 'op_mod', 1, undef
	],
	[#Rule 221
		 'op_mod', 0, undef
	],
	[#Rule 222
		 'op_attribute', 1, undef
	],
	[#Rule 223
		 'op_type_spec', 1, undef
	],
	[#Rule 224
		 'op_type_spec', 1,
sub
#line 1376 "parser20.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 225
		 'parameter_dcls', 3,
sub
#line 1386 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 226
		 'parameter_dcls', 2,
sub
#line 1390 "parser20.yp"
{
			undef;
		}
	],
	[#Rule 227
		 'parameter_dcls', 3,
sub
#line 1394 "parser20.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 228
		 'param_dcls', 1,
sub
#line 1402 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 229
		 'param_dcls', 3,
sub
#line 1406 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 230
		 'param_dcls', 2,
sub
#line 1411 "parser20.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 231
		 'param_dcls', 2,
sub
#line 1416 "parser20.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 232
		 'param_dcl', 3,
sub
#line 1425 "parser20.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 233
		 'param_attribute', 1, undef
	],
	[#Rule 234
		 'param_attribute', 1, undef
	],
	[#Rule 235
		 'param_attribute', 1, undef
	],
	[#Rule 236
		 'raises_expr', 4,
sub
#line 1447 "parser20.yp"
{
			$_[3];
		}
	],
	[#Rule 237
		 'raises_expr', 4,
sub
#line 1451 "parser20.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 238
		 'raises_expr', 2,
sub
#line 1456 "parser20.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 239
		 'exception_names', 1,
sub
#line 1464 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 240
		 'exception_names', 3,
sub
#line 1468 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 241
		 'exception_name', 1,
sub
#line 1476 "parser20.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 242
		 'context_expr', 4,
sub
#line 1484 "parser20.yp"
{
			$_[3];
		}
	],
	[#Rule 243
		 'context_expr', 4,
sub
#line 1488 "parser20.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 244
		 'context_expr', 2,
sub
#line 1493 "parser20.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 245
		 'string_literals', 1,
sub
#line 1501 "parser20.yp"
{
			[$_[1]];
		}
	],
	[#Rule 246
		 'string_literals', 3,
sub
#line 1505 "parser20.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 247
		 'param_type_spec', 1, undef
	],
	[#Rule 248
		 'param_type_spec', 1, undef
	],
	[#Rule 249
		 'param_type_spec', 1,
sub
#line 1518 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1523 "parser20.yp"


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
