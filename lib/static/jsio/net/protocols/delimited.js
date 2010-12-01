jsio('import net.interfaces');

exports.DelimitedProtocol = Class(net.interfaces.Protocol, function(supr) {

	this.init = function(delimiter) {
		if (!delimiter) {
			delimiter = '\r\n'
		}
		this.delimiter = delimiter;
		this.buffer = ""
	}

	this.connectionMade = function() {
		logger.debug('connectionMade');
	}
	
	this.dataReceived = function(data) {
		if (!data) { return; }
		logger.debug('dataReceived:(' + data.length + ')', data);
		logger.debug('last 2:', data.slice(data.length-2));
		this.buffer += data;
		logger.debug('index', this.buffer.indexOf(this.delimiter));
		var i;
		while ((i = this.buffer.indexOf(this.delimiter)) != -1) {
			var line = this.buffer.slice(0, i);
			this.buffer = this.buffer.slice(i + this.delimiter.length);
			this.lineReceived(line);
		}
	}

	this.lineReceived = function(line) {
		logger.debug('Not implemented, lineReceived:', line);
	}
	this.sendLine = function(line) {
		logger.debug('WRITE:', line + this.delimiter);
		this.transport.write(line + this.delimiter);
	}
	this.connectionLost = function() {
		logger.debug('connectionLost');
	}
});

