# Kong Plugin OAuth JWT

summary: Validates JWT

## Shared Dict

Needs shared dict. Export variable `KONG_NGINX_HTTP_LUA_SHARED_DICT=oauth_jwt_shared_dict 32m`.

<!-- BEGINNING OF KONG-PLUGIN DOCS HOOK -->
## Plugin Priority

Priority: **1000**

## Plugin Version

Version: **0.1.0**

## Configs

| name | type | required | default | validations |
| ---- | ---- | -------- | ------- | ----------- |
| config.on_invalid_jwt | **string** | true | <pre>redirect_to_oauth_authorize_endpoint</pre> | <pre>- one_of:<br/>  - redirect_to_oauth_authorize_endpoint<br/>  - return_unauthorized</pre> |
| config.return_unauthorized_custom_response_headers | **map[string][string]** (*check `'config.return_unauthorized_custom_response_headers' object`) | true |  |  |
| config.state_algorithm | **string** | true | <pre>sha256</pre> | <pre>- one_of:<br/>  - sha256<br/>  - sha1<br/>  - md5</pre> |
| config.state_secret | **string** | false |  |  |
| config.state_redirect_force_scheme | **string** | false |  | <pre>- one_of:<br/>  - http<br/>  - https</pre> |
| config.state_redirect_force_host | **string** | false |  |  |
| config.state_redirect_force_port | **number** | false |  |  |
| config.jwt_keys | **map[string][string]** (*check `'config.jwt_keys' object`) | true |  |  |
| config.oauth_provider | **string** | true | <pre>google</pre> | <pre>- one_of:<br/>  - custom<br/>  - facebook<br/>  - github<br/>  - gitlab<br/>  - google<br/>  - microsoft<br/>  - yandex<br/>  - zoho</pre> |
| config.oauth_provider_authorize_endpoint | **string** | false |  |  |
| config.oauth_provider_authorize_endpoint_querystring_more | **map[string][string]** (*check `'config.oauth_provider_authorize_endpoint_querystring_more' object`) | true |  |  |
| config.oauth_scopes | **set of strings** | false |  |  |
| config.oauth_client_id | **string** | true |  |  |
| config.oauth_callback_url | **string** | true |  |  |
| config.find_token_at_query_params | **set of strings** | true | <pre>- oauth_jwt</pre> |  |
| config.find_token_at_cookies | **set of strings** | true | <pre>- oauth_jwt</pre> |  |
| config.find_token_at_headers | **set of strings** | true | <pre>- Authorization</pre> |  |
| config.find_token_at_headers_bearer_prefix | **boolean** | true | <pre>true</pre> |  |
| config.use_cache | **boolean** | true | <pre>true</pre> |  |
| config.override_ttl | **boolean** | true |  |  |
| config.ttl | **number** | true | <pre>120</pre> |  |
| config.run_on_preflight | **boolean** | true |  |  |
| config.run_on_connection_upgrade | **boolean** | true | <pre>true</pre> |  |
| config.validate_jwt_claim_exp | **boolean** | true | <pre>true</pre> |  |
| config.valid_jwt_claim_iss | **set of strings** | false | <pre>- kong</pre> |  |
| config.valid_jwt_claim_domains | **set of strings** | false |  |  |
| config.valid_jwt_claim_sub_allowlist | **set of strings** | false |  |  |
| config.valid_jwt_claim_sub_denylist | **set of strings** | false |  |  |
| config.claims_to_headers | **array of records** | true | <pre>- header: x-token-sub<br/>  claim: sub</pre> |  |
| config.claims_to_validate | **map[string][record]** (*check `'config.claims_to_validate' object`) | false | <pre>iss:<br/>  values_are_regex: false<br/>  accepted_values:<br/>  - kong</pre> |  |
| config.use_cache_authz | **boolean** | true | <pre>true</pre> |  |
| config.authz_ttl | **number** | true | <pre>1800</pre> |  |

### 'config.return_unauthorized_custom_response_headers' object

| keys_type | keys_validations | values_type | values_required | values_default | values_validations |
| --------- | ---------------- | ----------- | --------------- | -------------- | ------------------ |
| **string** |  | **string** | true |  |  |

### 'config.jwt_keys' object

| keys_type | keys_validations | values_type | values_required | values_default | values_validations |
| --------- | ---------------- | ----------- | --------------- | -------------- | ------------------ |
| **string** |  | **string** | true |  |  |

### 'config.oauth_provider_authorize_endpoint_querystring_more' object

| keys_type | keys_validations | values_type | values_required | values_default | values_validations |
| --------- | ---------------- | ----------- | --------------- | -------------- | ------------------ |
| **string** |  | **string** | true |  |  |

### 'config.claims_to_validate' object

| keys_type | keys_validations | values_type | values_required | values_default | values_validations |
| --------- | ---------------- | ----------- | --------------- | -------------- | ------------------ |
| **string** |  |  |  |  |  |

## Usage

```yaml
---
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
    state_redirect_force_port: 0
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
    claims_to_validate: {}
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
