// Copied from
// https://github.com/jasonish/libevent-examples/blob/6d20f0d86c2cd263f5edff28862bc09ce4a3220f/echo-server/libevent_echosrv1.c
// for testing purposes only.

/*
 * Copyright (c) 2011, Jason Ish
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in
 *   the documentation and/or other materials provided with the
 *   distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * libevent echo server example.
 */

#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>

/* For inet_ntoa. */
#include <arpa/inet.h>

/* Required by event.h. */
#include <sys/time.h>

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Libevent. */
#include <event.h>

/* Port to listen on. */
#define SERVER_PORT 5555

/**
 * A struct for client specific data, in this simple case the only
 * client specific data is the read event.
 */
struct client {
  struct event ev_read;
};

/**
 * Set a socket to non-blocking mode.
 */
int setnonblock(int fd) {
  int flags;

  flags = fcntl(fd, F_GETFL);
  if (flags < 0)
    return flags;
  flags |= O_NONBLOCK;
  if (fcntl(fd, F_SETFL, flags) < 0)
    return -1;

  return 0;
}

/**
 * This function will be called by libevent when the client socket is
 * ready for reading.
 */
void on_read(int fd, short ev, void *arg) {
  struct client *client = (struct client *)arg;
  u_char buf[8196];
  int len, wlen;

  len = read(fd, buf, sizeof(buf));
  if (len == 0) {
    /* Client disconnected, remove the read event and the
     * free the client structure. */
    printf("Client disconnected.\n");
    close(fd);
    event_del(&client->ev_read);
    free(client);
    return;
  } else if (len < 0) {
    /* Some other error occurred, close the socket, remove
     * the event and free the client structure. */
    printf("Socket failure, disconnecting client: %s", strerror(errno));
    close(fd);
    event_del(&client->ev_read);
    free(client);
    return;
  }

  /* XXX For the sake of simplicity we'll echo the data write
   * back to the client.  Normally we shouldn't do this in a
   * non-blocking app, we should queue the data and wait to be
   * told that we can write.
   */
  wlen = write(fd, buf, len);
  if (wlen < len) {
    /* We didn't write all our data.  If we had proper
     * queueing/buffering setup, we'd finish off the write
     * when told we can write again.  For this simple case
     * we'll just lose the data that didn't make it in the
     * write.
     */
    printf("Short write, not all data echoed back to client.\n");
  }
}

/**
 * This function will be called by libevent when there is a connection
 * ready to be accepted.
 */
void on_accept(int fd, short ev, void *arg) {
  int client_fd;
  struct sockaddr_in client_addr;
  socklen_t client_len = sizeof(client_addr);
  struct client *client;

  /* Accept the new connection. */
  client_fd = accept(fd, (struct sockaddr *)&client_addr, &client_len);
  if (client_fd == -1) {
    warn("accept failed");
    return;
  }

  /* Set the client socket to non-blocking mode. */
  if (setnonblock(client_fd) < 0)
    warn("failed to set client socket non-blocking");

  /* We've accepted a new client, allocate a client object to
   * maintain the state of this client. */
  client = calloc(1, sizeof(*client));
  if (client == NULL)
    err(1, "malloc failed");

  /* Setup the read event, libevent will call on_read() whenever
   * the clients socket becomes read ready.  We also make the
   * read event persistent so we don't have to re-add after each
   * read. */
  event_set(&client->ev_read, client_fd, EV_READ | EV_PERSIST, on_read, client);

  /* Setting up the event does not activate, add the event so it
   * becomes active. */
  event_add(&client->ev_read, NULL);

  printf("Accepted connection from %s\n", inet_ntoa(client_addr.sin_addr));
}

int main(int argc, char **argv) {
  int listen_fd;
  struct sockaddr_in listen_addr;
  int reuseaddr_on = 1;

  /* The socket accept event. */
  struct event ev_accept;

  /* Initialize libevent. */
  event_init();

// comment out since it is called from test and should terminate

//  /* Create our listening socket. This is largely boiler plate
//   * code that I'll abstract away in the future. */
//  listen_fd = socket(AF_INET, SOCK_STREAM, 0);
//  if (listen_fd < 0)
//    err(1, "listen failed");
//  if (setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &reuseaddr_on,
//                 sizeof(reuseaddr_on)) == -1)
//    err(1, "setsockopt failed");
//  memset(&listen_addr, 0, sizeof(listen_addr));
//  listen_addr.sin_family = AF_INET;
//  listen_addr.sin_addr.s_addr = INADDR_ANY;
//  listen_addr.sin_port = htons(SERVER_PORT);
//  if (bind(listen_fd, (struct sockaddr *)&listen_addr, sizeof(listen_addr)) < 0)
//    err(1, "bind failed");
//  if (listen(listen_fd, 5) < 0)
//    err(1, "listen failed");
//
//  /* Set the socket to non-blocking, this is essential in event
//   * based programming with libevent. */
//  if (setnonblock(listen_fd) < 0)
//    err(1, "failed to set server socket to non-blocking");
//
//  /* We now have a listening socket, we create a read event to
//   * be notified when a client connects. */
//  event_set(&ev_accept, listen_fd, EV_READ | EV_PERSIST, on_accept, NULL);
//  event_add(&ev_accept, NULL);
//
//  /* Start the libevent event loop. */
//  event_dispatch();

  return 0;
}
