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
			'NATIVE' => 31,
			'ABSTRACT' => 2,
			'STRUCT' => 33,
			'VALUETYPE' => 9,
			'TYPEDEF' => 36,
			'MODULE' => 12,
			'IDENTIFIER' => 38,
			'UNION' => 39,
			'error' => 18,
			'LOCAL' => 21,
			'CONST' => 22,
			'EXCEPTION' => 24,
			'CUSTOM' => 42,
			'ENUM' => 27,
			'INTERFACE' => -33
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 29,
			'interface_header' => 30,
			'except_dcl' => 3,
			'value_header' => 32,
			'specification' => 4,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 34,
			'union_type' => 37,
			'exception_header' => 35,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'module' => 40,
			'constr_forward_decl' => 20,
			'enum_header' => 19,
			'value_abs_dcl' => 23,
			'type_dcl' => 41,
			'union_header' => 25,
			'definitions' => 26,
			'definition' => 43,
			'interface_mod' => 28
		}
	},
	{#State 1
		DEFAULT => -66
	},
	{#State 2
		ACTIONS => {
			'error' => 45,
			'VALUETYPE' => 44,
			'INTERFACE' => -31
		}
	},
	{#State 3
		ACTIONS => {
			'error' => 47,
			";" => 46
		}
	},
	{#State 4
		ACTIONS => {
			'' => 48
		}
	},
	{#State 5
		ACTIONS => {
			"{" => 50,
			'error' => 49
		}
	},
	{#State 6
		ACTIONS => {
			'error' => 52,
			";" => 51
		}
	},
	{#State 7
		DEFAULT => -65
	},
	{#State 8
		ACTIONS => {
			"{" => 53
		}
	},
	{#State 9
		ACTIONS => {
			'error' => 54,
			'IDENTIFIER' => 55
		}
	},
	{#State 10
		DEFAULT => -63
	},
	{#State 11
		ACTIONS => {
			"{" => 56
		}
	},
	{#State 12
		ACTIONS => {
			'error' => 57,
			'IDENTIFIER' => 58
		}
	},
	{#State 13
		DEFAULT => -24
	},
	{#State 14
		ACTIONS => {
			'error' => 60,
			";" => 59
		}
	},
	{#State 15
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 88,
			'VALUEBASE' => 89,
			'FIXED' => 63,
			'SEQUENCE' => 65,
			'STRUCT' => 93,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'UNION' => 104,
			'WCHAR' => 77,
			'FLOAT' => 84,
			'OCTET' => 82,
			'ENUM' => 27,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 70,
			'wide_char_type' => 71,
			'type_spec' => 73,
			'signed_long_int' => 72,
			'string_type' => 75,
			'struct_header' => 11,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'base_type_spec' => 80,
			'enum_type' => 81,
			'enum_header' => 19,
			'union_header' => 25,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85,
			'wide_string_type' => 90,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 98,
			'struct_type' => 100,
			'union_type' => 102,
			'sequence_type' => 105,
			'unsigned_long_int' => 106,
			'template_type_spec' => 107,
			'constr_type_spec' => 108,
			'simple_type_spec' => 109,
			'fixed_pt_type' => 110
		}
	},
	{#State 16
		DEFAULT => -180
	},
	{#State 17
		DEFAULT => -25
	},
	{#State 18
		DEFAULT => -3
	},
	{#State 19
		ACTIONS => {
			"{" => 112,
			'error' => 111
		}
	},
	{#State 20
		DEFAULT => -182
	},
	{#State 21
		DEFAULT => -32
	},
	{#State 22
		ACTIONS => {
			'CHAR' => 87,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'FIXED' => 114,
			'WCHAR' => 77,
			'DOUBLE' => 94,
			'error' => 120,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'OCTET' => 82,
			'FLOAT' => 84,
			'WSTRING' => 99,
			'UNSIGNED' => 74
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 113,
			'signed_int' => 64,
			'wide_string_type' => 121,
			'integer_type' => 123,
			'boolean_type' => 122,
			'char_type' => 115,
			'octet_type' => 116,
			'scoped_name' => 117,
			'fixed_pt_const_type' => 124,
			'wide_char_type' => 118,
			'signed_long_int' => 72,
			'signed_short_int' => 98,
			'const_type' => 125,
			'string_type' => 119,
			'unsigned_longlong_int' => 78,
			'unsigned_long_int' => 106,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85
		}
	},
	{#State 23
		DEFAULT => -64
	},
	{#State 24
		ACTIONS => {
			'error' => 126,
			'IDENTIFIER' => 127
		}
	},
	{#State 25
		ACTIONS => {
			'SWITCH' => 128
		}
	},
	{#State 26
		DEFAULT => -1
	},
	{#State 27
		ACTIONS => {
			'error' => 129,
			'IDENTIFIER' => 130
		}
	},
	{#State 28
		ACTIONS => {
			'INTERFACE' => 131
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 133,
			";" => 132
		}
	},
	{#State 30
		ACTIONS => {
			"{" => 134
		}
	},
	{#State 31
		ACTIONS => {
			'error' => 135,
			'IDENTIFIER' => 137
		},
		GOTOS => {
			'simple_declarator' => 136
		}
	},
	{#State 32
		ACTIONS => {
			"{" => 138
		}
	},
	{#State 33
		ACTIONS => {
			'error' => 139,
			'IDENTIFIER' => 140
		}
	},
	{#State 34
		DEFAULT => -178
	},
	{#State 35
		ACTIONS => {
			"{" => 142,
			'error' => 141
		}
	},
	{#State 36
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 88,
			'VALUEBASE' => 89,
			'FIXED' => 63,
			'SEQUENCE' => 65,
			'STRUCT' => 93,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'UNION' => 104,
			'WCHAR' => 77,
			'error' => 145,
			'FLOAT' => 84,
			'OCTET' => 82,
			'ENUM' => 27,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 70,
			'wide_char_type' => 71,
			'type_spec' => 143,
			'signed_long_int' => 72,
			'type_declarator' => 144,
			'string_type' => 75,
			'struct_header' => 11,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'base_type_spec' => 80,
			'enum_type' => 81,
			'enum_header' => 19,
			'union_header' => 25,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85,
			'wide_string_type' => 90,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 98,
			'struct_type' => 100,
			'union_type' => 102,
			'sequence_type' => 105,
			'unsigned_long_int' => 106,
			'template_type_spec' => 107,
			'constr_type_spec' => 108,
			'simple_type_spec' => 109,
			'fixed_pt_type' => 110
		}
	},
	{#State 37
		DEFAULT => -179
	},
	{#State 38
		ACTIONS => {
			'error' => 146
		}
	},
	{#State 39
		ACTIONS => {
			'error' => 147,
			'IDENTIFIER' => 148
		}
	},
	{#State 40
		ACTIONS => {
			'error' => 150,
			";" => 149
		}
	},
	{#State 41
		ACTIONS => {
			'error' => 152,
			";" => 151
		}
	},
	{#State 42
		ACTIONS => {
			'error' => 154,
			'VALUETYPE' => 153
		}
	},
	{#State 43
		ACTIONS => {
			'TYPEDEF' => 36,
			'IDENTIFIER' => 38,
			'NATIVE' => 31,
			'MODULE' => 12,
			'ABSTRACT' => 2,
			'UNION' => 39,
			'STRUCT' => 33,
			'LOCAL' => 21,
			'CONST' => 22,
			'EXCEPTION' => 24,
			'CUSTOM' => 42,
			'VALUETYPE' => 9,
			'ENUM' => 27,
			'INTERFACE' => -33
		},
		DEFAULT => -4,
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 29,
			'interface_header' => 30,
			'except_dcl' => 3,
			'value_header' => 32,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 34,
			'union_type' => 37,
			'exception_header' => 35,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'module' => 40,
			'enum_header' => 19,
			'constr_forward_decl' => 20,
			'value_abs_dcl' => 23,
			'type_dcl' => 41,
			'definitions' => 155,
			'union_header' => 25,
			'definition' => 43,
			'interface_mod' => 28
		}
	},
	{#State 44
		ACTIONS => {
			'error' => 156,
			'IDENTIFIER' => 157
		}
	},
	{#State 45
		DEFAULT => -77
	},
	{#State 46
		DEFAULT => -8
	},
	{#State 47
		DEFAULT => -14
	},
	{#State 48
		DEFAULT => 0
	},
	{#State 49
		DEFAULT => -21
	},
	{#State 50
		ACTIONS => {
			'NATIVE' => 31,
			'ABSTRACT' => 2,
			'STRUCT' => 33,
			'VALUETYPE' => 9,
			'TYPEDEF' => 36,
			'MODULE' => 12,
			'IDENTIFIER' => 38,
			'UNION' => 39,
			'error' => 158,
			'LOCAL' => 21,
			'CONST' => 22,
			'EXCEPTION' => 24,
			'CUSTOM' => 42,
			'ENUM' => 27,
			'INTERFACE' => -33
		},
		GOTOS => {
			'value_forward_dcl' => 1,
			'const_dcl' => 29,
			'interface_header' => 30,
			'except_dcl' => 3,
			'value_header' => 32,
			'module_header' => 5,
			'interface' => 6,
			'value_box_dcl' => 7,
			'value_abs_header' => 8,
			'value_dcl' => 10,
			'struct_type' => 34,
			'union_type' => 37,
			'exception_header' => 35,
			'struct_header' => 11,
			'interface_dcl' => 13,
			'value' => 14,
			'value_box_header' => 15,
			'enum_type' => 16,
			'forward_dcl' => 17,
			'module' => 40,
			'enum_header' => 19,
			'constr_forward_decl' => 20,
			'value_abs_dcl' => 23,
			'type_dcl' => 41,
			'definitions' => 159,
			'union_header' => 25,
			'definition' => 43,
			'interface_mod' => 28
		}
	},
	{#State 51
		DEFAULT => -9
	},
	{#State 52
		DEFAULT => -15
	},
	{#State 53
		ACTIONS => {
			'PRIVATE' => 161,
			'ONEWAY' => 162,
			'FACTORY' => 169,
			'UNSIGNED' => -314,
			'SHORT' => -314,
			'WCHAR' => -314,
			'error' => 171,
			'CONST' => 22,
			"}" => 172,
			'EXCEPTION' => 24,
			'OCTET' => -314,
			'FLOAT' => -314,
			'ENUM' => 27,
			'ANY' => -314,
			'CHAR' => -314,
			'OBJECT' => -314,
			'NATIVE' => 31,
			'VALUEBASE' => -314,
			'VOID' => -314,
			'STRUCT' => 33,
			'DOUBLE' => -314,
			'LONG' => -314,
			'STRING' => -314,
			"::" => -314,
			'WSTRING' => -314,
			'BOOLEAN' => -314,
			'TYPEDEF' => 36,
			'IDENTIFIER' => -314,
			'UNION' => 39,
			'READONLY' => 178,
			'ATTRIBUTE' => -297,
			'PUBLIC' => 179
		},
		GOTOS => {
			'init_header_param' => 160,
			'const_dcl' => 173,
			'op_mod' => 163,
			'state_member' => 165,
			'except_dcl' => 164,
			'op_attribute' => 166,
			'attr_mod' => 167,
			'state_mod' => 168,
			'exports' => 174,
			'_export' => 175,
			'export' => 176,
			'init_header' => 170,
			'struct_type' => 34,
			'op_header' => 177,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 180,
			'init_dcl' => 181,
			'enum_header' => 19,
			'constr_forward_decl' => 20,
			'attr_dcl' => 182,
			'type_dcl' => 183,
			'union_header' => 25
		}
	},
	{#State 54
		DEFAULT => -87
	},
	{#State 55
		ACTIONS => {
			":" => 185,
			";" => -67,
			"{" => -83,
			'error' => -67,
			'SUPPORTS' => 186
		},
		DEFAULT => -70,
		GOTOS => {
			'supported_interface_spec' => 187,
			'value_inheritance_spec' => 184
		}
	},
	{#State 56
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 88,
			'VALUEBASE' => 89,
			'FIXED' => 63,
			'SEQUENCE' => 65,
			'STRUCT' => 93,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'UNION' => 104,
			'WCHAR' => 77,
			'error' => 189,
			'FLOAT' => 84,
			'OCTET' => 82,
			'ENUM' => 27,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 70,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'type_spec' => 188,
			'string_type' => 75,
			'struct_header' => 11,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'base_type_spec' => 80,
			'enum_type' => 81,
			'enum_header' => 19,
			'member_list' => 190,
			'union_header' => 25,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85,
			'wide_string_type' => 90,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 98,
			'member' => 191,
			'struct_type' => 100,
			'union_type' => 102,
			'sequence_type' => 105,
			'unsigned_long_int' => 106,
			'template_type_spec' => 107,
			'constr_type_spec' => 108,
			'simple_type_spec' => 109,
			'fixed_pt_type' => 110
		}
	},
	{#State 57
		DEFAULT => -23
	},
	{#State 58
		DEFAULT => -22
	},
	{#State 59
		DEFAULT => -11
	},
	{#State 60
		DEFAULT => -17
	},
	{#State 61
		DEFAULT => -218
	},
	{#State 62
		DEFAULT => -192
	},
	{#State 63
		ACTIONS => {
			"<" => 193,
			'error' => 192
		}
	},
	{#State 64
		DEFAULT => -217
	},
	{#State 65
		ACTIONS => {
			"<" => 195,
			'error' => 194
		}
	},
	{#State 66
		DEFAULT => -200
	},
	{#State 67
		DEFAULT => -194
	},
	{#State 68
		DEFAULT => -199
	},
	{#State 69
		DEFAULT => -197
	},
	{#State 70
		ACTIONS => {
			"::" => 196
		},
		DEFAULT => -191
	},
	{#State 71
		DEFAULT => -195
	},
	{#State 72
		DEFAULT => -220
	},
	{#State 73
		DEFAULT => -69
	},
	{#State 74
		ACTIONS => {
			'SHORT' => 197,
			'LONG' => 198
		}
	},
	{#State 75
		DEFAULT => -202
	},
	{#State 76
		DEFAULT => -222
	},
	{#State 77
		DEFAULT => -232
	},
	{#State 78
		DEFAULT => -227
	},
	{#State 79
		DEFAULT => -198
	},
	{#State 80
		DEFAULT => -189
	},
	{#State 81
		DEFAULT => -207
	},
	{#State 82
		DEFAULT => -234
	},
	{#State 83
		DEFAULT => -225
	},
	{#State 84
		DEFAULT => -214
	},
	{#State 85
		DEFAULT => -221
	},
	{#State 86
		DEFAULT => -235
	},
	{#State 87
		DEFAULT => -231
	},
	{#State 88
		DEFAULT => -236
	},
	{#State 89
		DEFAULT => -349
	},
	{#State 90
		DEFAULT => -203
	},
	{#State 91
		DEFAULT => -196
	},
	{#State 92
		DEFAULT => -193
	},
	{#State 93
		ACTIONS => {
			'IDENTIFIER' => 199
		}
	},
	{#State 94
		DEFAULT => -215
	},
	{#State 95
		ACTIONS => {
			'DOUBLE' => 200,
			'LONG' => 201
		},
		DEFAULT => -223
	},
	{#State 96
		ACTIONS => {
			"<" => 202
		},
		DEFAULT => -283
	},
	{#State 97
		ACTIONS => {
			'error' => 203,
			'IDENTIFIER' => 204
		}
	},
	{#State 98
		DEFAULT => -219
	},
	{#State 99
		ACTIONS => {
			"<" => 205
		},
		DEFAULT => -286
	},
	{#State 100
		DEFAULT => -205
	},
	{#State 101
		DEFAULT => -233
	},
	{#State 102
		DEFAULT => -206
	},
	{#State 103
		DEFAULT => -58
	},
	{#State 104
		ACTIONS => {
			'IDENTIFIER' => 206
		}
	},
	{#State 105
		DEFAULT => -201
	},
	{#State 106
		DEFAULT => -226
	},
	{#State 107
		DEFAULT => -190
	},
	{#State 108
		DEFAULT => -188
	},
	{#State 109
		DEFAULT => -187
	},
	{#State 110
		DEFAULT => -204
	},
	{#State 111
		DEFAULT => -269
	},
	{#State 112
		ACTIONS => {
			'error' => 207,
			'IDENTIFIER' => 209
		},
		GOTOS => {
			'enumerators' => 210,
			'enumerator' => 208
		}
	},
	{#State 113
		DEFAULT => -130
	},
	{#State 114
		DEFAULT => -348
	},
	{#State 115
		DEFAULT => -127
	},
	{#State 116
		DEFAULT => -135
	},
	{#State 117
		ACTIONS => {
			"::" => 196
		},
		DEFAULT => -134
	},
	{#State 118
		DEFAULT => -128
	},
	{#State 119
		DEFAULT => -131
	},
	{#State 120
		DEFAULT => -125
	},
	{#State 121
		DEFAULT => -132
	},
	{#State 122
		DEFAULT => -129
	},
	{#State 123
		DEFAULT => -126
	},
	{#State 124
		DEFAULT => -133
	},
	{#State 125
		ACTIONS => {
			'error' => 211,
			'IDENTIFIER' => 212
		}
	},
	{#State 126
		DEFAULT => -305
	},
	{#State 127
		DEFAULT => -304
	},
	{#State 128
		ACTIONS => {
			'error' => 214,
			"(" => 213
		}
	},
	{#State 129
		DEFAULT => -271
	},
	{#State 130
		DEFAULT => -270
	},
	{#State 131
		ACTIONS => {
			'error' => 215,
			'IDENTIFIER' => 216
		}
	},
	{#State 132
		DEFAULT => -7
	},
	{#State 133
		DEFAULT => -13
	},
	{#State 134
		ACTIONS => {
			'PRIVATE' => 161,
			'ONEWAY' => 162,
			'FACTORY' => 169,
			'UNSIGNED' => -314,
			'SHORT' => -314,
			'WCHAR' => -314,
			'error' => 217,
			'CONST' => 22,
			"}" => 218,
			'EXCEPTION' => 24,
			'OCTET' => -314,
			'FLOAT' => -314,
			'ENUM' => 27,
			'ANY' => -314,
			'CHAR' => -314,
			'OBJECT' => -314,
			'NATIVE' => 31,
			'VALUEBASE' => -314,
			'VOID' => -314,
			'STRUCT' => 33,
			'DOUBLE' => -314,
			'LONG' => -314,
			'STRING' => -314,
			"::" => -314,
			'WSTRING' => -314,
			'BOOLEAN' => -314,
			'TYPEDEF' => 36,
			'IDENTIFIER' => -314,
			'UNION' => 39,
			'READONLY' => 178,
			'ATTRIBUTE' => -297,
			'PUBLIC' => 179
		},
		GOTOS => {
			'init_header_param' => 160,
			'const_dcl' => 173,
			'op_mod' => 163,
			'state_member' => 165,
			'except_dcl' => 164,
			'op_attribute' => 166,
			'attr_mod' => 167,
			'state_mod' => 168,
			'exports' => 219,
			'_export' => 175,
			'export' => 176,
			'init_header' => 170,
			'struct_type' => 34,
			'op_header' => 177,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 180,
			'init_dcl' => 181,
			'enum_header' => 19,
			'constr_forward_decl' => 20,
			'attr_dcl' => 182,
			'type_dcl' => 183,
			'union_header' => 25,
			'interface_body' => 220
		}
	},
	{#State 135
		DEFAULT => -184
	},
	{#State 136
		DEFAULT => -181
	},
	{#State 137
		DEFAULT => -212
	},
	{#State 138
		ACTIONS => {
			'PRIVATE' => 161,
			'ONEWAY' => 162,
			'FACTORY' => 169,
			'UNSIGNED' => -314,
			'SHORT' => -314,
			'WCHAR' => -314,
			'error' => 223,
			'CONST' => 22,
			"}" => 224,
			'EXCEPTION' => 24,
			'OCTET' => -314,
			'FLOAT' => -314,
			'ENUM' => 27,
			'ANY' => -314,
			'CHAR' => -314,
			'OBJECT' => -314,
			'NATIVE' => 31,
			'VALUEBASE' => -314,
			'VOID' => -314,
			'STRUCT' => 33,
			'DOUBLE' => -314,
			'LONG' => -314,
			'STRING' => -314,
			"::" => -314,
			'WSTRING' => -314,
			'BOOLEAN' => -314,
			'TYPEDEF' => 36,
			'IDENTIFIER' => -314,
			'UNION' => 39,
			'READONLY' => 178,
			'ATTRIBUTE' => -297,
			'PUBLIC' => 179
		},
		GOTOS => {
			'init_header_param' => 160,
			'const_dcl' => 173,
			'op_mod' => 163,
			'value_elements' => 225,
			'except_dcl' => 164,
			'state_member' => 221,
			'op_attribute' => 166,
			'attr_mod' => 167,
			'state_mod' => 168,
			'value_element' => 222,
			'export' => 226,
			'init_header' => 170,
			'struct_type' => 34,
			'op_header' => 177,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 180,
			'init_dcl' => 227,
			'enum_header' => 19,
			'constr_forward_decl' => 20,
			'attr_dcl' => 182,
			'type_dcl' => 183,
			'union_header' => 25
		}
	},
	{#State 139
		DEFAULT => -351
	},
	{#State 140
		ACTIONS => {
			"{" => -239
		},
		DEFAULT => -350
	},
	{#State 141
		DEFAULT => -303
	},
	{#State 142
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 88,
			'VALUEBASE' => 89,
			'FIXED' => 63,
			'SEQUENCE' => 65,
			'STRUCT' => 93,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'UNION' => 104,
			'WCHAR' => 77,
			'error' => 228,
			"}" => 230,
			'FLOAT' => 84,
			'OCTET' => 82,
			'ENUM' => 27,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 70,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'type_spec' => 188,
			'string_type' => 75,
			'struct_header' => 11,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'base_type_spec' => 80,
			'enum_type' => 81,
			'enum_header' => 19,
			'member_list' => 229,
			'union_header' => 25,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85,
			'wide_string_type' => 90,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 98,
			'member' => 191,
			'struct_type' => 100,
			'union_type' => 102,
			'sequence_type' => 105,
			'unsigned_long_int' => 106,
			'template_type_spec' => 107,
			'constr_type_spec' => 108,
			'simple_type_spec' => 109,
			'fixed_pt_type' => 110
		}
	},
	{#State 143
		ACTIONS => {
			'error' => 233,
			'IDENTIFIER' => 237
		},
		GOTOS => {
			'declarators' => 231,
			'declarator' => 232,
			'simple_declarator' => 235,
			'array_declarator' => 236,
			'complex_declarator' => 234
		}
	},
	{#State 144
		DEFAULT => -177
	},
	{#State 145
		DEFAULT => -183
	},
	{#State 146
		ACTIONS => {
			";" => 238
		}
	},
	{#State 147
		DEFAULT => -353
	},
	{#State 148
		ACTIONS => {
			'SWITCH' => -249
		},
		DEFAULT => -352
	},
	{#State 149
		DEFAULT => -10
	},
	{#State 150
		DEFAULT => -16
	},
	{#State 151
		DEFAULT => -6
	},
	{#State 152
		DEFAULT => -12
	},
	{#State 153
		ACTIONS => {
			'error' => 239,
			'IDENTIFIER' => 240
		}
	},
	{#State 154
		DEFAULT => -89
	},
	{#State 155
		DEFAULT => -5
	},
	{#State 156
		DEFAULT => -76
	},
	{#State 157
		ACTIONS => {
			"{" => -74,
			'SUPPORTS' => 186,
			":" => 185
		},
		DEFAULT => -68,
		GOTOS => {
			'supported_interface_spec' => 187,
			'value_inheritance_spec' => 241
		}
	},
	{#State 158
		ACTIONS => {
			"}" => 242
		}
	},
	{#State 159
		ACTIONS => {
			"}" => 243
		}
	},
	{#State 160
		ACTIONS => {
			'error' => 245,
			";" => 244
		}
	},
	{#State 161
		DEFAULT => -108
	},
	{#State 162
		DEFAULT => -315
	},
	{#State 163
		ACTIONS => {
			'CHAR' => 87,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'OBJECT' => 88,
			'IDENTIFIER' => 103,
			'VALUEBASE' => 89,
			'VOID' => 251,
			'WCHAR' => 77,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'OCTET' => 82,
			'FLOAT' => 84,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'wide_string_type' => 250,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 246,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'signed_short_int' => 98,
			'string_type' => 247,
			'op_type_spec' => 252,
			'base_type_spec' => 248,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'unsigned_long_int' => 106,
			'param_type_spec' => 249,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85
		}
	},
	{#State 164
		ACTIONS => {
			'error' => 254,
			";" => 253
		}
	},
	{#State 165
		DEFAULT => -41
	},
	{#State 166
		DEFAULT => -313
	},
	{#State 167
		ACTIONS => {
			'ATTRIBUTE' => 255
		}
	},
	{#State 168
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 88,
			'VALUEBASE' => 89,
			'FIXED' => 63,
			'SEQUENCE' => 65,
			'STRUCT' => 93,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'UNION' => 104,
			'WCHAR' => 77,
			'error' => 257,
			'FLOAT' => 84,
			'OCTET' => 82,
			'ENUM' => 27,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 70,
			'wide_char_type' => 71,
			'type_spec' => 256,
			'signed_long_int' => 72,
			'string_type' => 75,
			'struct_header' => 11,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'base_type_spec' => 80,
			'enum_type' => 81,
			'enum_header' => 19,
			'union_header' => 25,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85,
			'wide_string_type' => 90,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 98,
			'struct_type' => 100,
			'union_type' => 102,
			'sequence_type' => 105,
			'unsigned_long_int' => 106,
			'template_type_spec' => 107,
			'constr_type_spec' => 108,
			'simple_type_spec' => 109,
			'fixed_pt_type' => 110
		}
	},
	{#State 169
		ACTIONS => {
			'error' => 258,
			'IDENTIFIER' => 259
		}
	},
	{#State 170
		ACTIONS => {
			'error' => 261,
			"(" => 260
		}
	},
	{#State 171
		ACTIONS => {
			"}" => 262
		}
	},
	{#State 172
		DEFAULT => -71
	},
	{#State 173
		ACTIONS => {
			'error' => 264,
			";" => 263
		}
	},
	{#State 174
		ACTIONS => {
			"}" => 265
		}
	},
	{#State 175
		DEFAULT => -38
	},
	{#State 176
		ACTIONS => {
			'_exports' => 266
		},
		DEFAULT => -40
	},
	{#State 177
		ACTIONS => {
			'error' => 268,
			"(" => 267
		},
		GOTOS => {
			'parameter_dcls' => 269
		}
	},
	{#State 178
		DEFAULT => -296
	},
	{#State 179
		DEFAULT => -107
	},
	{#State 180
		ACTIONS => {
			'error' => 271,
			";" => 270
		}
	},
	{#State 181
		DEFAULT => -42
	},
	{#State 182
		ACTIONS => {
			'error' => 273,
			";" => 272
		}
	},
	{#State 183
		ACTIONS => {
			'error' => 275,
			";" => 274
		}
	},
	{#State 184
		DEFAULT => -85
	},
	{#State 185
		ACTIONS => {
			'TRUNCATABLE' => 277
		},
		DEFAULT => -95,
		GOTOS => {
			'inheritance_mod' => 276
		}
	},
	{#State 186
		ACTIONS => {
			'error' => 279,
			'IDENTIFIER' => 103,
			"::" => 97
		},
		GOTOS => {
			'scoped_name' => 278,
			'interface_names' => 281,
			'interface_name' => 280
		}
	},
	{#State 187
		DEFAULT => -93
	},
	{#State 188
		ACTIONS => {
			'IDENTIFIER' => 237
		},
		GOTOS => {
			'declarators' => 282,
			'declarator' => 232,
			'simple_declarator' => 235,
			'array_declarator' => 236,
			'complex_declarator' => 234
		}
	},
	{#State 189
		ACTIONS => {
			"}" => 283
		}
	},
	{#State 190
		ACTIONS => {
			"}" => 284
		}
	},
	{#State 191
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 88,
			'VALUEBASE' => 89,
			'FIXED' => 63,
			'SEQUENCE' => 65,
			'STRUCT' => 93,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'UNION' => 104,
			'WCHAR' => 77,
			'FLOAT' => 84,
			'OCTET' => 82,
			'ENUM' => 27,
			'ANY' => 86
		},
		DEFAULT => -240,
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 70,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'type_spec' => 188,
			'string_type' => 75,
			'struct_header' => 11,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'base_type_spec' => 80,
			'enum_type' => 81,
			'enum_header' => 19,
			'member_list' => 285,
			'union_header' => 25,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85,
			'wide_string_type' => 90,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 98,
			'member' => 191,
			'struct_type' => 100,
			'union_type' => 102,
			'sequence_type' => 105,
			'unsigned_long_int' => 106,
			'template_type_spec' => 107,
			'constr_type_spec' => 108,
			'simple_type_spec' => 109,
			'fixed_pt_type' => 110
		}
	},
	{#State 192
		DEFAULT => -347
	},
	{#State 193
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 295,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'primary_expr' => 305,
			'and_expr' => 306,
			'scoped_name' => 288,
			'positive_int_const' => 289,
			'wide_string_literal' => 290,
			'boolean_literal' => 292,
			'mult_expr' => 308,
			'const_exp' => 293,
			'or_expr' => 294,
			'unary_expr' => 312,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 194
		DEFAULT => -281
	},
	{#State 195
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 88,
			'VALUEBASE' => 89,
			'FIXED' => 63,
			'SEQUENCE' => 65,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'WCHAR' => 77,
			'error' => 316,
			'FLOAT' => 84,
			'OCTET' => 82,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'wide_string_type' => 90,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 70,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'signed_short_int' => 98,
			'string_type' => 75,
			'sequence_type' => 105,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'base_type_spec' => 80,
			'unsigned_long_int' => 106,
			'template_type_spec' => 107,
			'unsigned_short_int' => 83,
			'simple_type_spec' => 317,
			'fixed_pt_type' => 110,
			'signed_longlong_int' => 85
		}
	},
	{#State 196
		ACTIONS => {
			'error' => 318,
			'IDENTIFIER' => 319
		}
	},
	{#State 197
		DEFAULT => -228
	},
	{#State 198
		ACTIONS => {
			'LONG' => 320
		},
		DEFAULT => -229
	},
	{#State 199
		DEFAULT => -239
	},
	{#State 200
		DEFAULT => -216
	},
	{#State 201
		DEFAULT => -224
	},
	{#State 202
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 322,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'primary_expr' => 305,
			'and_expr' => 306,
			'scoped_name' => 288,
			'positive_int_const' => 321,
			'wide_string_literal' => 290,
			'boolean_literal' => 292,
			'mult_expr' => 308,
			'const_exp' => 293,
			'or_expr' => 294,
			'unary_expr' => 312,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 203
		DEFAULT => -60
	},
	{#State 204
		DEFAULT => -59
	},
	{#State 205
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 324,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'primary_expr' => 305,
			'and_expr' => 306,
			'scoped_name' => 288,
			'positive_int_const' => 323,
			'wide_string_literal' => 290,
			'boolean_literal' => 292,
			'mult_expr' => 308,
			'const_exp' => 293,
			'or_expr' => 294,
			'unary_expr' => 312,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 206
		DEFAULT => -249
	},
	{#State 207
		ACTIONS => {
			"}" => 325
		}
	},
	{#State 208
		ACTIONS => {
			";" => 326,
			"," => 327
		},
		DEFAULT => -272
	},
	{#State 209
		DEFAULT => -276
	},
	{#State 210
		ACTIONS => {
			"}" => 328
		}
	},
	{#State 211
		DEFAULT => -124
	},
	{#State 212
		ACTIONS => {
			'error' => 329,
			"=" => 330
		}
	},
	{#State 213
		ACTIONS => {
			'CHAR' => 87,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'error' => 334,
			'LONG' => 338,
			"::" => 97,
			'ENUM' => 27,
			'UNSIGNED' => 74
		},
		GOTOS => {
			'switch_type_spec' => 335,
			'unsigned_int' => 61,
			'signed_int' => 64,
			'integer_type' => 337,
			'boolean_type' => 336,
			'unsigned_longlong_int' => 78,
			'char_type' => 331,
			'enum_type' => 333,
			'unsigned_long_int' => 106,
			'scoped_name' => 332,
			'enum_header' => 19,
			'signed_long_int' => 72,
			'unsigned_short_int' => 83,
			'signed_short_int' => 98,
			'signed_longlong_int' => 85
		}
	},
	{#State 214
		DEFAULT => -248
	},
	{#State 215
		ACTIONS => {
			"{" => -36
		},
		DEFAULT => -30
	},
	{#State 216
		ACTIONS => {
			"{" => -34,
			":" => 339
		},
		DEFAULT => -29,
		GOTOS => {
			'interface_inheritance_spec' => 340
		}
	},
	{#State 217
		ACTIONS => {
			"}" => 341
		}
	},
	{#State 218
		DEFAULT => -26
	},
	{#State 219
		DEFAULT => -37
	},
	{#State 220
		ACTIONS => {
			"}" => 342
		}
	},
	{#State 221
		DEFAULT => -102
	},
	{#State 222
		ACTIONS => {
			'PRIVATE' => 161,
			'ONEWAY' => 162,
			'FACTORY' => 169,
			'CONST' => 22,
			'EXCEPTION' => 24,
			"}" => -81,
			'ENUM' => 27,
			'NATIVE' => 31,
			'STRUCT' => 33,
			'TYPEDEF' => 36,
			'UNION' => 39,
			'READONLY' => 178,
			'ATTRIBUTE' => -297,
			'PUBLIC' => 179
		},
		DEFAULT => -314,
		GOTOS => {
			'init_header_param' => 160,
			'const_dcl' => 173,
			'op_mod' => 163,
			'value_elements' => 343,
			'except_dcl' => 164,
			'state_member' => 221,
			'op_attribute' => 166,
			'attr_mod' => 167,
			'state_mod' => 168,
			'value_element' => 222,
			'export' => 226,
			'init_header' => 170,
			'struct_type' => 34,
			'op_header' => 177,
			'exception_header' => 35,
			'union_type' => 37,
			'struct_header' => 11,
			'enum_type' => 16,
			'op_dcl' => 180,
			'init_dcl' => 227,
			'enum_header' => 19,
			'constr_forward_decl' => 20,
			'attr_dcl' => 182,
			'type_dcl' => 183,
			'union_header' => 25
		}
	},
	{#State 223
		ACTIONS => {
			"}" => 344
		}
	},
	{#State 224
		DEFAULT => -78
	},
	{#State 225
		ACTIONS => {
			"}" => 345
		}
	},
	{#State 226
		DEFAULT => -101
	},
	{#State 227
		DEFAULT => -103
	},
	{#State 228
		ACTIONS => {
			"}" => 346
		}
	},
	{#State 229
		ACTIONS => {
			"}" => 347
		}
	},
	{#State 230
		DEFAULT => -300
	},
	{#State 231
		DEFAULT => -185
	},
	{#State 232
		ACTIONS => {
			"," => 348
		},
		DEFAULT => -208
	},
	{#State 233
		DEFAULT => -186
	},
	{#State 234
		DEFAULT => -211
	},
	{#State 235
		DEFAULT => -210
	},
	{#State 236
		DEFAULT => -213
	},
	{#State 237
		ACTIONS => {
			"[" => 351
		},
		DEFAULT => -212,
		GOTOS => {
			'fixed_array_sizes' => 349,
			'fixed_array_size' => 350
		}
	},
	{#State 238
		DEFAULT => -18
	},
	{#State 239
		DEFAULT => -88
	},
	{#State 240
		ACTIONS => {
			'SUPPORTS' => 186,
			":" => 185
		},
		DEFAULT => -84,
		GOTOS => {
			'supported_interface_spec' => 187,
			'value_inheritance_spec' => 352
		}
	},
	{#State 241
		DEFAULT => -75
	},
	{#State 242
		DEFAULT => -20
	},
	{#State 243
		DEFAULT => -19
	},
	{#State 244
		DEFAULT => -109
	},
	{#State 245
		DEFAULT => -110
	},
	{#State 246
		ACTIONS => {
			"::" => 196
		},
		DEFAULT => -343
	},
	{#State 247
		DEFAULT => -341
	},
	{#State 248
		DEFAULT => -340
	},
	{#State 249
		DEFAULT => -316
	},
	{#State 250
		DEFAULT => -342
	},
	{#State 251
		DEFAULT => -317
	},
	{#State 252
		ACTIONS => {
			'error' => 353,
			'IDENTIFIER' => 354
		}
	},
	{#State 253
		DEFAULT => -45
	},
	{#State 254
		DEFAULT => -50
	},
	{#State 255
		ACTIONS => {
			'CHAR' => 87,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'OBJECT' => 88,
			'IDENTIFIER' => 103,
			'VALUEBASE' => 89,
			'WCHAR' => 77,
			'DOUBLE' => 94,
			'error' => 355,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'OCTET' => 82,
			'FLOAT' => 84,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'wide_string_type' => 250,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 246,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'signed_short_int' => 98,
			'string_type' => 247,
			'base_type_spec' => 248,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'unsigned_long_int' => 106,
			'param_type_spec' => 356,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85
		}
	},
	{#State 256
		ACTIONS => {
			'error' => 358,
			'IDENTIFIER' => 237
		},
		GOTOS => {
			'declarators' => 357,
			'declarator' => 232,
			'simple_declarator' => 235,
			'array_declarator' => 236,
			'complex_declarator' => 234
		}
	},
	{#State 257
		ACTIONS => {
			";" => 359
		}
	},
	{#State 258
		DEFAULT => -116
	},
	{#State 259
		DEFAULT => -115
	},
	{#State 260
		ACTIONS => {
			'error' => 364,
			")" => 365,
			'IN' => 362
		},
		GOTOS => {
			'init_param_decls' => 361,
			'init_param_attribute' => 360,
			'init_param_decl' => 363
		}
	},
	{#State 261
		DEFAULT => -114
	},
	{#State 262
		DEFAULT => -73
	},
	{#State 263
		DEFAULT => -44
	},
	{#State 264
		DEFAULT => -49
	},
	{#State 265
		DEFAULT => -72
	},
	{#State 266
		DEFAULT => -39
	},
	{#State 267
		ACTIONS => {
			'error' => 367,
			")" => 371,
			'OUT' => 372,
			'INOUT' => 368,
			'IN' => 366
		},
		GOTOS => {
			'param_dcl' => 373,
			'param_dcls' => 370,
			'param_attribute' => 369
		}
	},
	{#State 268
		DEFAULT => -310
	},
	{#State 269
		ACTIONS => {
			'RAISES' => 377,
			'CONTEXT' => 374
		},
		DEFAULT => -306,
		GOTOS => {
			'context_expr' => 376,
			'raises_expr' => 375
		}
	},
	{#State 270
		DEFAULT => -47
	},
	{#State 271
		DEFAULT => -52
	},
	{#State 272
		DEFAULT => -46
	},
	{#State 273
		DEFAULT => -51
	},
	{#State 274
		DEFAULT => -43
	},
	{#State 275
		DEFAULT => -48
	},
	{#State 276
		ACTIONS => {
			'error' => 380,
			'IDENTIFIER' => 103,
			"::" => 97
		},
		GOTOS => {
			'scoped_name' => 378,
			'value_name' => 379,
			'value_names' => 381
		}
	},
	{#State 277
		DEFAULT => -94
	},
	{#State 278
		ACTIONS => {
			"::" => 196
		},
		DEFAULT => -57
	},
	{#State 279
		DEFAULT => -99
	},
	{#State 280
		ACTIONS => {
			"," => 382
		},
		DEFAULT => -55
	},
	{#State 281
		DEFAULT => -98
	},
	{#State 282
		ACTIONS => {
			'error' => 384,
			";" => 383
		}
	},
	{#State 283
		DEFAULT => -238
	},
	{#State 284
		DEFAULT => -237
	},
	{#State 285
		DEFAULT => -241
	},
	{#State 286
		DEFAULT => -165
	},
	{#State 287
		DEFAULT => -166
	},
	{#State 288
		ACTIONS => {
			"::" => 196
		},
		DEFAULT => -158
	},
	{#State 289
		ACTIONS => {
			"," => 385
		}
	},
	{#State 290
		DEFAULT => -164
	},
	{#State 291
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 387,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 308,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'const_exp' => 386,
			'and_expr' => 306,
			'or_expr' => 294,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 292
		DEFAULT => -169
	},
	{#State 293
		DEFAULT => -176
	},
	{#State 294
		ACTIONS => {
			"|" => 388
		},
		DEFAULT => -136
	},
	{#State 295
		ACTIONS => {
			">" => 389
		}
	},
	{#State 296
		ACTIONS => {
			"^" => 390
		},
		DEFAULT => -137
	},
	{#State 297
		ACTIONS => {
			"<<" => 391,
			">>" => 392
		},
		DEFAULT => -141
	},
	{#State 298
		DEFAULT => -175
	},
	{#State 299
		ACTIONS => {
			'WIDE_STRING_LITERAL' => 299
		},
		DEFAULT => -172,
		GOTOS => {
			'wide_string_literal' => 393
		}
	},
	{#State 300
		DEFAULT => -159
	},
	{#State 301
		DEFAULT => -174
	},
	{#State 302
		ACTIONS => {
			"+" => 394,
			"-" => 395
		},
		DEFAULT => -143
	},
	{#State 303
		DEFAULT => -163
	},
	{#State 304
		DEFAULT => -168
	},
	{#State 305
		DEFAULT => -154
	},
	{#State 306
		ACTIONS => {
			"&" => 396
		},
		DEFAULT => -139
	},
	{#State 307
		DEFAULT => -162
	},
	{#State 308
		ACTIONS => {
			"%" => 398,
			"*" => 397,
			"/" => 399
		},
		DEFAULT => -146
	},
	{#State 309
		ACTIONS => {
			'STRING_LITERAL' => 309
		},
		DEFAULT => -170,
		GOTOS => {
			'string_literal' => 400
		}
	},
	{#State 310
		DEFAULT => -167
	},
	{#State 311
		DEFAULT => -156
	},
	{#State 312
		DEFAULT => -149
	},
	{#State 313
		DEFAULT => -155
	},
	{#State 314
		DEFAULT => -157
	},
	{#State 315
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'boolean_literal' => 292,
			'scoped_name' => 288,
			'primary_expr' => 401,
			'literal' => 300,
			'wide_string_literal' => 290
		}
	},
	{#State 316
		ACTIONS => {
			">" => 402
		}
	},
	{#State 317
		ACTIONS => {
			">" => 404,
			"," => 403
		}
	},
	{#State 318
		DEFAULT => -62
	},
	{#State 319
		DEFAULT => -61
	},
	{#State 320
		DEFAULT => -230
	},
	{#State 321
		ACTIONS => {
			">" => 405
		}
	},
	{#State 322
		ACTIONS => {
			">" => 406
		}
	},
	{#State 323
		ACTIONS => {
			">" => 407
		}
	},
	{#State 324
		ACTIONS => {
			">" => 408
		}
	},
	{#State 325
		DEFAULT => -268
	},
	{#State 326
		DEFAULT => -275
	},
	{#State 327
		ACTIONS => {
			'IDENTIFIER' => 209
		},
		DEFAULT => -274,
		GOTOS => {
			'enumerators' => 409,
			'enumerator' => 208
		}
	},
	{#State 328
		DEFAULT => -267
	},
	{#State 329
		DEFAULT => -123
	},
	{#State 330
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 411,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 308,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'const_exp' => 410,
			'and_expr' => 306,
			'or_expr' => 294,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 331
		DEFAULT => -251
	},
	{#State 332
		ACTIONS => {
			"::" => 196
		},
		DEFAULT => -254
	},
	{#State 333
		DEFAULT => -253
	},
	{#State 334
		ACTIONS => {
			")" => 412
		}
	},
	{#State 335
		ACTIONS => {
			")" => 413
		}
	},
	{#State 336
		DEFAULT => -252
	},
	{#State 337
		DEFAULT => -250
	},
	{#State 338
		ACTIONS => {
			'LONG' => 201
		},
		DEFAULT => -223
	},
	{#State 339
		ACTIONS => {
			'error' => 414,
			'IDENTIFIER' => 103,
			"::" => 97
		},
		GOTOS => {
			'scoped_name' => 278,
			'interface_names' => 415,
			'interface_name' => 280
		}
	},
	{#State 340
		DEFAULT => -35
	},
	{#State 341
		DEFAULT => -28
	},
	{#State 342
		DEFAULT => -27
	},
	{#State 343
		DEFAULT => -82
	},
	{#State 344
		DEFAULT => -80
	},
	{#State 345
		DEFAULT => -79
	},
	{#State 346
		DEFAULT => -302
	},
	{#State 347
		DEFAULT => -301
	},
	{#State 348
		ACTIONS => {
			'IDENTIFIER' => 237
		},
		GOTOS => {
			'declarators' => 416,
			'declarator' => 232,
			'simple_declarator' => 235,
			'array_declarator' => 236,
			'complex_declarator' => 234
		}
	},
	{#State 349
		DEFAULT => -288
	},
	{#State 350
		ACTIONS => {
			"[" => 351
		},
		DEFAULT => -289,
		GOTOS => {
			'fixed_array_sizes' => 417,
			'fixed_array_size' => 350
		}
	},
	{#State 351
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 419,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'primary_expr' => 305,
			'and_expr' => 306,
			'scoped_name' => 288,
			'positive_int_const' => 418,
			'wide_string_literal' => 290,
			'boolean_literal' => 292,
			'mult_expr' => 308,
			'const_exp' => 293,
			'or_expr' => 294,
			'unary_expr' => 312,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 352
		DEFAULT => -86
	},
	{#State 353
		DEFAULT => -312
	},
	{#State 354
		DEFAULT => -311
	},
	{#State 355
		DEFAULT => -295
	},
	{#State 356
		ACTIONS => {
			'error' => 420,
			'IDENTIFIER' => 137
		},
		GOTOS => {
			'simple_declarators' => 422,
			'simple_declarator' => 421
		}
	},
	{#State 357
		ACTIONS => {
			";" => 423
		}
	},
	{#State 358
		ACTIONS => {
			";" => 424
		}
	},
	{#State 359
		DEFAULT => -106
	},
	{#State 360
		ACTIONS => {
			'CHAR' => 87,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'OBJECT' => 88,
			'IDENTIFIER' => 103,
			'VALUEBASE' => 89,
			'WCHAR' => 77,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'OCTET' => 82,
			'FLOAT' => 84,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'wide_string_type' => 250,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 246,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'signed_short_int' => 98,
			'string_type' => 247,
			'base_type_spec' => 248,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'unsigned_long_int' => 106,
			'param_type_spec' => 425,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85
		}
	},
	{#State 361
		ACTIONS => {
			")" => 426
		}
	},
	{#State 362
		DEFAULT => -120
	},
	{#State 363
		ACTIONS => {
			"," => 427
		},
		DEFAULT => -117
	},
	{#State 364
		ACTIONS => {
			")" => 428
		}
	},
	{#State 365
		DEFAULT => -111
	},
	{#State 366
		DEFAULT => -326
	},
	{#State 367
		ACTIONS => {
			")" => 429
		}
	},
	{#State 368
		DEFAULT => -328
	},
	{#State 369
		ACTIONS => {
			'CHAR' => 87,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'OBJECT' => 88,
			'IDENTIFIER' => 103,
			'VALUEBASE' => 89,
			'WCHAR' => 77,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'OCTET' => 82,
			'FLOAT' => 84,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'wide_string_type' => 250,
			'integer_type' => 92,
			'boolean_type' => 91,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 246,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'signed_short_int' => 98,
			'string_type' => 247,
			'base_type_spec' => 248,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'unsigned_long_int' => 106,
			'param_type_spec' => 430,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85
		}
	},
	{#State 370
		ACTIONS => {
			")" => 431
		}
	},
	{#State 371
		DEFAULT => -319
	},
	{#State 372
		DEFAULT => -327
	},
	{#State 373
		ACTIONS => {
			";" => 432,
			"," => 433
		},
		DEFAULT => -321
	},
	{#State 374
		ACTIONS => {
			'error' => 435,
			"(" => 434
		}
	},
	{#State 375
		ACTIONS => {
			'CONTEXT' => 374
		},
		DEFAULT => -307,
		GOTOS => {
			'context_expr' => 436
		}
	},
	{#State 376
		DEFAULT => -309
	},
	{#State 377
		ACTIONS => {
			'error' => 438,
			"(" => 437
		}
	},
	{#State 378
		ACTIONS => {
			"::" => 196
		},
		DEFAULT => -100
	},
	{#State 379
		ACTIONS => {
			"," => 439
		},
		DEFAULT => -96
	},
	{#State 380
		DEFAULT => -92
	},
	{#State 381
		ACTIONS => {
			'SUPPORTS' => 186
		},
		DEFAULT => -90,
		GOTOS => {
			'supported_interface_spec' => 440
		}
	},
	{#State 382
		ACTIONS => {
			'IDENTIFIER' => 103,
			"::" => 97
		},
		GOTOS => {
			'scoped_name' => 278,
			'interface_names' => 441,
			'interface_name' => 280
		}
	},
	{#State 383
		DEFAULT => -242
	},
	{#State 384
		DEFAULT => -243
	},
	{#State 385
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 443,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'primary_expr' => 305,
			'and_expr' => 306,
			'scoped_name' => 288,
			'positive_int_const' => 442,
			'wide_string_literal' => 290,
			'boolean_literal' => 292,
			'mult_expr' => 308,
			'const_exp' => 293,
			'or_expr' => 294,
			'unary_expr' => 312,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 386
		ACTIONS => {
			")" => 444
		}
	},
	{#State 387
		ACTIONS => {
			")" => 445
		}
	},
	{#State 388
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 308,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'and_expr' => 306,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'xor_expr' => 446,
			'shift_expr' => 297,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 389
		DEFAULT => -346
	},
	{#State 390
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 308,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'and_expr' => 447,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'shift_expr' => 297,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 391
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 308,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 448
		}
	},
	{#State 392
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 308,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 449
		}
	},
	{#State 393
		DEFAULT => -173
	},
	{#State 394
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 450,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315
		}
	},
	{#State 395
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 451,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315
		}
	},
	{#State 396
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 308,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'shift_expr' => 452,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 397
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'unary_expr' => 453,
			'scoped_name' => 288,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315
		}
	},
	{#State 398
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'unary_expr' => 454,
			'scoped_name' => 288,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315
		}
	},
	{#State 399
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'CHARACTER_LITERAL' => 286,
			"+" => 311,
			'FIXED_PT_LITERAL' => 310,
			'WIDE_CHARACTER_LITERAL' => 287,
			"-" => 313,
			"::" => 97,
			'FALSE' => 298,
			'WIDE_STRING_LITERAL' => 299,
			'INTEGER_LITERAL' => 307,
			"~" => 314,
			"(" => 291,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'unary_expr' => 455,
			'scoped_name' => 288,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315
		}
	},
	{#State 400
		DEFAULT => -171
	},
	{#State 401
		DEFAULT => -153
	},
	{#State 402
		DEFAULT => -280
	},
	{#State 403
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 457,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'string_literal' => 303,
			'primary_expr' => 305,
			'and_expr' => 306,
			'scoped_name' => 288,
			'positive_int_const' => 456,
			'wide_string_literal' => 290,
			'boolean_literal' => 292,
			'mult_expr' => 308,
			'const_exp' => 293,
			'or_expr' => 294,
			'unary_expr' => 312,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 404
		DEFAULT => -279
	},
	{#State 405
		DEFAULT => -282
	},
	{#State 406
		DEFAULT => -284
	},
	{#State 407
		DEFAULT => -285
	},
	{#State 408
		DEFAULT => -287
	},
	{#State 409
		DEFAULT => -273
	},
	{#State 410
		DEFAULT => -121
	},
	{#State 411
		DEFAULT => -122
	},
	{#State 412
		DEFAULT => -247
	},
	{#State 413
		ACTIONS => {
			"{" => 459,
			'error' => 458
		}
	},
	{#State 414
		DEFAULT => -54
	},
	{#State 415
		DEFAULT => -53
	},
	{#State 416
		DEFAULT => -209
	},
	{#State 417
		DEFAULT => -290
	},
	{#State 418
		ACTIONS => {
			"]" => 460
		}
	},
	{#State 419
		ACTIONS => {
			"]" => 461
		}
	},
	{#State 420
		DEFAULT => -294
	},
	{#State 421
		ACTIONS => {
			"," => 462
		},
		DEFAULT => -298
	},
	{#State 422
		DEFAULT => -293
	},
	{#State 423
		DEFAULT => -104
	},
	{#State 424
		DEFAULT => -105
	},
	{#State 425
		ACTIONS => {
			'IDENTIFIER' => 137
		},
		GOTOS => {
			'simple_declarator' => 463
		}
	},
	{#State 426
		DEFAULT => -112
	},
	{#State 427
		ACTIONS => {
			'IN' => 362
		},
		GOTOS => {
			'init_param_decls' => 464,
			'init_param_attribute' => 360,
			'init_param_decl' => 363
		}
	},
	{#State 428
		DEFAULT => -113
	},
	{#State 429
		DEFAULT => -320
	},
	{#State 430
		ACTIONS => {
			'IDENTIFIER' => 137
		},
		GOTOS => {
			'simple_declarator' => 465
		}
	},
	{#State 431
		DEFAULT => -318
	},
	{#State 432
		DEFAULT => -324
	},
	{#State 433
		ACTIONS => {
			'OUT' => 372,
			'INOUT' => 368,
			'IN' => 366
		},
		DEFAULT => -323,
		GOTOS => {
			'param_dcl' => 373,
			'param_dcls' => 466,
			'param_attribute' => 369
		}
	},
	{#State 434
		ACTIONS => {
			'error' => 467,
			'STRING_LITERAL' => 309
		},
		GOTOS => {
			'string_literal' => 468,
			'string_literals' => 469
		}
	},
	{#State 435
		DEFAULT => -337
	},
	{#State 436
		DEFAULT => -308
	},
	{#State 437
		ACTIONS => {
			'error' => 471,
			'IDENTIFIER' => 103,
			"::" => 97
		},
		GOTOS => {
			'scoped_name' => 470,
			'exception_names' => 472,
			'exception_name' => 473
		}
	},
	{#State 438
		DEFAULT => -331
	},
	{#State 439
		ACTIONS => {
			'IDENTIFIER' => 103,
			"::" => 97
		},
		GOTOS => {
			'scoped_name' => 378,
			'value_name' => 379,
			'value_names' => 474
		}
	},
	{#State 440
		DEFAULT => -91
	},
	{#State 441
		DEFAULT => -56
	},
	{#State 442
		ACTIONS => {
			">" => 475
		}
	},
	{#State 443
		ACTIONS => {
			">" => 476
		}
	},
	{#State 444
		DEFAULT => -160
	},
	{#State 445
		DEFAULT => -161
	},
	{#State 446
		ACTIONS => {
			"^" => 390
		},
		DEFAULT => -138
	},
	{#State 447
		ACTIONS => {
			"&" => 396
		},
		DEFAULT => -140
	},
	{#State 448
		ACTIONS => {
			"+" => 394,
			"-" => 395
		},
		DEFAULT => -145
	},
	{#State 449
		ACTIONS => {
			"+" => 394,
			"-" => 395
		},
		DEFAULT => -144
	},
	{#State 450
		ACTIONS => {
			"%" => 398,
			"*" => 397,
			"/" => 399
		},
		DEFAULT => -147
	},
	{#State 451
		ACTIONS => {
			"%" => 398,
			"*" => 397,
			"/" => 399
		},
		DEFAULT => -148
	},
	{#State 452
		ACTIONS => {
			"<<" => 391,
			">>" => 392
		},
		DEFAULT => -142
	},
	{#State 453
		DEFAULT => -150
	},
	{#State 454
		DEFAULT => -152
	},
	{#State 455
		DEFAULT => -151
	},
	{#State 456
		ACTIONS => {
			">" => 477
		}
	},
	{#State 457
		ACTIONS => {
			">" => 478
		}
	},
	{#State 458
		DEFAULT => -246
	},
	{#State 459
		ACTIONS => {
			'error' => 482,
			'CASE' => 479,
			'DEFAULT' => 481
		},
		GOTOS => {
			'case_labels' => 484,
			'switch_body' => 483,
			'case' => 480,
			'case_label' => 485
		}
	},
	{#State 460
		DEFAULT => -291
	},
	{#State 461
		DEFAULT => -292
	},
	{#State 462
		ACTIONS => {
			'IDENTIFIER' => 137
		},
		GOTOS => {
			'simple_declarators' => 486,
			'simple_declarator' => 421
		}
	},
	{#State 463
		DEFAULT => -119
	},
	{#State 464
		DEFAULT => -118
	},
	{#State 465
		DEFAULT => -325
	},
	{#State 466
		DEFAULT => -322
	},
	{#State 467
		ACTIONS => {
			")" => 487
		}
	},
	{#State 468
		ACTIONS => {
			"," => 488
		},
		DEFAULT => -338
	},
	{#State 469
		ACTIONS => {
			")" => 489
		}
	},
	{#State 470
		ACTIONS => {
			"::" => 196
		},
		DEFAULT => -334
	},
	{#State 471
		ACTIONS => {
			")" => 490
		}
	},
	{#State 472
		ACTIONS => {
			")" => 491
		}
	},
	{#State 473
		ACTIONS => {
			"," => 492
		},
		DEFAULT => -332
	},
	{#State 474
		DEFAULT => -97
	},
	{#State 475
		DEFAULT => -344
	},
	{#State 476
		DEFAULT => -345
	},
	{#State 477
		DEFAULT => -277
	},
	{#State 478
		DEFAULT => -278
	},
	{#State 479
		ACTIONS => {
			'FLOATING_PT_LITERAL' => 304,
			'CHARACTER_LITERAL' => 286,
			'WIDE_CHARACTER_LITERAL' => 287,
			"::" => 97,
			'INTEGER_LITERAL' => 307,
			"(" => 291,
			'IDENTIFIER' => 103,
			'STRING_LITERAL' => 309,
			'FIXED_PT_LITERAL' => 310,
			"+" => 311,
			'error' => 494,
			"-" => 313,
			'WIDE_STRING_LITERAL' => 299,
			'FALSE' => 298,
			"~" => 314,
			'TRUE' => 301
		},
		GOTOS => {
			'mult_expr' => 308,
			'string_literal' => 303,
			'boolean_literal' => 292,
			'primary_expr' => 305,
			'const_exp' => 493,
			'and_expr' => 306,
			'or_expr' => 294,
			'unary_expr' => 312,
			'scoped_name' => 288,
			'xor_expr' => 296,
			'shift_expr' => 297,
			'wide_string_literal' => 290,
			'literal' => 300,
			'unary_operator' => 315,
			'add_expr' => 302
		}
	},
	{#State 480
		ACTIONS => {
			'CASE' => 479,
			'DEFAULT' => 481
		},
		DEFAULT => -255,
		GOTOS => {
			'case_labels' => 484,
			'switch_body' => 495,
			'case' => 480,
			'case_label' => 485
		}
	},
	{#State 481
		ACTIONS => {
			'error' => 496,
			":" => 497
		}
	},
	{#State 482
		ACTIONS => {
			"}" => 498
		}
	},
	{#State 483
		ACTIONS => {
			"}" => 499
		}
	},
	{#State 484
		ACTIONS => {
			'CHAR' => 87,
			'OBJECT' => 88,
			'VALUEBASE' => 89,
			'FIXED' => 63,
			'SEQUENCE' => 65,
			'STRUCT' => 93,
			'DOUBLE' => 94,
			'LONG' => 95,
			'STRING' => 96,
			"::" => 97,
			'WSTRING' => 99,
			'UNSIGNED' => 74,
			'SHORT' => 76,
			'BOOLEAN' => 101,
			'IDENTIFIER' => 103,
			'UNION' => 104,
			'WCHAR' => 77,
			'FLOAT' => 84,
			'OCTET' => 82,
			'ENUM' => 27,
			'ANY' => 86
		},
		GOTOS => {
			'unsigned_int' => 61,
			'floating_pt_type' => 62,
			'signed_int' => 64,
			'char_type' => 67,
			'value_base_type' => 66,
			'object_type' => 68,
			'octet_type' => 69,
			'scoped_name' => 70,
			'wide_char_type' => 71,
			'signed_long_int' => 72,
			'type_spec' => 500,
			'string_type' => 75,
			'struct_header' => 11,
			'element_spec' => 501,
			'unsigned_longlong_int' => 78,
			'any_type' => 79,
			'base_type_spec' => 80,
			'enum_type' => 81,
			'enum_header' => 19,
			'union_header' => 25,
			'unsigned_short_int' => 83,
			'signed_longlong_int' => 85,
			'wide_string_type' => 90,
			'boolean_type' => 91,
			'integer_type' => 92,
			'signed_short_int' => 98,
			'struct_type' => 100,
			'union_type' => 102,
			'sequence_type' => 105,
			'unsigned_long_int' => 106,
			'template_type_spec' => 107,
			'constr_type_spec' => 108,
			'simple_type_spec' => 109,
			'fixed_pt_type' => 110
		}
	},
	{#State 485
		ACTIONS => {
			'CASE' => 479,
			'DEFAULT' => 481
		},
		DEFAULT => -259,
		GOTOS => {
			'case_labels' => 502,
			'case_label' => 485
		}
	},
	{#State 486
		DEFAULT => -299
	},
	{#State 487
		DEFAULT => -336
	},
	{#State 488
		ACTIONS => {
			'STRING_LITERAL' => 309
		},
		GOTOS => {
			'string_literal' => 468,
			'string_literals' => 503
		}
	},
	{#State 489
		DEFAULT => -335
	},
	{#State 490
		DEFAULT => -330
	},
	{#State 491
		DEFAULT => -329
	},
	{#State 492
		ACTIONS => {
			'IDENTIFIER' => 103,
			"::" => 97
		},
		GOTOS => {
			'scoped_name' => 470,
			'exception_names' => 504,
			'exception_name' => 473
		}
	},
	{#State 493
		ACTIONS => {
			'error' => 505,
			":" => 506
		}
	},
	{#State 494
		DEFAULT => -263
	},
	{#State 495
		DEFAULT => -256
	},
	{#State 496
		DEFAULT => -265
	},
	{#State 497
		DEFAULT => -264
	},
	{#State 498
		DEFAULT => -245
	},
	{#State 499
		DEFAULT => -244
	},
	{#State 500
		ACTIONS => {
			'IDENTIFIER' => 237
		},
		GOTOS => {
			'declarator' => 507,
			'simple_declarator' => 235,
			'array_declarator' => 236,
			'complex_declarator' => 234
		}
	},
	{#State 501
		ACTIONS => {
			'error' => 509,
			";" => 508
		}
	},
	{#State 502
		DEFAULT => -260
	},
	{#State 503
		DEFAULT => -339
	},
	{#State 504
		DEFAULT => -333
	},
	{#State 505
		DEFAULT => -262
	},
	{#State 506
		DEFAULT => -261
	},
	{#State 507
		DEFAULT => -266
	},
	{#State 508
		DEFAULT => -257
	},
	{#State 509
		DEFAULT => -258
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
#line 70 "parser24.yp"
{
			$_[0]->YYData->{root} = new Specification($_[0],
					'list_decl'			=>	$_[1],
			);
		}
	],
	[#Rule 2
		 'specification', 0,
sub
#line 76 "parser24.yp"
{
			$_[0]->Error("Empty specification.\n");
		}
	],
	[#Rule 3
		 'specification', 1,
sub
#line 80 "parser24.yp"
{
			$_[0]->Error("definition declaration expected.\n");
		}
	],
	[#Rule 4
		 'definitions', 1,
sub
#line 87 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 5
		 'definitions', 2,
sub
#line 91 "parser24.yp"
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
		 'definition', 2, undef
	],
	[#Rule 12
		 'definition', 2,
sub
#line 112 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 13
		 'definition', 2,
sub
#line 118 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 14
		 'definition', 2,
sub
#line 124 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 15
		 'definition', 2,
sub
#line 130 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 16
		 'definition', 2,
sub
#line 136 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 17
		 'definition', 2,
sub
#line 142 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 18
		 'definition', 3,
sub
#line 148 "parser24.yp"
{
			# when IDENTIFIER is a future keyword
			$_[0]->Error("'$_[1]' unexpected.\n");
			$_[0]->YYErrok();
			new node($_[0],
					'idf'					=>	$_[1]
			);
		}
	],
	[#Rule 19
		 'module', 4,
sub
#line 161 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[1]->Configure($_[0],
					'list_decl'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 20
		 'module', 4,
sub
#line 168 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("definition declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 21
		 'module', 2,
sub
#line 174 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentRoot($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 22
		 'module_header', 2,
sub
#line 183 "parser24.yp"
{
			new Module($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 23
		 'module_header', 2,
sub
#line 189 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 24
		 'interface', 1, undef
	],
	[#Rule 25
		 'interface', 1, undef
	],
	[#Rule 26
		 'interface_dcl', 3,
sub
#line 206 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 27
		 'interface_dcl', 4,
sub
#line 214 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 28
		 'interface_dcl', 4,
sub
#line 222 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 29
		 'forward_dcl', 3,
sub
#line 233 "parser24.yp"
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
	[#Rule 30
		 'forward_dcl', 3,
sub
#line 249 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 31
		 'interface_mod', 1, undef
	],
	[#Rule 32
		 'interface_mod', 1, undef
	],
	[#Rule 33
		 'interface_mod', 0, undef
	],
	[#Rule 34
		 'interface_header', 3,
sub
#line 267 "parser24.yp"
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
	[#Rule 35
		 'interface_header', 4,
sub
#line 283 "parser24.yp"
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
	[#Rule 36
		 'interface_header', 3,
sub
#line 305 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 37
		 'interface_body', 1, undef
	],
	[#Rule 38
		 'exports', 1,
sub
#line 319 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 39
		 'exports', 2,
sub
#line 323 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 40
		 '_export', 1, undef
	],
	[#Rule 41
		 '_export', 1,
sub
#line 334 "parser24.yp"
{
			$_[0]->Error("state member unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 42
		 '_export', 1,
sub
#line 339 "parser24.yp"
{
			$_[0]->Error("initializer unexpected.\n");
			$_[1];						#default action
		}
	],
	[#Rule 43
		 'export', 2, undef
	],
	[#Rule 44
		 'export', 2, undef
	],
	[#Rule 45
		 'export', 2, undef
	],
	[#Rule 46
		 'export', 2, undef
	],
	[#Rule 47
		 'export', 2, undef
	],
	[#Rule 48
		 'export', 2,
sub
#line 357 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 49
		 'export', 2,
sub
#line 363 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 50
		 'export', 2,
sub
#line 369 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 51
		 'export', 2,
sub
#line 375 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 52
		 'export', 2,
sub
#line 381 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 53
		 'interface_inheritance_spec', 2,
sub
#line 391 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 54
		 'interface_inheritance_spec', 2,
sub
#line 395 "parser24.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 55
		 'interface_names', 1,
sub
#line 403 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 56
		 'interface_names', 3,
sub
#line 407 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 57
		 'interface_name', 1,
sub
#line 416 "parser24.yp"
{
				Interface->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 58
		 'scoped_name', 1, undef
	],
	[#Rule 59
		 'scoped_name', 2,
sub
#line 426 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 60
		 'scoped_name', 2,
sub
#line 430 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			'';
		}
	],
	[#Rule 61
		 'scoped_name', 3,
sub
#line 436 "parser24.yp"
{
			$_[1] . $_[2] . $_[3];
		}
	],
	[#Rule 62
		 'scoped_name', 3,
sub
#line 440 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
			$_[1];
		}
	],
	[#Rule 63
		 'value', 1, undef
	],
	[#Rule 64
		 'value', 1, undef
	],
	[#Rule 65
		 'value', 1, undef
	],
	[#Rule 66
		 'value', 1, undef
	],
	[#Rule 67
		 'value_forward_dcl', 2,
sub
#line 462 "parser24.yp"
{
			new ForwardRegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 68
		 'value_forward_dcl', 3,
sub
#line 468 "parser24.yp"
{
			new ForwardAbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 69
		 'value_box_dcl', 2,
sub
#line 478 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'type'				=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 70
		 'value_box_header', 2,
sub
#line 489 "parser24.yp"
{
			new BoxedValue($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 71
		 'value_abs_dcl', 3,
sub
#line 499 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 72
		 'value_abs_dcl', 4,
sub
#line 507 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 73
		 'value_abs_dcl', 4,
sub
#line 515 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("export declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 74
		 'value_abs_header', 3,
sub
#line 525 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 75
		 'value_abs_header', 4,
sub
#line 531 "parser24.yp"
{
			new AbstractValue($_[0],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 76
		 'value_abs_header', 3,
sub
#line 538 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 77
		 'value_abs_header', 2,
sub
#line 543 "parser24.yp"
{
			$_[0]->Error("'valuetype' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 78
		 'value_dcl', 3,
sub
#line 552 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	[]
			) if (defined $_[1]);
		}
	],
	[#Rule 79
		 'value_dcl', 4,
sub
#line 560 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[1]->Configure($_[0],
					'list_decl'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 80
		 'value_dcl', 4,
sub
#line 568 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->YYData->{curr_itf} = undef;
			$_[0]->Error("value_element expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 81
		 'value_elements', 1,
sub
#line 578 "parser24.yp"
{
			[$_[1]->getRef()];
		}
	],
	[#Rule 82
		 'value_elements', 2,
sub
#line 582 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]->getRef());
			$_[2];
		}
	],
	[#Rule 83
		 'value_header', 2,
sub
#line 591 "parser24.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 84
		 'value_header', 3,
sub
#line 597 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 85
		 'value_header', 3,
sub
#line 604 "parser24.yp"
{
			new RegularValue($_[0],
					'idf'				=>	$_[2],
					'inheritance'		=>	$_[3]
			);
		}
	],
	[#Rule 86
		 'value_header', 4,
sub
#line 611 "parser24.yp"
{
			new RegularValue($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[3],
					'inheritance'		=>	$_[4]
			);
		}
	],
	[#Rule 87
		 'value_header', 2,
sub
#line 619 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 88
		 'value_header', 3,
sub
#line 624 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 89
		 'value_header', 2,
sub
#line 629 "parser24.yp"
{
			$_[0]->Error("valuetype expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 90
		 'value_inheritance_spec', 3,
sub
#line 638 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3]
			);
		}
	],
	[#Rule 91
		 'value_inheritance_spec', 4,
sub
#line 645 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'modifier'			=>	$_[2],
					'list_value'		=>	$_[3],
					'list_interface'	=>	$_[4]
			);
		}
	],
	[#Rule 92
		 'value_inheritance_spec', 3,
sub
#line 653 "parser24.yp"
{
			$_[0]->Error("value_name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 93
		 'value_inheritance_spec', 1,
sub
#line 658 "parser24.yp"
{
			new InheritanceSpec($_[0],
					'list_interface'	=>	$_[1]
			);
		}
	],
	[#Rule 94
		 'inheritance_mod', 1, undef
	],
	[#Rule 95
		 'inheritance_mod', 0, undef
	],
	[#Rule 96
		 'value_names', 1,
sub
#line 674 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 97
		 'value_names', 3,
sub
#line 678 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 98
		 'supported_interface_spec', 2,
sub
#line 686 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 99
		 'supported_interface_spec', 2,
sub
#line 690 "parser24.yp"
{
			$_[0]->Error("Interface name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 100
		 'value_name', 1,
sub
#line 699 "parser24.yp"
{
			Value->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 101
		 'value_element', 1, undef
	],
	[#Rule 102
		 'value_element', 1, undef
	],
	[#Rule 103
		 'value_element', 1, undef
	],
	[#Rule 104
		 'state_member', 4,
sub
#line 717 "parser24.yp"
{
			new StateMembers($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'list_expr'			=>	$_[3]
			);
		}
	],
	[#Rule 105
		 'state_member', 4,
sub
#line 725 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 106
		 'state_member', 3,
sub
#line 730 "parser24.yp"
{
			$_[0]->Error("type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 107
		 'state_mod', 1, undef
	],
	[#Rule 108
		 'state_mod', 1, undef
	],
	[#Rule 109
		 'init_dcl', 2, undef
	],
	[#Rule 110
		 'init_dcl', 2,
sub
#line 748 "parser24.yp"
{
			$_[0]->Warning("';' expected.\n");
			$_[0]->YYErrok();
			$_[1];						#default action
		}
	],
	[#Rule 111
		 'init_header_param', 3,
sub
#line 758 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1];						#default action
		}
	],
	[#Rule 112
		 'init_header_param', 4,
sub
#line 764 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 113
		 'init_header_param', 4,
sub
#line 772 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("init_param_decls expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 114
		 'init_header_param', 2,
sub
#line 779 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 115
		 'init_header', 2,
sub
#line 789 "parser24.yp"
{
			new Initializer($_[0],						# like Operation
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 116
		 'init_header', 2,
sub
#line 795 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 117
		 'init_param_decls', 1,
sub
#line 804 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 118
		 'init_param_decls', 3,
sub
#line 808 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 119
		 'init_param_decl', 3,
sub
#line 817 "parser24.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 120
		 'init_param_attribute', 1, undef
	],
	[#Rule 121
		 'const_dcl', 5,
sub
#line 835 "parser24.yp"
{
			new Constant($_[0],
					'type'				=>	$_[2],
					'idf'				=>	$_[3],
					'list_expr'			=>	$_[5]
			);
		}
	],
	[#Rule 122
		 'const_dcl', 5,
sub
#line 843 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 123
		 'const_dcl', 4,
sub
#line 848 "parser24.yp"
{
			$_[0]->Error("'=' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 124
		 'const_dcl', 3,
sub
#line 853 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 125
		 'const_dcl', 2,
sub
#line 858 "parser24.yp"
{
			$_[0]->Error("const_type expected.\n");
			$_[0]->YYErrok();
		}
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
		 'const_type', 1, undef
	],
	[#Rule 133
		 'const_type', 1, undef
	],
	[#Rule 134
		 'const_type', 1,
sub
#line 883 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 135
		 'const_type', 1, undef
	],
	[#Rule 136
		 'const_exp', 1, undef
	],
	[#Rule 137
		 'or_expr', 1, undef
	],
	[#Rule 138
		 'or_expr', 3,
sub
#line 901 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 139
		 'xor_expr', 1, undef
	],
	[#Rule 140
		 'xor_expr', 3,
sub
#line 911 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 141
		 'and_expr', 1, undef
	],
	[#Rule 142
		 'and_expr', 3,
sub
#line 921 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 143
		 'shift_expr', 1, undef
	],
	[#Rule 144
		 'shift_expr', 3,
sub
#line 931 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 145
		 'shift_expr', 3,
sub
#line 935 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 146
		 'add_expr', 1, undef
	],
	[#Rule 147
		 'add_expr', 3,
sub
#line 945 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 148
		 'add_expr', 3,
sub
#line 949 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 149
		 'mult_expr', 1, undef
	],
	[#Rule 150
		 'mult_expr', 3,
sub
#line 959 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 151
		 'mult_expr', 3,
sub
#line 963 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 152
		 'mult_expr', 3,
sub
#line 967 "parser24.yp"
{
			BuildBinop($_[1],$_[2],$_[3]);
		}
	],
	[#Rule 153
		 'unary_expr', 2,
sub
#line 975 "parser24.yp"
{
			BuildUnop($_[1],$_[2]);
		}
	],
	[#Rule 154
		 'unary_expr', 1, undef
	],
	[#Rule 155
		 'unary_operator', 1, undef
	],
	[#Rule 156
		 'unary_operator', 1, undef
	],
	[#Rule 157
		 'unary_operator', 1, undef
	],
	[#Rule 158
		 'primary_expr', 1,
sub
#line 995 "parser24.yp"
{
			[
				Constant->Lookup($_[0],$_[1])
			];
		}
	],
	[#Rule 159
		 'primary_expr', 1,
sub
#line 1001 "parser24.yp"
{
			[ $_[1] ];
		}
	],
	[#Rule 160
		 'primary_expr', 3,
sub
#line 1005 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 161
		 'primary_expr', 3,
sub
#line 1009 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 162
		 'literal', 1,
sub
#line 1018 "parser24.yp"
{
			new IntegerLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 163
		 'literal', 1,
sub
#line 1025 "parser24.yp"
{
			new StringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 164
		 'literal', 1,
sub
#line 1031 "parser24.yp"
{
			new WideStringLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 165
		 'literal', 1,
sub
#line 1037 "parser24.yp"
{
			new CharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 166
		 'literal', 1,
sub
#line 1043 "parser24.yp"
{
			new WideCharacterLiteral($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 167
		 'literal', 1,
sub
#line 1049 "parser24.yp"
{
			new FixedPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 168
		 'literal', 1,
sub
#line 1056 "parser24.yp"
{
			new FloatingPtLiteral($_[0],
					'value'				=>	$_[1],
					'lexeme'			=>	$_[0]->YYData->{lexeme}
			);
		}
	],
	[#Rule 169
		 'literal', 1, undef
	],
	[#Rule 170
		 'string_literal', 1, undef
	],
	[#Rule 171
		 'string_literal', 2,
sub
#line 1070 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 172
		 'wide_string_literal', 1, undef
	],
	[#Rule 173
		 'wide_string_literal', 2,
sub
#line 1079 "parser24.yp"
{
			$_[1] . $_[2];
		}
	],
	[#Rule 174
		 'boolean_literal', 1,
sub
#line 1087 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	1
			);
		}
	],
	[#Rule 175
		 'boolean_literal', 1,
sub
#line 1093 "parser24.yp"
{
			new BooleanLiteral($_[0],
					'value'				=>	0
			);
		}
	],
	[#Rule 176
		 'positive_int_const', 1,
sub
#line 1103 "parser24.yp"
{
			new Expression($_[0],
					'list_expr'			=>	$_[1]
			);
		}
	],
	[#Rule 177
		 'type_dcl', 2,
sub
#line 1113 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 178
		 'type_dcl', 1, undef
	],
	[#Rule 179
		 'type_dcl', 1, undef
	],
	[#Rule 180
		 'type_dcl', 1, undef
	],
	[#Rule 181
		 'type_dcl', 2,
sub
#line 1123 "parser24.yp"
{
			new TypeDeclarator($_[0],
					'modifier'			=>	$_[1],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 182
		 'type_dcl', 1, undef
	],
	[#Rule 183
		 'type_dcl', 2,
sub
#line 1132 "parser24.yp"
{
			$_[0]->Error("type_declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 184
		 'type_dcl', 2,
sub
#line 1137 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 185
		 'type_declarator', 2,
sub
#line 1146 "parser24.yp"
{
			new TypeDeclarators($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 186
		 'type_declarator', 2,
sub
#line 1153 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 187
		 'type_spec', 1, undef
	],
	[#Rule 188
		 'type_spec', 1, undef
	],
	[#Rule 189
		 'simple_type_spec', 1, undef
	],
	[#Rule 190
		 'simple_type_spec', 1, undef
	],
	[#Rule 191
		 'simple_type_spec', 1,
sub
#line 1174 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
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
#line 1226 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 209
		 'declarators', 3,
sub
#line 1230 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 210
		 'declarator', 1,
sub
#line 1239 "parser24.yp"
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
		 'complex_declarator', 1, undef
	],
	[#Rule 214
		 'floating_pt_type', 1,
sub
#line 1261 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 215
		 'floating_pt_type', 1,
sub
#line 1267 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 216
		 'floating_pt_type', 2,
sub
#line 1273 "parser24.yp"
{
			new FloatingPtType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 217
		 'integer_type', 1, undef
	],
	[#Rule 218
		 'integer_type', 1, undef
	],
	[#Rule 219
		 'signed_int', 1, undef
	],
	[#Rule 220
		 'signed_int', 1, undef
	],
	[#Rule 221
		 'signed_int', 1, undef
	],
	[#Rule 222
		 'signed_short_int', 1,
sub
#line 1301 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 223
		 'signed_long_int', 1,
sub
#line 1311 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 224
		 'signed_longlong_int', 2,
sub
#line 1321 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 225
		 'unsigned_int', 1, undef
	],
	[#Rule 226
		 'unsigned_int', 1, undef
	],
	[#Rule 227
		 'unsigned_int', 1, undef
	],
	[#Rule 228
		 'unsigned_short_int', 2,
sub
#line 1341 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 229
		 'unsigned_long_int', 2,
sub
#line 1351 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2]
			);
		}
	],
	[#Rule 230
		 'unsigned_longlong_int', 3,
sub
#line 1361 "parser24.yp"
{
			new IntegerType($_[0],
					'value'				=>	$_[1] . ' ' . $_[2] . ' ' . $_[3]
			);
		}
	],
	[#Rule 231
		 'char_type', 1,
sub
#line 1371 "parser24.yp"
{
			new CharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 232
		 'wide_char_type', 1,
sub
#line 1381 "parser24.yp"
{
			new WideCharType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 233
		 'boolean_type', 1,
sub
#line 1391 "parser24.yp"
{
			new BooleanType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 234
		 'octet_type', 1,
sub
#line 1401 "parser24.yp"
{
			new OctetType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 235
		 'any_type', 1,
sub
#line 1411 "parser24.yp"
{
			new AnyType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 236
		 'object_type', 1,
sub
#line 1421 "parser24.yp"
{
			new ObjectType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 237
		 'struct_type', 4,
sub
#line 1431 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 238
		 'struct_type', 4,
sub
#line 1438 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("member expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 239
		 'struct_header', 2,
sub
#line 1447 "parser24.yp"
{
			new StructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 240
		 'member_list', 1,
sub
#line 1457 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 241
		 'member_list', 2,
sub
#line 1461 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 242
		 'member', 3,
sub
#line 1470 "parser24.yp"
{
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 243
		 'member', 3,
sub
#line 1477 "parser24.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Members($_[0],
					'type'				=>	$_[1],
					'list_expr'			=>	$_[2]
			);
		}
	],
	[#Rule 244
		 'union_type', 8,
sub
#line 1490 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'type'				=>	$_[4],
					'list_expr'			=>	$_[7]
			) if (defined $_[1]);
		}
	],
	[#Rule 245
		 'union_type', 8,
sub
#line 1498 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_body expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 246
		 'union_type', 6,
sub
#line 1504 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 247
		 'union_type', 5,
sub
#line 1510 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("switch_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 248
		 'union_type', 3,
sub
#line 1516 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 249
		 'union_header', 2,
sub
#line 1525 "parser24.yp"
{
			new UnionType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 250
		 'switch_type_spec', 1, undef
	],
	[#Rule 251
		 'switch_type_spec', 1, undef
	],
	[#Rule 252
		 'switch_type_spec', 1, undef
	],
	[#Rule 253
		 'switch_type_spec', 1, undef
	],
	[#Rule 254
		 'switch_type_spec', 1,
sub
#line 1543 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 255
		 'switch_body', 1,
sub
#line 1551 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 256
		 'switch_body', 2,
sub
#line 1555 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 257
		 'case', 3,
sub
#line 1564 "parser24.yp"
{
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 258
		 'case', 3,
sub
#line 1571 "parser24.yp"
{
			$_[0]->Error("';' expected.\n");
			$_[0]->YYErrok();
			new Case($_[0],
					'list_label'		=>	$_[1],
					'element'			=>	$_[2]
			);
		}
	],
	[#Rule 259
		 'case_labels', 1,
sub
#line 1583 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 260
		 'case_labels', 2,
sub
#line 1587 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 261
		 'case_label', 3,
sub
#line 1596 "parser24.yp"
{
			$_[2];						# here only a expression, type is not known
		}
	],
	[#Rule 262
		 'case_label', 3,
sub
#line 1600 "parser24.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			$_[2];
		}
	],
	[#Rule 263
		 'case_label', 2,
sub
#line 1606 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 264
		 'case_label', 2,
sub
#line 1611 "parser24.yp"
{
			new Default($_[0]);
		}
	],
	[#Rule 265
		 'case_label', 2,
sub
#line 1615 "parser24.yp"
{
			$_[0]->Error("':' expected.\n");
			$_[0]->YYErrok();
			new Default($_[0]);
		}
	],
	[#Rule 266
		 'element_spec', 2,
sub
#line 1625 "parser24.yp"
{
			new Element($_[0],
					'type'			=>	$_[1],
					'list_expr'		=>	$_[2]
			);
		}
	],
	[#Rule 267
		 'enum_type', 4,
sub
#line 1636 "parser24.yp"
{
			$_[1]->Configure($_[0],
					'list_expr'		=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 268
		 'enum_type', 4,
sub
#line 1642 "parser24.yp"
{
			$_[0]->Error("enumerator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 269
		 'enum_type', 2,
sub
#line 1647 "parser24.yp"
{
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 270
		 'enum_header', 2,
sub
#line 1655 "parser24.yp"
{
			new EnumType($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 271
		 'enum_header', 2,
sub
#line 1661 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 272
		 'enumerators', 1,
sub
#line 1669 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 273
		 'enumerators', 3,
sub
#line 1673 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 274
		 'enumerators', 2,
sub
#line 1678 "parser24.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 275
		 'enumerators', 2,
sub
#line 1683 "parser24.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 276
		 'enumerator', 1,
sub
#line 1692 "parser24.yp"
{
			new Enum($_[0],
					'idf'				=>	$_[1]
			);
		}
	],
	[#Rule 277
		 'sequence_type', 6,
sub
#line 1702 "parser24.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3],
					'max'				=>	$_[5]
			);
		}
	],
	[#Rule 278
		 'sequence_type', 6,
sub
#line 1710 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 279
		 'sequence_type', 4,
sub
#line 1715 "parser24.yp"
{
			new SequenceType($_[0],
					'value'				=>	$_[1],
					'type'				=>	$_[3]
			);
		}
	],
	[#Rule 280
		 'sequence_type', 4,
sub
#line 1722 "parser24.yp"
{
			$_[0]->Error("simple_type_spec expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 281
		 'sequence_type', 2,
sub
#line 1727 "parser24.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 282
		 'string_type', 4,
sub
#line 1736 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 283
		 'string_type', 1,
sub
#line 1743 "parser24.yp"
{
			new StringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 284
		 'string_type', 4,
sub
#line 1749 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 285
		 'wide_string_type', 4,
sub
#line 1758 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1],
					'max'				=>	$_[3]
			);
		}
	],
	[#Rule 286
		 'wide_string_type', 1,
sub
#line 1765 "parser24.yp"
{
			new WideStringType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 287
		 'wide_string_type', 4,
sub
#line 1771 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 288
		 'array_declarator', 2,
sub
#line 1780 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 289
		 'fixed_array_sizes', 1,
sub
#line 1788 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 290
		 'fixed_array_sizes', 2,
sub
#line 1792 "parser24.yp"
{
			unshift(@{$_[2]},$_[1]);
			$_[2];
		}
	],
	[#Rule 291
		 'fixed_array_size', 3,
sub
#line 1801 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 292
		 'fixed_array_size', 3,
sub
#line 1805 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 293
		 'attr_dcl', 4,
sub
#line 1814 "parser24.yp"
{
			new Attributes($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[3],
					'list_expr'			=>	$_[4]
			);
		}
	],
	[#Rule 294
		 'attr_dcl', 4,
sub
#line 1822 "parser24.yp"
{
			$_[0]->Error("declarator expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 295
		 'attr_dcl', 3,
sub
#line 1827 "parser24.yp"
{
			$_[0]->Error("type expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 296
		 'attr_mod', 1, undef
	],
	[#Rule 297
		 'attr_mod', 0, undef
	],
	[#Rule 298
		 'simple_declarators', 1,
sub
#line 1842 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 299
		 'simple_declarators', 3,
sub
#line 1846 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 300
		 'except_dcl', 3,
sub
#line 1855 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1];
		}
	],
	[#Rule 301
		 'except_dcl', 4,
sub
#line 1860 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[1]->Configure($_[0],
					'list_expr'			=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 302
		 'except_dcl', 4,
sub
#line 1867 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'members expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 303
		 'except_dcl', 2,
sub
#line 1873 "parser24.yp"
{
			$_[0]->YYData->{symbtab}->PopCurrentScope($_[1]);
			$_[0]->Error("'\x7b' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 304
		 'exception_header', 2,
sub
#line 1882 "parser24.yp"
{
			new Exception($_[0],
					'idf'				=>	$_[2],
			);
		}
	],
	[#Rule 305
		 'exception_header', 2,
sub
#line 1888 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 306
		 'op_dcl', 2,
sub
#line 1897 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2]
			) if (defined $_[1]);
		}
	],
	[#Rule 307
		 'op_dcl', 3,
sub
#line 1905 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_raise'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 308
		 'op_dcl', 4,
sub
#line 1914 "parser24.yp"
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
	[#Rule 309
		 'op_dcl', 3,
sub
#line 1924 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[1]->Configure($_[0],
					'list_param'	=>	$_[2],
					'list_context'	=>	$_[3]
			) if (defined $_[1]);
		}
	],
	[#Rule 310
		 'op_dcl', 2,
sub
#line 1933 "parser24.yp"
{
			delete $_[0]->YYData->{unnamed_symbtab}
					if (exists $_[0]->YYData->{unnamed_symbtab});
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 311
		 'op_header', 3,
sub
#line 1943 "parser24.yp"
{
			new Operation($_[0],
					'modifier'			=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 312
		 'op_header', 3,
sub
#line 1951 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 313
		 'op_mod', 1, undef
	],
	[#Rule 314
		 'op_mod', 0, undef
	],
	[#Rule 315
		 'op_attribute', 1, undef
	],
	[#Rule 316
		 'op_type_spec', 1, undef
	],
	[#Rule 317
		 'op_type_spec', 1,
sub
#line 1975 "parser24.yp"
{
			new VoidType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 318
		 'parameter_dcls', 3,
sub
#line 1985 "parser24.yp"
{
			$_[2];
		}
	],
	[#Rule 319
		 'parameter_dcls', 2,
sub
#line 1989 "parser24.yp"
{
			undef;
		}
	],
	[#Rule 320
		 'parameter_dcls', 3,
sub
#line 1993 "parser24.yp"
{
			$_[0]->Error("parameters declaration expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 321
		 'param_dcls', 1,
sub
#line 2001 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 322
		 'param_dcls', 3,
sub
#line 2005 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 323
		 'param_dcls', 2,
sub
#line 2010 "parser24.yp"
{
			$_[0]->Warning("',' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 324
		 'param_dcls', 2,
sub
#line 2015 "parser24.yp"
{
			$_[0]->Error("';' unexpected.\n");
			[$_[1]];
		}
	],
	[#Rule 325
		 'param_dcl', 3,
sub
#line 2024 "parser24.yp"
{
			new Parameter($_[0],
					'attr'				=>	$_[1],
					'type'				=>	$_[2],
					'idf'				=>	$_[3]
			);
		}
	],
	[#Rule 326
		 'param_attribute', 1, undef
	],
	[#Rule 327
		 'param_attribute', 1, undef
	],
	[#Rule 328
		 'param_attribute', 1, undef
	],
	[#Rule 329
		 'raises_expr', 4,
sub
#line 2046 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 330
		 'raises_expr', 4,
sub
#line 2050 "parser24.yp"
{
			$_[0]->Error("name expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 331
		 'raises_expr', 2,
sub
#line 2055 "parser24.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 332
		 'exception_names', 1,
sub
#line 2063 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 333
		 'exception_names', 3,
sub
#line 2067 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 334
		 'exception_name', 1,
sub
#line 2075 "parser24.yp"
{
			Exception->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 335
		 'context_expr', 4,
sub
#line 2083 "parser24.yp"
{
			$_[3];
		}
	],
	[#Rule 336
		 'context_expr', 4,
sub
#line 2087 "parser24.yp"
{
			$_[0]->Error("string expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 337
		 'context_expr', 2,
sub
#line 2092 "parser24.yp"
{
			$_[0]->Error("'(' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 338
		 'string_literals', 1,
sub
#line 2100 "parser24.yp"
{
			[$_[1]];
		}
	],
	[#Rule 339
		 'string_literals', 3,
sub
#line 2104 "parser24.yp"
{
			unshift(@{$_[3]},$_[1]);
			$_[3];
		}
	],
	[#Rule 340
		 'param_type_spec', 1, undef
	],
	[#Rule 341
		 'param_type_spec', 1, undef
	],
	[#Rule 342
		 'param_type_spec', 1, undef
	],
	[#Rule 343
		 'param_type_spec', 1,
sub
#line 2119 "parser24.yp"
{
			TypeDeclarator->Lookup($_[0],$_[1]);
		}
	],
	[#Rule 344
		 'fixed_pt_type', 6,
sub
#line 2127 "parser24.yp"
{
			new FixedPtType($_[0],
					'value'				=>	$_[1],
					'd'					=>	$_[3],
					's'					=>	$_[5]
			);
		}
	],
	[#Rule 345
		 'fixed_pt_type', 6,
sub
#line 2135 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 346
		 'fixed_pt_type', 4,
sub
#line 2140 "parser24.yp"
{
			$_[0]->Error("Expression expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 347
		 'fixed_pt_type', 2,
sub
#line 2145 "parser24.yp"
{
			$_[0]->Error("'<' expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 348
		 'fixed_pt_const_type', 1,
sub
#line 2154 "parser24.yp"
{
			new FixedPtConstType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 349
		 'value_base_type', 1,
sub
#line 2164 "parser24.yp"
{
			new ValueBaseType($_[0],
					'value'				=>	$_[1]
			);
		}
	],
	[#Rule 350
		 'constr_forward_decl', 2,
sub
#line 2174 "parser24.yp"
{
			new ForwardStructType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 351
		 'constr_forward_decl', 2,
sub
#line 2180 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	],
	[#Rule 352
		 'constr_forward_decl', 2,
sub
#line 2185 "parser24.yp"
{
			new ForwardUnionType($_[0],
					'idf'				=>	$_[2]
			);
		}
	],
	[#Rule 353
		 'constr_forward_decl', 2,
sub
#line 2191 "parser24.yp"
{
			$_[0]->Error("Identifier expected.\n");
			$_[0]->YYErrok();
		}
	]
],
                                  @_);
    bless($self,$class);
}

#line 2197 "parser24.yp"


package Parser;

use strict;
use vars qw($IDL_version);
$IDL_version = '2.4';

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
