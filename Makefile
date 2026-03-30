.PHONY: all
pkg_dir = $(shell pwd)/package
magit_dir = ${pkg_dir}/magit
dash_dir = ${pkg_dir}/dash.el
helm_dir = ${pkg_dir}/helm
magit_popup_dir = ${pkg_dir}/magit-popup
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

all:
	emacs --batch --eval '(byte-recompile-directory ".")'
	mkdir -p erc/log
	cd ${magit_dir} && \
		echo "LOAD_PATH = -L ${magit_dir}/lisp \
		-L ${dash_dir} \
		-L ${magit_popup_dir} \
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
		make clean && \
		make lisp
	cd ${helm_dir} && make clean && EMACSLOADPATH="${async_dir}:" make
