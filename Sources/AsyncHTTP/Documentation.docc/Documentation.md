# ``AsyncHTTP``

Generic Swift networking library with async/await

## Overview

AsyncHTTP

## Topics

### Requests

- ``HTTPRequest``
- ``HTTPRequestOption``
- ``HTTPRequestBody``

### Loading Requests

- ``Loader``
- ``Loaders``
- ``AnyLoader``
- ``HTTPLoader``
- ``CompositeLoader``
- ``HTTPResponse``

### HTTP

- ``HTTPMethod``
- ``HTTPHeader``
- ``AuthorizationHeader``
- ``HTTPStatus``
- ``HTTPVersion``
- ``MIMEType``
- ``URIScheme``

### Timeout

- ``Timeout``
- ``TimeoutOption``

### Retry Strategy

- ``RetryStrategy``
- ``RetryStrategyWrapper``
- ``RetryStrategyOption``
- ``Backoff``

### Server Environment

- ``ServerEnvironment``
- ``ServerEnvironmentOption``

### Identifying Requests

- ``HTTPRequestIdentifier``
- ``HTTPRequestIdentifierOption``

### Formatting

- ``Formatter``
- ``CURLHTTPRequestFormatter``
- ``StandardHTTPRequestFormatter``
- ``StandardHTTPResponseFormatter``
- ``Formattible``
- ``DefaultFormattible``

### Validation

- ``LoaderValidationError``
- ``RequestValidationError``

### Utils

- ``Converted``
- ``ConversionStrategy``
- ``TwoWayConversionStrategy``
- ``DecoderStrategy``
- ``EncoderStrategy``
- ``HTTPFormattible``
