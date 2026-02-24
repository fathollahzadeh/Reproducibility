WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
),
AggregateMetrics AS (
    SELECT 
        PostTypeId,
        COUNT(PostId) AS TotalPosts,
        AVG(Score) AS AverageScore,
        SUM(ViewCount) AS TotalViews,
        AVG(CommentCount) AS AverageComments,
        SUM(VoteCount) AS TotalVotes,
        AVG(OwnerReputation) AS AverageOwnerReputation
    FROM 
        PostMetrics
    GROUP BY 
        PostTypeId
)

SELECT 
    pt.Name AS PostType,
    am.TotalPosts,
    am.AverageScore,
    am.TotalViews,
    am.AverageComments,
    am.TotalVotes,
    am.AverageOwnerReputation
FROM 
    AggregateMetrics am
JOIN 
    PostTypes pt ON pt.Id = am.PostTypeId
ORDER BY 
    am.TotalPosts DESC;