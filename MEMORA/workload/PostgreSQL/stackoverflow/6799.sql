WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 YEAR'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 MONTH'
    GROUP BY 
        v.PostId
),
PostSummary AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.OwnerDisplayName,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    ps.PostId, 
    ps.Title, 
    ps.CreationDate, 
    ps.Score, 
    ps.ViewCount, 
    ps.OwnerDisplayName,
    ps.RecentVoteCount,
    CASE 
        WHEN ps.RecentVoteCount > 10 THEN 'Trending'
        WHEN ps.Score > 100 THEN 'Popular'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    PostSummary ps
ORDER BY 
    ps.RecentVoteCount DESC, 
    ps.Score DESC;