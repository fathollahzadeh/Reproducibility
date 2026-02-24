
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.*, 
        pt.Name AS PostType,
        COALESCE(badgeCount.BadgeCount, 0) AS UserBadges
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON pt.Id = 1 
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) badgeCount ON badgeCount.UserId = rp.OwnerUserId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerName,
    CommentCount,
    PostType,
    UserBadges
FROM 
    TopPosts
WHERE 
    UserBadges > 0
ORDER BY 
    Score DESC, CommentCount DESC
LIMIT 10;
