
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        MAX(b.Date) AS LatestBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 MONTH'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CreationDate, 
        OwnerDisplayName, 
        CommentCount, 
        LatestBadgeDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Score, 
    tp.ViewCount, 
    tp.CreationDate, 
    tp.OwnerDisplayName, 
    tp.CommentCount,
    CASE 
        WHEN tp.LatestBadgeDate IS NOT NULL THEN 'Has Badge' 
        ELSE 'No Badge' 
    END AS BadgeStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
