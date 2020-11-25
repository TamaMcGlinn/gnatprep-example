all:
	echo 'You must choose a configuration, such as "make bar_foo"'

bar_foo:
	gprbuild -d -p -g -XBar=bar -XFoo=foo

clean:
	rm -rf obj/
