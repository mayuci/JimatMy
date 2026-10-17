const ApiError = require('../utils/api_error');

function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    error: {
      code: 'ROUTE_NOT_FOUND',
      message: `Route not found: ${req.method} ${req.originalUrl}`,
    },
  });
}

function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  const isApiError = error instanceof ApiError;
  if (!isApiError) console.error(error);

  const response = {
    success: false,
    error: {
      code: isApiError ? error.code : 'INTERNAL_ERROR',
      message: isApiError ? error.message : 'An unexpected error occurred',
    },
  };
  if (isApiError && error.details !== undefined) response.error.details = error.details;

  return res.status(isApiError ? error.status : 500).json(response);
}

module.exports = { errorHandler, notFoundHandler };
