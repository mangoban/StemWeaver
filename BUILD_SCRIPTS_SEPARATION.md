# Build Scripts Separation

## Problem
GitHub Actions workflow was failing with:
```
mkdir: cannot create directory '/home/bendeb': Permission denied
```

## Root Cause
The build scripts were trying to use `/home/bendeb/build_temp` as a temp directory, which:
1. Doesn't exist in GitHub Actions environment
2. Can't be created due to permission restrictions
3. Caused the build to fail

## Solution
Created separate build scripts for different environments:

### 1. `build.sh` (Local Use)
- **Purpose**: Interactive local builds with menu
- **Temp Directory**: Tries `/home/bendeb/build_temp`, falls back to `/tmp/stemweaver_build`
- **Features**: 
  - Interactive menu (Options 1-6)
  - Auto-cleanup before builds
  - Build logs in `.build_logs/`
  - Progress indicators

### 2. `packaging/build_appimage_github.sh` (GitHub Actions)
- **Purpose**: CI/CD builds
- **Temp Directory**: Always uses `/tmp/stemweaver_build`
- **Features**:
  - No interactive elements
  - Works in restricted environments
  - Uses only default paths
  - No permission issues

### 3. `packaging/build_appimage.sh` (Universal)
- **Purpose**: Can be used by both, but `build.sh` calls it
- **Temp Directory**: Smart detection (tries custom, falls back to /tmp)
- **Status**: Still works, but GitHub workflow now uses the GitHub-specific version

## Changes Made

### Files Modified:
1. **`build.sh`**
   - Updated temp directory logic to use `mkdir -p` with error checking
   - Prevents permission errors on local systems

2. **`packaging/build_appimage.sh`**
   - Same temp directory fix as build.sh
   - More robust error handling

3. **`packaging/build_appimage_github.sh`** (NEW)
   - GitHub-specific build script
   - Uses only `/tmp` (no custom paths)
   - No permission checks needed

4. **`.github/workflows/build_all.yml`**
   - Updated to use `build_appimage_github.sh`
   - Both x86_64 and ARM64 builds updated

## How It Works

### Local Development:
```bash
cd /home/bendeb/stemweaver
./build.sh
# Select option 1 for AppImage
```

### GitHub Actions:
```yaml
- name: Build AppImage
  run: packaging/build_appimage_github.sh
```

## Benefits

✅ **No permission errors** in GitHub Actions  
✅ **Local builds still work** with custom temp directory  
✅ **Separation of concerns** - local vs CI  
✅ **More robust** - better error handling  
✅ **Future-proof** - easy to maintain both environments  

## Testing

To test the fix works:

### Local:
```bash
cd /home/bendeb/stemweaver
./build.sh
# Should work without errors
```

### GitHub:
- Push a tag (e.g., `v1.1.1-test`)
- Workflow should complete successfully
- Check Actions tab for results

## Summary

The separation ensures:
- **Local users** get the best experience (fast builds with custom temp dir)
- **GitHub Actions** gets reliable builds (no permission issues)
- **Both** produce identical AppImages
