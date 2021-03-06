plHttp
======

Grammar rules as defined in the various HTTP specification documents.



Terminology
-----------

Messages flow from **unstream** to **downstream**.

**Inbound** means toward the origin server;
**outbound** means toward the user agent.

A *proxy* is a message-forwarding agent select by the client.

A **gateway** or **reverse proxy** is an intermediary that acts
as the origin server and forwards requests to another server(s).

A **tunnel** is a blind relay between two connections
and uses no message caching.

An **interception proxy** or **transparent proxy** or **captive portal**
is not selected by the client.

A **cache* is a local store of previous response messages,
plus the subsystem that controls message storage/retrieval/deletion.
Both clients and servers may employ caches.

A response is **cacheable** if a cache is allowed to store a copy
for use in subsequent reuqests.

  * **Age**
    The age of a response is the time since it was sent by, or
    successfully validated with, the origin server.
  * **Entity**
    The payload of the message.
  * **Expiration date**
    Either the *Explicit expiration time* or the *Heuristic expiration time*.
  * **Explicit expiration time**
    The time at which the origin server intends that an entity should
     no longer be returned by a cache without further validation.
  * **First-hand**
    A response is first-hand if it comes directly and without
    unnecessary delay from the origin server, perhaps via one or more
    proxies, or if its validity has just been checked directly with
    the origin server.
  * **Fresh**
    The property of a response for which `age < freshness lifetime`.
  * **Freshness lifetime**
    The length of time between the generation of a response and its
    expiration time.
  * **Gateway**
    A receiving agent.
    Acting as if it were the origin server for the requested resource.
  * **Heuristic expiration time**
    An expiration time assigned by a cache when no explicit expiration
     time is available.
  * **Inbound/outbound**
    Traveling toward the origin server. / Traveling toward the user agent.
  * **Intermediary**
    A *Gateway*, *Proxy* or *Tunnel*
  * **Pipelining**
    Sending multiple requests without waiting for each response.
  * **Proxy**
    A forwarding agent, making requests on behalf of other clients.
  * **Representation**
    An entity included with a response that is subject to content negotiation.
    Information that is intended to reflect a past, current, or desired state
     of a given resource, in a format that can be readily communicated via the
     HTTP protocol, and that consists of a set of representation metadata and
     a potentially unbounded stream of representation data.
  * **Resource**
    A network data object or service that can be identified by a URI.
    The possible target of an HTTP request.
  * **Stale**
    The property of a response for which `age >= freshness lifetime`.
  * **Transforming proxy**
    An HTTP-to-HTTP proxy that is designed or configured to modify messages in
     a semantically meaningful way (i.e., modifications, beyond those required
     by normal HTTP processing, that change the message in a way that would be
     significant to the original sender or potentially significant to
     downstream recipients).
  * **Transparent proxy**
    A proxy that does not modify the request or response beyond
     what is required for proxy authentication and identification.
  * **Tunnel**
    An intermediary program which is acting as a blind relay between
     two connections.
    A tunnel is not considered a party to the HTTP communication.
  * **Upstream/downstream**
    All messages flow from upstream to downstream.
  * **Validator**
    A protocol element (e.g., an entity tag or a Last-Modified time)
     that is used to find out whether a cache entry is an equivalent
     copy of an entity.
  * **Variant**
    A resource may have one, or more than one, representation(s)
     associated with it at any given instant.
    Use of the term 'variant' does not necessarily imply that the resource
     is subject to content negotiation.



Client request
--------------

Components:
  - Method
  - URI
  - Protocol version
  - MIME-like message:
    - Client information
    - Request modifiers
    - Body content



Server response
---------------

Components:

  - Protocol version
  - Success or error code
  - MIME-like message:
    - Server information
    - Entity meta-information
    - Entity-body content



Method
------

  - CONNECT
    Establish a tunnel to the server identified by the target resource.
  - DELETE
    Remove all current representations of the target resource.
  - GET
    Transfer a current representation of the target resource.
  - HEAD
    Same as GET, but only transfer the status line and header section.
  - OPTIONS
    Describe the communication options for the target resource.
  - POST
    Perform resource-specific processing on the request payload.
  - PUT
    Replace all current representations of the target resource with the
    request payload.
  - TRACE
    Perform a message loop-back test along the path to the target resource.



BNF and DCG
-----------

In BNFs there are (at least) three ways for writing an optional component:
  1. Using square brackets (e.g., [1]).
  2. Using the Regular Expression operator `?` (e.g., [2]).
  2. Using counters (e.g., [3]).

~~~{.abnf}
[1]   a = b [c]
[2]   a = b ?c
[3]   a = b 0*1(c)
~~~

Sometimes we come accross mixtures of BNF syntax, as in [4].
Some productions of [4] have multiple parse trees (ambiguity):
  - No field value.
  - A field value consisting of zero field contents and
    zero linear white spaces.

~~~{.abnf}
[4] message-header = field-name ":" [ field-value ]
    field-value = *( field-content | LWS )
~~~

We observe that BNF usage is often directed towards producing all and only
conforming strings, but not to the way in which the end result is
constructed (i.e., BNF grammars are sometimes used as decision procedures
that cannot be used to perform structural analysis in all cases).



Content Negotiation
-------------------

Variants:
  1. **Proactive**: The server selects the representation based upon the user
     agent's stated preferences.
     Adventageous when:
       - The algorithm for selecting from among the available representations
         is difficult to describe to a user agent.
       - The server desires to send its "best guess" to the user agent along
         with the first response (hoping to avoid the round trip delay of a
         subsequent request if the "best guess" is good enough for the user).
     Disadvantages:
       - The server cannot always determine what is "best" for the user
         because it has limited knowledge of user agent capabilities
         and intended response use.
       - Having the user agent describe its capabilities in every request is
         inefficient if many responses do not have multiple representations.
       - Having the user agent descrive its capabilities is a potential risk
         to user privacy.
       - Limits the reusability of responses for shared caching.
  2. **Reactive**: The server provides a list of representations for the user
     agent to choose from.
     Advantageous when:
       - The response would vary over commonly used dimensions.
       - The origin server is unable to determine user agent capabilities
         based on the request.
       - Public caches are used to distribute server load and reduce network
         usage.
     Disadvantages:
       - Needs a second request to obtain an alternate representation.
  3. **Conditional content**: The representation consists of multiple parts
     that are selectively rendered based on user agent parameters.
  4. **Active content**: The representation contains a script that makes
     additional (more specific) requests based on the user agent
     characteristics.
  5. **Transparent Content Negotiation**: Content selection is performed by
     an intermediary.



References
----------

The current HTTP specification documents:

  1. RFC 7230: Message Syntax and Routing
  2. RFC 7231: Semantics and Content
  3. RFC 7232: Conditional Requests
  4. RFC 7233: Range Requests
  5. RFC 7234: Caching
  6. RFC 7235: Authentication

Obsolete HTTP specification documents:

  1. RFC 2145: HTTP versioning
  2. RFC 2616: HTTP 1.1
  3. RFC 2817: Use of CONNECT to establish a tunnel
  4. RFC 2818: Informal description of HTTPS scheme

The current HTTP specification documents make use of the following documents:

  1. RFC 1919: Transparent proxy
  2. RFC 2045: MIME
  3. RFC 3040: Interception proxy
  4. RFC 3986: URI
  5. RFC 5234: ABNF
  6. RFC 5246: TLS 
  7. RFC 5322: Internet mail
