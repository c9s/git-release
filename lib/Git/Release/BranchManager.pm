package Git::Release::BranchManager;
use warnings;
use strict;
use Moose;

has manager => ( is => 'rw', isa => 'Git::Release' );


sub _parse_branches { 
    my $self = shift;
    my @list = grep { ! /HEAD/ } $self->manager->repo->command( 'branch' , '-a' );
    chomp @list;

    # strip spaces
    map { s{^\*?\s*}{}g } @list;
    return @list;
}

sub local_branches { 
    my $self = shift;
    my @list = grep !/^remotes/, $self->_parse_branches;
    return map { $self->new_branch( ref => $_ ) } @list;
}

sub remote_branches {
    my $self = shift;
    my @list = grep /^remotes/,$self->_parse_branches;

    # remove remtoes names, strip star char.
    return map { $self->new_branch( ref => $_ ) } @list;
}

sub find_local_branches {
    my ( $self, $name ) = @_;
    my @branches = $self->local_branches;
    if ( ref $name eq 'RegExp' ) {
        @branches = grep { $_->name =~ $name } @branches;
    } else {
        @branches = grep { $_->name eq $name } @branches;
    }
    return @branches if wantarray;
    return $branches[0];
}

sub find_remote_branches {
    my ( $self, $name ) = @_;
    my @branches = $self->remote_branches;
    if ( ref $name eq 'RegExp' ) {
        @branches = grep { $_->name =~ $name } @branches;
    } else {
        @branches = grep { $_->name eq $name } @branches;
    }
    return @branches if wantarray;
    return $branches[0];
}

sub current {
    my $self = shift;
    my $name = $self->current_name;
    return $self->new_branch( ref => $name );
}

sub current_name { 
    my $self = shift;
    my $name = $self->manager->repo->command('rev-parse','--abbrev-ref','HEAD');
    chomp( $name );
    return $name;
}

sub ready_branches { 
    my $self = shift;
    my $prefix = $self->manager->config->ready_prefix;
    my @branches = $self->remote_branches;
    return grep { $_->name =~ /^$prefix/ } @branches;
}

sub new_branch { 
    my $self = shift;
    my %args;
    %args = @_ if @_ > 1;
    %args = (ref => $_[0]) if @_ == 1;
    my $branch = Git::Release::Branch->new(  
            %args, manager => $self->manager );
    return $branch;
}

sub find_local_or_remote_branches { 
    my ($self,$name) = @_;
    my @branches = ( $self->find_local_branches( $name ), $self->find_remote_branches( $name ) );
    return @branches if wantarray;
    return $branches[0];
}

sub develop { 
    return $_[0]->find_local_or_remote_branches('develop'); 
}

sub master { 
    return $_[0]->find_local_or_remote_branches('master'); 
}

1;
