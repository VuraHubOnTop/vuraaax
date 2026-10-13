
export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (request.method !== "GET") {
      return Response.json(
        { success: false, message: "Method not allowed" },
        { status: 405 }
      );
    }

    if (url.pathname === "/") {
      return Response.json({
        success: true,
        message: "Lua License API is online"
      });
    }

    if (url.pathname === "/health") {
      return Response.json({
        success: true,
        status: "online"
      });
    }

    return Response.json(
      { success: false, message: "Endpoint not found" },
      { status: 404 }
    );
  }
};
