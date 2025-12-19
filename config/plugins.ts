export default ({ env }) => ({
  documentation: {
    enabled: true,
    config: {
      openapi: "3.0.0",
      info: {
        version: "1.0.0",
        title: "Grupo SER API",
        description: "API documentation for Grupo SER CMS",
        termsOfService: "",
        contact: {
          name: "Grupo SER",
          email: "",
          url: "",
        },
        license: {
          name: "MIT",
          url: "https://opensource.org/licenses/MIT",
        },
      },
      "x-strapi-config": {
        // Mutate the plugins configuration
        plugins: null,
        path: "/documentation",
      },
      servers: [
        {
          url: "http://localhost:1337/api",
          description: "Development server",
        },
      ],
      externalDocs: {
        description: "Find out more",
        url: "https://docs.strapi.io/developer-docs/latest/getting-started/introduction.html",
      },
      security: [{ bearerAuth: [] }],
    },
  },
  // AWS S3 Upload Provider Configuration
  upload: {
    config: {
      provider: "aws-s3",
      providerOptions: {
        baseUrl: env("CDN_URL", "https://assets.gruposer.com.br"),
        rootPath: env("AWS_S3_ROOT_PATH", "uploads"),
        s3Options: {
          credentials: {
            accessKeyId: env("AWS_ACCESS_KEY_ID"),
            secretAccessKey: env("AWS_SECRET_ACCESS_KEY"),
          },
          region: env("AWS_REGION", "us-east-1"),
          params: {
            ACL: env("AWS_ACL", "private"), // CloudFront OAC access
            Bucket: env("AWS_BUCKET", "strapi-media-uploads"),
          },
        },
      },
      actionOptions: {
        upload: {},
        uploadStream: {},
        delete: {},
      },
    },
  },
});
