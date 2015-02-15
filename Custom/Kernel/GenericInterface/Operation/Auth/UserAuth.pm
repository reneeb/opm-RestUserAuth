# --
# Kernel/GenericInterface/Operation/Auth/UserAuth.pm - GenericInterface UserAuth operation backend
# Copyright (C) 2015 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Operation::Auth::UserAuth;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsStringWithData IsHashRefWithData);

use base qw(
    Kernel::GenericInterface::Operation::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Operation::Ticket::UserAuth - GenericInterface Auth Create Operation backend

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Operation->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (
        qw(DebuggerObject WebserviceID)
        )
    {
        if ( !$Param{$Needed} ) {

            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=item Run()

Retrieve a new session id value.

    my $Result = $OperationObject->Run(
        Data => {
            UserLogin => 'Agent1',
            Password  => 'some password',   # plain text password
        },
    );

    $Result = {
        Success      => 1,                                # 0 or 1
        ErrorMessage => '',                               # In case of an error
        Data => {
            UserName => '',
            Groups   => [
                'Group1',
                'Group2',
            ],
        },
    };

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !IsHashRefWithData( $Param{Data} ) ) {

        return $Self->ReturnError(
            ErrorCode    => 'UserAuth.MissingParameter',
            ErrorMessage => "UserAuth: The request is empty!",
        );
    }

    for my $Needed (qw( Password UserLogin )) {
        if ( !$Param{Data}->{$Needed} ) {

            return $Self->ReturnError(
                ErrorCode    => 'UserAuth.MissingParameter',
                ErrorMessage => "UserAuth: $Needed parameter is missing!",
            );
        }
    }

    my $AuthResult = $Self->Auth(
        %Param,
    );

    if ( !$AuthResult ) {

        return $Self->ReturnError(
            ErrorCode    => 'UserAuth.AuthFail',
            ErrorMessage => "UserAuth: Authorization failing!",
        );
    }

    return {
        Success => 1,
        Data    => $AuthResult,
    };
}

=item Auth()

performs user authentication and return a new SessionID value

    my $Result = $CommonObject->CreateSessionID(
        Data {
            UserLogin => 'Agent1',
            Password  => 'some password',   # plain text password
        }
    );

Returns undef on failure or

    $Result = {
        UserName => 'User Name',
        Groups   => [
            'Group1',
        ],
    }

=cut

sub Auth {
    my ( $Self, %Param ) = @_;

    # get params
    my $PostPw = $Param{Data}->{Password} || '';

    # if UserLogin
    my $PostUser = $Param{Data}->{UserLogin} || '';

    # check submitted data
    my $User = $Kernel::OM->Get('Kernel::System::Auth')->Auth(
        User => $PostUser,
        Pw   => $PostPw,
    );

    my %UserData = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        User  => $User,
        Valid => 1,
    );

    # login is invalid
    return if !$User;

    my %Groups;

    # get groups rw/ro
    for my $Type (qw(rw ro)) {
        my %GroupData = $Kernel::OM->Get('Kernel::System::Group')->GroupMemberList(
            Result => 'HASH',
            Type   => $Type,
            UserID => $UserData{UserID},
        );

        for ( sort keys %GroupData ) {
            $Groups{ $GroupData{$_} } = 1;
        }
    }

    return +{
        UserName => $UserData{UserFullname},
        Groups   => [ sort keys %Groups ],
    };
}


1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
