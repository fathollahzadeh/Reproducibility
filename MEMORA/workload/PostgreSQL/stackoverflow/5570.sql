
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON rp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerDisplayName,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    CASE 
        WHEN pm.Score > 100 THEN 'Hot'
        WHEN pm.ViewCount > 1000 THEN 'Trending'
        ELSE 'New'
    END AS Status
FROM 
    PostMetrics pm
WHERE 
    pm.Rank <= 5
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
