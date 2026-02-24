WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
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
Metrics AS (
    SELECT 
        PostTypeId,
        COUNT(PostId) AS TotalPosts,
        AVG(CommentCount) AS AvgComments,
        AVG(VoteCount) AS AvgVotes,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes,
        COUNT(DISTINCT BadgeCount) AS DistinctBadgeCounts
    FROM 
        PostStats
    GROUP BY 
        PostTypeId
)

SELECT 
    pt.Name AS PostType,
    m.TotalPosts,
    m.AvgComments,
    m.AvgVotes,
    m.AvgUpVotes,
    m.AvgDownVotes,
    m.DistinctBadgeCounts
FROM 
    Metrics m
JOIN 
    PostTypes pt ON m.PostTypeId = pt.Id
ORDER BY 
    m.TotalPosts DESC;