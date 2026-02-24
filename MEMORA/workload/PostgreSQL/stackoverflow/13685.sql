
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate
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
PostTypeSummary AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(ps.PostId) AS TotalPosts,
        AVG(ps.CommentCount) AS AvgComments,
        AVG(ps.VoteCount) AS AvgVotes,
        AVG(ps.UpVoteCount) AS AvgUpVotes,
        AVG(ps.DownVoteCount) AS AvgDownVotes
    FROM 
        PostTypes pt
    LEFT JOIN 
        PostStats ps ON pt.Id = ps.PostTypeId
    GROUP BY 
        pt.Id, pt.Name
)
SELECT 
    pts.PostTypeName,
    pts.TotalPosts,
    pts.AvgComments,
    pts.AvgVotes,
    pts.AvgUpVotes,
    pts.AvgDownVotes,
    us.UserId,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostTypeSummary pts
JOIN 
    UserStats us ON us.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL)
ORDER BY 
    pts.TotalPosts DESC;
