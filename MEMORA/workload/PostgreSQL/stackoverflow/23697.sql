
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id AND c.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')) AS RecentComments
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.UserDisplayName AS ClosedBy,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(av.NetVotes, 0) AS NetVotes,
    rp.RecentComments,
    CASE 
        WHEN rp.Rank = 1 AND rp.AnswerCount > 0 THEN 'Top Question'
        WHEN rp.RecentComments > 5 THEN 'High Interaction'
        ELSE 'Regular'
    END AS PostTypeCategory,
    u.UserId,
    u.PostsCreated,
    u.TotalBadgeClass,
    cp.CloseReason,
    cp.ClosedBy
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
LEFT JOIN 
    UserInteractions u ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId)
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.Id
WHERE 
    (rp.Score > 10 OR rp.RecentComments > 3)
    AND (rp.ViewCount - COALESCE(av.NetVotes, 0)) > 25
    AND (u.PostsCreated > 5 OR av.NetVotes IS NOT NULL)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 100;
