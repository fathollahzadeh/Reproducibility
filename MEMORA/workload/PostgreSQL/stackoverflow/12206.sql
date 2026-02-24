WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        p.OwnerUserId,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, u.Reputation
),
PostTypeCounts AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.VoteCount) AS TotalVotes,
        AVG(ps.Score) AS AverageScore,
        AVG(ps.ViewCount) AS AverageViews,
        AVG(ps.OwnerReputation) AS AverageOwnerReputation
    FROM 
        PostStats ps
    JOIN 
        PostTypes pt ON ps.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    PostTypeName,
    TotalPosts,
    TotalComments,
    TotalVotes,
    AverageScore,
    AverageViews,
    AverageOwnerReputation
FROM 
    PostTypeCounts
ORDER BY 
    TotalPosts DESC;