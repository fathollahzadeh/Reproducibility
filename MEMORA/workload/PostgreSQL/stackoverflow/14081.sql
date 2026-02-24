
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCountTotal,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
        p.CommentCount, p.FavoriteCount, u.DisplayName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerDisplayName,
    us.PostCount AS UserPostCount,
    us.BadgeCount AS UserBadgeCount,
    vs.TotalUpvotes,
    vs.TotalDownvotes
FROM 
    PostStats ps
LEFT JOIN 
    UserStats us ON ps.OwnerDisplayName = us.DisplayName
LEFT JOIN 
    VoteStats vs ON ps.PostId = vs.PostId
ORDER BY 
    ps.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
