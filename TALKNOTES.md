
With a practically empty nexus3_repository.rb type file, this is what we get with `puppet resource`:

```
$ RUBYLIB=$(pwd)/lib puppet resource nexus3_repository --debug
Debug: Runtime environment: puppet_version=3.8.4, ruby_version=2.0.0, run_mode=user, default_encoding=UTF-8
Error: Could not run: nexus3_repository has no providers and has not overridden 'instances'
```

And this for `puppet apply`:

```
$ RUBYLIB=$(pwd)/lib puppet apply -e "nexus3_repository {'blah': }"
Notice: Compiled catalog for tcinel.home.timcinel.com in environment production in 0.01 seconds
Error: No set of title patterns matched the title "blah".
```

* * *

Now, with a namevar specified in the type class, `puppet apply` works:

```
$ RUBYLIB=$(pwd)/lib puppet apply -e "nexus3_repository {'blah': }"
Notice: Compiled catalog for tcinel.home.timcinel.com in environment production in 0.01 seconds
Notice: Finished catalog run in 0.03 seconds
```

* * *

Made nexus3_repository ensurable, which breaks puppet apply again:

```
$ RUBYLIB=$(pwd)/lib puppet apply -e "nexus3_repository {'blah': }"
Notice: Compiled catalog for tcinel.home.timcinel.com in environment production in 0.01 seconds
Error: /Stage[main]/Main/Nexus3_repository[blah]: Could not evaluate: No ability to determine if nexus3_repository exists
Notice: Finished catalog run in 0.03 seconds
```

* * *

Before implementing the provider, we refactored the utility classes so they can be conveniently used by a provider.

* * *

Implemented bare minimum required to use 'puppet resource' in the nexus3_repository provider. It works now:

```
▶ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_repository
nexus3_repository { 'blahblah':
  ensure => 'present',
}
nexus3_repository { 'maven-releases':
  ensure => 'present',
}
nexus3_repository { 'maven-snapshots':
  ensure => 'present',
}
```

* * *

Implemented create and destroy methods in the provider

```
$ RUBYLIB=$(pwd)/lib puppet apply -e "nexus3_repository {'zigzug': ensure => present }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.03 seconds
Notice: /Stage[main]/Main/Nexus3_repository[zigzug]/ensure: created
Notice: Finished catalog run in 0.19 seconds

$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_repository --debug
Debug: Runtime environment: puppet_version=3.8.4, ruby_version=2.0.0, run_mode=user, default_encoding=UTF-8
nexus3_repository { 'blahblah':
  ensure => 'present',
}
nexus3_repository { 'maven-releases':
  ensure => 'present',
}
nexus3_repository { 'maven-snapshots':
  ensure => 'present',
}
nexus3_repository { 'zigzug':
  ensure => 'present',
}

$ RUBYLIB=$(pwd)/lib puppet apply -e "resources { 'nexus3_repository': purge => true } nexus3_repository {'zigzug': ensure => present }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.06 seconds
Notice: /Stage[main]/Main/Nexus3_repository[maven-snapshots]/ensure: removed
Notice: /Stage[main]/Main/Nexus3_repository[maven-releases]/ensure: removed
Notice: /Stage[main]/Main/Nexus3_repository[zigzug]/ensure: created
Notice: /Stage[main]/Main/Nexus3_repository[blahblah]/ensure: removed
Notice: Finished catalog run in 0.21 seconds

$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_repository --debug
Debug: Runtime environment: puppet_version=3.8.4, ruby_version=2.0.0, run_mode=user, default_encoding=UTF-8
nexus3_repository { 'zigzug':
  ensure => 'present',
}
```

* * *

But I forgot to add prefetch so Puppet would try to recreate repos that were already there.
Fixed now:

```
$ RUBYLIB=$(pwd)/lib puppet apply -e "resources { 'nexus3_repository': purge => true }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.02 seconds
Notice: /Stage[main]/Main/Nexus3_repository[zigzug]/ensure: removed
Notice: Finished catalog run in 0.07 seconds

$ RUBYLIB=$(pwd)/lib puppet apply -e "resources { 'nexus3_repository': purge => true } nexus3_repository {'zigzug': ensure => present }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.06 seconds
Notice: /Stage[main]/Main/Nexus3_repository[zigzug]/ensure: created
Notice: Finished catalog run in 0.14 seconds

$ RUBYLIB=$(pwd)/lib puppet apply -e "resources { 'nexus3_repository': purge => true } nexus3_repository {'zigzug': ensure => present }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.06 seconds
Notice: Finished catalog run in 0.04 seconds
```

* * *

Added a new 'online' property to the nexus3_repository type.

Had to introduce flushing and munging for this to work properly.

# repo is currently online
$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_repository
nexus3_repository { 'zigzug':
  ensure => 'present',
  online => 'true',
}

# changes from online to offline
$ RUBYLIB=$(pwd)/lib puppet apply -e "resources { 'nexus3_repository': purge => true } nexus3_repository {'zigzug': ensure => present, online => false }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.06 seconds
Notice: /Stage[main]/Main/Nexus3_repository[zigzug]/online: online changed 'true' to 'false'
Notice: Finished catalog run in 0.07 seconds

# doesn't attempt to change it again
$ RUBYLIB=$(pwd)/lib puppet apply -e "resources { 'nexus3_repository': purge => true } nexus3_repository {'zigzug': ensure => present, online => false }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.06 seconds
Notice: Finished catalog run in 0.06 seconds

# repo is currently offline
$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_repository
nexus3_repository { 'zigzug':
  ensure => 'present',
  online => 'false',
}

* * *

Added a new 'blobstore' property to the nexus3_repository type.

This property is immutable, making things mildly interesting.

```
# no repositories
▶ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_repository

# create a new repository with a different blobstore
▶ RUBYLIB=$(pwd)/lib puppet apply -e "resources { 'nexus3_repository': purge => true } nexus3_repository {'zigzug': ensure => present, online => true, blobstore => 'zuperduper', }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.08 seconds
Notice: /Stage[main]/Main/Nexus3_repository[zigzug]/ensure: created
Notice: Finished catalog run in 0.16 seconds

# new blobstore is being used
$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_repository
nexus3_repository { 'zigzug':
  ensure    => 'present',
  blobstore => 'zuperduper',
  online    => 'true',
}

# attempt and fail to change blobstore
$ RUBYLIB=$(pwd)/lib puppet apply -e "resources { 'nexus3_repository': purge => true } nexus3_repository {'zigzug': ensure => present, online => true, blobstore => 'default', }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.06 seconds
Error: blobstore property is immutable
Error: /Stage[main]/Main/Nexus3_repository[zigzug]/blobstore: change from zuperduper to default failed: blobstore property is immutable
Notice: Finished catalog run in 0.06 seconds
```

* * *

Added a nexus3_blobstore type and provider

```
# no blobstores
▶ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_blobstore


# create a blobstore
$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet apply -e "resources { 'nexus3_blobstore': purge => true } nexus3_blobstore {'flubber': ensure => present, path => '/nexus-data/blobs/flubber' }"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.07 seconds
Notice: /Stage[main]/Main/Nexus3_blobstore[flubber]/ensure: created
Notice: Finished catalog run in 0.07 seconds

# there's a blobstore now
$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet resource nexus3_blobstorenexus3_blobstore { 'flubber':
  ensure => 'present',
  type   => 'File',
}

# kill the blobstore
$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib puppet apply -e "resources { 'nexus3_blobstore': purge => true }"Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.02 seconds
Notice: /Stage[main]/Main/Nexus3_blobstore[flubber]/ensure: removed
Notice: Finished catalog run in 0.07 seconds
```

* * *

However I was using deep_merge was wrong and breaking everything horribly. Have removed it.

* * *

Added glorious autorequire. Now blobstores are created before dependent repos.

```
# create a bunch of repositories and blobstores in no particular order
# puppet creates dependencies first, noice. unfortunately the resolver doesn't
# work backwards for destruction :'(
$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib \
puppet apply -e "
resources { 'nexus3_repository': purge => true }
resources { 'nexus3_blobstore': purge => true }

nexus3_repository {'repo1': ensure => present, online => true, blobstore => 'flubber', }
nexus3_repository {'repo2': ensure => present, online => true, blobstore => 'flubber', }
nexus3_repository {'repo3': ensure => present, online => false, blobstore => 'ooze', }
nexus3_repository {'repo4': ensure => present, online => false, blobstore => 'default', }

nexus3_blobstore {'flubber': ensure => present, path => '/nexus-data/blobs/flubber' }
nexus3_blobstore {'ooze': ensure => present, path => '/nexus-data/blobs/ooze' }
nexus3_blobstore {'default': ensure => present, path => '/nexus-data/blobs/default' }
"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.09 seconds
Notice: /Stage[main]/Main/Nexus3_repository[repo4]/ensure: created
Notice: /Stage[main]/Main/Nexus3_repository[repo2]/ensure: created
Notice: /Stage[main]/Main/Nexus3_repository[repo1]/ensure: created
Notice: /Stage[main]/Main/Nexus3_blobstore[ooze]/ensure: created
Notice: /Stage[main]/Main/Nexus3_blobstore[yetanotherblob]/ensure: removed
Notice: /Stage[main]/Main/Nexus3_blobstore[anotherblob]/ensure: removed
Notice: /Stage[main]/Main/Nexus3_repository[repo3]/ensure: created
Notice: Finished catalog run in 0.56 seconds

# reapply same manifest - no changes. yipee!
$ RUBYLIB=/Users/tcinel/build/puppet-camp/lib \
puppet apply -e "
resources { 'nexus3_repository': purge => true }
resources { 'nexus3_blobstore': purge => true }

nexus3_repository {'repo1': ensure => present, online => true, blobstore => 'flubber', }
nexus3_repository {'repo2': ensure => present, online => true, blobstore => 'flubber', }
nexus3_repository {'repo3': ensure => present, online => false, blobstore => 'ooze', }
nexus3_repository {'repo4': ensure => present, online => false, blobstore => 'default', }

nexus3_blobstore {'flubber': ensure => present, path => '/nexus-data/blobs/flubber' }
nexus3_blobstore {'ooze': ensure => present, path => '/nexus-data/blobs/ooze' }
nexus3_blobstore {'default': ensure => present, path => '/nexus-data/blobs/default' }
"
Notice: Compiled catalog for tcinel.office.atlassian.com in environment production in 0.12 seconds
Notice: Finished catalog run in 0.09 seconds

```

* * *
