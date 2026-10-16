extends CanvasLayer

@onready var label: Label = $Panel/Label
@onready var buttons: Array[Button] = [
	$Panel/VBoxContainer/Button1,
	$Panel/VBoxContainer2/Button2,
	$Panel/VBoxContainer/Button3,
	$Panel/VBoxContainer2/Button4
]

var callback_reponse: Callable

func _ready() -> void:
	hide() # La popup est cachée par défaut au lancement du jeu
	# Connecter automatiquement les 4 boutons
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_choice_pressed.bind(i))

# Fonction pour afficher la popup avec une question, des choix et une action au clic
func ask(question: String, choices: Array[String], callback: Callable) -> void:
	label.text = question
	callback_reponse = callback
	
	for i in range(buttons.size()):
		if i < choices.size():
			buttons[i].text = choices[i]
			buttons[i].show()
		else:
			buttons[i].hide()
	
	show()

func _on_choice_pressed(index: int) -> void:
	hide()
	if callback_reponse.is_valid():
		callback_reponse.call(index) # Renvoie l'index du bouton cliqué (0 à 3)
