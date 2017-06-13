/// The supported response status codes. Reminiscent of HTTP, no?
library response_status;

/// The response completed successfully.
const int OK = 200;

/// A key was assigned successfully.
const int CREATED = 201;

/// The requested key does, indeed, exist.
const int FOUND = 302;

/// The request contained malformed data.
const int MALFORMED = 400;

/// The user attempted to access a resource in a way it is not permitted to.
const int UNAUTHORIZED = 403;

/// The requested key does not exist.
const int NOT_FOUND = 404;

/// An internal server error prevent the response from completing successfully.
const int SERVER_ERROR = 500;

/// Distinguishes a broadcasted message from a normal response.
const int BROADCAST = 100;