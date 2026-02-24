
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) AS PostAgeInSeconds
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.PostTypeId, p.Score, p.ViewCount, p.CreationDate
)

SELECT 
    pt.Name AS PostType,
    COUNT(ps.PostId) AS TotalPosts,
    AVG(ps.CommentCount) AS AvgCommentsPerPost,
    AVG(ps.VoteCount) AS AvgVotesPerPost,
    AVG(ps.Score) AS AvgScore,
    AVG(ps.ViewCount) AS AvgViewCount,
    AVG(ps.PostAgeInSeconds) AS AvgPostAgeInSeconds
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
