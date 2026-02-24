
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        p.FavoriteCount,
        COUNT(DISTINCT c.Id) AS TotalCommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score, p.FavoriteCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.TotalCommentCount,
    ps.Score,
    ps.FavoriteCount,
    us.UserId,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.PostId = (SELECT p1.Id FROM Posts p1 WHERE p1.OwnerUserId = us.UserId LIMIT 1)
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
