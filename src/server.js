const http = require('http')

const server = http.createServer((request, response) => {
  response.writeHead(429, { 'Content-Type': 'application/json' })
  response.write(JSON.stringify({ error: 'validation-failed' }))
  response.end()
})

server.listen(8080)
