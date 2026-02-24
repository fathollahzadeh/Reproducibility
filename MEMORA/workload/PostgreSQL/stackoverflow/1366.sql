WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Reputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Reputation,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(v.TotalVotes, 0) AS TotalVotes
    FROM 
        RecentPosts rp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS TotalVotes 
         FROM Votes 
         GROUP BY PostId) v ON rp.PostId = v.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.Reputation,
    ps.CommentCount,
    ps.TotalVotes,
    CASE 
        WHEN ps.Reputation > 1000 THEN 'High Reputation User'
        ELSE 'User with Low Reputation'
    END AS UserReputationCategory,
    CASE 
        WHEN ps.Score > 10 THEN 'Popular Post'
        WHEN ps.Score BETWEEN 1 AND 10 THEN 'Moderate Post'
        ELSE 'Less Popular Post'
    END AS PostPopularityCategory
FROM 
    PostSummary ps
WHERE 
    ps.Reputation IS NOT NULL
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 50;