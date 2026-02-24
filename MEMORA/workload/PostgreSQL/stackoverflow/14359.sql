
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(v.BountyAmount) AS AverageBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) AS PostAgeInSeconds
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
        COUNT(p.Id) AS TotalPosts,
        SUM(u.Views) AS TotalViews,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CommentCount,
    ps.VoteCount,
    ps.AverageBounty,
    ps.BadgeCount,
    ps.PostAgeInSeconds,
    us.UserId,
    us.TotalPosts,
    us.TotalViews,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.AvgReputation
FROM 
    PostStatistics ps
JOIN 
    Users u ON ps.PostId = u.Id
JOIN 
    UserStatistics us ON u.Id = us.UserId
ORDER BY 
    ps.PostId;
