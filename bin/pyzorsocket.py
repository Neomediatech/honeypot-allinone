import argparse
import email.parser
import email.policy
import os
import json
from socketserver import TCPServer, ThreadingMixIn, StreamRequestHandler

import pyzor.client
import pyzor.digest
import pyzor.config

# import logging

class RequestHandler(StreamRequestHandler):

    def handle(self):
        cmd = self.rfile.readline().decode()[:-1]
        if cmd == "CHECK":
            self.handle_check()
        else:
            self.write_json({"error": "unknown command"})

    def handle_check(self):
        parser = email.parser.BytesParser(policy=email.policy.SMTP)
        msg = parser.parse(self.rfile)

        servers = pyzor.config.load_servers("/root/.pyzor/servers")
        # log = "/tmp/pyzor.log"
        # logging.basicConfig(filename=log,level=logging.DEBUG,format='%(asctime)s %(message)s', datefmt='%d/%m/%Y %H:%M:%S')
        # logging.info(servers)

        digest = pyzor.digest.DataDigester(msg).value
        check = pyzor.client.Client().check(digest, address=servers[0])

        self.write_json({k: v for k, v in check.items()})

    def write_json(self, d):
        j = json.dumps(d) + "\n"
        self.wfile.write(j.encode())


class Server(ThreadingMixIn, TCPServer):
    pass


def main():
    argp = argparse.ArgumentParser(description="Expose pyzor on a socket")
    argp.add_argument("addr", help="address to listen on")
    argp.add_argument("port", help="port to listen on")
    args = argp.parse_args()

    addr = (args.addr, int(args.port))

    srv = Server(addr, RequestHandler)
    try:
        srv.serve_forever()
    finally:
        srv.server_close()


if __name__ == "__main__":
    main()
