WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(b.Class) AS HighestBadgeClass,
        AVG(u.Reputation) AS AverageUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PostTypeCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(ps.ViewCount) AS TotalViews,
        AVG(ps.Score) AS AverageScore
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    LEFT JOIN 
        PostStatistics ps ON ps.PostId = p.Id
    GROUP BY 
        pt.Name
)
SELECT 
    pt.PostType,
    pt.PostCount,
    pt.TotalViews,
    pt.AverageScore
FROM 
    PostTypeCounts pt
ORDER BY 
    pt.PostCount DESC;