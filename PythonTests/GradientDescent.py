import numpy as np

# Define the function for which we want to find the minima
def objective_function(params):
    a, b, c, d = params
    return (a - 2)**2 + b**2 + (c + 2)**2 + (2*d)**2 - 5

# Define the gradient of the function
def gradient(params):
    a, b, c, d = params
    grad_a = 2 * (a - 2)
    grad_b = 2 * b
    grad_c = 2 * (c + 2)
    grad_d = 2 * (2 * d)
    return np.array([grad_a, grad_b, grad_c, grad_d])

def gradient_descent_output_convergence(objective_func, gradient_func, initial_params, learning_rate, num_iterations, convergence_threshold=0.001):
    """
    Gradient descent with convergence checking based on the change in output (objective function value).
    Stops when the absolute change in the objective function value becomes smaller than threshold.
    """
    params = np.array(initial_params, dtype=float)
    history = []
    
    print(f"Starting gradient descent with output convergence threshold: {convergence_threshold}")
    print(f"Initial parameters: {params}")
    initial_value = objective_func(params)
    print(f"Initial function value: {initial_value:.4f}\n")
    history.append(initial_value) # Add initial value to history

    for i in range(num_iterations):
        # Calculate gradient and update parameters
        grad = gradient_func(params)
        params = params - learning_rate * grad
        
        # Record current function value
        current_value = objective_func(params)
        
        # Check convergence (skip first actual iteration after initial value)
        if i > 0:
            value_change = np.abs(current_value - history[-1]) # Compare with the last value in history
            
            if value_change < convergence_threshold:
                print(f"*** CONVERGED at iteration {i + 1} ***")
                break
        
        history.append(current_value) # Add current value to history for the next iteration's comparison
        
        # Print progress
        print(f"Iteration {i + 1}: params={np.round(params, 4)}, value={current_value:.4f}")

    return params, history

if __name__ == "__main__":
    # Parameters
    initial_parameters = [0.0, 0.0, 0.0, 0.0]
    learning_rate = 0.125
    num_iterations = 50
    convergence_threshold_output = 0.001  # Stop when output changes < 0.001
    
    # Run gradient descent with output convergence
    final_params_output, values_history_output = gradient_descent_output_convergence(
        objective_function,
        gradient,
        initial_parameters,
        learning_rate,
        num_iterations,
        convergence_threshold_output
    )
    
    # Results
    print(f"\nFinal parameters: {np.round(final_params_output, 4)}")
    print(f"Final function value: {objective_function(final_params_output):.4f}")
    print(f"Theoretical minimum: [2, 0, -2, 0] with value -5.0")