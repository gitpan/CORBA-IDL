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
		DEFAULT => -111
	},
	{#State 9
		ACTIONS => {
			"{" => 42,
			'error' => 41
		}
	},
	{#State 10
		DEFAULT => -112
	},
	{#State 11
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 75,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'IDENTIFIER' => 84,
			'UNION' => 16,
			'WCHAR' => 59,
			'error' => 64,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'type_spec' => 54,
			'signed_long_int' => 53,
			'type_declarator' => 55,
			'string_type' => 57,
			'struct_header' => 12,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 72,
			'integer_type' => 73,
			'boolean_type' => 74,
			'signed_short_int' => 79,
			'struct_type' => 81,
			'union_type' => 83,
			'sequence_type' => 85,
			'unsigned_long_int' => 86,
			'template_type_spec' => 87,
			'constr_type_spec' => 88,
			'simple_type_spec' => 89,
			'fixed_pt_type' => 90
		}
	},
	{#State 12
		ACTIONS => {
			"{" => 91
		}
	},
	{#State 13
		ACTIONS => {
			'error' => 92
		}
	},
	{#State 14
		ACTIONS => {
			'error' => 93,
			'IDENTIFIER' => 94
		}
	},
	{#State 15
		DEFAULT => -22
	},
	{#State 16
		ACTIONS => {
			'IDENTIFIER' => 95
		}
	},
	{#State 17
		DEFAULT => -113
	},
	{#State 18
		DEFAULT => -23
	},
	{#State 19
		DEFAULT => -3
	},
	{#State 20
		ACTIONS => {
			"{" => 97,
			'error' => 96
		}
	},
	{#State 21
		ACTIONS => {
			'error' => 99,
			";" => 98
		}
	},
	{#State 22
		ACTIONS => {
			'CHAR' => 70,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'IDENTIFIER' => 84,
			'FIXED' => 101,
			'WCHAR' => 59,
			'DOUBLE' => 75,
			'error' => 106,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'FLOAT' => 67,
			'WSTRING' => 80,
			'UNSIGNED' => 56
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 100,
			'signed_int' => 46,
			'wide_string_type' => 107,
			'integer_type' => 109,
			'boolean_type' => 108,
			'char_type' => 102,
			'scoped_name' => 103,
			'fixed_pt_const_type' => 110,
			'wide_char_type' => 104,
			'signed_long_int' => 53,
			'signed_short_int' => 79,
			'const_type' => 111,
			'string_type' => 105,
			'unsigned_longlong_int' => 60,
			'unsigned_long_int' => 86,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68
		}
	},
	{#State 23
		ACTIONS => {
			'error' => 112,
			'IDENTIFIER' => 113
		}
	},
	{#State 24
		ACTIONS => {
			'SWITCH' => 114
		}
	},
	{#State 25
		ACTIONS => {
			'error' => 116,
			";" => 115
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
			'definitions' => 117,
			'type_dcl' => 25,
			'definition' => 27
		}
	},
	{#State 28
		ACTIONS => {
			'error' => 118,
			'IDENTIFIER' => 119
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 120,
			'IDENTIFIER' => 121
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
			'CHAR' => -243,
			'OBJECT' => -243,
			'ONEWAY' => 122,
			'FIXED' => -243,
			'VOID' => -243,
			'STRUCT' => 5,
			'DOUBLE' => -243,
			'LONG' => -243,
			'STRING' => -243,
			"::" => -243,
			'WSTRING' => -243,
			'UNSIGNED' => -243,
			'SHORT' => -243,
			'TYPEDEF' => 11,
			'BOOLEAN' => -243,
			'IDENTIFIER' => -243,
			'UNION' => 16,
			'READONLY' => 133,
			'WCHAR' => -243,
			'ATTRIBUTE' => -226,
			'error' => 127,
			'CONST' => 22,
			"}" => 128,
			'EXCEPTION' => 23,
			'OCTET' => -243,
			'FLOAT' => -243,
			'ENUM' => 28,
			'ANY' => -243
		},
		GOTOS => {
			'const_dcl' => 129,
			'op_mod' => 123,
			'except_dcl' => 124,
			'op_attribute' => 125,
			'attr_mod' => 126,
			'exports' => 130,
			'export' => 131,
			'struct_type' => 8,
			'op_header' => 132,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 17,
			'op_dcl' => 134,
			'enum_header' => 20,
			'attr_dcl' => 135,
			'type_dcl' => 136,
			'union_header' => 24,
			'interface_body' => 137
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
		DEFAULT => -168
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
			'error' => 138,
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
			'definitions' => 139,
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
		DEFAULT => -232
	},
	{#State 42
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 75,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'IDENTIFIER' => 84,
			'UNION' => 16,
			'WCHAR' => 59,
			'error' => 141,
			"}" => 143,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'type_spec' => 140,
			'string_type' => 57,
			'struct_header' => 12,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'member_list' => 142,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 72,
			'boolean_type' => 74,
			'integer_type' => 73,
			'signed_short_int' => 79,
			'member' => 144,
			'struct_type' => 81,
			'union_type' => 83,
			'sequence_type' => 85,
			'unsigned_long_int' => 86,
			'template_type_spec' => 87,
			'constr_type_spec' => 88,
			'simple_type_spec' => 89,
			'fixed_pt_type' => 90
		}
	},
	{#State 43
		DEFAULT => -147
	},
	{#State 44
		DEFAULT => -122
	},
	{#State 45
		ACTIONS => {
			"<" => 146,
			'error' => 145
		}
	},
	{#State 46
		DEFAULT => -146
	},
	{#State 47
		ACTIONS => {
			"<" => 148,
			'error' => 147
		}
	},
	{#State 48
		DEFAULT => -124
	},
	{#State 49
		DEFAULT => -129
	},
	{#State 50
		DEFAULT => -127
	},
	{#State 51
		ACTIONS => {
			"::" => 149
		},
		DEFAULT => -121
	},
	{#State 52
		DEFAULT => -125
	},
	{#State 53
		DEFAULT => -149
	},
	{#State 54
		ACTIONS => {
			'error' => 152,
			'IDENTIFIER' => 156
		},
		GOTOS => {
			'declarators' => 150,
			'declarator' => 151,
			'simple_declarator' => 154,
			'array_declarator' => 155,
			'complex_declarator' => 153
		}
	},
	{#State 55
		DEFAULT => -110
	},
	{#State 56
		ACTIONS => {
			'SHORT' => 157,
			'LONG' => 158
		}
	},
	{#State 57
		DEFAULT => -131
	},
	{#State 58
		DEFAULT => -151
	},
	{#State 59
		DEFAULT => -161
	},
	{#State 60
		DEFAULT => -156
	},
	{#State 61
		DEFAULT => -128
	},
	{#State 62
		DEFAULT => -119
	},
	{#State 63
		DEFAULT => -136
	},
	{#State 64
		DEFAULT => -114
	},
	{#State 65
		DEFAULT => -163
	},
	{#State 66
		DEFAULT => -154
	},
	{#State 67
		DEFAULT => -143
	},
	{#State 68
		DEFAULT => -150
	},
	{#State 69
		DEFAULT => -164
	},
	{#State 70
		DEFAULT => -160
	},
	{#State 71
		DEFAULT => -165
	},
	{#State 72
		DEFAULT => -132
	},
	{#State 73
		DEFAULT => -123
	},
	{#State 74
		DEFAULT => -126
	},
	{#State 75
		DEFAULT => -144
	},
	{#State 76
		ACTIONS => {
			'LONG' => 160,
			'DOUBLE' => 159
		},
		DEFAULT => -152
	},
	{#State 77
		ACTIONS => {
			"<" => 161
		},
		DEFAULT => -212
	},
	{#State 78
		ACTIONS => {
			'error' => 162,
			'IDENTIFIER' => 163
		}
	},
	{#State 79
		DEFAULT => -148
	},
	{#State 80
		ACTIONS => {
			"<" => 164
		},
		DEFAULT => -215
	},
	{#State 81
		DEFAULT => -134
	},
	{#State 82
		DEFAULT => -162
	},
	{#State 83
		DEFAULT => -135
	},
	{#State 84
		DEFAULT => -50
	},
	{#State 85
		DEFAULT => -130
	},
	{#State 86
		DEFAULT => -155
	},
	{#State 87
		DEFAULT => -120
	},
	{#State 88
		DEFAULT => -118
	},
	{#State 89
		DEFAULT => -117
	},
	{#State 90
		DEFAULT => -133
	},
	{#State 91
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 75,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'IDENTIFIER' => 84,
			'UNION' => 16,
			'WCHAR' => 59,
			'error' => 165,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'type_spec' => 140,
			'string_type' => 57,
			'struct_header' => 12,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'member_list' => 166,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 72,
			'boolean_type' => 74,
			'integer_type' => 73,
			'signed_short_int' => 79,
			'member' => 144,
			'struct_type' => 81,
			'union_type' => 83,
			'sequence_type' => 85,
			'unsigned_long_int' => 86,
			'template_type_spec' => 87,
			'constr_type_spec' => 88,
			'simple_type_spec' => 89,
			'fixed_pt_type' => 90
		}
	},
	{#State 92
		ACTIONS => {
			";" => 167
		}
	},
	{#State 93
		DEFAULT => -21
	},
	{#State 94
		DEFAULT => -20
	},
	{#State 95
		DEFAULT => -178
	},
	{#State 96
		DEFAULT => -198
	},
	{#State 97
		ACTIONS => {
			'error' => 168,
			'IDENTIFIER' => 170
		},
		GOTOS => {
			'enumerators' => 171,
			'enumerator' => 169
		}
	},
	{#State 98
		DEFAULT => -10
	},
	{#State 99
		DEFAULT => -15
	},
	{#State 100
		DEFAULT => -64
	},
	{#State 101
		DEFAULT => -278
	},
	{#State 102
		DEFAULT => -61
	},
	{#State 103
		ACTIONS => {
			"::" => 149
		},
		DEFAULT => -68
	},
	{#State 104
		DEFAULT => -62
	},
	{#State 105
		DEFAULT => -65
	},
	{#State 106
		DEFAULT => -59
	},
	{#State 107
		DEFAULT => -66
	},
	{#State 108
		DEFAULT => -63
	},
	{#State 109
		DEFAULT => -60
	},
	{#State 110
		DEFAULT => -67
	},
	{#State 111
		ACTIONS => {
			'error' => 172,
			'IDENTIFIER' => 173
		}
	},
	{#State 112
		DEFAULT => -234
	},
	{#State 113
		DEFAULT => -233
	},
	{#State 114
		ACTIONS => {
			'error' => 175,
			"(" => 174
		}
	},
	{#State 115
		DEFAULT => -6
	},
	{#State 116
		DEFAULT => -11
	},
	{#State 117
		DEFAULT => -5
	},
	{#State 118
		DEFAULT => -200
	},
	{#State 119
		DEFAULT => -199
	},
	{#State 120
		ACTIONS => {
			"{" => -31
		},
		DEFAULT => -28
	},
	{#State 121
		ACTIONS => {
			"{" => -29,
			":" => 176
		},
		DEFAULT => -27,
		GOTOS => {
			'interface_inheritance_spec' => 177
		}
	},
	{#State 122
		DEFAULT => -244
	},
	{#State 123
		ACTIONS => {
			'CHAR' => 70,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'OBJECT' => 71,
			'IDENTIFIER' => 84,
			'FIXED' => 45,
			'VOID' => 183,
			'WCHAR' => 59,
			'DOUBLE' => 75,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'OCTET' => 65,
			'FLOAT' => 67,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'wide_string_type' => 182,
			'integer_type' => 73,
			'boolean_type' => 74,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 178,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'signed_short_int' => 79,
			'string_type' => 179,
			'op_type_spec' => 184,
			'base_type_spec' => 180,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'unsigned_long_int' => 86,
			'param_type_spec' => 181,
			'unsigned_short_int' => 66,
			'fixed_pt_type' => 185,
			'signed_longlong_int' => 68
		}
	},
	{#State 124
		ACTIONS => {
			'error' => 187,
			";" => 186
		}
	},
	{#State 125
		DEFAULT => -242
	},
	{#State 126
		ACTIONS => {
			'ATTRIBUTE' => 188
		}
	},
	{#State 127
		ACTIONS => {
			"}" => 189
		}
	},
	{#State 128
		DEFAULT => -24
	},
	{#State 129
		ACTIONS => {
			'error' => 191,
			";" => 190
		}
	},
	{#State 130
		DEFAULT => -32
	},
	{#State 131
		ACTIONS => {
			'ONEWAY' => 122,
			'STRUCT' => 5,
			'TYPEDEF' => 11,
			'UNION' => 16,
			'READONLY' => 133,
			'ATTRIBUTE' => -226,
			'CONST' => 22,
			"}" => -33,
			'EXCEPTION' => 23,
			'ENUM' => 28
		},
		DEFAULT => -243,
		GOTOS => {
			'const_dcl' => 129,
			'op_mod' => 123,
			'except_dcl' => 124,
			'op_attribute' => 125,
			'attr_mod' => 126,
			'exports' => 192,
			'export' => 131,
			'struct_type' => 8,
			'op_header' => 132,
			'exception_header' => 9,
			'union_type' => 10,
			'struct_header' => 12,
			'enum_type' => 17,
			'op_dcl' => 134,
			'enum_header' => 20,
			'attr_dcl' => 135,
			'type_dcl' => 136,
			'union_header' => 24
		}
	},
	{#State 132
		ACTIONS => {
			'error' => 194,
			"(" => 193
		},
		GOTOS => {
			'parameter_dcls' => 195
		}
	},
	{#State 133
		DEFAULT => -225
	},
	{#State 134
		ACTIONS => {
			'error' => 197,
			";" => 196
		}
	},
	{#State 135
		ACTIONS => {
			'error' => 199,
			";" => 198
		}
	},
	{#State 136
		ACTIONS => {
			'error' => 201,
			";" => 200
		}
	},
	{#State 137
		ACTIONS => {
			"}" => 202
		}
	},
	{#State 138
		ACTIONS => {
			"}" => 203
		}
	},
	{#State 139
		ACTIONS => {
			"}" => 204
		}
	},
	{#State 140
		ACTIONS => {
			'IDENTIFIER' => 156
		},
		GOTOS => {
			'declarators' => 205,
			'declarator' => 151,
			'simple_declarator' => 154,
			'array_declarator' => 155,
			'complex_declarator' => 153
		}
	},
	{#State 141
		ACTIONS => {
			"}" => 206
		}
	},
	{#State 142
		ACTIONS => {
			"}" => 207
		}
	},
	{#State 143
		DEFAULT => -229
	},
	{#State 144
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 75,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'IDENTIFIER' => 84,
			'UNION' => 16,
			'WCHAR' => 59,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		DEFAULT => -169,
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'type_spec' => 140,
			'string_type' => 57,
			'struct_header' => 12,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'member_list' => 208,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 72,
			'boolean_type' => 74,
			'integer_type' => 73,
			'signed_short_int' => 79,
			'member' => 144,
			'struct_type' => 81,
			'union_type' => 83,
			'sequence_type' => 85,
			'unsigned_long_int' => 86,
			'template_type_spec' => 87,
			'constr_type_spec' => 88,
			'simple_type_spec' => 89,
			'fixed_pt_type' => 90
		}
	},
	{#State 145
		DEFAULT => -277
	},
	{#State 146
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 218,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'primary_expr' => 228,
			'and_expr' => 229,
			'scoped_name' => 211,
			'positive_int_const' => 212,
			'wide_string_literal' => 213,
			'boolean_literal' => 215,
			'mult_expr' => 231,
			'const_exp' => 216,
			'or_expr' => 217,
			'unary_expr' => 235,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 147
		DEFAULT => -210
	},
	{#State 148
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'SEQUENCE' => 47,
			'DOUBLE' => 75,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'IDENTIFIER' => 84,
			'WCHAR' => 59,
			'error' => 239,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'wide_string_type' => 72,
			'integer_type' => 73,
			'boolean_type' => 74,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'signed_short_int' => 79,
			'string_type' => 57,
			'sequence_type' => 85,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'unsigned_long_int' => 86,
			'template_type_spec' => 87,
			'unsigned_short_int' => 66,
			'simple_type_spec' => 240,
			'fixed_pt_type' => 90,
			'signed_longlong_int' => 68
		}
	},
	{#State 149
		ACTIONS => {
			'error' => 241,
			'IDENTIFIER' => 242
		}
	},
	{#State 150
		DEFAULT => -115
	},
	{#State 151
		ACTIONS => {
			"," => 243
		},
		DEFAULT => -137
	},
	{#State 152
		DEFAULT => -116
	},
	{#State 153
		DEFAULT => -140
	},
	{#State 154
		DEFAULT => -139
	},
	{#State 155
		DEFAULT => -142
	},
	{#State 156
		ACTIONS => {
			"[" => 246
		},
		DEFAULT => -141,
		GOTOS => {
			'fixed_array_sizes' => 244,
			'fixed_array_size' => 245
		}
	},
	{#State 157
		DEFAULT => -157
	},
	{#State 158
		ACTIONS => {
			'LONG' => 247
		},
		DEFAULT => -158
	},
	{#State 159
		DEFAULT => -145
	},
	{#State 160
		DEFAULT => -153
	},
	{#State 161
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 249,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'primary_expr' => 228,
			'and_expr' => 229,
			'scoped_name' => 211,
			'positive_int_const' => 248,
			'wide_string_literal' => 213,
			'boolean_literal' => 215,
			'mult_expr' => 231,
			'const_exp' => 216,
			'or_expr' => 217,
			'unary_expr' => 235,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 162
		DEFAULT => -52
	},
	{#State 163
		DEFAULT => -51
	},
	{#State 164
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 251,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'primary_expr' => 228,
			'and_expr' => 229,
			'scoped_name' => 211,
			'positive_int_const' => 250,
			'wide_string_literal' => 213,
			'boolean_literal' => 215,
			'mult_expr' => 231,
			'const_exp' => 216,
			'or_expr' => 217,
			'unary_expr' => 235,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 165
		ACTIONS => {
			"}" => 252
		}
	},
	{#State 166
		ACTIONS => {
			"}" => 253
		}
	},
	{#State 167
		DEFAULT => -16
	},
	{#State 168
		ACTIONS => {
			"}" => 254
		}
	},
	{#State 169
		ACTIONS => {
			";" => 255,
			"," => 256
		},
		DEFAULT => -201
	},
	{#State 170
		DEFAULT => -205
	},
	{#State 171
		ACTIONS => {
			"}" => 257
		}
	},
	{#State 172
		DEFAULT => -58
	},
	{#State 173
		ACTIONS => {
			'error' => 258,
			"=" => 259
		}
	},
	{#State 174
		ACTIONS => {
			'CHAR' => 70,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'IDENTIFIER' => 84,
			'error' => 263,
			'LONG' => 267,
			"::" => 78,
			'ENUM' => 28,
			'UNSIGNED' => 56
		},
		GOTOS => {
			'switch_type_spec' => 264,
			'unsigned_int' => 43,
			'signed_int' => 46,
			'integer_type' => 266,
			'boolean_type' => 265,
			'unsigned_longlong_int' => 60,
			'char_type' => 260,
			'enum_type' => 262,
			'unsigned_long_int' => 86,
			'scoped_name' => 261,
			'enum_header' => 20,
			'signed_long_int' => 53,
			'unsigned_short_int' => 66,
			'signed_short_int' => 79,
			'signed_longlong_int' => 68
		}
	},
	{#State 175
		DEFAULT => -177
	},
	{#State 176
		ACTIONS => {
			'error' => 269,
			'IDENTIFIER' => 84,
			"::" => 78
		},
		GOTOS => {
			'scoped_name' => 268,
			'interface_names' => 271,
			'interface_name' => 270
		}
	},
	{#State 177
		DEFAULT => -30
	},
	{#State 178
		ACTIONS => {
			"::" => 149
		},
		DEFAULT => -273
	},
	{#State 179
		DEFAULT => -270
	},
	{#State 180
		DEFAULT => -269
	},
	{#State 181
		DEFAULT => -245
	},
	{#State 182
		DEFAULT => -271
	},
	{#State 183
		DEFAULT => -246
	},
	{#State 184
		ACTIONS => {
			'error' => 272,
			'IDENTIFIER' => 273
		}
	},
	{#State 185
		DEFAULT => -272
	},
	{#State 186
		DEFAULT => -37
	},
	{#State 187
		DEFAULT => -42
	},
	{#State 188
		ACTIONS => {
			'CHAR' => 70,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'OBJECT' => 71,
			'IDENTIFIER' => 84,
			'FIXED' => 45,
			'WCHAR' => 59,
			'DOUBLE' => 75,
			'error' => 274,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'OCTET' => 65,
			'FLOAT' => 67,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'wide_string_type' => 182,
			'integer_type' => 73,
			'boolean_type' => 74,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 178,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'signed_short_int' => 79,
			'string_type' => 179,
			'base_type_spec' => 180,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'unsigned_long_int' => 86,
			'param_type_spec' => 275,
			'unsigned_short_int' => 66,
			'fixed_pt_type' => 185,
			'signed_longlong_int' => 68
		}
	},
	{#State 189
		DEFAULT => -26
	},
	{#State 190
		DEFAULT => -36
	},
	{#State 191
		DEFAULT => -41
	},
	{#State 192
		DEFAULT => -34
	},
	{#State 193
		ACTIONS => {
			'error' => 277,
			")" => 281,
			'OUT' => 282,
			'INOUT' => 278,
			'IN' => 276
		},
		GOTOS => {
			'param_dcl' => 283,
			'param_dcls' => 280,
			'param_attribute' => 279
		}
	},
	{#State 194
		DEFAULT => -239
	},
	{#State 195
		ACTIONS => {
			'RAISES' => 287,
			'CONTEXT' => 284
		},
		DEFAULT => -235,
		GOTOS => {
			'context_expr' => 286,
			'raises_expr' => 285
		}
	},
	{#State 196
		DEFAULT => -39
	},
	{#State 197
		DEFAULT => -44
	},
	{#State 198
		DEFAULT => -38
	},
	{#State 199
		DEFAULT => -43
	},
	{#State 200
		DEFAULT => -35
	},
	{#State 201
		DEFAULT => -40
	},
	{#State 202
		DEFAULT => -25
	},
	{#State 203
		DEFAULT => -18
	},
	{#State 204
		DEFAULT => -17
	},
	{#State 205
		ACTIONS => {
			'error' => 289,
			";" => 288
		}
	},
	{#State 206
		DEFAULT => -231
	},
	{#State 207
		DEFAULT => -230
	},
	{#State 208
		DEFAULT => -170
	},
	{#State 209
		DEFAULT => -98
	},
	{#State 210
		DEFAULT => -99
	},
	{#State 211
		ACTIONS => {
			"::" => 149
		},
		DEFAULT => -91
	},
	{#State 212
		ACTIONS => {
			"," => 290
		}
	},
	{#State 213
		DEFAULT => -97
	},
	{#State 214
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 292,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 231,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'const_exp' => 291,
			'and_expr' => 229,
			'or_expr' => 217,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 215
		DEFAULT => -102
	},
	{#State 216
		DEFAULT => -109
	},
	{#State 217
		ACTIONS => {
			"|" => 293
		},
		DEFAULT => -69
	},
	{#State 218
		ACTIONS => {
			">" => 294
		}
	},
	{#State 219
		ACTIONS => {
			"^" => 295
		},
		DEFAULT => -70
	},
	{#State 220
		ACTIONS => {
			"<<" => 296,
			">>" => 297
		},
		DEFAULT => -74
	},
	{#State 221
		DEFAULT => -108
	},
	{#State 222
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 222
		},
		DEFAULT => -105,
		GOTOS => {
			'wide_string_literal' => 298
		}
	},
	{#State 223
		DEFAULT => -92
	},
	{#State 224
		DEFAULT => -107
	},
	{#State 225
		ACTIONS => {
			"+" => 299,
			"-" => 300
		},
		DEFAULT => -76
	},
	{#State 226
		DEFAULT => -96
	},
	{#State 227
		DEFAULT => -101
	},
	{#State 228
		DEFAULT => -87
	},
	{#State 229
		ACTIONS => {
			"&" => 301
		},
		DEFAULT => -72
	},
	{#State 230
		DEFAULT => -95
	},
	{#State 231
		ACTIONS => {
			"%" => 303,
			"*" => 302,
			"/" => 304
		},
		DEFAULT => -79
	},
	{#State 232
		ACTIONS => {
			'STRING_LITERAL' => 232
		},
		DEFAULT => -103,
		GOTOS => {
			'string_literal' => 305
		}
	},
	{#State 233
		DEFAULT => -100
	},
	{#State 234
		DEFAULT => -89
	},
	{#State 235
		DEFAULT => -82
	},
	{#State 236
		DEFAULT => -88
	},
	{#State 237
		DEFAULT => -90
	},
	{#State 238
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'boolean_literal' => 215,
			'scoped_name' => 211,
			'primary_expr' => 306,
			'literal' => 223,
			'wide_string_literal' => 213
		}
	},
	{#State 239
		ACTIONS => {
			">" => 307
		}
	},
	{#State 240
		ACTIONS => {
			">" => 309,
			"," => 308
		}
	},
	{#State 241
		DEFAULT => -54
	},
	{#State 242
		DEFAULT => -53
	},
	{#State 243
		ACTIONS => {
			'IDENTIFIER' => 156
		},
		GOTOS => {
			'declarators' => 310,
			'declarator' => 151,
			'simple_declarator' => 154,
			'array_declarator' => 155,
			'complex_declarator' => 153
		}
	},
	{#State 244
		DEFAULT => -217
	},
	{#State 245
		ACTIONS => {
			"[" => 246
		},
		DEFAULT => -218,
		GOTOS => {
			'fixed_array_sizes' => 311,
			'fixed_array_size' => 245
		}
	},
	{#State 246
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 313,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'primary_expr' => 228,
			'and_expr' => 229,
			'scoped_name' => 211,
			'positive_int_const' => 312,
			'wide_string_literal' => 213,
			'boolean_literal' => 215,
			'mult_expr' => 231,
			'const_exp' => 216,
			'or_expr' => 217,
			'unary_expr' => 235,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 247
		DEFAULT => -159
	},
	{#State 248
		ACTIONS => {
			">" => 314
		}
	},
	{#State 249
		ACTIONS => {
			">" => 315
		}
	},
	{#State 250
		ACTIONS => {
			">" => 316
		}
	},
	{#State 251
		ACTIONS => {
			">" => 317
		}
	},
	{#State 252
		DEFAULT => -167
	},
	{#State 253
		DEFAULT => -166
	},
	{#State 254
		DEFAULT => -197
	},
	{#State 255
		DEFAULT => -204
	},
	{#State 256
		ACTIONS => {
			'IDENTIFIER' => 170
		},
		DEFAULT => -203,
		GOTOS => {
			'enumerators' => 318,
			'enumerator' => 169
		}
	},
	{#State 257
		DEFAULT => -196
	},
	{#State 258
		DEFAULT => -57
	},
	{#State 259
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 320,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 231,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'const_exp' => 319,
			'and_expr' => 229,
			'or_expr' => 217,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 260
		DEFAULT => -180
	},
	{#State 261
		ACTIONS => {
			"::" => 149
		},
		DEFAULT => -183
	},
	{#State 262
		DEFAULT => -182
	},
	{#State 263
		ACTIONS => {
			")" => 321
		}
	},
	{#State 264
		ACTIONS => {
			")" => 322
		}
	},
	{#State 265
		DEFAULT => -181
	},
	{#State 266
		DEFAULT => -179
	},
	{#State 267
		ACTIONS => {
			'LONG' => 160
		},
		DEFAULT => -152
	},
	{#State 268
		ACTIONS => {
			"::" => 149
		},
		DEFAULT => -49
	},
	{#State 269
		DEFAULT => -46
	},
	{#State 270
		ACTIONS => {
			"," => 323
		},
		DEFAULT => -47
	},
	{#State 271
		DEFAULT => -45
	},
	{#State 272
		DEFAULT => -241
	},
	{#State 273
		DEFAULT => -240
	},
	{#State 274
		DEFAULT => -224
	},
	{#State 275
		ACTIONS => {
			'error' => 324,
			'IDENTIFIER' => 327
		},
		GOTOS => {
			'simple_declarators' => 326,
			'simple_declarator' => 325
		}
	},
	{#State 276
		DEFAULT => -255
	},
	{#State 277
		ACTIONS => {
			")" => 328
		}
	},
	{#State 278
		DEFAULT => -257
	},
	{#State 279
		ACTIONS => {
			'CHAR' => 70,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'OBJECT' => 71,
			'IDENTIFIER' => 84,
			'FIXED' => 45,
			'WCHAR' => 59,
			'DOUBLE' => 75,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'OCTET' => 65,
			'FLOAT' => 67,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'wide_string_type' => 182,
			'integer_type' => 73,
			'boolean_type' => 74,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 178,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'signed_short_int' => 79,
			'string_type' => 179,
			'base_type_spec' => 180,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'unsigned_long_int' => 86,
			'param_type_spec' => 329,
			'unsigned_short_int' => 66,
			'fixed_pt_type' => 185,
			'signed_longlong_int' => 68
		}
	},
	{#State 280
		ACTIONS => {
			")" => 330
		}
	},
	{#State 281
		DEFAULT => -248
	},
	{#State 282
		DEFAULT => -256
	},
	{#State 283
		ACTIONS => {
			";" => 331,
			"," => 332
		},
		DEFAULT => -250
	},
	{#State 284
		ACTIONS => {
			'error' => 334,
			"(" => 333
		}
	},
	{#State 285
		ACTIONS => {
			'CONTEXT' => 284
		},
		DEFAULT => -236,
		GOTOS => {
			'context_expr' => 335
		}
	},
	{#State 286
		DEFAULT => -238
	},
	{#State 287
		ACTIONS => {
			'error' => 337,
			"(" => 336
		}
	},
	{#State 288
		DEFAULT => -171
	},
	{#State 289
		DEFAULT => -172
	},
	{#State 290
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 339,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'primary_expr' => 228,
			'and_expr' => 229,
			'scoped_name' => 211,
			'positive_int_const' => 338,
			'wide_string_literal' => 213,
			'boolean_literal' => 215,
			'mult_expr' => 231,
			'const_exp' => 216,
			'or_expr' => 217,
			'unary_expr' => 235,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 291
		ACTIONS => {
			")" => 340
		}
	},
	{#State 292
		ACTIONS => {
			")" => 341
		}
	},
	{#State 293
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 231,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'and_expr' => 229,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'xor_expr' => 342,
			'shift_expr' => 220,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 294
		DEFAULT => -276
	},
	{#State 295
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 231,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'and_expr' => 343,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'shift_expr' => 220,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 296
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 231,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 344
		}
	},
	{#State 297
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 231,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 345
		}
	},
	{#State 298
		DEFAULT => -106
	},
	{#State 299
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 346,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238
		}
	},
	{#State 300
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 347,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238
		}
	},
	{#State 301
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 231,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'shift_expr' => 348,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 302
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'unary_expr' => 349,
			'scoped_name' => 211,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238
		}
	},
	{#State 303
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'unary_expr' => 350,
			'scoped_name' => 211,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238
		}
	},
	{#State 304
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'CHARACTER_LITERAL' => 209,
			"+" => 234,
			'FIXED_PT_LITERAL' => 233,
			'WIDE_CHARACTER_LITERAL' => 210,
			"-" => 236,
			"::" => 78,
			'FALSE' => 221,
			'WIDE_STRING_LITERAL' => 222,
			'INTEGER_LITERAL' => 230,
			"~" => 237,
			"(" => 214,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'unary_expr' => 351,
			'scoped_name' => 211,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238
		}
	},
	{#State 305
		DEFAULT => -104
	},
	{#State 306
		DEFAULT => -86
	},
	{#State 307
		DEFAULT => -209
	},
	{#State 308
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 353,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'string_literal' => 226,
			'primary_expr' => 228,
			'and_expr' => 229,
			'scoped_name' => 211,
			'positive_int_const' => 352,
			'wide_string_literal' => 213,
			'boolean_literal' => 215,
			'mult_expr' => 231,
			'const_exp' => 216,
			'or_expr' => 217,
			'unary_expr' => 235,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 309
		DEFAULT => -208
	},
	{#State 310
		DEFAULT => -138
	},
	{#State 311
		DEFAULT => -219
	},
	{#State 312
		ACTIONS => {
			"]" => 354
		}
	},
	{#State 313
		ACTIONS => {
			"]" => 355
		}
	},
	{#State 314
		DEFAULT => -211
	},
	{#State 315
		DEFAULT => -213
	},
	{#State 316
		DEFAULT => -214
	},
	{#State 317
		DEFAULT => -216
	},
	{#State 318
		DEFAULT => -202
	},
	{#State 319
		DEFAULT => -55
	},
	{#State 320
		DEFAULT => -56
	},
	{#State 321
		DEFAULT => -176
	},
	{#State 322
		ACTIONS => {
			"{" => 357,
			'error' => 356
		}
	},
	{#State 323
		ACTIONS => {
			'IDENTIFIER' => 84,
			"::" => 78
		},
		GOTOS => {
			'scoped_name' => 268,
			'interface_names' => 358,
			'interface_name' => 270
		}
	},
	{#State 324
		DEFAULT => -223
	},
	{#State 325
		ACTIONS => {
			"," => 359
		},
		DEFAULT => -227
	},
	{#State 326
		DEFAULT => -222
	},
	{#State 327
		DEFAULT => -141
	},
	{#State 328
		DEFAULT => -249
	},
	{#State 329
		ACTIONS => {
			'IDENTIFIER' => 327
		},
		GOTOS => {
			'simple_declarator' => 360
		}
	},
	{#State 330
		DEFAULT => -247
	},
	{#State 331
		DEFAULT => -253
	},
	{#State 332
		ACTIONS => {
			'OUT' => 282,
			'INOUT' => 278,
			'IN' => 276
		},
		DEFAULT => -252,
		GOTOS => {
			'param_dcl' => 283,
			'param_dcls' => 361,
			'param_attribute' => 279
		}
	},
	{#State 333
		ACTIONS => {
			'error' => 362,
			'STRING_LITERAL' => 232
		},
		GOTOS => {
			'string_literal' => 363,
			'string_literals' => 364
		}
	},
	{#State 334
		DEFAULT => -266
	},
	{#State 335
		DEFAULT => -237
	},
	{#State 336
		ACTIONS => {
			'error' => 366,
			'IDENTIFIER' => 84,
			"::" => 78
		},
		GOTOS => {
			'scoped_name' => 365,
			'exception_names' => 367,
			'exception_name' => 368
		}
	},
	{#State 337
		DEFAULT => -260
	},
	{#State 338
		ACTIONS => {
			">" => 369
		}
	},
	{#State 339
		ACTIONS => {
			">" => 370
		}
	},
	{#State 340
		DEFAULT => -93
	},
	{#State 341
		DEFAULT => -94
	},
	{#State 342
		ACTIONS => {
			"^" => 295
		},
		DEFAULT => -71
	},
	{#State 343
		ACTIONS => {
			"&" => 301
		},
		DEFAULT => -73
	},
	{#State 344
		ACTIONS => {
			"+" => 299,
			"-" => 300
		},
		DEFAULT => -78
	},
	{#State 345
		ACTIONS => {
			"+" => 299,
			"-" => 300
		},
		DEFAULT => -77
	},
	{#State 346
		ACTIONS => {
			"%" => 303,
			"*" => 302,
			"/" => 304
		},
		DEFAULT => -80
	},
	{#State 347
		ACTIONS => {
			"%" => 303,
			"*" => 302,
			"/" => 304
		},
		DEFAULT => -81
	},
	{#State 348
		ACTIONS => {
			"<<" => 296,
			">>" => 297
		},
		DEFAULT => -75
	},
	{#State 349
		DEFAULT => -83
	},
	{#State 350
		DEFAULT => -85
	},
	{#State 351
		DEFAULT => -84
	},
	{#State 352
		ACTIONS => {
			">" => 371
		}
	},
	{#State 353
		ACTIONS => {
			">" => 372
		}
	},
	{#State 354
		DEFAULT => -220
	},
	{#State 355
		DEFAULT => -221
	},
	{#State 356
		DEFAULT => -175
	},
	{#State 357
		ACTIONS => {
			'error' => 376,
			'CASE' => 373,
			'DEFAULT' => 375
		},
		GOTOS => {
			'case_labels' => 378,
			'switch_body' => 377,
			'case' => 374,
			'case_label' => 379
		}
	},
	{#State 358
		DEFAULT => -48
	},
	{#State 359
		ACTIONS => {
			'IDENTIFIER' => 327
		},
		GOTOS => {
			'simple_declarators' => 380,
			'simple_declarator' => 325
		}
	},
	{#State 360
		DEFAULT => -254
	},
	{#State 361
		DEFAULT => -251
	},
	{#State 362
		ACTIONS => {
			")" => 381
		}
	},
	{#State 363
		ACTIONS => {
			"," => 382
		},
		DEFAULT => -267
	},
	{#State 364
		ACTIONS => {
			")" => 383
		}
	},
	{#State 365
		ACTIONS => {
			"::" => 149
		},
		DEFAULT => -263
	},
	{#State 366
		ACTIONS => {
			")" => 384
		}
	},
	{#State 367
		ACTIONS => {
			")" => 385
		}
	},
	{#State 368
		ACTIONS => {
			"," => 386
		},
		DEFAULT => -261
	},
	{#State 369
		DEFAULT => -274
	},
	{#State 370
		DEFAULT => -275
	},
	{#State 371
		DEFAULT => -206
	},
	{#State 372
		DEFAULT => -207
	},
	{#State 373
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 227,
			'CHARACTER_LITERAL' => 209,
			'WIDE_CHARACTER_LITERAL' => 210,
			"::" => 78,
			'INTEGER_LITERAL' => 230,
			"(" => 214,
			'IDENTIFIER' => 84,
			'STRING_LITERAL' => 232,
			'FIXED_PT_LITERAL' => 233,
			"+" => 234,
			'error' => 388,
			"-" => 236,
			'WIDE_STRING_LITERAL' => 222,
			'FALSE' => 221,
			"~" => 237,
			'TRUE' => 224
		},
		GOTOS => {
			'mult_expr' => 231,
			'string_literal' => 226,
			'boolean_literal' => 215,
			'primary_expr' => 228,
			'const_exp' => 387,
			'and_expr' => 229,
			'or_expr' => 217,
			'unary_expr' => 235,
			'scoped_name' => 211,
			'xor_expr' => 219,
			'shift_expr' => 220,
			'wide_string_literal' => 213,
			'literal' => 223,
			'unary_operator' => 238,
			'add_expr' => 225
		}
	},
	{#State 374
		ACTIONS => {
			'CASE' => 373,
			'DEFAULT' => 375
		},
		DEFAULT => -184,
		GOTOS => {
			'case_labels' => 378,
			'switch_body' => 389,
			'case' => 374,
			'case_label' => 379
		}
	},
	{#State 375
		ACTIONS => {
			'error' => 390,
			":" => 391
		}
	},
	{#State 376
		ACTIONS => {
			"}" => 392
		}
	},
	{#State 377
		ACTIONS => {
			"}" => 393
		}
	},
	{#State 378
		ACTIONS => {
			'CHAR' => 70,
			'OBJECT' => 71,
			'FIXED' => 45,
			'SEQUENCE' => 47,
			'STRUCT' => 5,
			'DOUBLE' => 75,
			'LONG' => 76,
			'STRING' => 77,
			"::" => 78,
			'WSTRING' => 80,
			'UNSIGNED' => 56,
			'SHORT' => 58,
			'BOOLEAN' => 82,
			'IDENTIFIER' => 84,
			'UNION' => 16,
			'WCHAR' => 59,
			'FLOAT' => 67,
			'OCTET' => 65,
			'ENUM' => 28,
			'ANY' => 69
		},
		GOTOS => {
			'unsigned_int' => 43,
			'floating_pt_type' => 44,
			'signed_int' => 46,
			'char_type' => 48,
			'object_type' => 49,
			'octet_type' => 50,
			'scoped_name' => 51,
			'wide_char_type' => 52,
			'signed_long_int' => 53,
			'type_spec' => 394,
			'string_type' => 57,
			'struct_header' => 12,
			'element_spec' => 395,
			'unsigned_longlong_int' => 60,
			'any_type' => 61,
			'base_type_spec' => 62,
			'enum_type' => 63,
			'enum_header' => 20,
			'union_header' => 24,
			'unsigned_short_int' => 66,
			'signed_longlong_int' => 68,
			'wide_string_type' => 72,
			'boolean_type' => 74,
			'integer_type' => 73,
			'signed_short_int' => 79,
			'struct_type' => 81,
			'union_type' => 83,
			'sequence_type' => 85,
			'unsigned_long_int' => 86,
			'template_type_spec' => 87,
			'constr_type_spec' => 88,
			'simple_type_spec' => 89,
			'fixed_pt_type' => 90
		}
	},
	{#State 379
		ACTIONS => {
			'CASE' => 373,
			'DEFAULT' => 375
		},
		DEFAULT => -188,
		GOTOS => {
			'case_labels' => 396,
			'case_label' => 379
		}
	},
	{#State 380
		DEFAULT => -228
	},
	{#State 381
		DEFAULT => -265
	},
	{#State 382
		ACTIONS => {
			'STRING_LITERAL' => 232
		},
		GOTOS => {
			'string_literal' => 363,
			'string_literals' => 397
		}
	},
	{#State 383
		DEFAULT => -264
	},
	{#State 384
		DEFAULT => -259
	},
	{#State 385
		DEFAULT => -258
	},
	{#State 386
		ACTIONS => {
			'IDENTIFIER' => 84,
			"::" => 78
		},
		GOTOS => {
			'scoped_name' => 365,
			'exception_names' => 398,
			'exception_name' => 368
		}
	},
	{#State 387
		ACTIONS => {
			'error' => 399,
			":" => 400
		}
	},
	{#State 388
		DEFAULT => -192
	},
	{#State 389
		DEFAULT => -185
	},
	{#State 390
		DEFAULT => -194
	},
	{#State 391
		DEFAULT => -193
	},
	{#State 392
		DEFAULT => -174
	},
	{#State 393
		DEFAULT => -173
	},
	{#State 394
		ACTIONS => {
			'IDENTIFIER' => 156
		},
		GOTOS => {
			'declarator' => 401,
			'simple_declarator' => 154,
			'array_declarator' => 155,
			'complex_declarator' => 153
		}
	},
	{#State 395
		ACTIONS => {
			'error' => 403,
			";" => 402
		}
	},
	{#State 396
		DEFAULT => -189
	},
	{#State 397
		DEFAULT => -268
	},
	{#State 398
		DEFAULT => -262
	},
	{#State 399
		DEFAULT => -191
	},
	{#State 400
		DEFAULT => -190
	},
	{#State 401
		DEFAULT => -195
	},
	{#State 402
		DEFAULT => -186
	},
	{#State 403
		DEFAULT => -187
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
#line 59 "parser21.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 0,
sub
#line 65 "parser21.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 69 "parser21.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 76 "parser21.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 80 "parser21.yp"
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
#line 99 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 12
		 'definition', 2,
sub
#line 105 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 111 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 117 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 123 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'definition', 3,
sub
#line 129 "parser21.yp"
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
#line 142 "parser21.yp"
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
#line 149 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 19
		 'module', 2,
sub
#line 155 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 20
		 'module_header', 2,
sub
#line 164 "parser21.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 21
		 'module_header', 2,
sub
#line 170 "parser21.yp"
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
#line 187 "parser21.yp"
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
#line 195 "parser21.yp"
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
#line 203 "parser21.yp"
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
#line 214 "parser21.yp"
{
			new ForwardRegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 28
		 'forward_dcl', 2,
sub
#line 220 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 29
		 'interface_header', 2,
sub
#line 229 "parser21.yp"
{
			new RegularInterface($_[0],
					'idf'					=>	$_[2]
			);
		}
	],
	[#Rule 30
		 'interface_header', 3,
sub
#line 235 "parser21.yp"
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
#line 245 "parser21.yp"
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
#line 259 "parser21.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 34
		 'exports', 2,
sub
#line 263 "parser21.yp"
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
#line 282 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 41
		 'export', 2,
sub
#line 288 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 42
		 'export', 2,
sub
#line 294 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'export', 2,
sub
#line 300 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 44
		 'export', 2,
sub
#line 306 "parser21.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 45
		 'interface_inheritance_spec', 2,
sub
#line 316 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 46
		 'interface_inheritance_spec', 2,
sub
#line 320 "parser21.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 47
		 'interface_names', 1,
sub
#line 328 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 48
		 'interface_names', 3,
sub
#line 332 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 49
		 'interface_name', 1,
sub
#line 340 "parser21.yp"
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
#line 350 "parser21.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 52
		 'scoped_name', 2,
sub
#line 354 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 53
		 'scoped_name', 3,
sub
#line 360 "parser21.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 54
		 'scoped_name', 3,
sub
#line 364 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 55
		 'const_dcl', 5,
sub
#line 374 "parser21.yp"
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
#line 382 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 57
		 'const_dcl', 4,
sub
#line 387 "parser21.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 58
		 'const_dcl', 3,
sub
#line 392 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 59
		 'const_dcl', 2,
sub
#line 397 "parser21.yp"
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
		 'const_type', 1, undef
	],
	[#Rule 66
		 'const_type', 1, undef
	],
	[#Rule 67
		 'const_type', 1, undef
	],
	[#Rule 68
		 'const_type', 1,
sub
#line 422 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 69
		 'const_exp', 1, undef
	],
	[#Rule 70
		 'or_expr', 1, undef
	],
	[#Rule 71
		 'or_expr', 3,
sub
#line 438 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 72
		 'xor_expr', 1, undef
	],
	[#Rule 73
		 'xor_expr', 3,
sub
#line 448 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 74
		 'and_expr', 1, undef
	],
	[#Rule 75
		 'and_expr', 3,
sub
#line 458 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 76
		 'shift_expr', 1, undef
	],
	[#Rule 77
		 'shift_expr', 3,
sub
#line 468 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 78
		 'shift_expr', 3,
sub
#line 472 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 79
		 'add_expr', 1, undef
	],
	[#Rule 80
		 'add_expr', 3,
sub
#line 482 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 81
		 'add_expr', 3,
sub
#line 486 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 82
		 'mult_expr', 1, undef
	],
	[#Rule 83
		 'mult_expr', 3,
sub
#line 496 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 84
		 'mult_expr', 3,
sub
#line 500 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 85
		 'mult_expr', 3,
sub
#line 504 "parser21.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 86
		 'unary_expr', 2,
sub
#line 512 "parser21.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 87
		 'unary_expr', 1, undef
	],
	[#Rule 88
		 'unary_operator', 1, undef
	],
	[#Rule 89
		 'unary_operator', 1, undef
	],
	[#Rule 90
		 'unary_operator', 1, undef
	],
	[#Rule 91
		 'primary_expr', 1,
sub
#line 532 "parser21.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 92
		 'primary_expr', 1,
sub
#line 538 "parser21.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 93
		 'primary_expr', 3,
sub
#line 542 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 94
		 'primary_expr', 3,
sub
#line 546 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 95
		 'literal', 1,
sub
#line 555 "parser21.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 96
		 'literal', 1,
sub
#line 562 "parser21.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 97
		 'literal', 1,
sub
#line 568 "parser21.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 98
		 'literal', 1,
sub
#line 574 "parser21.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 99
		 'literal', 1,
sub
#line 580 "parser21.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 100
		 'literal', 1,
sub
#line 586 "parser21.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 101
		 'literal', 1,
sub
#line 593 "parser21.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 102
		 'literal', 1, undef
	],
	[#Rule 103
		 'string_literal', 1, undef
	],
	[#Rule 104
		 'string_literal', 2,
sub
#line 607 "parser21.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 105
		 'wide_string_literal', 1, undef
	],
	[#Rule 106
		 'wide_string_literal', 2,
sub
#line 616 "parser21.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 107
		 'boolean_literal', 1,
sub
#line 624 "parser21.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 108
		 'boolean_literal', 1,
sub
#line 630 "parser21.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 109
		 'positive_int_const', 1,
sub
#line 640 "parser21.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 110
		 'type_dcl', 2,
sub
#line 650 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 111
		 'type_dcl', 1, undef
	],
	[#Rule 112
		 'type_dcl', 1, undef
	],
	[#Rule 113
		 'type_dcl', 1, undef
	],
	[#Rule 114
		 'type_dcl', 2,
sub
#line 660 "parser21.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 115
		 'type_declarator', 2,
sub
#line 669 "parser21.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 116
		 'type_declarator', 2,
sub
#line 676 "parser21.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 117
		 'type_spec', 1, undef
	],
	[#Rule 118
		 'type_spec', 1, undef
	],
	[#Rule 119
		 'simple_type_spec', 1, undef
	],
	[#Rule 120
		 'simple_type_spec', 1, undef
	],
	[#Rule 121
		 'simple_type_spec', 1,
sub
#line 697 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 122
		 'base_type_spec', 1, undef
	],
	[#Rule 123
		 'base_type_spec', 1, undef
	],
	[#Rule 124
		 'base_type_spec', 1, undef
	],
	[#Rule 125
		 'base_type_spec', 1, undef
	],
	[#Rule 126
		 'base_type_spec', 1, undef
	],
	[#Rule 127
		 'base_type_spec', 1, undef
	],
	[#Rule 128
		 'base_type_spec', 1, undef
	],
	[#Rule 129
		 'base_type_spec', 1, undef
	],
	[#Rule 130
		 'template_type_spec', 1, undef
	],
	[#Rule 131
		 'template_type_spec', 1, undef
	],
	[#Rule 132
		 'template_type_spec', 1, undef
	],
	[#Rule 133
		 'template_type_spec', 1, undef
	],
	[#Rule 134
		 'constr_type_spec', 1, undef
	],
	[#Rule 135
		 'constr_type_spec', 1, undef
	],
	[#Rule 136
		 'constr_type_spec', 1, undef
	],
	[#Rule 137
		 'declarators', 1,
sub
#line 747 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 138
		 'declarators', 3,
sub
#line 751 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 139
		 'declarator', 1,
sub
#line 760 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 140
		 'declarator', 1, undef
	],
	[#Rule 141
		 'simple_declarator', 1, undef
	],
	[#Rule 142
		 'complex_declarator', 1, undef
	],
	[#Rule 143
		 'floating_pt_type', 1,
sub
#line 782 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 144
		 'floating_pt_type', 1,
sub
#line 788 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 145
		 'floating_pt_type', 2,
sub
#line 794 "parser21.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 146
		 'integer_type', 1, undef
	],
	[#Rule 147
		 'integer_type', 1, undef
	],
	[#Rule 148
		 'signed_int', 1, undef
	],
	[#Rule 149
		 'signed_int', 1, undef
	],
	[#Rule 150
		 'signed_int', 1, undef
	],
	[#Rule 151
		 'signed_short_int', 1,
sub
#line 822 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 152
		 'signed_long_int', 1,
sub
#line 832 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 153
		 'signed_longlong_int', 2,
sub
#line 842 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 154
		 'unsigned_int', 1, undef
	],
	[#Rule 155
		 'unsigned_int', 1, undef
	],
	[#Rule 156
		 'unsigned_int', 1, undef
	],
	[#Rule 157
		 'unsigned_short_int', 2,
sub
#line 862 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 158
		 'unsigned_long_int', 2,
sub
#line 872 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 159
		 'unsigned_longlong_int', 3,
sub
#line 882 "parser21.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 160
		 'char_type', 1,
sub
#line 892 "parser21.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 161
		 'wide_char_type', 1,
sub
#line 902 "parser21.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 162
		 'boolean_type', 1,
sub
#line 912 "parser21.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 163
		 'octet_type', 1,
sub
#line 922 "parser21.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'any_type', 1,
sub
#line 932 "parser21.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'object_type', 1,
sub
#line 942 "parser21.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 166
		 'struct_type', 4,
sub
#line 952 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 167
		 'struct_type', 4,
sub
#line 959 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 168
		 'struct_header', 2,
sub
#line 968 "parser21.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 169
		 'member_list', 1,
sub
#line 978 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 170
		 'member_list', 2,
sub
#line 982 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 171
		 'member', 3,
sub
#line 991 "parser21.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 172
		 'member', 3,
sub
#line 998 "parser21.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 173
		 'union_type', 8,
sub
#line 1011 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 174
		 'union_type', 8,
sub
#line 1019 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 175
		 'union_type', 6,
sub
#line 1025 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 176
		 'union_type', 5,
sub
#line 1031 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 177
		 'union_type', 3,
sub
#line 1037 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 178
		 'union_header', 2,
sub
#line 1046 "parser21.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 179
		 'switch_type_spec', 1, undef
	],
	[#Rule 180
		 'switch_type_spec', 1, undef
	],
	[#Rule 181
		 'switch_type_spec', 1, undef
	],
	[#Rule 182
		 'switch_type_spec', 1, undef
	],
	[#Rule 183
		 'switch_type_spec', 1,
sub
#line 1064 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 184
		 'switch_body', 1,
sub
#line 1072 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 185
		 'switch_body', 2,
sub
#line 1076 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 186
		 'case', 3,
sub
#line 1085 "parser21.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 187
		 'case', 3,
sub
#line 1092 "parser21.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 188
		 'case_labels', 1,
sub
#line 1104 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 189
		 'case_labels', 2,
sub
#line 1108 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 190
		 'case_label', 3,
sub
#line 1117 "parser21.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 191
		 'case_label', 3,
sub
#line 1121 "parser21.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 192
		 'case_label', 2,
sub
#line 1127 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 193
		 'case_label', 2,
sub
#line 1132 "parser21.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 194
		 'case_label', 2,
sub
#line 1136 "parser21.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 195
		 'element_spec', 2,
sub
#line 1146 "parser21.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 196
		 'enum_type', 4,
sub
#line 1157 "parser21.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 197
		 'enum_type', 4,
sub
#line 1163 "parser21.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 198
		 'enum_type', 2,
sub
#line 1168 "parser21.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 199
		 'enum_header', 2,
sub
#line 1176 "parser21.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 200
		 'enum_header', 2,
sub
#line 1182 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 201
		 'enumerators', 1,
sub
#line 1190 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 202
		 'enumerators', 3,
sub
#line 1194 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 203
		 'enumerators', 2,
sub
#line 1199 "parser21.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 204
		 'enumerators', 2,
sub
#line 1204 "parser21.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 205
		 'enumerator', 1,
sub
#line 1213 "parser21.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 206
		 'sequence_type', 6,
sub
#line 1223 "parser21.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 207
		 'sequence_type', 6,
sub
#line 1231 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 208
		 'sequence_type', 4,
sub
#line 1236 "parser21.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 209
		 'sequence_type', 4,
sub
#line 1243 "parser21.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 210
		 'sequence_type', 2,
sub
#line 1248 "parser21.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 211
		 'string_type', 4,
sub
#line 1257 "parser21.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 212
		 'string_type', 1,
sub
#line 1264 "parser21.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 213
		 'string_type', 4,
sub
#line 1270 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 214
		 'wide_string_type', 4,
sub
#line 1279 "parser21.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 215
		 'wide_string_type', 1,
sub
#line 1286 "parser21.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 216
		 'wide_string_type', 4,
sub
#line 1292 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 217
		 'array_declarator', 2,
sub
#line 1301 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 218
		 'fixed_array_sizes', 1,
sub
#line 1309 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 219
		 'fixed_array_sizes', 2,
sub
#line 1313 "parser21.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 220
		 'fixed_array_size', 3,
sub
#line 1322 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 221
		 'fixed_array_size', 3,
sub
#line 1326 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 222
		 'attr_dcl', 4,
sub
#line 1335 "parser21.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 223
		 'attr_dcl', 4,
sub
#line 1343 "parser21.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 224
		 'attr_dcl', 3,
sub
#line 1348 "parser21.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 225
		 'attr_mod', 1, undef
	],
	[#Rule 226
		 'attr_mod', 0, undef
	],
	[#Rule 227
		 'simple_declarators', 1,
sub
#line 1363 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 228
		 'simple_declarators', 3,
sub
#line 1367 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 229
		 'except_dcl', 3,
sub
#line 1376 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 230
		 'except_dcl', 4,
sub
#line 1381 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 231
		 'except_dcl', 4,
sub
#line 1388 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 232
		 'except_dcl', 2,
sub
#line 1394 "parser21.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 233
		 'exception_header', 2,
sub
#line 1403 "parser21.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 234
		 'exception_header', 2,
sub
#line 1409 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 235
		 'op_dcl', 2,
sub
#line 1418 "parser21.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 236
		 'op_dcl', 3,
sub
#line 1426 "parser21.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 237
		 'op_dcl', 4,
sub
#line 1435 "parser21.yp"
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
	[#Rule 238
		 'op_dcl', 3,
sub
#line 1445 "parser21.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 239
		 'op_dcl', 2,
sub
#line 1454 "parser21.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 240
		 'op_header', 3,
sub
#line 1464 "parser21.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 241
		 'op_header', 3,
sub
#line 1472 "parser21.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 242
		 'op_mod', 1, undef
	],
	[#Rule 243
		 'op_mod', 0, undef
	],
	[#Rule 244
		 'op_attribute', 1, undef
	],
	[#Rule 245
		 'op_type_spec', 1, undef
	],
	[#Rule 246
		 'op_type_spec', 1,
sub
#line 1496 "parser21.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 247
		 'parameter_dcls', 3,
sub
#line 1506 "parser21.yp"
{
			$_[2];
		}
	],
	[#Rule 248
		 'parameter_dcls', 2,
sub
#line 1510 "parser21.yp"
{
			undef;
		}
	],
	[#Rule 249
		 'parameter_dcls', 3,
sub
#line 1514 "parser21.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 250
		 'param_dcls', 1,
sub
#line 1522 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 251
		 'param_dcls', 3,
sub
#line 1526 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 252
		 'param_dcls', 2,
sub
#line 1531 "parser21.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 253
		 'param_dcls', 2,
sub
#line 1536 "parser21.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 254
		 'param_dcl', 3,
sub
#line 1545 "parser21.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 255
		 'param_attribute', 1, undef
	],
	[#Rule 256
		 'param_attribute', 1, undef
	],
	[#Rule 257
		 'param_attribute', 1, undef
	],
	[#Rule 258
		 'raises_expr', 4,
sub
#line 1567 "parser21.yp"
{
			$_[3];
		}
	],
	[#Rule 259
		 'raises_expr', 4,
sub
#line 1571 "parser21.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 260
		 'raises_expr', 2,
sub
#line 1576 "parser21.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 261
		 'exception_names', 1,
sub
#line 1584 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 262
		 'exception_names', 3,
sub
#line 1588 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 263
		 'exception_name', 1,
sub
#line 1596 "parser21.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 264
		 'context_expr', 4,
sub
#line 1604 "parser21.yp"
{
			$_[3];
		}
	],
	[#Rule 265
		 'context_expr', 4,
sub
#line 1608 "parser21.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 266
		 'context_expr', 2,
sub
#line 1613 "parser21.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 267
		 'string_literals', 1,
sub
#line 1621 "parser21.yp"
{
			[$_[1]];
		}
	],
	[#Rule 268
		 'string_literals', 3,
sub
#line 1625 "parser21.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 269
		 'param_type_spec', 1, undef
	],
	[#Rule 270
		 'param_type_spec', 1, undef
	],
	[#Rule 271
		 'param_type_spec', 1, undef
	],
	[#Rule 272
		 'param_type_spec', 1, undef
	],
	[#Rule 273
		 'param_type_spec', 1,
sub
#line 1642 "parser21.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 274
		 'fixed_pt_type', 6,
sub
#line 1650 "parser21.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 275
		 'fixed_pt_type', 6,
sub
#line 1658 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 276
		 'fixed_pt_type', 4,
sub
#line 1663 "parser21.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 277
		 'fixed_pt_type', 2,
sub
#line 1668 "parser21.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 278
		 'fixed_pt_const_type', 1,
sub
#line 1677 "parser21.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 1684 "parser21.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '2.1';

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
