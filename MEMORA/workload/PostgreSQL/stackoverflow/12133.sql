
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ps.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStats ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.PostCount,
    us.TotalViews,
    SUM(ps.Score) AS TotalScore,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.VoteCount) AS TotalVotes
FROM 
    UserStats us
LEFT JOIN 
    PostStats ps ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
GROUP BY 
    us.UserId, us.Reputation, us.BadgeCount, us.PostCount, us.TotalViews
ORDER BY 
    TotalVotes DESC, TotalScore DESC;
