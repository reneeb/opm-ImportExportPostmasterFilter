# --
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::PostmasterFilter::Export;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Main
    Kernel::System::PostMaster::ImportExport
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Export DynamicField configuration');
    $Self->AddOption(
        Name        => 'filter',
        Description => "Name of the filter that should be exported.",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddOption(
        Name        => 'file',
        Description => "Write the configuration to that file",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );


    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Export PostmasterFilter configuration...</yellow>\n");

    my $UtilObject = $Kernel::OM->Get('Kernel::System::PostMaster::ImportExport');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my @Names = @{ $Self->GetOption('filter') || [] };
    my $JSON = $UtilObject->PostmasterFilterExport(
        IDs => \@Names,
    );

    my $File = $Self->GetOption('file');
    if ( !$File ) {
        print $JSON;
    }
    else {
        $MainObject->FileWrite(
            Location => $File,
            Content  => \$JSON,
            Mode     => 'utf-8',
        );
    }

    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
