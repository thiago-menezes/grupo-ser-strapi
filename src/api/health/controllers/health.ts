/**
 * Health check controller
 * Returns 200 OK if Strapi is running and database is accessible
 */
export default ({ strapi }) => ({
  async index(ctx) {
    try {
      // Check database connection
      const dbConnection = await strapi.db.connection.raw("SELECT 1");

      ctx.send({
        status: "ok",
        timestamp: new Date().toISOString(),
        version: strapi.config.info.strapi,
        database: dbConnection ? "connected" : "disconnected",
      });
    } catch (error) {
      ctx.status = 503;
      ctx.send({
        status: "error",
        timestamp: new Date().toISOString(),
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  },
});
