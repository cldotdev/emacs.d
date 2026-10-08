.PHONY: all update compile grammars grammars-clean
pkg_dir = $(shell pwd)/package
ts_dir = $(shell pwd)/tree-sitter
magit_dir = ${pkg_dir}/magit
dash_dir = ${pkg_dir}/dash.el
helm_dir = ${pkg_dir}/helm
ghub_dir = ${pkg_dir}/ghub/lisp
transient_dir = ${pkg_dir}/transient
with_editor_dir = ${pkg_dir}/with-editor
graphql_dir = ${pkg_dir}/graphql.el
treepy_dir = ${pkg_dir}/treepy.el
async_dir = ${pkg_dir}/emacs-async
libegit2_dir = ${pkg_dir}/libegit2
compat_dir = ${pkg_dir}/compat
llama_dir = ${pkg_dir}/llama
cond_let_dir = ${pkg_dir}/cond-let
jobs ?= $(shell getconf _NPROCESSORS_ONLN)

all: compile grammars

# Refresh a checkout from upstream. Run `make grammars' as well when
# init/init-treesit-grammars.el changes.
update:
	git pull --ff-only
	git submodule sync --recursive
	git submodule update --init --recursive
	@# `git pull' cannot rmdir the work tree of a submodule that upstream
	@# removed, and `git submodule update' ignores it, so it stays in
	@# package/ forever. Compare against `submodule status --recursive',
	@# because it reaches submodules nested inside another submodule, which
	@# the superproject's own index knows nothing about. A
	@# `.git' file means git built the work tree; a hand-made clone has a
	@# `.git' directory instead, so leave that one alone.
	@registered="$$(git submodule status --recursive | awk '{print $$2}')"; \
	find . -name .git -prune -print | grep -v '^\./\.git$$' | \
		sed 's|^\./||; s|/\.git$$||' | \
	while read -r dir; do \
		printf '%s\n' "$$registered" | grep -qxF "$$dir" && continue; \
		if [ -f "$$dir/.git" ]; then \
			echo "pruning unregistered submodule $$dir"; \
			rm -rf "$$dir"; \
		else \
			echo "note: $$dir holds a git repository git does not track; left alone"; \
		fi; \
	done
	@# `loaddefs-generate' rewrites the file only when a helm source is
	@# newer, and helm's `autoloads' target has no prerequisites to force
	@# the rebuild, so upgrading Emacs alone never updates the header.
	rm -f ${helm_dir}/helm-autoloads.el
	@# magit's and helm's own rules rebuild a file only when its own source
	@# changes, not when a macro it takes from another submodule does, so an
	@# upgrade rebuilds both from scratch.
	$(MAKE) -C ${magit_dir} clean-lisp
	$(MAKE) -C ${helm_dir} clean
	$(MAKE) compile

compile:
	mkdir -p erc/log
	@# Some packages do not ignore the build output this target leaves in
	@# them, and the superproject's .gitignore does not reach into a
	@# submodule.  This replaces ~/.config/git/ignore in each submodule
	@# rather than adding to it.
	git submodule foreach --quiet --recursive \
		'git config core.excludesFile ${CURDIR}/submodule.gitignore'
	cd ${magit_dir} && \
		echo "LOAD_PATH = -L ${magit_dir}/lisp \
		-L ${dash_dir} \
		-L ${ghub_dir} \
		-L ${transient_dir}/lisp \
		-L ${with_editor_dir}/lisp \
		-L ${graphql_dir} \
		-L ${treepy_dir} \
		-L ${libegit2_dir} \
		-L ${compat_dir} \
		-L ${llama_dir} \
		-L ${cond_let_dir} \
		-L ${pkg_dir}" >config.mk && \
		$(MAKE) -j${jobs} lisp
	@# magit's makefiles declare the build order between its files, so it
	@# builds in parallel.  helm's do not, so it stays on a plain `make',
	@# which runs serially even under `make -jN'.
	cd ${helm_dir} && EMACSLOADPATH="${async_dir}:" make autoloads compile
	@# Byte-compile everything the two makefiles above did not build, then
	@# native-compile all of it.  Their `.elc' are newer than their sources
	@# by now, and `byte-recompile-directory' leaves such a file alone.
	emacs --batch -l make-compile.el

# Build every tree-sitter grammar listed in init/init-treesit-grammars.el.
# Each language is git-cloned + compiled by `treesit-install-language-grammar'
# into ${ts_dir} (= ~/.emacs.d/tree-sitter/). Re-run to refresh.
grammars:
	emacs -Q --batch -L init -l init-treesit-grammars \
	  --eval '(let (fail) (dolist (e treesit-language-source-alist) (condition-case err (treesit-install-language-grammar (car e)) (error (push (car e) fail) (message "FAIL %s: %S" (car e) err)))) (when fail (message "Failed grammars: %S" (nreverse fail)) (kill-emacs 1)))'

grammars-clean:
	rm -rf ${ts_dir}
