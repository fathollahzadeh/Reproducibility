WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        v.PostId, v.VoteTypeId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(rv.VoteCount, 0) AS UpVotes,
        COALESCE(rv.VoteCount, 0) AS DownVotes,
        rp.ScoreRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId AND rv.VoteTypeId = 2
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.UpVotes,
    pm.DownVotes,
    pm.ViewCount,
    pm.CreationDate,
    pm.OwnerDisplayName,
    CASE 
        WHEN pm.ScoreRank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS RankCategory
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;