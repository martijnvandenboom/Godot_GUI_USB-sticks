extends Control

onready var popup = get_node("WindowDialog")
onready var password_tekst = get_node("WindowDialog/LineEdit")
onready var textbox = get_node("TextEdit")
onready var optionbox = get_node("OptionButton")
onready var origineelcommando = get_node("tekstOrigineelCommando")
onready var bijgewerktcommando = get_node("tekstBijgewerktCommando")

func split_string(text, delimiter):
	var words = []
	var word = ""
	for c in text:
		if c == delimiter:
			words.append(word)
			word = ""
		else:
			word += c
	if word != "":
		words.append(word)
	return words

func remove_empty_strings(array):
	var filtered_array = []
	for element in array:
		if element != "":
			filtered_array.append(element)
	return filtered_array

func run_command():
	# Define the bash script with placeholders for variables
	var password = Global.password
	var script_template = """
devices=\\$(echo '{password}' | sudo -S diskutil list | grep external | awk '{print \\$1}')

if [[ ! -z \\$devices ]]; then
	echo ''
	for disk in \\$devices; do
		#echo \\$disk
		echo '{password}' | sudo -S mount | grep \\$disk | awk -F' ' '\\$3 ~ "/Volumes/" {print \\$3, \\$4, \\$5, \\$6, \\$7, \\$8, \\$9, \\$10}' | awk -F'(' '{print \\$1}' | sed 's/^ *//; s/ *$//' | sed 's/ /\\ /g'
	done
else
	echo ''
	echo 'Er zijn geen externe USB sticks aangesloten!'
	echo ''
fi

""" 
	var script = script_template.replace("{password}", password)

	# Prepare the result array
	var result = []
	var gesplitst = []
	var opgeschoond = []
	
	# Execute the script using bash
	var exit_code = OS.execute("bash", ["-c", script], true, result)

	# Check the exit code and print the result
	if exit_code == 0:
		print("Command executed successfully.")
		#print(result.count())
		
		for line in result:
			gesplitst = split_string(line,"\n")

		opgeschoond = remove_empty_strings(gesplitst)
		
		for line in opgeschoond:
			#print(aantal)
			#print(line)
			Global.USB_devices.append(line)
			textbox.text = textbox.text + line + "\n"
			
		for device in Global.USB_devices:
			optionbox.add_item(device)
	
		optionbox.connect("item_selected", self, "_on_option_button_item_selected")
		Global.geselecteerdeTekst = optionbox.get_item_text(0)
		
	else:
		print("Command execution failed with exit code %d" % exit_code)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Scan_button_up():
	popup.visible = true

func _on_Uitvoeren_button_up():
	Global.password = password_tekst.text
	popup.visible = false
	textbox.text = ""
	optionbox.clear()
	Global.USB_devices = []
		
	run_command()

func _on_option_button_item_selected(index):
	# Get the text of the selected item using the index
	Global.geselecteerdeTekst = optionbox.get_item_text(index)

func add_backslash_before_spaces(input_str: String) -> String:
	return input_str.replace(" ", "\\ ")

func cut_string_before_substring(input_str: String, substring: String) -> String:
	var pos = input_str.find(substring)
	if pos != -1:
		return input_str.substr(0, pos)
	else:
		return input_str

func _on_Bijwerken_button_up():
	var stringOrigineel = origineelcommando.text
	var geselecteerdeOptie = Global.geselecteerdeTekst
	
	print(stringOrigineel)
	print(cut_string_before_substring(stringOrigineel, "--volume"))

	print(add_backslash_before_spaces(geselecteerdeOptie))
	
	bijgewerktcommando.text = str(cut_string_before_substring(stringOrigineel, "--volume") + " --volume " + add_backslash_before_spaces(geselecteerdeOptie))

