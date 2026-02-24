WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostAggregates AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        ur.Reputation,
        ur.TotalBadges,
        COALESCE(cp.CloseCount, 0) AS CloseCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    pa.Title,
    pa.ViewCount,
    pa.Reputation,
    pa.TotalBadges,
    pa.CloseCount,
    CASE 
        WHEN pa.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    DENSE_RANK() OVER (ORDER BY pa.Reputation DESC) AS ReputationRank
FROM 
    PostAggregates pa
WHERE 
    pa.Reputation > 500
ORDER BY 
    pa.ViewCount DESC, pa.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
