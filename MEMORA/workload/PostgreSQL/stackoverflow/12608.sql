WITH PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.PostTypeId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AveragePostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT
    ps.PostId,
    ps.PostTypeId,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    us.UserId,
    us.TotalBadges,
    us.TotalViews,
    us.AveragePostScore
FROM
    PostStatistics ps
JOIN 
    Users u ON ps.PostId = u.Id
JOIN 
    UserStatistics us ON u.Id = us.UserId
ORDER BY 
    ps.PostId;