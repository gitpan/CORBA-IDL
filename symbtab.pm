use strict;

package Symbtab;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser) = @_;
	my $self = {};
	bless($self, $class);
	$self->{current_root} = '';
	$self->{current_scope} = '';
	$self->{parser} = $parser;
	# Symbol Table
	$self->{coll} = {};
	$self->{defn} = {};
	# Forward declaration Symbol Table
	$self->{fwd_coll} = {};
	$self->{fwd_defn} = {};
	# C Mapping
	$self->{c_mapping} = {};
	return $self;
}

sub _CheckCMapping {
	my $self = shift;
	my($g_name) = @_;

	my $c_key = $g_name;
	$c_key =~ s/^:://;
	$c_key =~ s/::/_/g;
	if (exists $self->{c_mapping}{$c_key}) {
		$self->{parser}->Info(
				"'$g_name' is ambiguous (C mapping) with '$self->{c_mapping}{$c_key}'.\n");
	} else {
		$self->{c_mapping}{$c_key} = $g_name
	}
}

sub _Insert {
	my $self = shift;
	my($g_name,$node) = @_;
#	print "_Insert $g_name\n";
	my $key = lc $g_name;
	$self->{coll}{$key} = $g_name;
	$self->{defn}{$key} = $node;
	return;
}

sub Insert {
	my $self = shift;
	my($name,$node) = @_;
#	print "Insert '$name' ",ref $node,"\n";
	delete $self->{msg} if (exists $self->{msg});
	my $scope = $self->{current_root} . $self->{current_scope};
	my $g_name = $scope . '::' . $name;
#	my $prev = $self->__Lookup($scope,$g_name,$name);
	my $prev = $self->___Lookup($g_name,$name);
	if (defined $prev) {
		my $class = ref $prev;
		if ($class =~ s/^Forward//) {
			if (ref $node ne $class) {
				$self->{parser}->Error(
						"Definition of '$name' conflicts with previous declaration.\n");
				return;
			} else {
				# the previous must be the same
				foreach (keys %{$prev}) {
					if (	   $_ eq 'coll'
							or $_ eq 'lineno'
							or $_ eq 'hash_attribute_operation' ) {
						next;
					}
					if (	   $_ eq 'repos_id'
							or $_ eq 'version' ) {
						$node->{$_} = $prev->{$_};
						next;
					}
					if ($_ eq 'filename') {
						if (	   $prev->isa('ForwardStruct')
								or $prev->isa('ForwardUnion') ) {
							if ($prev->{$_} ne $node->{$_}) {
								$self->{parser}->Error(
								"Definition of '$name' is not in the same file.\n");
								return;
							}
						}
						next;
					}
					if ($prev->{$_} ne $node->{$_}) {
						if ($_ eq 'prefix') {
							$self->{parser}->Error(
									"Prefix redefinition for '$name'.\n");
							next;
						}
						$self->{parser}->Error(
								"Definition of '$name' conflicts with previous declaration.\n");
						return;
					}
				}
			}
			$prev->{fwd} = $node;
		} else {
			$self->{msg} ||= "Identifier '$name' already exists.\n";
			$self->{parser}->Error($self->{msg}) if (! $node->isa('Dummy'));
			return;
		}
	}
	# insert
	my $key = lc $g_name;
	$self->{coll}{$key} = $g_name;
	$self->{defn}{$key} = $node;
	$node->{coll} = $g_name;
	$self->_CheckCMapping($g_name);
	return;
}

sub InsertForward {
	my $self = shift;
	my($name,$node) = @_;
#	print "InsertForward '$name' '$node->{idf}'\n";
	delete $self->{msg} if (exists $self->{msg});
	my $scope = $self->{current_root} . $self->{current_scope};
	my $g_name = $scope . '::' . $name;
	my $prev = $self->__Lookup($scope,$g_name,$name);
	if (defined $prev) {
		my $class = ref $prev;
		if ($class =~ /^Forward/) {
			# redeclaration
			if (ref $node ne $class) {
				$self->{parser}->Error(
						"Definition of '$name' conflicts with previous declaration.\n");
				return;
			} else {
				# the previous must be the same
				foreach (keys %{$prev}) {
					if (	   $_ eq 'coll'
							or $_ eq 'lineno'
							or $_ eq 'filename' ) {
						next;
					}
					if (	   $_ eq 'repos_id'
							or $_ eq 'version' ) {
						$node->{$_} = $prev->{$_};
						next;
					}
					if ($prev->{$_} ne $node->{$_}) {
						if ($_ eq 'prefix') {
							$self->{parser}->Error(
									"Prefix redefinition for '$name'.\n");
							next;
						}
						$self->{parser}->Error(
								"Definition of '$name' conflicts with previous declaration.\n");
						return;
					}
				}
			}
		} else {
			$self->{msg} ||= "Identifier '$name' already exists.\n";
			$self->{parser}->Error($self->{msg});
			return;
		}
	}
	# insert
	my $key = lc $g_name;
	$self->{fwd_coll}{$key} = $g_name;
	$self->{fwd_defn}{$key} = $node;
	$node->{coll} = $g_name;
	return;
}

sub OpenModule {
	my $self = shift;
	my($name,$node) = @_;
#	print "OpenModule '$name'\n";
	delete $self->{msg} if (exists $self->{msg});
	my $scope = $self->{current_root} . $self->{current_scope};
	my $g_name = $scope . '::' . $name;
	my $prev = $self->__Lookup($scope,$g_name,$name);
	if (defined $prev) {
		if ($prev->isa('Module')) {
			# reopen
			$node->{coll} = $g_name;
			return;
		} else {
			$self->{msg} ||= "Identifier '$name' already exists.\n";
			$self->{parser}->Error($self->{msg});
			return;
		}
	}
	# insert
	my $key = lc $g_name;
	$self->{coll}{$key} = $g_name;
	$self->{defn}{$key} = $node;
	$node->{coll} = $g_name;
	$self->_CheckCMapping($g_name);
	return;
}

sub ___Lookup {
	my $self = shift;
	my($g_name,$name) = @_;
	$name ||= $g_name;
#	print "___Lookup: '$g_name' '$name'\n";
	my $key = lc $g_name;
	if (exists $self->{coll}{$key}) {
		if ($self->{coll}{$key} ne $g_name) {
			$self->{msg} = "Identifier '$name' collides with '$self->{coll}{$key}'.\n";
		}
#		print "found ",ref $self->{defn}{$key},".\n";
		return $self->{defn}{$key};
	} elsif (exists $self->{fwd_coll}{$key}) {
		if ($self->{fwd_coll}{$key} ne $g_name) {
			$self->{msg} = "Identifier '$name' collides with '$self->{fwd_coll}{$key}'.\n";
		}
#		print "found (fwd) ",ref $self->{fwd_defn}{$key},".\n";
		return $self->{fwd_defn}{$key};
	} else {
#		print "not found.\n";
		return undef;
	}
}

sub __Lookup {
	my $self = shift;
	my($scope,$g_name,$name) = @_;
#	print "__Lookup: '$scope' '$g_name' '$name'\n";
	my $defn = $self->___Lookup($g_name,$name);
	if (defined $defn) {
		if ($defn->isa('Dummy')) {
			return $defn->{node};
		}
		return $defn;
	}
	my $node = $self->___Lookup($scope,$scope);
	if (defined $node and exists $node->{hash_inheritance}) {
		my @list;
		foreach (values %{$node->{hash_inheritance}}) {
			if (defined $_) {
				$g_name = $_->{coll} . '::' . $name;
				$defn = $self->___Lookup($g_name,$name);
				if ( 		defined $defn
						and ! $defn->isa('Dummy') ) {
					my $found = 0;
					foreach (@list) {
						if ($defn == $_) {
							$found = 1;
							last;
						}
					}
					push @list,$defn if (! $found);
				}
			}
		}
		if (@list) {
			if (@list > 1) {
				$self->{parser}->Error("Ambiguous symbol '$name'.\n");
			}
			return $list[0];
		}
	}
	return undef;
}

sub _Lookup {
	my $self = shift;
	my($name) = @_;
	my $defn;
#	print "_Lookup: '$name'\n";
	if ($name =~ /^::/) {
		# global name
#		print "global name.\n";
		return $self->___Lookup($name);
	} elsif ($name =~ /^[0-9A-Z_a-z]+$/) {
		# identifier alone
		my $scope_init = $self->{current_root} . $self->{current_scope};
		my $scope = $scope_init;
#		print "Lookup init : '$scope'\n";
		while (1) {
			# Section 3.15.3 Special Scoping Rules for Type Names
			my $g_name = $scope . '::' . $name;
			$defn = $self->__Lookup($scope,$g_name,$name);
			last if (defined $defn || $scope eq '');
			$scope =~ s/::[0-9A-Z_a-z]+$//;
#			print "Lookup curr : '$scope'\n";
		};
		if (defined $defn) {
			while ($scope_init ne $scope) {
				my $node = $self->___Lookup($scope_init);
				if (! $node->isa('Module') ) {
					$self->_Insert($scope_init . '::' . $name,$defn);
				}
				$scope_init =~ s/::[0-9A-Z_a-z]+$//;
			}
		}
		return $defn;
	} else {
		# qualified name
		my @list = split /::/,$name;
		my $idf = pop @list;
		my $scoped_name = $name;
		$scoped_name =~ s/::[0-9A-Z_a-z]+$//;
#		print "qualified name : '$scoped_name' '$idf'\n";
		my $scope = $self->_Lookup($scoped_name);		# recursive
		if (defined $scope) {
			$defn = $self->___Lookup($scope->{coll} . '::' . $idf);
		}
		return $defn;
	}
}

sub Lookup {
	my $self = shift;
	my($name) = @_;
	delete $self->{msg} if (exists $self->{msg});
	my $defn = $self->_Lookup($name);
	if (defined $defn) {
		$self->{parser}->Error($self->{msg}) if (exists $self->{msg});
	} else {
		$self->{parser}->Error("Undefined symbol '$name'.\n");
	}
	return $defn;
}

sub CheckForward {
	my $self = shift;
	foreach (keys %{$self->{fwd_coll}}) {
		if (! exists $self->{fwd_defn}{$_}->{fwd}) {
			$self->{parser}->Error("'$self->{fwd_coll}{$_}' never defined.\n");
		}
	}
}

sub PragmaID {							#	10.6.5.1	The ID Pragma
	my $self = shift;
	my($name,$id) = @_;
#	$name =~ s/_//g;
	my $node = $self->Lookup($name);
	if (defined $node) {
		if (exists $node->{repos_id}) {
			$self->{parser}->Error("Repository ID redefinition for '$name'.\n")
					unless ($id eq $node->{repos_id});
		} else {
			$node->{repos_id} = $id;
			if ($id =~ /^IDL:/) {
				#	10.6.1		OMG IDL Format
				if ($id =~ /^IDL:[0-9A-Za-z_:\.\/\-]+:([0-9]+)\.([0-9]+)/) {
					my $version = $1 . '.' . $2;
					if (exists $node->{version}) {
						$self->{parser}->Error("Version redefinition for '$name'.\n")
								unless ($version eq $node->{version});
					} else {
						$node->{version} = $version;
					}
				} else {
					$self->{parser}->Error("Bad IDL format for Repository ID '$id'.\n");
				}
			} elsif ($id =~ /^RMI:/) {
				#	10.6.2		RMI Hashed Format
				# TODO
			} elsif ($id =~ /^DCE:/) {
				#	10.6.3		DCE UUID Format
				$self->{parser}->Error("Bad DCE format for Repository ID '$id'.\n")
						unless ($id =~ /^DCE:[0-9A-Fa-f\-]+:[0-9]+/);
			} elsif ($id =~ /^LOCAL:/) {
				# 	10.6.4		LOCAL Format
				# followed by an arbitrary string.
			}
		}
	}
}

sub PragmaPrefix {						#	10.6.5.2	The Prefix Pragma
	my $self = shift;
	my($prefix) = @_;
	my $key = $self->{parser}->YYData->{filename} . $self->{current_root} . $self->{current_scope};
	$self->{prefix}->{$key} = $prefix;
}

sub GetPrefix {
	my $self = shift;
	my $key = $self->{parser}->YYData->{filename} . $self->{current_root} . $self->{current_scope};
	return $self->{prefix}->{$key} if (exists $self->{prefix}->{$key});
	return "";
}

sub PragmaVersion {						#	10.6.5.3	The Version Pragma
	my $self = shift;
	my($name,$major,$minor) = @_;
#	$name =~ s/_//g;
	my $version = $major . '.' . $minor;
	my $node = $self->Lookup($name);
	if (defined $node) {
		if (exists $node->{version}) {
			$self->{parser}->Error("Version redefinition for '$name'.\n")
					unless ($version eq $node->{version});
		} else {
			$node->{version} = $version;
		}
	}
}

sub Dump {
	my $self = shift;
	print "Symbole Table:\n";
	foreach (sort keys %{$self->{coll}}) {
		my $node = $self->{defn}{$_};
		my $lineno = $node->{lineno} || "";
		print $lineno,"\t",$self->{coll}{$_},"\t\t",ref $node,"\n";
	}
	print "ForwardSymbole Table:\n";
	foreach (sort keys %{$self->{fwd_coll}}) {
		my $node = $self->{fwd_defn}{$_};
		my $lineno = $node->{lineno} || "";
		print $lineno,"\t",$self->{fwd_coll}{$_},"\t\t",ref $node,"\n";
	}
	print "\n";
	return;
}

sub PushCurrentRoot {
	my $self = shift;
	my($node) = @_;
	my $key = $self->{parser}->YYData->{filename} . $self->{current_root};
	my $prefix = $self->{prefix}->{$key};
	if ($prefix) {
		$prefix .= '/' . $node->{idf};
	} else {
		$prefix = $node->{idf};
	}
	$self->{current_root} .= '::' . $node->{idf};
	$key .= '::' . $node->{idf};
	$self->{prefix}->{$key} = $prefix;
	return;
}

sub PopCurrentRoot {
	my $self = shift;
	my($node) = @_;
	return if ($self->{current_root} =~ s/::$node->{idf}$//);
#	$self->{current_root} =~ s/::[0-9A-Z_a-z]+$//;
	$self->{parser}->Error(
			"PopCurrentRoot: INTERNAL_ERROR $self->{current_root} $node->{idf}.\n");
	return;
}

sub PushCurrentScope {
	my $self = shift;
	my($node) = @_;
	my $key = $self->{parser}->YYData->{filename} . $self->{current_root} . $self->{current_scope};
	my $prefix = $self->{prefix}->{$key};
	if ($prefix) {
		$prefix .= '/' . $node->{idf};
	} else {
		$prefix = $node->{idf};
	}
	$self->{current_scope} .= '::' . $node->{idf};
	$key .= '::' . $node->{idf};
	$self->{prefix}->{$key} = $prefix;
	return;
}

sub PopCurrentScope {
	my $self = shift;
	my($node) = @_;
	return if ($self->{current_scope} =~ s/::$node->{idf}$//);
#	$self->{current_scope} =~ s/::[0-9A-Z_a-z]+$//;
	$self->{parser}->Error(
			"PopCurrentScope: INTERNAL_ERROR $self->{current_scope} $node->{idf}.\n");
	return;
}

#
#
#

package UnnamedSymbtab;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my($parser) = @_;
	my $self = {};
	bless($self, $class);
	$self->{parser} = $parser;
	$self->{coll} = {};
	return $self;
}

sub Insert {
	my $self = shift;
	my($name) = @_;
#	print "Insert '$name'\n";
	my $key = lc $name;
	if (exists $self->{coll}{$key}) {
		if ($self->{coll}{$key} eq $name) {
			$self->{parser}->Error(
					"Identifier '$name' already exists.\n");
		} else {
			$self->{parser}->Error(
					"Identifier '$name' collides with '$self->{coll}{$key}'.\n");
		}
	} else {
		$self->{coll}{$key} = $name;
	}
	return;
}

sub InsertUsed {
	my $self = shift;
	my($name) = @_;
#	print "InsertUsed '$name'\n";
	my $key = lc $name;
	$self->{coll}{$key} = $name if (! exists $self->{coll}{$key});
	return;
}

1;

