WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.BadgeCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerName,
    tp.Score,
    tp.ViewCount,
    CASE 
        WHEN tp.BadgeCount > 0 THEN 'Active User'
        ELSE 'Newcomer' 
    END AS UserCategory,
    CASE 
        WHEN tp.CommentCount > 10 THEN 'Highly Discussed'
        ELSE 'Less Discussed' 
    END AS DiscussionLevel
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
    AND ph.CreationDate = (
        SELECT MAX(CreationDate)
        FROM PostHistory
        WHERE PostId = tp.PostId
    )
WHERE 
    ph.PostHistoryTypeId = 10 
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;