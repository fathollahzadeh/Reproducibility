WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
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
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostTypeStats AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name,
        COUNT(p.Id) AS PostCount,
        AVG(ps.Score) AS AvgScore,
        AVG(ps.ViewCount) AS AvgViews,
        AVG(ps.CommentCount) AS AvgComments,
        AVG(ps.VoteCount) AS AvgVotes
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    LEFT JOIN 
        PostStats ps ON p.Id = ps.PostId
    GROUP BY 
        pt.Id, pt.Name
)

SELECT 
    pts.Name AS PostType,
    pts.PostCount,
    pts.AvgScore,
    pts.AvgViews,
    pts.AvgComments,
    pts.AvgVotes,
    COALESCE(us.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(us.TotalDownVotes, 0) AS TotalDownVotes,
    us.BadgeCount AS UserBadgeCount
FROM 
    PostTypeStats pts
LEFT JOIN 
    UserStats us ON us.UserId = (SELECT MIN(Id) FROM Users) 
ORDER BY 
    pts.PostCount DESC;