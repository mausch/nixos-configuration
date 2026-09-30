from http.server import ThreadingHTTPServer

from jevk5 import JevK5GGUF
from jevk5.server import make_handler


model = JevK5GGUF(temperature=2.07)
ThreadingHTTPServer(
    ("127.0.0.1", 8091), make_handler(model, "crh225/plumb-4b-GGUF:Q4_K_M")
).serve_forever()
