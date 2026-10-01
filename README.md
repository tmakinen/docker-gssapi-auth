# GSSAPI Authentication Container

A lightweight, minimal Apache container acting as a stateless authentication helper for reverse proxies using Nginx `auth_request`. It validates Kerberos/GSSAPI tokens (`Negotiate`), performs automatic realm stripping on the username, and returns the cleaned identity in a response header.

## Environment Variables

| Variable | Description | Example |
| :--- | :--- | :--- |
| `KERBEROS_REALM` | The Kerberos realm / Active Directory domain. | `EXAMPLE.COM` |
| `KERBEROS_KDC` | The KDC server endpoint or proxy URL. | `https://kdc.example.com/KdcProxy` |

## Volumes

* `/etc/krb5.keytab`: Read-only bind mount containing the service principal keys (`HTTP/host.example.com@EXAMPLE.COM`).

## Docker Compose Example

```yaml
---
services:
  gssapi-auth-service:
    build: .
    ports:
      - "8000:8000"
    environment:
      - KERBEROS_REALM=EXAMPLE.COM
      - KERBEROS_KDC=https://kdc.example.com/KdcProxy
    volumes:
      - /etc/krb5.keytab:/etc/krb5.keytab:ro
    restart: always
```

## Protocol Specifications

* **Successful Validation**: Returns `200 OK` with the response header `X-Remote-User: username`.
* **Failed / Missing Token**: Returns `401 Unauthorized` with the header `WWW-Authenticate: Negotiate`.

## Nginx Generic Integration Example

A basic example demonstrating how to lock down a generic path (`/protected-resource`) using the centralized GSSAPI verification container.

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    # Internal routing location pointing to the GSSAPI container endpoint
    location = /internal/auth-gssapi {
        internal;
        proxy_pass http://gssapi-auth-service:8000/;
        proxy_set_header Host $host;
        proxy_set_header Connection "";
        proxy_set_header Content-Length "";
        proxy_pass_request_body off;
    }

    # The specific path requiring Kerberos/GSSAPI verification
    location /protected-resource {
        # Trigger the subrequest to the GSSAPI helper container
        auth_request /internal/auth-gssapi;
        
        # Capture the cleaned username response header from the Apache container
        auth_request_set $auth_user $upstream_http_x_remote_user;
        
        # Pass the verified username down to the destination backend server
        proxy_set_header X-Remote-User $auth_user;
        
        proxy_pass http://127.0.0.1:8080;
    }
}
```
