#
# Copyright 2016 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Written by John Wu (jwu@web.com)
# 2018-06-13

package hardware::server::cisco::ucce::mode::pg_agents;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Data::Dumper;

my %indexes = (
    AgentsLoggedOn => '8.1',
    AgentsReady => '9.1',
    AgentsTalking => '10.1',
);

my $oid_cccaPgAgents = '.1.3.6.1.4.1.9.9.473.1.3.5.1';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
        }
    );
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $result = $self->{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cccaPgAgents },
        ],
        nothing_quit => 1,
    );
    #print Data::Dumper->Dump([\$result],[qw(*result)]);

    my %totals = ();
    foreach my $key (keys %{$result->{$oid_cccaPgAgents}}) {
	if ( $key =~ $indexes{'AgentsLoggedOn'} ) {
           $totals{$indexes{'AgentsLoggedOn'}} += $result->{$oid_cccaPgAgents}->{$key};
	} elsif ( $key =~ $indexes{'AgentsReady'} ) {
           $totals{$indexes{'AgentsReady'}} += $result->{$oid_cccaPgAgents}->{$key};
	} elsif ( $key =~ $indexes{'AgentsTalking'} ) {
           $totals{$indexes{'AgentsTalking'}} += $result->{$oid_cccaPgAgents}->{$key};
	}
    }
    foreach my $key ( keys %indexes ) {
        $self->{output}->output_add(
            short_msg => sprintf("%s: %d", $key, $totals{$indexes{$key}}),
        );
        $self->{output}->perfdata_add(
            label => $key,
            value => $totals{$indexes{$key}},
        );
    }
    #print Data::Dumper->Dump([\%totals],[qw(*totals)]);
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Agents Statuses

=back

=cut
