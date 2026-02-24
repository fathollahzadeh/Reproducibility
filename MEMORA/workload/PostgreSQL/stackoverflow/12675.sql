
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COUNT(c.Id) AS CommentTotal,
        COUNT(DISTINCT v.Id) AS VoteTotal
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.Score) AS UserPostScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.CommentTotal,
    ps.VoteTotal,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.UserPostScore
FROM 
    PostStats ps
JOIN 
    Posts p ON ps.PostId = p.Id
JOIN 
    UserStats us ON us.UserId = p.OwnerUserId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
