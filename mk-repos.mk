#!/usr/bin/make -f

#### ids and services

my.name      := Thierry Delamare
my.email     := t.delamare@epiconcept.fr

github.user  := thydel

local.prefix := epi

repo.base     = $(or $(and $(GIT),$(github.user)),$(local.prefix))
repo.dir      = usr/$(repo.base)

hg.remote    := admin@mercurial.epiconcept.net
hg.dir        = $(repo.dir)
hg.base       = ssh://$(hg.remote)/$(hg.dir)

hgweb.remote := hgweb@repo.charenton.tld
hgweb.dir     = $(repo.dir)
hgweb.base    = ssh://$(hgweb.remote)/$(hgweb.dir)
hgweb.meta   := .hgwebremote .hgwebpath

#### repos

# local workdir
WORKDIR ?= ~/usr/$(or $(and $(GIT),$(github.user)),$(local.prefix))
work     = $(WORKDIR)

repos := mk-repos a-thy
roles := ar-my-account ar-runp ar-fix-bash-bug ar-ansible-version ar-patch ar-misc
roles += ar-dummy ar-emacs24 ar-my-sudoers ar-my-screenrc ar-my-bashrc ar-my-dotemacs
roles += ar-vagrant ar-r-base ar-vagrant-wheezy-box

mk-repos.desc                := GNU Make helper to manage public and private repository skeleton creation
a-thy.desc                   := Ansible playbook for installing my own user account setup on a new instance
ar-my-account.desc           := Ansible role to create self user account
ar-dummy.desc                := Test mk-repos
ar-runp.desc                 := Ansible role to embed runp module
ar-fix-bash-bug.desc         := Fix bash bug on various debian release
ar-ansible-version.desc      := Set ansible version fact
ar-patch.desc                := Ansible role to embed patch module
ar-misc.desc                 := Ansible role for various simple tasks
ar-emacs24.desc              := Ansible role to install emacs24
ar-my-sudoers.desc           := Ansible role to install my sudoers config
ar-my-screenrc.desc          := Ansible role to install my screenrc
ar-my-bashrc.desc            := Ansible role to install my bashrc
ar-my-dotemacs.desc          := Ansible role to install my dotemacs

ar-vagrant.desc              := Ansible role to install latest Vagrant
ar-r-base.desc               := Ansible role to install r-base from cran.r-project.org
ar-vagrant-wheezy-box.desc   := Ansible role using git@github.com:dotzero/vagrant-debian-wheezy-64.git

~  := repo
$~  =
$~ += $(eval $(strip $1).desc := $(strip $2))
$~ += $(eval repos            += $(strip $1))

$(call repo, ai-misc, Ansible inventory for misc play)

#### gnumakism

# default to harmless
top: usage; @date

# default SHELL is /bin/sh
SHELL := /bin/bash

# how we were invoked
self := $(lastword $(MAKEFILE_LIST))
$(self):;

# safer than default behavior
.DELETE_ON_ERROR:

#### install

# how to name and where to install cmd

github.repo := mk-repos
install     := mkr
local       := /usr/local
$(install)  := $(local)/bin/$(install)

# install target not available to installed instance

ifneq ($(self),$($(install)))
install: $($(install));
$($(install)): $(self); sudo install $< $@
endif

#### help

phony := usage help show
meta := $(phony) install
.PHONY: $(phony)

~  := usage
$~ := echo;
ifneq ($(self),$($(install)))
$~ += echo -e "\tusage: make -f $(self) help";
$~ += echo -e "\tusage: $(install) help \# after make -f $(self) install";
else
$~ += echo -e "\tusage: $(install) help";
$~ += echo -e "\tinstalled from: https://github.com/$(github.user)/$(github.repo).git";
endif
$~ += echo;
$~:; @$($@)

~  := help
$~ := echo;
$~ += echo -e "\tmeta targets: $(meta)";
$~ += echo -e "\trun targets: [argvar=val]... [repo-name]... [role-name]...";
$~ += echo -e "\targ vars: WORKDIR GITHUBPASS";
$~ += echo -e "\trepo names: $(repos)";
$~ += echo -e "\troles names: $(roles)";
$~ += echo;
$~:; @$($@)

~ := show
$~.vars := my.name my.email github.user hg.base work local install
$~ += echo -e '$1_$($1)';
$~:; @echo; ($(foreach _,$($@.vars),$(call $@,$_))) | column -t -s_ | sed -e $$'s/^/\t/'; echo

#### asserts

# My agent has a maximum lifetime

$(if $(filter $(shell ssh-add -l > /dev/null || echo T),T),$(error your agent has no keys))

# must learn how to better auth

# now bash check with ': $${GITHUBPASS:?};' before using it
ifdef NEVER
targets := $(or $(MAKECMDGOALS),usage)
. := $(or $(filter $(targets),$(meta)),$(GITHUBPASS),$(error no GITHUBPASS))
endif

#### top level targets and rules

~  := repos.dep.hg
$~ := %/.hg
$~ += %/LICENSE.md
$~ += %/.hg/hgrc %/.hgignore %/.hgremote %/.hgfirstcommit
$~ += $(hgweb.meta:%=\%/%)

~  := repos.dep.git
$~ := %/.git
$~ += %/.gitconfig %/.gitignore %/.gitremote %/.gitfirstcommit

GIT :=

repos.dep  =
repos.dep += $(repos.dep.hg)
repos.dep += $(and $(GIT),$(repos.dep.git))

ifdef NEVER
repos.dep := %/.hg %/.git
repos.dep += %/LICENSE.md
repos.dep += %/.hg/hgrc %/.hgignore %/.hgremote %/.hgfirstcommit
repos.dep += $(hgweb.meta:%=\%/%)
repos.dep += %/.gitconfig %/.gitignore %/.gitremote %/.gitfirstcommit
endif

repos.work := $(repos:%=$(work)/%)

repos: $(repos.work);
$(repos.work): % : $(repos.dep);

roles.work := $(roles:%=$(work)/%)

roles: $(roles.work);
$(roles.work): % : %/README.md $(repos.dep);

$(foreach _,$(repos) $(roles),$(eval $_: $(work)/$_;))

#### meta rules

# common rules pattern for making leaf repos files from a same name
# variable containing generating command
#
#   repos: repos/readme repos/date
#   readme = echo some default text
#   date = date +%F
#   $(call $(rule, readme date))
#
# produce
#
# %/readme:; @($($@F))) > $@
# %/date:; @($($@F))) > $@
# 
# which will expand as
#
# repos/readme: @(echo some default text) > repos/readme
# repos/date: @(date +%F) > repos/date

rule = $(eval %/$1:; @($$($$(@F))) > $$@)

#### galaxy

%/README.md:; ansible-galaxy init $*

#### common

license := LICENSE.md

#%/$(license): $(license); install -m 0444 $< $@
%/$(license):; curl -s https://raw.githubusercontent.com/$(github.user)/mk-repos/master/LICENSE.md > $@

#### mercurial

%/.hg:; hg init $*

## strings parts

hgrc.ui   := [ui]\nusername = $(my.name) <$(my.email)>\n
hgrc.path  = [paths]\ndefault = $(hg.base)/$(*F)

ignore     = .hgremote .gitconfig .gitremote .gitfirstcommit .hgfirstcommit README.html
ignore    += $(hgweb.meta)
hgignore   = .git/ .gitignore $(ignore)
gitignore  = .hg/ .hgignore $(ignore)

## rules commands parts

hgrc       = echo -e '$(hgrc.ui)$(hgrc.path)'

.hgignore  = echo -e 'syntax: glob\n\n*~\n';
.hgignore += echo $(hgignore) | tr ' ' '\n'

# ansible like remote execution of this makefile
.hgremote  = ssh -A $(hg.remote) make --no-print-directory -C $(hg.dir) -f - $(*F)/.hg < $(self)

.hgfirstcommit  = (cd $*; hg add);
.hgfirstcommit += (cd $*; hg commit -m Initial);
.hgfirstcommit += (cd $*; hg push)

hg.files := .hg/hgrc .hgignore .hgremote .hgfirstcommit
$(foreach _,$(hg.files),$(call rule,$_))

#### hgweb

# ansible like remote execution of this makefile
.hgwebremote = ssh -A $(hgweb.remote) make --no-print-directory -C $(hgweb.dir) -f - $(*F)/.hg < $(self)

.hgwebpath.augeas  = set /augeas/load/Puppet/incl $*/.hg/hgrc\n
.hgwebpath.augeas += load\n
.hgwebpath.augeas += set /files/$*/.hg/hgrc/paths/hgweb "$(hgweb.base)/$(*F)"\n
.hgwebpath.augeas += save

.hgwebpath = echo -e '$(.hgwebpath.augeas)' | augtool

$(foreach _,$(hgweb.meta),$(call rule,$_))

#### git

%/.git:; git init $*

## rules commands parts

.gitconfig  = (cd $*; git remote add origin git@github.com:$(github.user)/$(*F));
.gitconfig += (cd $*; git config --local user.name "$(my.name)");
.gitconfig += (cd $*; git config --local user.email $(my.email))

.gitignore  = echo $(gitignore) | tr ' ' '\n'

# rule .gitremote

github.api  := https://api.github.com
github.repo  = { "name": "$(*F)", "description": "$($(*F).desc)" }

github.check  := jq -e .name > /dev/null
github.existp  = curl -s $(github.api)/$(github.user)/$(*F) | $(github.check)
github.create  = : $${GITHUBPASS:?};
github.create += curl -s -u $(github.user):$$GITHUBPASS $(github.api)/user/repos -d '$(github.repo)'
github.create += | $(github.check)

.gitremote     = $(github.existp) || $(github.create)

# rule .gitfirstcommit

.gitfirstcommit  = (cd $*; git add .);
.gitfirstcommit += (cd $*; git commit -m Initial);
.gitfirstcommit += (cd $*; git push -u origin master)

jq := /usr/bin/jq
jq: $(jq)
$(jq):; sudo aptitude install jq

%/.gitremote: $(jq)

# rules generator

git.files := .gitconfig .gitignore .gitremote .gitfirstcommit
$(foreach _,$(git.files),$(call rule,$_))

####

github := /usr/local/bin/github
github: $(github);
$(github):; sudo gem install json github

%.html: %.md; markdown $< > $@

readme: README.html;

################

git := GIT := T

vartar := git

$(vartar):; @: $($@) $(eval $($@))

################

st :=
st += hg st;
st += git status;

comment := Allow separate use of hg and git

com :=
com += hg com -m '$(comment)';
com += git commit -am '$(comment)';

st com:; $($@)
