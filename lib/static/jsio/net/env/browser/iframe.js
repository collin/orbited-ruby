"use import";

import net.interfaces;
from util.browser import $;

exports.Listener = Class(net.interfaces.Listener, function(supr) {
	var ID = 0;
	
	var tabStyle = {
		background: '#442',
		border: '1px solid #885',
		margin: '0px 0px -1px 3px',
		MozBorderRadius: '3px 0px 0px 3px',
		WebkitBorderRadius: '3px 0px 0px 3px',
		boxSizing: 'border-box',
		borderRightWidth: '0px',
		padding: '2px 0px 2px 5px',
		cursor: 'pointer'
	};
	
	this.init = function(server, opts) {
		supr(this, 'init', arguments);
		this._clients = {};
		this._numTabs = 0;
		this._frames = [];
		
		$.style(document.documentElement, {overflow: 'hidden', margin: '0px', padding: '0px', width: '100%', height: '100%'});
		$.style(document.body, {margin: '0px', padding: '0px', width: '100%', height: '100%'});
		$.onEvent(window, 'resize', this, 'onResize');
		
		this._leftCol = $({
			style: {
				position: 'absolute',
				top: '0px',
				left: '0px',
				width: '150px',
				height: '100%',
				overflow: 'hidden',
				paddingTop: '5px',
				background: '#444',
				fontWeight: 'bold',
				color: '#EEA'
			},
			parent: document.body
		});
		
		this._rightCol = $({
			style: {
				position: 'absolute',
				top: '0px',
				right: '0px',
				height: '100%',
				background: '#EEE',
				boxSizing: 'border-box',
				border: '1px solid #CCC',
				borderWidth: '0px 1px',
				overflowX: 'hidden',
				overflowY: 'auto'
			},	
			parent: document.body
		});
		
		this._serverContent = $({
			style: {
				position: 'absolute',
				top: '0px',
				right: '0px',
				width: '100%',
				height: '100%',
				boxSizing: 'border-box',
				padding: '10px'
			},
			parent: this._rightCol
		});
		
		var el = this.createTab('server');
		$.onEvent(el, 'click', this, 'showFrame', this._serverContent);
		
		if (opts && opts.clientURL) {
			var el = this.createTab('+ client', 1);
			$.onEvent(el, 'click', this, 'onNewTabClick');
			this._lastTab = el;
		}
		
		this.onResize();
	}
	
	this.getDOM = function() {
		return this._serverContent;
	}
	
	this.onResize = function() {
		this._rightCol.style.width = $(window).width - 150 + 'px';
	}
	
	this.createTab = function(text, indent) {
		var el = $({
			style: tabStyle
		});
		
		$.style(el, { marginLeft: indent * 10 + 'px' });
		
		el.text = $({
			text: text,
			parent: el
		});
		
		var status = $({
			style: { 'float': 'right' },
			before: el.text
		});
		
		el.status = function(text) { $.setText(status, text); }
		
		if (this._lastTab) {
			this._leftCol.insertBefore(el, this._lastTab);
		} else {
			this._leftCol.appendChild(el);
		}
		
		$.onEvent(el, 'mouseover', bind($, $.style, el, {background: '#664'}));
		$.onEvent(el, 'mouseout', bind($, $.style, el, {background: '#442'}));
		$.onEvent(el, 'mousedown', bind($, $.style, el, {background: '#111'}));
		$.onEvent(el, 'mouseup', bind($, $.style, el, {background: '#442'}));
		return el;
	}
	
	this.onNewTabClick = function() { this.newTab(); }
	
	this.newTab = function(url, text) {
		++this._numTabs;
		var text = text || this._numTabs;
		var el = this.createTab(text);
		el.status('loading...');
		
		var frame = $({
			tag: 'iframe',
			attrs: {
				border: 0,
				name: 'tab' + this._numTabs
			},
			style: {
				position: 'absolute',
				left: '200%',
				width: '100%',
				height: '100%',
				borderWidth: '0px'
			}
		});
		
		frame.src = url || this._opts.clientURL;
		this._rightCol.appendChild(frame);
		
		frame.onload = bind(this, 'onFrameLoad', frame, el);
		this._frames.push(frame);
		
		$.onEvent(el, 'click', this, 'showFrame', frame);
		
		el.reload = $({
			text: 'R',
			style: {
				'float': 'right',
				'border': '1px solid #AAF',
				'background': '#000',
				'padding': '1px'
			},
			before: el.firstChild
		});
		
		$.onEvent(el.reload, 'click', function() {
			el.status('loading...');
			frame.contentWindow.location.reload(true);
		});
		
		this.onResize();
	}
	
	this.onFrameLoad = function(frame, el, text) {
		this.showFrame(frame);
		el.status('');
	}
	
	this.showFrame = function(frame) {
		if (this._currentFrame) { $.style(this._currentFrame, {left: '200%'}); }
		this._currentFrame = frame;
		$.style(frame, {left: '0%'});
	}
	
	this.listen = function() {
		$.onEvent(window, 'message', bind(this, '_onMessage'));
	}
	
	this._onMessage = function(evt) {
		var name = evt.source.name;
		var target = this._clients[name];
		var data = eval('(' + evt.data + ')');
		switch (data.type) {
			case 'open':
				this._clients[name] = new exports.Transport(evt.source);
				evt.source.postMessage('{type:"open"}','*');
				this.onConnect(this._clients[name]);
				break;
			case 'data':
				target.onData(data.payload);
				break;
			case 'close':
				target.onClose();
				evt.source.postMessage('{type:"close"}','*');
				delete this._clients[name];
				break;
		}
	}
});

exports.Connector = Class(net.interfaces.Connector, function() {
	this.connect = function() {
		$.onEvent(window, 'message', bind(this, '_onMessage'));
		window.parent.postMessage(JSON.stringify({type:"open"}), '*');
	}
	
	this._onMessage = function(evt) {
		var data = eval('(' + evt.data + ')');
		switch(data.type) {
			case 'open':
				this._transport = new exports.Transport(evt.source);
				this.onConnect(this._transport);
				break;
			case 'close':
				this._transport.onClose();
				break;
			case 'data':
				this._transport.onData(data.payload);
				break;
		}
	}
});

exports.Transport = Class(net.interfaces.Transport, function() {
	this.init = function(win) {
		this._win = win;
	}
	
	this.makeConnection = function(protocol) {
		this._protocol = protocol;
	}
	
	this.write = function(data, encoding) {
		if (this.encoding == 'utf8') {
			this._win.postMessage(JSON.stringify({type: 'data', payload: utf8.encode(data)}), '*');
		} else {
			this._win.postMessage(JSON.stringify({type: 'data', payload: data}), '*');
		} 
	}
	
	this.loseConnection = function(protocol) {
		this._win.postMessage(JSON.stringify({type: 'close', code: 301}), '*');
	}
	
	this.onData = function() { this._protocol.dataReceived.apply(this._protocol, arguments); }
	this.onClose = function() { this._protocol.connectionLost.apply(this._protocol, arguments); }
});
