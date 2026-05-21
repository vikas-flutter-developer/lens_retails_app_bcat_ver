import { NextFunction, Request, Response } from 'express';

export function errorHandler(
  err: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
) {
  const isError = err instanceof Error;

  res.status(500).json({
    statusCode: 500,
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString(),
    requestId: req.requestId ?? null,
    error: {
      message: isError ? err.message : 'Internal server error',
    },
  });
}
