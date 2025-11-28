#!/bin/bash
# Check memory configuration for Gradle builds
# Displays current memory settings and recommendations

echo "=== Gradle Memory Configuration ==="
echo ""

# Check GRADLE_OPTS
if [ -n "$GRADLE_OPTS" ]; then
    echo "GRADLE_OPTS: $GRADLE_OPTS"
    
    # Extract heap size
    HEAP_SIZE=$(echo "$GRADLE_OPTS" | grep -oP '(?<=-Xmx)\d+[mMgG]' || echo "not found")
    if [ "$HEAP_SIZE" != "not found" ]; then
        echo "  Heap size: $HEAP_SIZE"
    fi
    
    # Extract metaspace size
    METASPACE_SIZE=$(echo "$GRADLE_OPTS" | grep -oP '(?<=-XX:MaxMetaspaceSize=)\d+[mMgG]' || echo "not found")
    if [ "$METASPACE_SIZE" != "not found" ]; then
        echo "  MaxMetaspaceSize: $METASPACE_SIZE"
    fi
else
    echo "GRADLE_OPTS: not set (using defaults)"
fi

echo ""

# Check JAVA_OPTS
if [ -n "$JAVA_OPTS" ]; then
    echo "JAVA_OPTS: $JAVA_OPTS"
else
    echo "JAVA_OPTS: not set"
fi

echo ""

# System memory info
if [ -f /proc/meminfo ]; then
    TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_MEM_GB=$((TOTAL_MEM / 1024 / 1024))
    AVAIL_MEM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    AVAIL_MEM_GB=$((AVAIL_MEM / 1024 / 1024))
    
    echo "System Memory:"
    echo "  Total: ${TOTAL_MEM_GB}GB"
    echo "  Available: ${AVAIL_MEM_GB}GB"
    echo ""
    
    # Recommendations
    echo "Recommendations:"
    if [ "$TOTAL_MEM_GB" -lt 8 ]; then
        echo "  ⚠️  Low memory system (<8GB). Consider:"
        echo "     GRADLE_OPTS='-Xmx2048m -XX:MaxMetaspaceSize=512m'"
    elif [ "$TOTAL_MEM_GB" -lt 16 ]; then
        echo "  ✓ Medium memory system (8-16GB). Default settings should work:"
        echo "     GRADLE_OPTS='-Xmx4096m -XX:MaxMetaspaceSize=1024m'"
    else
        echo "  ✓ High memory system (>16GB). Can use more aggressive settings:"
        echo "     GRADLE_OPTS='-Xmx8192m -XX:MaxMetaspaceSize=2048m'"
    fi
fi

echo ""
echo "For Cloud Build N1_HIGHCPU_8 (7.5GB RAM):"
echo "  Recommended: GRADLE_OPTS='-Xmx4096m -XX:MaxMetaspaceSize=1024m'"
echo "  Use: --no-daemon --max-workers=1 --no-parallel"

