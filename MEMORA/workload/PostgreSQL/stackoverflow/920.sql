
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) FILTER (WHERE c.UserId IS NOT NULL) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
RecentUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName,
        CASE 
            WHEN u.LastAccessDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') THEN 'Active'
            ELSE 'Inactive'
        END AS UserStatus
    FROM 
        Users u
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Title,
    ru.DisplayName AS Owner,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.ScoreRank,
    COALESCE(rpc.EditCount, 0) AS EditCount,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    COALESCE(rp.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(rp.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(DENSE_RANK() OVER (ORDER BY rp.ViewCount DESC), 0) AS ViewRank,
    COALESCE(rp.UpVoteCount - rp.DownVoteCount, 0) AS NetVotes,
    CASE 
        WHEN rp.Score > 100 THEN 'Highly Popular'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityTier
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentUsers ru ON rp.OwnerUserId = ru.Id
LEFT JOIN 
    PostHistoryCounts rpc ON rp.Id = rpc.PostId
WHERE 
    rp.ScoreRank = 1
    AND rp.ViewCount > 10
ORDER BY 
    rp.CreationDate DESC
LIMIT 100 OFFSET 0;
