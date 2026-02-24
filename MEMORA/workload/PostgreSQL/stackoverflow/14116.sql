
WITH PostStats AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(b.Id) AS BadgeCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),

UserStats AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(ps.CommentCount, 0)) AS TotalComments,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes,
        SUM(ps.BadgeCount) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStats ps ON p.Id = ps.PostID
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    ps.PostID,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    us.UserID,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.TotalComments,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalBadges
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.OwnerUserId = us.UserID
ORDER BY 
    ps.ViewCount DESC
LIMIT 100;
