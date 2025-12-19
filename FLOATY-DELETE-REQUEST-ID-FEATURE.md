# Floaty Delete Request-ID Feature

**Branch**: P4DEVOPS-floaty-delete-request-id  
**PR Link**: https://github.com/puppetlabs/vmfloaty/pull/new/P4DEVOPS-floaty-delete-request-id  
**Date**: December 19, 2025

---

## Problem Statement

Previously, `floaty delete` only supported deleting VMs by hostname. Users had no way to:
1. Cancel pending ondemand VM requests before they complete
2. Bulk-delete all VMs from a completed ondemand request in one command

This required users to either:
- Wait for unwanted requests to complete, then delete VMs individually
- Manually track which VMs belonged to which request
- Use the vmpooler API directly via curl

---

## Solution

Extended `floaty delete` to accept request-ids (UUID format) in addition to hostnames.

### Behavior

When `floaty delete <request-id>` is called:
1. **For pending requests**: Marks the request status as 'deleted' to cancel provisioning
2. **For completed requests**: Moves all provisioned VMs to the termination queue
3. **Mixed input**: Can handle both hostnames and request-ids in the same command

### UUID Detection

The implementation uses a regex pattern to detect UUID format:
```ruby
/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
```

When a UUID is detected, floaty uses the `DELETE /ondemandvm/:requestid` endpoint instead of the regular `DELETE /vm/:hostname` endpoint.

---

## Implementation Details

### Files Changed

1. **lib/vmfloaty/pooler.rb** - Modified `Pooler.delete` method
   - Added UUID detection logic
   - Routes to appropriate endpoint based on input format
   - Maintains backward compatibility with hostname deletion

2. **lib/vmfloaty.rb** - Updated command documentation
   - Added new syntax example for request-id deletion
   - Updated description to mention ondemand request cancellation

3. **spec/vmfloaty/pooler_spec.rb** - Added comprehensive tests
   - Test single request-id deletion
   - Test multiple request-id deletion
   - Test mixed hostname and request-id deletion

4. **Gemfile** - Added Ruby 3.1+ compatibility gems
   - `abbrev` - Required by commander gem in Ruby 3.1+
   - `base64` - Required by spec_helper in Ruby 3.1+

### Code Changes

**Before**:
```ruby
def self.delete(verbose, url, hosts, token, _user)
  raise TokenError, 'Token provided was nil.' if token.nil?
  
  conn = Http.get_conn(verbose, url)
  conn.headers['X-AUTH-TOKEN'] = token if token
  
  response_body = {}
  hosts.each do |host|
    response = conn.delete "vm/#{host}"
    res_body = JSON.parse(response.body)
    response_body[host] = res_body
  end
  
  response_body
end
```

**After**:
```ruby
def self.delete(verbose, url, hosts, token, _user)
  raise TokenError, 'Token provided was nil.' if token.nil?
  
  conn = Http.get_conn(verbose, url)
  conn.headers['X-AUTH-TOKEN'] = token if token
  
  response_body = {}
  hosts.each do |host|
    # Check if this looks like a request-id (UUID format)
    if host =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      # This is a request-id, use the ondemandvm endpoint
      response = conn.delete "ondemandvm/#{host}"
      res_body = JSON.parse(response.body)
      response_body[host] = res_body
    else
      # This is a hostname, use the vm endpoint
      response = conn.delete "vm/#{host}"
      res_body = JSON.parse(response.body)
      response_body[host] = res_body
    end
  end
  
  response_body
end
```

---

## Usage Examples

### Delete a single ondemand request
```bash
floaty delete e3ff6271-d201-4f31-a315-d17f4e15863a
```

### Delete multiple requests
```bash
floaty delete e3ff6271-d201-4f31-a315-d17f4e15863a,a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

### Delete mixed hostnames and requests
```bash
floaty delete myvm1,e3ff6271-d201-4f31-a315-d17f4e15863a,myvm2
```

### Get request-id from ondemand request
```bash
# When you create an ondemand request, you get a request_id
floaty get centos-7-x86_64=5 --ondemand
# Output includes: "request_id": "e3ff6271-d201-4f31-a315-d17f4e15863a"

# Later, cancel it or delete completed VMs
floaty delete e3ff6271-d201-4f31-a315-d17f4e15863a
```

---

## Testing

### Test Coverage

All tests pass (142 examples, 0 failures):
```bash
bundle exec rspec
# Finished in 0.90126 seconds
# 142 examples, 0 failures
# Line Coverage: 47.72% (534 / 1119)
```

### New Tests Added

1. **Single request-id deletion**
   - Verifies correct endpoint is called
   - Validates response format

2. **Multiple request-id deletion**
   - Tests batch deletion
   - Ensures each request uses correct endpoint

3. **Mixed hostname and request-id deletion**
   - Validates intelligent routing
   - Confirms backward compatibility

---

## Backend API Support

This feature leverages the existing vmpooler API endpoint:

```
DELETE /api/v3/ondemandvm/:requestid
```

**API Behavior**:
- Sets request status to 'deleted' in Redis
- Moves any provisioned VMs from `running` to `completed` queue
- Returns `{"ok": true}` on success
- Returns 404 if request not found

Reference: [vmpooler API v3 docs](../Vmpooler/vmpooler/docs/API-v3.md#delete-ondemandvm)

---

## Backward Compatibility

✅ **Fully backward compatible** - All existing functionality preserved:
- Regular hostname deletion still works
- Command syntax unchanged for hostnames
- All existing tests continue to pass
- No breaking changes to API

---

## Benefits

1. **Improved UX**: Users can cancel unwanted requests easily
2. **Cost Savings**: Avoid provisioning VMs that won't be used
3. **Cleanup**: Bulk-delete all VMs from a request in one command
4. **Consistency**: Matches ABS behavior (floaty already supports JobID deletion)

---

## Next Steps

1. ✅ Create PR: https://github.com/puppetlabs/vmfloaty/pull/new/P4DEVOPS-floaty-delete-request-id
2. Get code review from vmfloaty maintainers
3. Address any feedback
4. Merge to main branch
5. Create new vmfloaty release with this feature

---

## Related Work

- Inspired by existing ABS JobID deletion support
- Complements ondemand VM provisioning feature added in earlier versions
- Part of broader effort to improve vmpooler queue reliability (P4DEVOPS-8567)
