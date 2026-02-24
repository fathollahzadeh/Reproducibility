
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(p.CreationDate) AS LastActivityDate,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, pt.Name
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS UserUpVotes,
        SUM(u.DownVotes) AS UserDownVotes,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.PostType,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.LastActivityDate,
    ps.TotalViews,
    us.UserId,
    us.DisplayName AS OwnerDisplayName,
    us.BadgeCount,
    us.UserUpVotes,
    us.UserDownVotes,
    us.PostsCount
FROM 
    PostStatistics ps
LEFT JOIN 
    UserStatistics us ON ps.PostId = us.UserId
ORDER BY 
    ps.TotalViews DESC
LIMIT 100;
