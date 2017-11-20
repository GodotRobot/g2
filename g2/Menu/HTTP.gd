extends Node

var t = Thread.new()

func dbg(s):
	pass
	#print(s)

func _init():
	var arg_bytes_loaded = {"name":"bytes_loaded","type":TYPE_INT}
	var arg_bytes_total = {"name":"bytes_total","type":TYPE_INT}
	add_user_signal("loading",[arg_bytes_loaded,arg_bytes_total])
	var arg_result = {"name":"result","type":TYPE_RAW_ARRAY}
	add_user_signal("loaded",[arg_result])

func get(domain,url,port,ssl):
	if(t.is_active()):
		return
	t.start(self, "_load", {"domain":domain,"url":url,"port":port,"ssl":ssl})

func _load(params):
	dbg("thread alive")
	var err = 0
	var http = HTTPClient.new()
	err = http.connect(params.domain,params.port,params.ssl)
	dbg("connected " + String(err))

	while(http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING):
		http.poll()
		dbg("connecting")
		OS.delay_msec(100)

	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	err = http.request(HTTPClient.METHOD_GET,params.url,headers)
	dbg("requested " + String(err))

	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
		dbg("requesting")
		OS.delay_msec(500)
#
	var rb = RawArray()
	if(http.has_response()):
		dbg("has response")
		var headers = http.get_response_headers_as_dictionary()
		while(http.get_status()==HTTPClient.STATUS_BODY):
			dbg("getting body")
			http.poll()
			var chunk = http.read_response_body_chunk()
			if(chunk.size()==0):
				OS.delay_usec(100)
			else:
				rb = rb+chunk
				call_deferred("_send_loading_signal",rb.size(),http.get_response_body_length())

	call_deferred("_send_loaded_signal")
	http.close()
	return rb

func _send_loading_signal(l,t):
	dbg("loading_signal")
	emit_signal("loading",l,t)
	pass

func _send_loaded_signal():
	dbg("loaded_signal")
	var r = t.wait_to_finish()
	emit_signal("loaded",r)
	pass