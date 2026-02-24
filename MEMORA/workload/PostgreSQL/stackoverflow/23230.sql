WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
AggregatedVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.CreationDate,
    CASE 
        WHEN ur.TotalReputation > 1000 THEN 'High Reputation'
        WHEN ur.TotalReputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation' 
    END AS ReputationCategory,
    av.Upvotes,
    av.Downvotes,
    ph.CloseCount,
    ph.DeleteCount
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    AggregatedVotes av ON p.PostId = av.PostId
LEFT JOIN 
    PostHistoryAnalysis ph ON p.PostId = ph.PostId
WHERE 
    p.PostRank = 1
    AND ur.BadgeCount IS NOT NULL
    AND (av.Upvotes IS NULL OR av.Upvotes > av.Downvotes)
ORDER BY 
    p.CreationDate DESC
LIMIT 100;