
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(pts.Name, 'Unknown') AS PostType,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pts ON p.PostTypeId = pts.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, pts.Name, u.DisplayName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.Views) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.PostType,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.VoteCount,
    us.PostCount AS UserPostCount,
    us.TotalUpVotes AS UserTotalUpVotes,
    us.TotalViews AS UserTotalViews
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.OwnerDisplayName = us.DisplayName
ORDER BY 
    ps.CreationDate DESC
LIMIT 100;
