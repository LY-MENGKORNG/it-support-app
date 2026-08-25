Bun.serve({
  port: 3000,
  routes: {},
  fetch(_req, _server) {
    return Response.json({ msg: "not found!" })
  },
})
