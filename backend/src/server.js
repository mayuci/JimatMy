const app = require('./app');
const pool = require('./config/database');
const { clearExpiredCoordinateCache } = require('./services/premise_coordinate_cache_service');
const { cleanupExpiredPasswordResets } = require('./services/password_reset_service');

const port = Number(process.env.PORT) || 3000;
let server;
let cacheCleanupTimer;
let passwordResetCleanupTimer;

async function start() {
  const removed = await clearExpiredCoordinateCache(pool);
  if (removed > 0) console.log(`Removed ${removed} expired premise coordinate rows.`);
  const resetRows = await cleanupExpiredPasswordResets(pool);
  if (resetRows > 0) console.log(`Removed ${resetRows} expired password reset records.`);
  server = app.listen(port, () => {
    console.log(`JimatMY API listening on http://localhost:${port}`);
  });
  cacheCleanupTimer = setInterval(() => {
    clearExpiredCoordinateCache(pool).catch((error) => {
      console.error(`Premise coordinate cleanup failed: ${error.message}`);
    });
  }, 6 * 60 * 60 * 1000);
  cacheCleanupTimer.unref();
  passwordResetCleanupTimer = setInterval(() => {
    cleanupExpiredPasswordResets(pool).catch((error) => {
      console.error(`Password reset cleanup failed: ${error.message}`);
    });
  }, 60 * 60 * 1000);
  passwordResetCleanupTimer.unref();
}

start().catch((error) => {
  console.error(`JimatMY API startup failed: ${error.message}`);
  process.exitCode = 1;
});

async function shutdown(signal) {
  console.log(`${signal} received; shutting down.`);
  if (cacheCleanupTimer) clearInterval(cacheCleanupTimer);
  if (passwordResetCleanupTimer) clearInterval(passwordResetCleanupTimer);
  if (!server) {
    await pool.end();
    process.exit(0);
  }
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
