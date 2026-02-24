
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        u.Reputation AS OwnerReputation
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
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.Reputation
),
PostTypesStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(ps.PostId) AS PostCount,
        AVG(ps.ViewCount) AS AvgViewCount,
        AVG(ps.Score) AS AvgScore,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.VoteCount) AS TotalVotes,
        AVG(ps.OwnerReputation) AS AvgOwnerReputation
    FROM 
        PostStats ps
    JOIN 
        PostTypes pt ON ps.PostId IS NOT NULL 
    GROUP BY 
        pt.Name
)
SELECT 
    PostTypeName,
    PostCount,
    AvgViewCount,
    AvgScore,
    TotalComments,
    TotalVotes,
    AvgOwnerReputation
FROM 
    PostTypesStats
ORDER BY 
    PostCount DESC;
