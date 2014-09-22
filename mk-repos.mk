#!/usr/bin/make -f

#### ids and services

my.name     := Thierry Delamare
my.email    := t.delamare@epiconcept.fr

github.user := thydel

hg.remote   := admin@mercurial.epiconcept.net
hg.dir      := usr
hg.base     := ssh://$(hg.remote)/$(hg.dir)

#### repos

repos := mk-repos a-thy
roles := ar-my-account

mk-repos.desc      := GNU Make helper to manage public and private repository skeleton creation
a-thy.desc         := Ansible playbook for installing my own user account setup on a new instance
ar-my-account.desc := Ansible role to create self user account

#### gnumakism

# default to harmless
top:; @date

# default SHELL is /bin/sh
SHELL := /bin/bash

# how we were invoked
self := $(lastword $(MAKEFILE_LIST))
$(self):;

# safer than default behavior
.DELETE_ON_ERROR:

#### install

# how to name and where to install cmd

name    := mkr
local   := /usr/local
$(name) := $(local)/bin/$(name)

# install target not available to installed instance

ifneq ($(self),$($(name)))
install: $($(name));
$($(name)): $(self); sudo install $< $@
endif

#### asserts

# My agent has a maximum lifetime

$(if $(filter $(shell ssh-add -l > /dev/null || echo T),T),$(error you agent has no keys))

#### top level targets and rules

repos.dep := %/.hg %/.hg/hgrc %/.hgignore %/.hgremote %/.git %/.gitconfig %/.gitignore %/.gitremote

repos: $(repos);
$(repos): % : $(repos.dep);

roles: $(roles);
$(roles): % : %/README.md $(repos.dep);

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

#### mercurial

%/.hg:; hg init $*

## strings parts

hgrc.ui   := [ui]\nusername = $(my.name) <$(my.email)>\n
hgrc.path  = [paths]\ndefault = $(hg.base)/$*

ignore     = .hgremote .gitremote .gitconfig README.html
hgignore   = .git/ .gitignore $(ignore)
gitignore  = .hg/ .hgignore $(ignore)

## rules commands parts

hgrc       = echo -e '$(hgrc.ui)$(hgrc.path)'

.hgignore  = echo -e 'syntax: glob\n\n*~\n';
.hgignore += echo $(hgignore) | tr ' ' '\n'

# ansible like remote execution of this makefile
.hgremote  = ssh -A $(hg.remote) make --no-print-directory -C $(hg.dir) -f - $*/.hg < $(self)

hg.files := .hg/hgrc .hgignore .hgremote
$(foreach _,$(hg.files),$(call rule,$_))

#### git

%/.git:; git init $*

## rules commands parts

.gitconfig  = (cd $*; git remote add origin git@github.com:$(github.user)/$*)
.gitconfig += (cd $*; git config --local user.name "$(my.name)");
.gitconfig += (cd $*; git config --local user.email $(my.email))

.gitignore  = echo $(gitignore) | tr ' ' '\n'

# rule .gitremote

github.api  := https://api.github.com
github.repo  = { "name": "$*", "description": "$($*.desc)" }

github.check   = jq -e .name > /dev/null
github.existp  = curl -s $(github.api)/$(github.user)/$* | $(github.check)
github.create  = curl -s -u $(github.user):$$GITHUBPASS $(github.api)/user/repos -d '$(github.repo)'
github.create += | $(github.check)

.gitremote     = $(github.existp) || $(github.create)

jq := /usr/bin/jq
jq: $(jq)
$(jq):; sudo aptitude install jq

%/.gitremote: $(jq)

# rules generator

git.files := .gitconfig .gitignore .gitremote
$(foreach _,$(git.files),$(call rule,$_))

####

github := /usr/local/bin/github
github: $(github);
$(github):; sudo gem install json github

%.html: %.md; markdown $< > $@

readme: README.html;
