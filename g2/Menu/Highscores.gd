extends Panel

func _on_loading(loaded,total):
	var percent = loaded*100/total

func _on_loaded(result):
	var result_string = result.get_string_from_ascii()
	#print(result_string)
	var scores = {}
	scores.parse_json(result_string)
	for i in range(5):
		get_node("VBoxContainer/GridContainer/Pos" + String(i+1)).set_text(String(i+1))
	var i=0
	for name in scores.names:
		get_node("VBoxContainer/GridContainer/Name" + String(i+1)).set_text(name)
		i += 1
	var i=0
	for score in scores.scores:
		get_node("VBoxContainer/GridContainer/Score" + String(i+1)).set_text(String(score))
		i += 1

func _ready():
	var http = get_node("HTTP")
	http.connect("loading",self,"_on_loading")
	http.connect("loaded",self,"_on_loaded")
	http.get("http://warpgamehighscores.azurewebsites.net","/",80,false) #domain,url,port,useSSL

func _init():
	pass