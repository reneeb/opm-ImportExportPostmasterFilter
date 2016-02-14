# --
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::PostmasterFilter::Import;

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

    $Self->Description('Import PostMaster filter configuration');

    $Self->AddOption(
        Name        => 'file',
        Description => "Read the configuration from that file",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );


    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Import PostMaster filter configuration...</yellow>\n");

    my $UtilObject = $Kernel::OM->Get('Kernel::System::PostMaster::ImportExport');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $File       = $Self->GetOption('file');
    my $ContentRef = $MainObject->FileRead(
        Location => $File,
        Mode     => 'utf-8',
    );

    $UtilObject->PostmasterFilterImport(
        Filters => ${$ContentRef},
        UserID  => 1,
    );

    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
