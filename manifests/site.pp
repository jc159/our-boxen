require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'staff',
  owner => $boxen_user
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  include nginx

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # node versions
  include nodejs::v0_4
  include nodejs::v0_6
  include nodejs::v0_8
  include nodejs::v0_10

  # default ruby versions
  include ruby::1_8_7
  include ruby::1_9_2
  include ruby::1_9_3
  include ruby::2_0_0

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar',
      
      # this added by jc159
      'stow'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }
  
  # custom additions jc159
  
  package { 'SuperDuper!':
        source   => 'http://www.shirt-pocket.com/mint/pepper/orderedlist/downloads/download.php?file=http%3A//www.shirt-pocket.com/downloads/SuperDuper%21.dmg',
        provider => appdmg_eula,
    }
    
  include appcleaner

  # this is based on patterns I saw in 
  # https://github.com/grahamgilbert/my-boxen/blob/master/modules/people/manifests/grahamgilbert/applications.pp
  package { 'Emacs':
        source   => 'http://emacsformacosx.com/emacs-builds/Emacs-24.3-universal-10.6.8.dmg',
        provider => appdmg,
    }
   
  class { 'osx::global::natural_mouse_scrolling':
    enabled => false
  }

  include evernote
  include crashplan
  #include dropbox
  include launchbar
  include java
  
  package { 'BasicTeX':
    provider => 'pkgdmg',
    source => 'http://mirror.ctan.org/systems/mac/mactex/mactex-basic.pkg',
  }
  
  package { 'BibDesk':
    provider => 'appdmg',
    source => 'http://softlayer-dal.dl.sourceforge.net/project/bibdesk/BibDesk/BibDesk-1.6.1/BibDesk-1.6.1.dmg',
  }

  package { 'Anki':
    provider => 'appdmg',
    source => 'http://ankisrs.net/download/mirror/anki-2.0.14.dmg',
  }

 # package { 'Dropbox':
#    provider => 'appdmg',
 #   source => 'http://www.dropbox.com/download?plat=mac',
#  }
  
  include skype
}
