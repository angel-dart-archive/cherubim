/// The supported request methods.
library request_method;

/// Read the value of a key.
const String GET = 'GET';

/// Assign a value to a key.
const String SET = 'SET';

/// Determine if a key exists.
const String EXISTS = 'exists';

/// Delete a key.
const String DELETE = 'delete';

/// Increment a value.
const String INCREMENT = 'INCREMENT';

/// Decrement a value.
const String DECREMENT = 'DECREMENT';

/// Add to a list.
const String LIST_ADD = 'LIST_ADD';

/// Remove from a list.
const String LIST_REMOVE = 'LIST_REMOVE';