# --
# Kernel/System/PostMaster/ImportExport.pm - Utility module for PostMasters provided by Perl-Services.de
# Copyright (C) 2013 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PostMaster::ImportExport;

use strict;
use warnings;

use JSON;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::DB
    Kernel::System::JSON
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');

    # get the cache TTL (in seconds)
    $Self->{CacheTTL} = int( $ConfigObject->Get('PostMaster::CacheTTL') || 3600 );

    # set lower if database is case sensitive
    $Self->{Lower} = '';
    if ( !$DBObject->GetDatabaseFunction('CaseInsensitive') ) {
        $Self->{Lower} = 'LOWER';
    }

    if ( $Self->_OTRSVersionGet() >= 3.3 ) {
        $Self->{f_not} = 1;
    }

    return $Self;
}

sub PostmasterFilterExport {
    my ($Self, %Param) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');

    my $FNot = '';
    if ( $Self->{f_not} ) {
        $FNot = ', f_not';
    }

    my $SQL = "SELECT f_name, f_stop, f_type, f_key, f_value $FNot "
        . ' FROM postmaster_filter';

    my @Bind;
    if ( $Param{IDs} && ref $Param{IDs} eq 'ARRAY' && @{$Param{IDs}} ) {
        my $Placeholder = join ', ', ('?') x @{$Param{IDs}};

        $SQL .= ' WHERE f_name IN( ' . $Placeholder . ')';
        @Bind = map{ \$_ }@{$Param{IDs}};
    }

    return '{}' if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    my %Filters;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Filter = (
            Type  => $Row[2],
            Key   => $Row[3],
            Value => $Row[4],
            Not   => $Row[5] ? 1 : 0,
        );

        $Filters{$Row[0]}->{Stop} = $Row[1];
        push @{$Filters{$Row[0]}->{Entries}}, \%Filter;
    }

    my @AllFilters;
    for my $Name ( sort keys %Filters ) {
        push @AllFilters, {
            Name => $Name,
            %{ $Filters{$Name} },
        },
    }

    my %ExportData = (
        Version => 1,
        Filters => \@AllFilters,
    );

    my $JSON = $JSONObject->Encode(
        Data => \%ExportData,
    ); 

    return $JSON;
}

sub PostmasterFilterImport {
    my ($Self, %Param) = @_;

    my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    for my $Needed ( qw(Filters) ) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $DoOverride = $ConfigObject->Get( 'PostmasterFilterImport::DoOverride' );

    my $Filters;
    eval {
        #$Filters = $JSONObject->Decode(
        #    Data => $Param{Filters},
        #);
        $Filters = JSON->new->allow_nonref(1)->utf8(1)->decode( $Param{Filters} );
    };

    return if !$Filters;

    $Filters = $Self->_HandleByVersion( Filters => $Filters );

    my ($FNot, $Placeholder) = ('','');
    if ( $Self->{f_not} ) {
        $FNot        = ', f_not';
        $Placeholder = ', ?';
    }

    my $InsertSQL = 'INSERT INTO postmaster_filter ('
        . "f_name, f_stop, f_type, f_key, f_value $FNot) "
        . " VALUES (?, ?, ?, ?, ? $Placeholder )";

    my $CheckSQL  = "SELECT f_name FROM postmaster_filter WHERE f_name = ?";

    my $DeleteSQL = 'DELETE FROM postmaster_filter WHERE f_name = ?';

    FILTER:
    for my $Filter ( keys %{$Filters} ) {

        next FILTER if ref $Filters->{$Filter} ne 'ARRAY';
        next FILTER if !@{ $Filters->{$Filter} };

        next FILTER if !$DBObject->Prepare(
            SQL   => $CheckSQL,
            Bind  => [ \$Filter ],
            Limit => 1,
        );

        my $Name;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $Name = $Row[0];
        }

        next FILTER if $Name && !$DoOverride;

        if ( $Name ) {
            next FILTER if !$DBObject->Do(
                SQL  => $DeleteSQL,
                Bind => [ \$Filter ],
            );
        } 

        for my $Part ( @{ $Filters->{$Filter} } ) {
            next FILTER if !$DBObject->Do(
                SQL  => $InsertSQL,
                Bind => [
                    \$Filter,
                    \$Part->{Stop},
                    \$Part->{Type},
                    \$Part->{Key},
                    \$Part->{Value},
                    ($Self->{f_not} ? \$Part->{Not} : ()),
                ],
            );
        }
    }

    return 1;
}

sub _HandleByVersion {
    my ($Self, %Param) = @_;

    my $Filters = $Param{Filters};

    return if !$Filters;               # anything went wrong
    return if !ref $Filters;           # anything went wrong, we need a reference
    return if ref $Filters ne 'HASH';  # anything went wrong

    # handle version 0
    if ( !exists $Filters->{Version} || ref $Filters->{Version} ) {
        return $Filters;
    }

    # handle version 1
    if ( $Filters->{Version} == 1 ) {
        my %ImportFilters;

        for my $Filter ( @{ $Filters->{Filters} || [] } ) {
            my $Name = $Filter->{Name};
            my $Stop = $Filter->{Stop};

            my @Entries = map {
                $_->{Stop} = $Stop;
                $_->{Not}  = undef if !$_->{Not};
                $_;
            } @{ $Filter->{Entries} || [] };

            $ImportFilters{$Name} = \@Entries;
        }

        return \%ImportFilters;
    }

    return;
}

sub _OTRSVersionGet {
    my ($Self) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Version    = $ConfigObject->Get( 'Version' );
    my ($MajorMin) = $Version =~ m{(\d+\.\d+)};

    return $MajorMin;
}

1;
