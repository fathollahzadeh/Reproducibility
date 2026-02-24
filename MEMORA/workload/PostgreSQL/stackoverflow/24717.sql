WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClass,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.TotalBadgeClass,
        ur.PostCount,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation > 1000
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCounts,
        ARRAY_AGG(DISTINCT c.Name) AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    COALESCE(cp.ClosureCounts, 0) AS ClosureCounts,
    COALESCE(cp.CloseReasonNames, '{}') AS CloseReasonNames,
    tu.Reputation AS UserReputation,
    tu.ReputationRank AS UserReputationRank
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON p.PostId = cp.PostId
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
WHERE 
    p.Score > 0
    AND p.CommentCount > 0
    AND (tu.ReputationRank IS NULL OR tu.ReputationRank <= 10)
ORDER BY 
    p.Score DESC,
    p.ViewCount DESC
LIMIT 100;