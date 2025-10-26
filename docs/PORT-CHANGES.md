# Port Configuration Changes - Fix Summary

## Issue
The original configuration used port 8080, which was already in use on the system, causing the Kind cluster creation to fail with the error:
```
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint awx-cluster-control-plane: Bind for 0.0.0.0:8080 failed: port is already allocated
```

## Solution
Changed the port configuration to use non-conflicting ports:

### Port Changes
- **AWX Web Interface**: `8080` → `9080`
- **AWX HTTPS**: `8443` → `9443`

## Files Updated

### 1. Configuration Files
- `kind-cluster-config.yaml` - Updated port mappings
- `awx-instance.yaml` - No changes needed (uses internal ports)
- `awx-pv.yaml` - No changes needed

### 2. Documentation
- `README.md` - Updated all port references from 8080 to 9080
- `Architecture.md` - Updated architecture diagrams and port references

### 3. Scripts
- `access-awx.sh` - Updated port-forwarding commands
- `health-check.sh` - Updated health check URLs and commands
- `quick-deploy.sh` - Updated deployment instructions and port references
- `backup-awx.sh` - No changes needed
- `cleanup.sh` - No changes needed
- **NEW**: `check-ports.sh` - Added port availability checker

## New Access Information

### URLs
- **AWX Web Interface**: `http://localhost:9080` (was 8080)
- **AWX HTTPS**: `https://localhost:9443` (was 8443)

### Port Forwarding Commands
```bash
# AWX Web Interface
kubectl port-forward service/awx-service 9080:80 -n awx

# PostgreSQL (optional - may conflict if local PostgreSQL is running)
kubectl port-forward service/awx-postgres 5432:5432 -n awx
```

### Access Scripts
```bash
# Check port availability before deployment
./check-ports.sh

# Quick deployment (now includes port check)
./quick-deploy.sh

# Easy access with credentials
./access-awx.sh

# Health monitoring
./health-check.sh
```

## Verification Steps

1. **Check ports are available**:
   ```bash
   ./check-ports.sh
   ```

2. **Deploy AWX**:
   ```bash
   ./quick-deploy.sh
   ```

3. **Access AWX**:
   ```bash
   ./access-awx.sh
   # Or manually:
   kubectl port-forward service/awx-service 9080:80 -n awx
   # Then open: http://localhost:9080
   ```

## Benefits of New Configuration

1. **No Port Conflicts**: Uses uncommon ports (9080/9443) that are unlikely to conflict
2. **Automated Checking**: New port-check script prevents deployment issues
3. **Easy Migration**: All existing functionality works with new ports
4. **Clear Documentation**: All references updated consistently

## Rollback (if needed)

To revert to original ports (8080/8443), update these files:
- `kind-cluster-config.yaml` - Change hostPort values back
- `README.md` - Update port references
- `Architecture.md` - Update port references
- All shell scripts - Update port references

## Additional Notes

- **PostgreSQL Port**: Port 5432 may conflict with local PostgreSQL installations, but this is optional for AWX operation
- **Kind Cluster**: Uses internal networking, so only the host port mappings needed to change
- **Security**: No additional security considerations with new ports
- **Performance**: No performance impact from port changes
