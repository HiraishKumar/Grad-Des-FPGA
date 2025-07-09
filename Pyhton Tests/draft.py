import numpy as np

# Define the function for which we want to find the minima
# f(a, b, c, d) = (a-2)^2 + b^2 + (c+2)^2 + (5*d)^2 - 5
def objective_function(params):
    """
    Calculates the value of the objective function.

    Args:
        params (np.array): A NumPy array containing the parameters [a, b, c, d].

    Returns:
        float: The value of the function at the given parameters.
    """
    a, b, c, d = params
    return (a - 2)**2 + b**2 + (c + 2)**2 + (2*d)**2 - 5

# Define the gradient of the function
# The partial derivatives are:
# df/da = 2*(a-2)
# df/db = 2*b
# df/dc = 2*(c+2)
# df/dd = 25*2*(d)
def gradient(params):
    """
    Calculates the gradient (vector of partial derivatives) of the objective function.

    Args:
        params (np.array): A NumPy array containing the parameters [a, b, c, d].

    Returns:
        np.array: A NumPy array containing the gradient [df/da, df/db, df/dc, df/dd].

    """

    a, b, c, d = params
    # h = 7.8125e-3
    # value = objective_function(np.array([a, b, c, d]))
    # term1 = (value - objective_function(np.array([a - h, b, c, d])))/h
    # term2 = (value - objective_function(np.array([a ,b - h, c, d])))/h
    # term3 = (value - objective_function(np.array([a, b, c - h, d])))/h
    # term4 = (value - objective_function(np.array([a ,b, c, d - h])))/h

    # return np.array([term1, term2, term3, term4])

    grad_a = 2 * (a - 2)
    grad_b = 2 * b
    grad_c = 2 * (c + 2)
    grad_d = 2 * (2 * d)
    return np.array([grad_a, grad_b, grad_c, grad_d])

def gradient_descent(objective_func, gradient_func, initial_params, learning_rate, num_iterations):
    """
    Performs gradient descent to find the minima of a function.

    Args:
        objective_func (function): The function to minimize.
        gradient_func (function): The gradient function of the objective function.
        initial_params (np.array): The starting point for the parameters.
        learning_rate (float): The step size for each iteration.
        num_iterations (int): The number of iterations to perform.

    Returns:
        np.array: The optimized parameters (approximating the minima).
        list: A list of function values at each iteration, for tracking convergence.
    """
    params = np.array(initial_params, dtype=float) # Ensure params are float for calculations
    history = [] # To store the function value at each step

    print(f"Starting gradient descent with initial parameters: {params}")
    print(f"Initial function value: {objective_func(params):.4f}\n")

    for i in range(num_iterations):
        # Calculate the gradient at the current parameters
        grad = gradient_func(params)

        # Update the parameters in the direction opposite to the gradient
        # (i.e., downhill)
        params = params - learning_rate * grad

        # Record the current function value
        current_value = objective_func(params)
        history.append(current_value)

        # Print progress periodically
    
        print(f"Iteration {i + 1}/{num_iterations}:")
        print(f"  Current parameters: {np.round(params, 4)}")
        print(f"  Function value: {current_value:.4f}")
        print(f"  Gradient magnitude: {np.linalg.norm(grad):.4f}\n")

    print("Gradient descent complete.")
    return params, history

if __name__ == "__main__":
    # Set initial parameters (a, b, c, d)
    # These can be chosen randomly or based on some prior knowledge.
    initial_parameters = [0.0, 0.0, 0.0, 0.0]

    # Set the learning rate (alpha)
    # A smaller learning rate means smaller steps, potentially slower convergence
    # but less chance of overshooting the minimum.
    # A larger learning rate means larger steps, potentially faster convergence
    # but risk of instability or overshooting.
    learning_rate = 0.125

    # Set the number of iterations
    num_iterations = 50

    # Run the gradient descent algorithm
    final_params, values_history = gradient_descent(
        objective_function,
        gradient,
        initial_parameters,
        learning_rate,
        num_iterations
    )

    # Print the final results
    print("\n--- Results ---")
    print(f"Approximate minima found at parameters (a, b, c, d):")
    print(f"a: {final_params[0]:.4f}")
    print(f"b: {final_params[1]:.4f}")
    print(f"c: {final_params[2]:.4f}")
    print(f"d: {final_params[3]:.4f}")
    print(f"\nMinimum function value: {objective_function(final_params):.4f}")
