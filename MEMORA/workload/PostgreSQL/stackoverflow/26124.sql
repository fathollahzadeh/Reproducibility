
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByView,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        u.DisplayName AS AuthorName,
        COALESCE(badge_count.BadgeCount, 0) AS BadgeCount,
        COALESCE(comment_count.CommentCount, 0) AS CommentCount,
        rp.RankByScore,
        rp.RankByView
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) badge_count ON u.Id = badge_count.UserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) comment_count ON rp.PostId = comment_count.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Tags,
    pd.ViewCount,
    pd.Score,
    pd.CreationDate,
    pd.AuthorName,
    pd.BadgeCount,
    pd.CommentCount,
    STRING_AGG(pt.Name, ', ') AS PostTypeNames
FROM 
    PostDetails pd
JOIN 
    PostTypes pt ON pd.PostId = pt.Id
WHERE 
    pd.RankByScore <= 5 OR pd.RankByView <= 5
GROUP BY 
    pd.PostId, pd.Title, pd.Tags, pd.ViewCount, pd.Score, pd.CreationDate, pd.AuthorName, pd.BadgeCount, pd.CommentCount
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
