# Class:: gitlab::gitolite inherits gitlab::pre
#
#
class gitlab::gitolite inherits gitlab::pre {
  file {
    '/var/cache/debconf/gitolite.preseed':
      ensure  => file,
      content => template('gitlab/gitolite.preseed.erb'),
      before  => Exec['install gitolite'];
    "${git_home}/${git_user}.pub":
      ensure  => file,
      owner   => $git_user,
      group   => $git_user,
      mode    => '0644',
      require => User[$git_user];
    "${git_home}/.gitolite.rc":
      ensure  => file,
      source  => 'puppet:///modules/gitlab/gitolite-rc',
      owner   => $git_user,
      group   => $git_user,
      mode    => '0644',
      require => [Exec['install gitolite'],User[$git_user]];
    "${git_home}/.gitolite/hooks/common/post-receive":
      ensure  => file,
      source  => 'puppet:///modules/gitlab/post-receive',
      owner   => $git_user,
      group   => $git_user,
      mode    => '0755',
      require => [Exec['gl-setup gitolite'],User[$git_user]];
    "${git_home}/.gitconfig":
      ensure  => file,
      content => template('gitlab/gitolite.gitconfig.erb'),
      owner   => $git_user,
      group   => $git_user,
      mode    => '0644',
      require => User[$git_user];
    "${git_home}/.profile":
      ensure => file,
      source => 'puppet:///modules/gitlab/git_user-dot-profile',
      owner  => $git_user,
      group  => $git_user,
      mode   => '0644',
      notify => Exec['gl-setup gitolite'];
  }

  exec {
    'clone gitolite':
      command     => "git clone -b gl-v304 https://github.com/gitlabhq/gitolite.git ${git_home}/gitolite",
      user        => $git_user,
      require     => [File["${git_home}/.gitconfig"],File["${git_home}/${git_user}.pub"]],
      path        => '/usr/bin/',
      refreshonly => true;
    'install gitolite':
      command     => "${git_home}/gitolite/install -ln ${git_home}/bin",
      user        => $git_user,
      require     => Exec['clone gitolite'],
      logoutput   => 'on_failure',
      refreshonly => true;
    'gl-setup gitolite':
      command     => "${git_home}/bin/gitolite setup -pk ${git_home}/${git_user}.pub",
      user        => $git_user,
      require     => [Package['install gitolite'],File["${git_home}/.gitconfig"],File["${git_home}/${git_user}.pub"]],
      logoutput   => 'on_failure',
      refreshonly => true;
  }

  file { "${git_home}/repositories":
    ensure    => directory,
    owner     => $git_user,
    group     => $git_user,
    mode      => '0770',
    subscribe => Exec['gl-setup gitolite']
  }

  # Solve strange issue with gitolite on ubuntu (https://github.com/sbadia/puppet-gitlab/issues/9)
  # So create a VERSION file if it doesn't exist
  if $operatingsystem == 'Ubuntu' {
    file {
      '/etc/gitolite':
        ensure  => directory,
        mode    => '0755';
      '/etc/gitolite/VERSION':
        ensure  => file,
        content => '42',
        replace => false,
        owner   => root,
        group   => root,
        mode    => '0644',
        require => File['/etc/gitolite'];
    }
  }
} # Class:: gitlab::gitolite inherits gitlab::pre
