# Kong Plugin OAuth JWT

summary: Validates JWT

## Shared Dict

Needs shared dict. Export variable `KONG_NGINX_HTTP_LUA_SHARED_DICT=oauth_jwt_shared_dict 32m`.

<!-- BEGINNING OF KONG-PLUGIN DOCS HOOK -->
## Plugin Priority

Priority: **1000**

## Plugin Version

Version: **0.1.0**

## config

| name | type | required | validations | default |
|-----|-----|-----|-----|-----|
| on_invalid_jwt | string | <pre>true</pre> | <pre>- one_of:<br/>  - redirect_to_oauth_authorize_endpoint<br/>  - return_unauthorized</pre> | <pre>redirect_to_oauth_authorize_endpoint</pre> |
| return_unauthorized_custom_response_headers | map[string][string] | <pre>true</pre> |  |  |
| state_algorithm | string | <pre>true</pre> | <pre>- one_of:<br/>  - sha256<br/>  - sha1<br/>  - md5</pre> | <pre>sha256</pre> |
| state_secret | string | <pre>false</pre> |  |  |
| state_redirect_force_scheme | string | <pre>false</pre> | <pre>- one_of:<br/>  - http<br/>  - https</pre> |  |
| state_redirect_force_host | string | <pre>false</pre> |  |  |
| state_redirect_force_port | number | <pre>false</pre> |  |  |
| jwt_keys | map[string][string] | <pre>true</pre> |  |  |
| oauth_provider | string | <pre>true</pre> | <pre>- one_of:<br/>  - custom<br/>  - facebook<br/>  - github<br/>  - gitlab<br/>  - google<br/>  - microsoft<br/>  - yandex<br/>  - zoho</pre> | <pre>google</pre> |
| oauth_provider_authorize_endpoint | string | <pre>false</pre> |  |  |
| oauth_provider_authorize_endpoint_querystring_more | map[string][string] | <pre>true</pre> |  |  |
| oauth_scopes | set of strings | <pre>false</pre> |  |  |
| oauth_client_id | string | <pre>true</pre> |  |  |
| oauth_callback_url | string | <pre>true</pre> |  |  |
| find_token_at_query_params | set of strings | <pre>true</pre> |  | <pre>- oauth_jwt</pre> |
| find_token_at_cookies | set of strings | <pre>true</pre> |  | <pre>- oauth_jwt</pre> |
| find_token_at_headers | set of strings | <pre>true</pre> |  | <pre>- Authorization</pre> |
| find_token_at_headers_bearer_prefix | boolean | <pre>true</pre> |  | <pre>true</pre> |
| use_cache | boolean | <pre>true</pre> |  | <pre>true</pre> |
| override_ttl | boolean | <pre>true</pre> |  | <pre>false</pre> |
| ttl | number | <pre>true</pre> |  | <pre>120</pre> |
| run_on_preflight | boolean | <pre>true</pre> |  | <pre>false</pre> |
| run_on_connection_upgrade | boolean | <pre>true</pre> |  | <pre>true</pre> |
| validate_jwt_claim_exp | boolean | <pre>true</pre> |  | <pre>true</pre> |
| valid_jwt_claim_iss | set of strings | <pre>false</pre> |  | <pre>- kong</pre> |
| valid_jwt_claim_domains | set of strings | <pre>false</pre> |  |  |
| valid_jwt_claim_sub_allowlist | set of strings | <pre>false</pre> |  |  |
| valid_jwt_claim_sub_denylist | set of strings | <pre>false</pre> |  |  |
| claims_to_headers | array of records** | <pre>true</pre> |  | <pre>- claim: sub<br/>  header: x-token-sub</pre> |
| claims_to_validate | map[string][record**] | <pre>false</pre> |  |  |
| use_cache_authz | boolean | <pre>true</pre> |  | <pre>true</pre> |
| authz_ttl | number | <pre>true</pre> |  | <pre>1800</pre> |

### record** of claims_to_headers

| name | type | required | validations | default |
|-----|-----|-----|-----|-----|
| claim | string | <pre>true</pre> |  |  |
| header | string | <pre>true</pre> |  |  |

### record** of claims_to_validate

| name | type | required | validations | default |
|-----|-----|-----|-----|-----|
| values_are_regex | boolean | <pre>false</pre> |  | <pre>false</pre> |
| accepted_values | array of strings | <pre>false</pre> |  |  |

## Usage

```yaml
plugins:
  - name: oauth-jwt
    enabled: true
    config:
      on_invalid_jwt: redirect_to_oauth_authorize_endpoint
      return_unauthorized_custom_response_headers: {}
      state_algorithm: sha256
      state_secret: ''
      state_redirect_force_scheme: ''
      state_redirect_force_host: ''
      state_redirect_force_port: 0.0
      jwt_keys: {}
      oauth_provider: google
      oauth_provider_authorize_endpoint: ''
      oauth_provider_authorize_endpoint_querystring_more: {}
      oauth_scopes: []
      oauth_client_id: ''
      oauth_callback_url: ''
      find_token_at_query_params:
        - oauth_jwt
      find_token_at_cookies:
        - oauth_jwt
      find_token_at_headers:
        - Authorization
      find_token_at_headers_bearer_prefix: true
      use_cache: true
      override_ttl: false
      ttl: 120
      run_on_preflight: false
      run_on_connection_upgrade: true
      validate_jwt_claim_exp: true
      valid_jwt_claim_iss:
        - kong
      valid_jwt_claim_domains: []
      valid_jwt_claim_sub_allowlist: []
      valid_jwt_claim_sub_denylist: []
      claims_to_headers:
        - header: x-token-sub
          claim: sub
      claims_to_validate:
        some_key:
          values_are_regex: false
          accepted_values: []
      use_cache_authz: true
      authz_ttl: 1800

```
<!-- END OF KONG-PLUGIN DOCS HOOK -->

### Gluu Example

```yaml
---
plugins:
  - name: oauth-jwt
    enabled: true
    config:
      state_secret: mystatesecret
      jwt_keys:
        privkey1: |
          -----BEGIN PUBLIC KEY-----
          MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAO+G+jiCIvgyNETd/YAR3b40Ag+oWEQ2
          QX1yau1ZbKRs2lUm7YqYxloV2uVLql/y/1MPnV+BtGviMKLNB6KHN0ECAwEAAQ==
          -----END PUBLIC KEY-----
      oauth_provider: custom
      oauth_client_id: myclientid
      oauth_callback_url: http://localhost:8000/auth/callback
      oauth_provider_authorize_endpoint: https://my-gluu-server.com/oxauth/restv1/authorize
```
