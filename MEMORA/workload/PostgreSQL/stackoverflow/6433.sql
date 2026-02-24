
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        rn <= 5 
),
PostMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COALESCE(SUM(CASE WHEN b.Class IS NOT NULL THEN b.Class ELSE 0 END), 0) AS TotalBadges,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount 
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
    LEFT JOIN 
        Votes v ON v.PostId = tp.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pm.OwnerDisplayName,
    pm.TotalBadges,
    pm.UpVoteCount,
    pm.DownVoteCount
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, 
    pm.ViewCount DESC;
