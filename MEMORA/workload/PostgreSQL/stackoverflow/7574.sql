WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    AND 
        p.PostTypeId IN (1, 2)  
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostMetrics AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.Score,
        trp.ViewCount,
        trp.CreationDate,
        trp.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ba.BadgeCount, 0) AS BadgeCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON trp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) ba ON ba.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId)
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pm.CreationDate,
    pm.OwnerDisplayName,
    pm.CommentCount,
    pm.BadgeCount
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC,
    pm.ViewCount DESC;