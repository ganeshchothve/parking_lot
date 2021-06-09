(function(factory) {
	factory(jQuery, window, document);
})(function(jQuery) {
	// Only continue if we're on IE8/IE9 with jQuery 1.5+ (contains the ajaxTransport function)
	if (jQuery.support.cors || !jQuery.ajaxTransport || !window.XDomainRequest) {
		return jQuery;
	}

	var httpRegEx = /^(https?:)?\/\//i;
	var getOrPostRegEx = /^get|post$/i;
	var sameSchemeRegEx = new RegExp('^(\/\/|' + location.protocol + ')', 'i');

	// ajaxTransport exists in jQuery 1.5+
	jQuery.ajaxTransport('* text html xml json', function(options, userOptions, jqXHR) {
		var xdr = null;

		return {
			send: function(headers, complete) {
				console.log('hell');
				var postData = '';
				var userType = (userOptions.dataType || '').toLowerCase();

				xdr = new XDomainRequest();
				if (/^\d+$/.test(userOptions.timeout)) {
					xdr.timeout = userOptions.timeout;
				}

				xdr.ontimeout = function() {
					complete(500, 'timeout');
				};

				xdr.onload = function() {
					var allResponseHeaders = 'Content-Length: ' + xdr.responseText.length + '\r\nContent-Type: ' + xdr.contentType;
					var status = {
						code: 200,
						message: 'success'
					};
					var responses = {
						text: xdr.responseText
					};
					try {
						if (userType === 'html' || /text\/html/i.test(xdr.contentType)) {
							responses.html = xdr.responseText;
						} else if (userType === 'json' || (userType !== 'text' && /\/json/i.test(xdr.contentType))) {
							try {
								responses.json = jQuery.parseJSON(xdr.responseText);
							} catch(e) {
								status.code = 500;
								status.message = 'parseerror';
								//throw 'Invalid JSON: ' + xdr.responseText;
							}
						} else if (userType === 'xml' || (userType !== 'text' && /\/xml/i.test(xdr.contentType))) {
							var doc = new ActiveXObject('Microsoft.XMLDOM');
							doc.async = false;
							try {
								doc.loadXML(xdr.responseText);
							} catch(e) {
								doc = undefined;
							}
							if (!doc || !doc.documentElement || doc.getElementsByTagName('parsererror').length) {
								status.code = 500;
								status.message = 'parseerror';
								throw 'Invalid XML: ' + xdr.responseText;
							}
							responses.xml = doc;
						}
					} catch(parseMessage) {
						throw parseMessage;
					} finally {
						complete(status.code, status.message, responses, allResponseHeaders);
					}
				};

				// set an empty handler for 'onprogress' so requests don't get aborted
				xdr.onprogress = function(){};
				xdr.onerror = function() {
					complete(500, 'error', {
						text: xdr.responseText
					});
				};

				if (userOptions.data) {
					postData = (jQuery.type(userOptions.data) === 'string') ? userOptions.data : jQuery.param(userOptions.data);
				}
				xdr.open(options.type, options.url);
				xdr.send(postData);
			},
			abort: function() {
				if (xdr) {
					xdr.abort();
				}
			}
		};
	});
	return jQuery;
});