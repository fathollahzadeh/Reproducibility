
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        COALESCE(pm.BadgeCount, 0) AS BadgeCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        WHERE 
            Date >= CURRENT_DATE - INTERVAL '1 year'
        GROUP BY 
            UserId
    ) pm ON p.OwnerUserId = pm.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pm.BadgeCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        RankScore,
        BadgeCount,
        OwnerUserId
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.BadgeCount,
    ut.DisplayName AS OwnerDisplayName,
    ut.Reputation AS OwnerReputation
FROM 
    TopPosts tp
JOIN 
    Users ut ON tp.OwnerUserId = ut.Id
ORDER BY 
    tp.RankScore;
