####################################################################
#
#    This file was generated using Parse::Yapp version 1.02.
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
# (c) Copyright 1998-1999 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.02';
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

    my($self)=$class->SUPER::new( yyversion => '1.02',
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
		DEFAULT => -101
	},
	{#State 9
		ACTIONS => {
			"{" => 41,
			'error' => 40
		}
	},
	{#State 10
		DEFAULT => -102
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
		DEFAULT => -103
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
			'CHAR' => -219,
			'ONEWAY' => 106,
			'VOID' => -219,
			'STRUCT' => 5,
			'DOUBLE' => -219,
			'LONG' => -219,
			'STRING' => -219,
			"::" => -219,
			'UNSIGNED' => -219,
			'SHORT' => -219,
			'TYPEDEF' => 11,
			'BOOLEAN' => -219,
			'IDENTIFIER' => -219,
			'UNION' => 15,
			'READONLY' => 117,
			'ATTRIBUTE' => -202,
			'error' => 111,
			'CONST' => 21,
			"}" => 112,
			'EXCEPTION' => 22,
			'OCTET' => -219,
			'FLOAT' => -219,
			'ENUM' => 27,
			'ANY' => -219
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
		DEFAULT => -147
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
		DEFAULT => -208
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
		DEFAULT => -132
	},
	{#State 43
		DEFAULT => -112
	},
	{#State 44
		DEFAULT => -131
	},
	{#State 45
		ACTIONS => {
			"<" => 130,
			'error' => 129
		}
	},
	{#State 46
		DEFAULT => -114
	},
	{#State 47
		DEFAULT => -116
	},
	{#State 48
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -111
	},
	{#State 49
		DEFAULT => -134
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
		DEFAULT => -100
	},
	{#State 52
		ACTIONS => {
			'SHORT' => 139,
			'LONG' => 140
		}
	},
	{#State 53
		DEFAULT => -119
	},
	{#State 54
		DEFAULT => -136
	},
	{#State 55
		DEFAULT => -117
	},
	{#State 56
		DEFAULT => -109
	},
	{#State 57
		DEFAULT => -122
	},
	{#State 58
		DEFAULT => -104
	},
	{#State 59
		DEFAULT => -143
	},
	{#State 60
		DEFAULT => -137
	},
	{#State 61
		DEFAULT => -129
	},
	{#State 62
		DEFAULT => -144
	},
	{#State 63
		DEFAULT => -141
	},
	{#State 64
		DEFAULT => -113
	},
	{#State 65
		DEFAULT => -115
	},
	{#State 66
		DEFAULT => -130
	},
	{#State 67
		DEFAULT => -135
	},
	{#State 68
		ACTIONS => {
			"<" => 141
		},
		DEFAULT => -191
	},
	{#State 69
		ACTIONS => {
			'error' => 142,
			'IDENTIFIER' => 143
		}
	},
	{#State 70
		DEFAULT => -133
	},
	{#State 71
		DEFAULT => -120
	},
	{#State 72
		DEFAULT => -121
	},
	{#State 73
		DEFAULT => -142
	},
	{#State 74
		DEFAULT => -48
	},
	{#State 75
		DEFAULT => -118
	},
	{#State 76
		DEFAULT => -138
	},
	{#State 77
		DEFAULT => -110
	},
	{#State 78
		DEFAULT => -108
	},
	{#State 79
		DEFAULT => -107
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
		DEFAULT => -157
	},
	{#State 84
		DEFAULT => -177
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
		DEFAULT => -61
	},
	{#State 89
		DEFAULT => -59
	},
	{#State 90
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -63
	},
	{#State 91
		DEFAULT => -62
	},
	{#State 92
		DEFAULT => -57
	},
	{#State 93
		DEFAULT => -60
	},
	{#State 94
		DEFAULT => -58
	},
	{#State 95
		ACTIONS => {
			'error' => 150,
			'IDENTIFIER' => 151
		}
	},
	{#State 96
		DEFAULT => -210
	},
	{#State 97
		DEFAULT => -209
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
		DEFAULT => -179
	},
	{#State 103
		DEFAULT => -178
	},
	{#State 104
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
		DEFAULT => -220
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
		DEFAULT => -218
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
		DEFAULT => -30
	},
	{#State 115
		ACTIONS => {
			'ONEWAY' => 106,
			'STRUCT' => 5,
			'TYPEDEF' => 11,
			'UNION' => 15,
			'READONLY' => 117,
			'ATTRIBUTE' => -202,
			'CONST' => 21,
			"}" => -31,
			'EXCEPTION' => 22,
			'ENUM' => 27
		},
		DEFAULT => -219,
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
		DEFAULT => -201
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
		DEFAULT => -205
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
		DEFAULT => -148,
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
		DEFAULT => -189
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
		DEFAULT => -105
	},
	{#State 133
		ACTIONS => {
			"," => 189
		},
		DEFAULT => -123
	},
	{#State 134
		DEFAULT => -106
	},
	{#State 135
		DEFAULT => -126
	},
	{#State 136
		DEFAULT => -125
	},
	{#State 137
		DEFAULT => -128
	},
	{#State 138
		ACTIONS => {
			"[" => 192
		},
		DEFAULT => -127,
		GOTOS => {
			'fixed_array_sizes' => 190,
			'fixed_array_size' => 191
		}
	},
	{#State 139
		DEFAULT => -140
	},
	{#State 140
		DEFAULT => -139
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
		DEFAULT => -50
	},
	{#State 143
		DEFAULT => -49
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
		DEFAULT => -180
	},
	{#State 148
		DEFAULT => -184
	},
	{#State 149
		ACTIONS => {
			"}" => 224
		}
	},
	{#State 150
		DEFAULT => -56
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
		DEFAULT => -156
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
		DEFAULT => -247
	},
	{#State 157
		DEFAULT => -246
	},
	{#State 158
		DEFAULT => -245
	},
	{#State 159
		DEFAULT => -221
	},
	{#State 160
		DEFAULT => -222
	},
	{#State 161
		ACTIONS => {
			'error' => 238,
			'IDENTIFIER' => 239
		}
	},
	{#State 162
		DEFAULT => -35
	},
	{#State 163
		DEFAULT => -40
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
		DEFAULT => -34
	},
	{#State 167
		DEFAULT => -39
	},
	{#State 168
		DEFAULT => -32
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
		DEFAULT => -215
	},
	{#State 171
		ACTIONS => {
			'RAISES' => 253,
			'CONTEXT' => 250
		},
		DEFAULT => -211,
		GOTOS => {
			'context_expr' => 252,
			'raises_expr' => 251
		}
	},
	{#State 172
		DEFAULT => -37
	},
	{#State 173
		DEFAULT => -42
	},
	{#State 174
		DEFAULT => -36
	},
	{#State 175
		DEFAULT => -41
	},
	{#State 176
		DEFAULT => -33
	},
	{#State 177
		DEFAULT => -38
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
		DEFAULT => -207
	},
	{#State 183
		DEFAULT => -206
	},
	{#State 184
		DEFAULT => -149
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
		DEFAULT => -52
	},
	{#State 188
		DEFAULT => -51
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
		DEFAULT => -193
	},
	{#State 191
		ACTIONS => {
			"[" => 192
		},
		DEFAULT => -194,
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
		DEFAULT => -92
	},
	{#State 194
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -86
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
		DEFAULT => -94
	},
	{#State 198
		DEFAULT => -99
	},
	{#State 199
		ACTIONS => {
			"|" => 266
		},
		DEFAULT => -64
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
		DEFAULT => -65
	},
	{#State 202
		ACTIONS => {
			"<<" => 269,
			">>" => 270
		},
		DEFAULT => -69
	},
	{#State 203
		DEFAULT => -98
	},
	{#State 204
		DEFAULT => -87
	},
	{#State 205
		DEFAULT => -97
	},
	{#State 206
		ACTIONS => {
			"+" => 271,
			"-" => 272
		},
		DEFAULT => -71
	},
	{#State 207
		DEFAULT => -91
	},
	{#State 208
		DEFAULT => -93
	},
	{#State 209
		DEFAULT => -82
	},
	{#State 210
		ACTIONS => {
			"&" => 273
		},
		DEFAULT => -67
	},
	{#State 211
		DEFAULT => -90
	},
	{#State 212
		ACTIONS => {
			"%" => 275,
			"*" => 274,
			"/" => 276
		},
		DEFAULT => -74
	},
	{#State 213
		ACTIONS => {
			'STRING_LITERAL' => 213
		},
		DEFAULT => -95,
		GOTOS => {
			'string_literal' => 277
		}
	},
	{#State 214
		DEFAULT => -84
	},
	{#State 215
		DEFAULT => -77
	},
	{#State 216
		DEFAULT => -83
	},
	{#State 217
		DEFAULT => -85
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
		DEFAULT => -146
	},
	{#State 220
		DEFAULT => -145
	},
	{#State 221
		DEFAULT => -176
	},
	{#State 222
		DEFAULT => -183
	},
	{#State 223
		ACTIONS => {
			'IDENTIFIER' => 148
		},
		DEFAULT => -182,
		GOTOS => {
			'enumerators' => 279,
			'enumerator' => 147
		}
	},
	{#State 224
		DEFAULT => -175
	},
	{#State 225
		DEFAULT => -55
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
		DEFAULT => -159
	},
	{#State 228
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -162
	},
	{#State 229
		DEFAULT => -161
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
		DEFAULT => -160
	},
	{#State 233
		DEFAULT => -158
	},
	{#State 234
		ACTIONS => {
			"::" => 131
		},
		DEFAULT => -47
	},
	{#State 235
		DEFAULT => -44
	},
	{#State 236
		ACTIONS => {
			"," => 284
		},
		DEFAULT => -45
	},
	{#State 237
		DEFAULT => -43
	},
	{#State 238
		DEFAULT => -217
	},
	{#State 239
		DEFAULT => -216
	},
	{#State 240
		DEFAULT => -200
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
		DEFAULT => -231
	},
	{#State 243
		ACTIONS => {
			")" => 289
		}
	},
	{#State 244
		DEFAULT => -233
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
		DEFAULT => -224
	},
	{#State 248
		DEFAULT => -232
	},
	{#State 249
		ACTIONS => {
			";" => 292,
			"," => 293
		},
		DEFAULT => -226
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
		DEFAULT => -212,
		GOTOS => {
			'context_expr' => 296
		}
	},
	{#State 252
		DEFAULT => -214
	},
	{#State 253
		ACTIONS => {
			'error' => 298,
			"(" => 297
		}
	},
	{#State 254
		DEFAULT => -150
	},
	{#State 255
		DEFAULT => -151
	},
	{#State 256
		DEFAULT => -188
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
		DEFAULT => -187
	},
	{#State 259
		DEFAULT => -124
	},
	{#State 260
		DEFAULT => -195
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
		DEFAULT => -190
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
		DEFAULT => -192
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
		DEFAULT => -96
	},
	{#State 278
		DEFAULT => -81
	},
	{#State 279
		DEFAULT => -181
	},
	{#State 280
		DEFAULT => -53
	},
	{#State 281
		DEFAULT => -54
	},
	{#State 282
		DEFAULT => -155
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
		DEFAULT => -199
	},
	{#State 286
		ACTIONS => {
			"," => 318
		},
		DEFAULT => -203
	},
	{#State 287
		DEFAULT => -198
	},
	{#State 288
		DEFAULT => -127
	},
	{#State 289
		DEFAULT => -225
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
		DEFAULT => -223
	},
	{#State 292
		DEFAULT => -229
	},
	{#State 293
		ACTIONS => {
			'OUT' => 248,
			'INOUT' => 244,
			'IN' => 242
		},
		DEFAULT => -228,
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
		DEFAULT => -242
	},
	{#State 296
		DEFAULT => -213
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
		DEFAULT => -236
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
		DEFAULT => -196
	},
	{#State 302
		DEFAULT => -197
	},
	{#State 303
		DEFAULT => -88
	},
	{#State 304
		DEFAULT => -89
	},
	{#State 305
		ACTIONS => {
			"^" => 268
		},
		DEFAULT => -66
	},
	{#State 306
		ACTIONS => {
			"&" => 273
		},
		DEFAULT => -68
	},
	{#State 307
		ACTIONS => {
			"+" => 271,
			"-" => 272
		},
		DEFAULT => -73
	},
	{#State 308
		ACTIONS => {
			"+" => 271,
			"-" => 272
		},
		DEFAULT => -72
	},
	{#State 309
		ACTIONS => {
			"%" => 275,
			"*" => 274,
			"/" => 276
		},
		DEFAULT => -75
	},
	{#State 310
		ACTIONS => {
			"%" => 275,
			"*" => 274,
			"/" => 276
		},
		DEFAULT => -76
	},
	{#State 311
		ACTIONS => {
			"<<" => 269,
			">>" => 270
		},
		DEFAULT => -70
	},
	{#State 312
		DEFAULT => -78
	},
	{#State 313
		DEFAULT => -80
	},
	{#State 314
		DEFAULT => -79
	},
	{#State 315
		DEFAULT => -154
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
		DEFAULT => -46
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
		DEFAULT => -230
	},
	{#State 320
		DEFAULT => -227
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
		DEFAULT => -243
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
		DEFAULT => -239
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
		DEFAULT => -237
	},
	{#State 328
		DEFAULT => -185
	},
	{#State 329
		DEFAULT => -186
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
		DEFAULT => -163,
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
		DEFAULT => -167,
		GOTOS => {
			'case_labels' => 353,
			'case_label' => 336
		}
	},
	{#State 337
		DEFAULT => -204
	},
	{#State 338
		DEFAULT => -241
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
		DEFAULT => -240
	},
	{#State 341
		DEFAULT => -235
	},
	{#State 342
		DEFAULT => -234
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
		DEFAULT => -171
	},
	{#State 346
		DEFAULT => -164
	},
	{#State 347
		DEFAULT => -173
	},
	{#State 348
		DEFAULT => -172
	},
	{#State 349
		DEFAULT => -153
	},
	{#State 350
		DEFAULT => -152
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
		DEFAULT => -168
	},
	{#State 354
		DEFAULT => -244
	},
	{#State 355
		DEFAULT => -238
	},
	{#State 356
		DEFAULT => -170
	},
	{#State 357
		DEFAULT => -169
	},
	{#State 358
		DEFAULT => -174
	},
	{#State 359
		DEFAULT => -165
	},
	{#State 360
		DEFAULT => -166
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
			$_[0]->Error("Empty specification\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 62 "parser20.yp"
{
			$_[0]->Error("definition declaration excepted.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 68 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 69 "parser20.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
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
#line 80 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 12
		 'definition', 2,
sub
#line 86 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 92 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 98 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 104 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'module', 4,
sub
#line 114 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->configure('list_decl' => $_[3])
					if (defined $_[1]);
		}
	],
	[#Rule 17
		 'module', 4,
sub
#line 120 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 18
		 'module', 2,
sub
#line 126 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module_header', 2,
sub
#line 135 "parser20.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 141 "parser20.yp"
{
			$_[0]->Error("Identifier excepted.\n");
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
#line 156 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	[]);
		}
	],
	[#Rule 24
		 'interface_dcl', 4,
sub
#line 162 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->configure('list_decl'		=>	$_[3]);
		}
	],
	[#Rule 25
		 'interface_dcl', 4,
sub
#line 168 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 26
		 'forward_dcl', 2,
sub
#line 179 "parser20.yp"
{
			new ForwardInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 27
		 'forward_dcl', 2,
sub
#line 185 "parser20.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 28
		 'interface_header', 2,
sub
#line 194 "parser20.yp"
{
			new Interface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 29
		 'interface_header', 3,
sub
#line 200 "parser20.yp"
{
			new Interface($_[0],
					'idf'					=>	$_[2],
					'list_inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 30
		 'interface_body', 1, undef
	],
	[#Rule 31
		 'exports', 1,
sub
#line 214 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 32
		 'exports', 2,
sub
#line 215 "parser20.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
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
		 'export', 2, undef
	],
	[#Rule 38
		 'export', 2,
sub
#line 226 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 39
		 'export', 2,
sub
#line 232 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 40
		 'export', 2,
sub
#line 238 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 41
		 'export', 2,
sub
#line 244 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 42
		 'export', 2,
sub
#line 250 "parser20.yp"
{
			$_[0]->Warning("';' excepted.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'interface_inheritance_spec', 2,
sub
#line 259 "parser20.yp"
{ $_[2]; }
	],
	[#Rule 44
		 'interface_inheritance_spec', 2,
sub
#line 261 "parser20.yp"
{
			$_[0]->Error("Interface name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 45
		 'interface_names', 1,
sub
#line 268 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 46
		 'interface_names', 3,
sub
#line 269 "parser20.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 47
		 'interface_name', 1,
sub
#line 274 "parser20.yp"
{
				Interface->Lookup($_[0],$_[1])
		}
	],
	[#Rule 48
		 'scoped_name', 1, undef
	],
	[#Rule 49
		 'scoped_name', 2,
sub
#line 283 "parser20.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 50
		 'scoped_name', 2,
sub
#line 287 "parser20.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 51
		 'scoped_name', 3,
sub
#line 293 "parser20.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 52
		 'scoped_name', 3,
sub
#line 297 "parser20.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 53
		 'const_dcl', 5,
sub
#line 307 "parser20.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 54
		 'const_dcl', 5,
sub
#line 315 "parser20.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 55
		 'const_dcl', 4,
sub
#line 320 "parser20.yp"
{
			$_[0]->Error("'=' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 56
		 'const_dcl', 3,
sub
#line 325 "parser20.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'const_dcl', 2,
sub
#line 330 "parser20.yp"
{
			$_[0]->Error("const_type excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 58
		 'const_type', 1, undef
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
		 'const_type', 1,
sub
#line 344 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 64
		 'const_exp', 1, undef
	],
	[#Rule 65
		 'or_expr', 1, undef
	],
	[#Rule 66
		 'or_expr', 3,
sub
#line 358 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 67
		 'xor_expr', 1, undef
	],
	[#Rule 68
		 'xor_expr', 3,
sub
#line 367 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 69
		 'and_expr', 1, undef
	],
	[#Rule 70
		 'and_expr', 3,
sub
#line 376 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 71
		 'shift_expr', 1, undef
	],
	[#Rule 72
		 'shift_expr', 3,
sub
#line 385 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 73
		 'shift_expr', 3,
sub
#line 389 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 74
		 'add_expr', 1, undef
	],
	[#Rule 75
		 'add_expr', 3,
sub
#line 398 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 76
		 'add_expr', 3,
sub
#line 402 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 77
		 'mult_expr', 1, undef
	],
	[#Rule 78
		 'mult_expr', 3,
sub
#line 411 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 79
		 'mult_expr', 3,
sub
#line 415 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 80
		 'mult_expr', 3,
sub
#line 419 "parser20.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 81
		 'unary_expr', 2,
sub
#line 427 "parser20.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 82
		 'unary_expr', 1, undef
	],
	[#Rule 83
		 'unary_operator', 1, undef
	],
	[#Rule 84
		 'unary_operator', 1, undef
	],
	[#Rule 85
		 'unary_operator', 1, undef
	],
	[#Rule 86
		 'primary_expr', 1,
sub
#line 443 "parser20.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 87
		 'primary_expr', 1,
sub
#line 449 "parser20.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 88
		 'primary_expr', 3,
sub
#line 453 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 89
		 'primary_expr', 3,
sub
#line 457 "parser20.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 90
		 'literal', 1,
sub
#line 466 "parser20.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 91
		 'literal', 1,
sub
#line 473 "parser20.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 92
		 'literal', 1,
sub
#line 479 "parser20.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 93
		 'literal', 1,
sub
#line 485 "parser20.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 94
		 'literal', 1, undef
	],
	[#Rule 95
		 'string_literal', 1, undef
	],
	[#Rule 96
		 'string_literal', 2,
sub
#line 496 "parser20.yp"
{ $_[1] . $_[2]; }
	],
	[#Rule 97
		 'boolean_literal', 1,
sub
#line 502 "parser20.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 98
		 'boolean_literal', 1,
sub
#line 508 "parser20.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 99
		 'positive_int_const', 1,
sub
#line 518 "parser20.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 100
		 'type_dcl', 2,
sub
#line 528 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 101
		 'type_dcl', 1, undef
	],
	[#Rule 102
		 'type_dcl', 1, undef
	],
	[#Rule 103
		 'type_dcl', 1, undef
	],
	[#Rule 104
		 'type_dcl', 2,
sub
#line 535 "parser20.yp"
{
			$_[0]->Error("type_declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 105
		 'type_declarator', 2,
sub
#line 544 "parser20.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 106
		 'type_declarator', 2,
sub
#line 551 "parser20.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 107
		 'type_spec', 1, undef
	],
	[#Rule 108
		 'type_spec', 1, undef
	],
	[#Rule 109
		 'simple_type_spec', 1, undef
	],
	[#Rule 110
		 'simple_type_spec', 1, undef
	],
	[#Rule 111
		 'simple_type_spec', 1,
sub
#line 568 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 112
		 'base_type_spec', 1, undef
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
		 'template_type_spec', 1, undef
	],
	[#Rule 119
		 'template_type_spec', 1, undef
	],
	[#Rule 120
		 'constr_type_spec', 1, undef
	],
	[#Rule 121
		 'constr_type_spec', 1, undef
	],
	[#Rule 122
		 'constr_type_spec', 1, undef
	],
	[#Rule 123
		 'declarators', 1,
sub
#line 598 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 124
		 'declarators', 3,
sub
#line 599 "parser20.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 125
		 'declarator', 1,
sub
#line 604 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 126
		 'declarator', 1, undef
	],
	[#Rule 127
		 'simple_declarator', 1, undef
	],
	[#Rule 128
		 'complex_declarator', 1, undef
	],
	[#Rule 129
		 'floating_pt_type', 1,
sub
#line 621 "parser20.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 130
		 'floating_pt_type', 1,
sub
#line 627 "parser20.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 131
		 'integer_type', 1, undef
	],
	[#Rule 132
		 'integer_type', 1, undef
	],
	[#Rule 133
		 'signed_int', 1, undef
	],
	[#Rule 134
		 'signed_int', 1, undef
	],
	[#Rule 135
		 'signed_long_int', 1,
sub
#line 649 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 136
		 'signed_short_int', 1,
sub
#line 659 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 137
		 'unsigned_int', 1, undef
	],
	[#Rule 138
		 'unsigned_int', 1, undef
	],
	[#Rule 139
		 'unsigned_long_int', 2,
sub
#line 675 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 140
		 'unsigned_short_int', 2,
sub
#line 685 "parser20.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 141
		 'char_type', 1,
sub
#line 695 "parser20.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 142
		 'boolean_type', 1,
sub
#line 705 "parser20.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 143
		 'octet_type', 1,
sub
#line 715 "parser20.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 144
		 'any_type', 1,
sub
#line 725 "parser20.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 145
		 'struct_type', 4,
sub
#line 735 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 146
		 'struct_type', 4,
sub
#line 742 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 147
		 'struct_header', 2,
sub
#line 751 "parser20.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 148
		 'member_list', 1,
sub
#line 760 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 149
		 'member_list', 2,
sub
#line 761 "parser20.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 150
		 'member', 3,
sub
#line 767 "parser20.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 151
		 'member', 3,
sub
#line 774 "parser20.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 152
		 'union_type', 8,
sub
#line 787 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			);
		}
	],
	[#Rule 153
		 'union_type', 8,
sub
#line 795 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 154
		 'union_type', 6,
sub
#line 801 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 155
		 'union_type', 5,
sub
#line 807 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 156
		 'union_type', 3,
sub
#line 813 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 157
		 'union_header', 2,
sub
#line 822 "parser20.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 158
		 'switch_type_spec', 1, undef
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
		 'switch_type_spec', 1,
sub
#line 836 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 163
		 'switch_body', 1,
sub
#line 843 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 164
		 'switch_body', 2,
sub
#line 844 "parser20.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 165
		 'case', 3,
sub
#line 850 "parser20.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 166
		 'case', 3,
sub
#line 857 "parser20.yp"
{
			$_[0]->Error("';' excepted.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 167
		 'case_labels', 1,
sub
#line 868 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 168
		 'case_labels', 2,
sub
#line 869 "parser20.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 169
		 'case_label', 3,
sub
#line 875 "parser20.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 170
		 'case_label', 3,
sub
#line 879 "parser20.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 171
		 'case_label', 2,
sub
#line 885 "parser20.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 172
		 'case_label', 2,
sub
#line 890 "parser20.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 173
		 'case_label', 2,
sub
#line 894 "parser20.yp"
{
			$_[0]->Error("':' excepted.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 174
		 'element_spec', 2,
sub
#line 904 "parser20.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 175
		 'enum_type', 4,
sub
#line 915 "parser20.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 176
		 'enum_type', 4,
sub
#line 922 "parser20.yp"
{
			$_[0]->Error("enumerator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 177
		 'enum_type', 2,
sub
#line 927 "parser20.yp"
{
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'enum_header', 2,
sub
#line 935 "parser20.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 179
		 'enum_header', 2,
sub
#line 941 "parser20.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 180
		 'enumerators', 1,
sub
#line 948 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 181
		 'enumerators', 3,
sub
#line 949 "parser20.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 182
		 'enumerators', 2,
sub
#line 951 "parser20.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 183
		 'enumerators', 2,
sub
#line 956 "parser20.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 184
		 'enumerator', 1,
sub
#line 965 "parser20.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 185
		 'sequence_type', 6,
sub
#line 975 "parser20.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 186
		 'sequence_type', 6,
sub
#line 983 "parser20.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 187
		 'sequence_type', 4,
sub
#line 988 "parser20.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 188
		 'sequence_type', 4,
sub
#line 995 "parser20.yp"
{
			$_[0]->Error("simple_type_spec excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 189
		 'sequence_type', 2,
sub
#line 1000 "parser20.yp"
{
			$_[0]->Error("'<' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 190
		 'string_type', 4,
sub
#line 1009 "parser20.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 191
		 'string_type', 1,
sub
#line 1016 "parser20.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 192
		 'string_type', 4,
sub
#line 1022 "parser20.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 193
		 'array_declarator', 2,
sub
#line 1030 "parser20.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 194
		 'fixed_array_sizes', 1,
sub
#line 1034 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 195
		 'fixed_array_sizes', 2,
sub
#line 1036 "parser20.yp"
{ unshift(@{$_[2]},$_[1]); $_[2]; }
	],
	[#Rule 196
		 'fixed_array_size', 3,
sub
#line 1041 "parser20.yp"
{ $_[2]; }
	],
	[#Rule 197
		 'fixed_array_size', 3,
sub
#line 1043 "parser20.yp"
{
			$_[0]->Error("Expression excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 198
		 'attr_dcl', 4,
sub
#line 1052 "parser20.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 199
		 'attr_dcl', 4,
sub
#line 1060 "parser20.yp"
{
			$_[0]->Error("declarator excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 200
		 'attr_dcl', 3,
sub
#line 1065 "parser20.yp"
{
			$_[0]->Error("type excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 201
		 'attr_mod', 1, undef
	],
	[#Rule 202
		 'attr_mod', 0, undef
	],
	[#Rule 203
		 'simple_declarators', 1,
sub
#line 1077 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 204
		 'simple_declarators', 3,
sub
#line 1079 "parser20.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 205
		 'except_dcl', 3,
sub
#line 1085 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 206
		 'except_dcl', 4,
sub
#line 1090 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 207
		 'except_dcl', 4,
sub
#line 1098 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members excepted.\n");
			$_[0]->YYErrok();
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 208
		 'except_dcl', 2,
sub
#line 1108 "parser20.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 209
		 'exception_header', 2,
sub
#line 1117 "parser20.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 210
		 'exception_header', 2,
sub
#line 1123 "parser20.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 211
		 'op_dcl', 2,
sub
#line 1132 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 212
		 'op_dcl', 3,
sub
#line 1141 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 213
		 'op_dcl', 4,
sub
#line 1151 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3],
					'list_context'	=>	$_[4]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 214
		 'op_dcl', 3,
sub
#line 1162 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			)
					if (defined $_[1]);
		}
	],
	[#Rule 215
		 'op_dcl', 2,
sub
#line 1172 "parser20.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 216
		 'op_header', 3,
sub
#line 1182 "parser20.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 217
		 'op_header', 3,
sub
#line 1190 "parser20.yp"
{
			$_[0]->Error("Identifier excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 218
		 'op_mod', 1, undef
	],
	[#Rule 219
		 'op_mod', 0, undef
	],
	[#Rule 220
		 'op_attribute', 1, undef
	],
	[#Rule 221
		 'op_type_spec', 1, undef
	],
	[#Rule 222
		 'op_type_spec', 1,
sub
#line 1210 "parser20.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 223
		 'parameter_dcls', 3,
sub
#line 1220 "parser20.yp"
{
			$_[2];
		}
	],
	[#Rule 224
		 'parameter_dcls', 2,
sub
#line 1224 "parser20.yp"
{
			undef;
		}
	],
	[#Rule 225
		 'parameter_dcls', 3,
sub
#line 1228 "parser20.yp"
{
			$_[0]->Error("parameters declaration excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 226
		 'param_dcls', 1,
sub
#line 1235 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 227
		 'param_dcls', 3,
sub
#line 1236 "parser20.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 228
		 'param_dcls', 2,
sub
#line 1238 "parser20.yp"
{
			$_[0]->Warning("',' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 229
		 'param_dcls', 2,
sub
#line 1243 "parser20.yp"
{
			$_[0]->Error("';' unexcepted.\n");
			[$_[1]];
		}
	],
	[#Rule 230
		 'param_dcl', 3,
sub
#line 1252 "parser20.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
        }
	],
	[#Rule 231
		 'param_attribute', 1, undef
	],
	[#Rule 232
		 'param_attribute', 1, undef
	],
	[#Rule 233
		 'param_attribute', 1, undef
	],
	[#Rule 234
		 'raises_expr', 4,
sub
#line 1271 "parser20.yp"
{
			$_[3];
		}
	],
	[#Rule 235
		 'raises_expr', 4,
sub
#line 1275 "parser20.yp"
{
			$_[0]->Error("name excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 236
		 'raises_expr', 2,
sub
#line 1280 "parser20.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 237
		 'exception_names', 1,
sub
#line 1287 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 238
		 'exception_names', 3,
sub
#line 1288 "parser20.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 239
		 'exception_name', 1,
sub
#line 1293 "parser20.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 240
		 'context_expr', 4,
sub
#line 1301 "parser20.yp"
{
			$_[3];
		}
	],
	[#Rule 241
		 'context_expr', 4,
sub
#line 1305 "parser20.yp"
{
			$_[0]->Error("string excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'context_expr', 2,
sub
#line 1310 "parser20.yp"
{
			$_[0]->Error("'(' excepted.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 243
		 'string_literals', 1,
sub
#line 1317 "parser20.yp"
{ [$_[1]]; }
	],
	[#Rule 244
		 'string_literals', 3,
sub
#line 1318 "parser20.yp"
{ unshift(@{$_[3]},$_[1]); $_[3]; }
	],
	[#Rule 245
		 'param_type_spec', 1, undef
	],
	[#Rule 246
		 'param_type_spec', 1, undef
	],
	[#Rule 247
		 'param_type_spec', 1,
sub
#line 1326 "parser20.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1331 "parser20.yp"


use strict;
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
