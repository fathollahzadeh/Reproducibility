
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MIN(b.Date) AS FirstBadgeDate,
        MAX(b.Date) AS LastBadgeDate,
        EXTRACT(EPOCH FROM p.CreationDate) AS CreationTimestamp
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.PostTypeId, p.ViewCount, p.Score
)
SELECT 
    pt.Name AS PostType,
    COUNT(ps.PostId) AS TotalPosts,
    AVG(ps.ViewCount) AS AvgViewCount,
    AVG(ps.Score) AS AvgScore,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.VoteCount) AS TotalVotes,
    MIN(ps.FirstBadgeDate) AS EarliestBadgeDate,
    MAX(ps.LastBadgeDate) AS LatestBadgeDate
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
