/**
 * Health check route for container orchestration (ECS, Kubernetes, etc.)
 */
export default {
  routes: [
    {
      method: "GET",
      path: "/_health",
      handler: "health.index",
      config: {
        auth: false, // Public endpoint
        policies: [],
        middlewares: [],
      },
    },
  ],
};
