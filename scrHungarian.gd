# KMMatcher Class: Hungarian Algorithm (Kuhn-Munkres)
class_name KMMatcher
extends RefCounted

# Properties of the KMMatcher class
var weights: Array  # Cost matrix
var n: int  # Number of rows (agents)
var m: int  # Number of columns (tasks)
var label_x: Array  # Labels for the x side (agents)
var label_y: Array  # Labels for the y side (tasks)
var max_match: int  # Maximum number of matches
var xy: Array  # Matched pairs (x -> y)
var yx: Array  # Matched pairs (y -> x)
var slack: Array  # Slack values for pathfinding
var slackyx: Array  # Corresponding x indices for slack values
var prev: Array  # Previous nodes in the augmenting path
var S: Array  # Tree for the x side
var T: Array  # Tree for the y side

# Constructor to initialize the KMMatcher with a given weights matrix
func _init(new_weights: Array):
	# Initialize weights, number of agents, and number of tasks
	weights = new_weights
	n = weights.size()
	m = weights[0].size()  # Assuming a 2D array

	# Ensure the number of agents does not exceed the number of tasks
	assert(n <= m)

	# Initialize labels for agents based on weights
	label_x = []
	for row in weights:
		label_x.append(row.max())  # Set label to the maximum value in the row

	label_y = []
	for i in range(m):
		label_y.append(0.0)  # Initialize labels for tasks to zero

	# Initialize matching variables
	max_match = 0
	xy = []
	for i in range(n):
		xy.append(-1)  # No matches for agents initially

	yx = []
	for i in range(m):
		yx.append(-1)  # No matches for tasks initially

	# Initialize variables for slack and previous nodes
	slack = []
	slackyx = []
	prev = []

# Function to augment the path after finding an augmenting path
func do_augment(x: int, y: int):
	# Increase the count of maximum matches
	max_match += 1

	# Backtrack through the path to update matches
	while x != -2:
		yx[y] = x  # Set the match for task y
		var ty = xy[x]  # Store the current match of agent x
		xy[x] = y  # Update the match for agent x to task y
		x = prev[x]  # Move to the previous agent in the path
		y = ty  # Continue with the previous match of agent x

# Function to find an augmenting path using the Hungarian Algorithm
func find_augment_path() -> Array:
	# Reset auxiliary arrays for pathfinding
	S = []
	for i in range(n):
		S.append(false)  # Keep track of matched agents

	T = []
	for i in range(m):
		T.append(false)  # Keep track of matched tasks

	slack = []
	slackyx = []
	for i in range(m):
		slack.append(0.0)  # Initialize slack values to zero
		slackyx.append(-1)  # No corresponding agent initially

	prev = []
	for i in range(n):
		prev.append(-1)  # No previous nodes initially

	# Initialize queue for BFS and find a root for augmentation
	var queue = []
	var root = -1

	# Find an unmatched agent as the starting point
	for x in range(n):
		if xy[x] == -1:
			queue.append(x)  # Add unmatched agent to the queue
			root = x  # Set this agent as the root
			prev[x] = -2  # Mark the root's previous as -2
			S[x] = true  # Add root to S
			break  # Exit loop once a root is found

	# Calculate initial slack values for the augmenting path
	for y in range(m):
		slack[y] = label_y[y] + label_x[root] - weights[root][y]
		slackyx[y] = root  # Track which agent is responsible for the slack

	# Main loop to find the augmenting path
	while true:
		# Traverse the queue to find potential matches
		for st in range(queue.size()):
			var x = queue[st]  # Current agent from the queue

			# Explore potential matches with tasks
			for y in range(m):
				# Check if task y is not matched and can be matched with agent x
				if not T[y] and is_close(weights[x][y], label_x[x] + label_y[y]):
					if yx[y] == -1:
						return [x, y]  # Found an augmenting path

					T[y] = true  # Mark task y as matched
					queue.append(yx[y])  # Add matched agent to the queue
					add_to_tree(yx[y], x)  # Update trees

		# Update labels based on the current state of slack
		update_labels()

		# Clear the queue for the next iteration
		queue.clear()

		# Check for tasks that can be matched based on slack
		for y in range(m):
			if not T[y] and is_close(slack[y], 0):
				var x = slackyx[y]  # Get the agent corresponding to the slack
				if yx[y] == -1:
					return [x, y]  # Found an augmenting path
				T[y] = true  # Mark task y as matched
				if not S[yx[y]]:
					queue.append(yx[y])  # Add matched agent to the queue
					add_to_tree(yx[y], x)  # Update trees

	# If no augmenting path was found, return an empty array
	return []  # No augmenting path found

# Function to solve the assignment problem using the Hungarian Algorithm
func solve(verbose: bool = false) -> float:
	# Main solving loop, repeating until all matches are found
	while max_match < n:
		var result = find_augment_path()  # Find an augmenting path
		var x = result[0]
		var y = result[1]
		do_augment(x, y)  # Augment the matching

		# Highlight the weights matrix with arrows for the current match
		print_weights_with_arrows(x, y)

	# Calculate the total weight of the matches
	var total_weight = 0.0
	var output_str = ""  # Initialize a string to accumulate output for rich print

	for x in range(n):
		# Prepare the output string with rich text for highlighting
		output_str += "[color=green]Match %s to %s[/color], weight [color=blue]%s[/color]\n" % [x, xy[x], weights[x][xy[x]]]
		total_weight += weights[x][xy[x]]  # Accumulate the weight

	if verbose:
		print_rich(output_str)  # Print total matches with formatting if verbose

	# Output the best total weight (minimum weight)
	print_rich("[color=red]Best total weight: %s[/color]" % total_weight)  # Output the best total weight
	return total_weight  # Return the total weight of the matches

# Function to highlight the weights matrix with arrows indicating matches
func print_weights_with_arrows(agent_index: int, task_index: int):
	print("Weights:")
	for i in range(n):
		# Print each row of the weights matrix
		print(weights[i])  # Print each row of the weights matrix
		if i == agent_index:
			var arrow_row = ""
			for j in range(m):
				if j == task_index:
					arrow_row += "^"  # Indicate matched task with an arrow
				else:
					arrow_row += " "  # No arrow for unmatched tasks
			print(arrow_row)  # Print the arrow row below the matched agent's row

# Function to add an agent to the tree and update slack values
func add_to_tree(x: int, prevx: int):
	# Add agent x to the tree and update its previous node
	S[x] = true  # Mark agent x as added to S
	prev[x] = prevx  # Set the previous agent for backtracking

	# Update slack values based on the new addition
	for y in range(m):
		# Check if the current slack can be reduced
		if label_x[x] + label_y[y] - weights[x][y] < slack[y]:
			slack[y] = label_x[x] + label_y[y] - weights[x][y]  # Update slack
			slackyx[y] = x  # Track the agent responsible for the new slack

# Function to update labels by reducing slack and adjusting labels
func update_labels():
	# Update labels by reducing slack and adjusting label_x and label_y
	var delta = INF  # Initialize delta as infinity
	for y in range(m):
		if not T[y]:  # Only consider unmatched tasks
			delta = min(delta, slack[y])  # Find the minimum slack value

	# Update labels for matched agents
	for x in range(n):
		if S[x]:
			label_x[x] -= delta  # Reduce the label for agent x

	# Update labels for matched tasks
	for y in range(m):
		if T[y]:
			label_y[y] += delta  # Increase the label for matched task
		else:
			slack[y] -= delta  # Reduce slack for unmatched tasks

# Helper function to check if two values are approximately equal
func is_close(a: float, b: float, tol: float = 0.00001) -> bool:
	return abs(a - b) < tol  # Check if two values are approximately equal
