#!/usr/bin/env ruby
# frozen_string_literal: true

require 'socket'
require 'openssl'

# Warning: OpenSSL support is a work in progress and should not be used for anything other than testing.
TCPSocket.open('natalie-lang.org', 443) do |sock|
  ssl_context = OpenSSL::SSL::SSLContext.new
  ssl_context.min_version = :TLS1_3
  ssl_context.max_version = :TLS1_3
  ssl_context.security_level = 2
  ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
  ssl_context.verify_hostname = true
  ssl_context.cert_store = OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE

  ssl_sock = OpenSSL::SSL::SSLSocket.new(sock, ssl_context)
  ssl_sock.hostname = 'natalie-lang.org'
  ssl_sock.connect

  ssl_sock.write("GET / HTTP/1.1\r\nHost: natalie-lang.org\r\nConnection: close\r\n\r\n")
  body = ssl_sock.read
  puts body.sub(/\A.*?(<html)/m, '\\1')
end
