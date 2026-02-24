
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p 
        LEFT JOIN Comments c ON p.Id = c.PostId
)
SELECT 
    u.Id AS UserId, 
    u.DisplayName, 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.CreationDate, 
    rp.CommentCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post' 
        ELSE 'Regular Post' 
    END AS PostRankDescription,
    COALESCE(BadgesEarned.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN u.Reputation < 100 THEN 'Novice User' 
        WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate User' 
        ELSE 'Expert User' 
    END AS UserLevel
FROM 
    Users u
INNER JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY UserId
) AS BadgesEarned ON u.Id = BadgesEarned.UserId
WHERE 
    rp.Score > 5 
    OR rp.CommentCount > 10
GROUP BY 
    u.Id, 
    u.DisplayName, 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.CreationDate, 
    rp.CommentCount, 
    rp.Rank, 
    BadgesEarned.BadgeCount, 
    u.Reputation
ORDER BY 
    UserLevel DESC, 
    rp.Score DESC;
