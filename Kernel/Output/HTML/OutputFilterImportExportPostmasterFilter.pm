# --
# Kernel/Output/HTML/OutputFilterImportExportPostmasterFilter.pm
# Copyright (C) 2014 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterImportExportPostmasterFilter;

use strict;
use warnings;

use List::Util qw(first);

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (
        qw(MainObject ConfigObject LogObject LayoutObject ParamObject)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;

    return 1 if !first{ $Templatename eq $_ }keys %{$Param{Templates} || { AdminPostMasterFilter => 1 } };

    my $Name = $Self->{ParamObject}->GetParam( Param => 'Name' );

    if ( !$Name ) {
        $Self->{LayoutObject}->Block(
            Name => 'Import',
        );
    }

    my $Snippet = $Self->{LayoutObject}->Output(
        TemplateFile => 'ImportExportPostmasterFilterWidget',
        Data         => {
            Name => $Name,
        },
    );

    ${ $Param{Data} } =~ s{(</div> \s+ <div \s+ class="ContentColumn">)}{$Snippet $1}mxs;

    return ${ $Param{Data} };
}

1;
