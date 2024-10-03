# Godot-Hungarian-Algorithm
A quick implementation of Kuhn-Munkres algorithm in Godot 4.3


# Base implementation and usage

In example.gd:
```
@onready var matcher = preload("res://scrHungarian.gd")

func _ready() -> void:
  #Initialize weights
	weights = [[39, 47],[5, 58]]
	print(weights)
	#Call the init method and pass the weights
	var matcherInst = matcher.new(weights)
	#Solve the problem
	var bestWeight = matcherInst.solve(true)
```

Prints:

```
[[39, 47], [5, 58]]
Weights:
[39, 47]
 ^
[5, 58]
Weights:
[39, 47]
^ 
[5, 58]
match 0 to 0, weight 39
match 1 to 1, weight 58

Best total weight: 97
```

# Using random weights

```
weights = generate_random_weights(5,5)

func generate_random_weights(rows: int, cols: int) -> Array:
	var random_weights = []
	for i in range(rows):
		var row = []
		for j in range(cols):
			row.append(randi_range(0, 100))  # Random float between 0.0 and 10.0
		random_weights.append(row)
	return random_weights
 ```
