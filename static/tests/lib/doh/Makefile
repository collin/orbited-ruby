
doh.js: dojo-trunk
	ln -fs ${PWD}/orbited.profile.js dojo-trunk/util/buildscripts/profiles/
	cd dojo-trunk/util/buildscripts && ./build.sh profile=orbited action=release releaseName=orbited
	@# a little hack to set the correct baseUrl (because we're changing the name of the script).
	sed -r -e 's,([/"])dojo(\.js"),\1doh\2,g ; s,=/dojo(.*/i;),=/doh\1,g' dojo-trunk/release/orbited/dojo/dojo.js > doh.js
	@# NB: for some odd reason doh.debug is reset when we
	@#     use the packet version of doh... so fix it here.
	echo 'dojo.addOnLoad(function() { doh.debug = console.debug; });' >> doh.js
	cp -R dojo-trunk/release/orbited/dojo/_firebug/ .
	rm _firebug/firebug.js

dojo-trunk:
	svn co http://svn.dojotoolkit.org/src/view/anon/all/trunk dojo-trunk

