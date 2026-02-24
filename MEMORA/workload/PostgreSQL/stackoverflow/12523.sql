WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(u.Reputation) AS AvgUserReputation,
        MAX(p.CreationDate) AS MaxCreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.PostTypeId
),
TypeStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(ps.PostId) AS TotalPosts,
        AVG(ps.CommentCount) AS AvgComments,
        AVG(ps.VoteCount) AS AvgVotes,
        AVG(ps.AvgUserReputation) AS AvgUserReputation,
        MIN(ps.MaxCreationDate) AS EarliestPostDate,
        MAX(ps.MaxCreationDate) AS LatestPostDate
    FROM 
        PostStats ps
    JOIN 
        PostTypes pt ON ps.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    AvgComments,
    AvgVotes,
    AvgUserReputation,
    EarliestPostDate,
    LatestPostDate
FROM 
    TypeStats
ORDER BY 
    TotalPosts DESC;