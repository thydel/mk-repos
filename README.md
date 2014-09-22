# MKR

GNU Make helper to manage my public and private repository skeleton
creation

- Edit *ID* section

	``` make
	my.name     := Thierry Delamare
	my.email    := t.delamare@epiconcept.fr

	github.user := thydel

	hg.remote   := admin@mercurial.epiconcept.net
	hg.dir      := usr
	hg.base     := ssh://$(hg.remote)/$(hg.dir)
	```

- Edit *repos* section to add a empty repo or an Ansible *roles*

	``` make
	repos := mk-repos a-thy
	roles := ar-my-account
	```

- Add a description

	``` make
	mk-repos.desc      := GNU Make helper to manage public and private repository skeleton creation
	a-thy.desc         := Ansible playbook for installing my own user account setup on a new instance
	ar-my-account.desc := Ansible role to create self user account

	```

- Create the repo as dual SCM by running

	``` console
	 export GITHUBPASS=secret
	make -f mk-repos.mk ar-my-account
	```
	
  This Will

  - Create a local dir
  - Initialize as **git** and **mercurial** repo
  - Initialize a new remote **git** and **mercurial** repo using configured *IDs*
  - Create `.hginore` and `.gitignore` files
  
- Makefile style behavior

  - Will not try to create something already existing (idempotent, safe to run twice)

