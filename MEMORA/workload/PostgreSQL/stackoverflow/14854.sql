
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT pl.RelatedPostId) AS TotalLinks
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title
),
AggregatedStatistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(TotalComments) AS PostComments,
        SUM(TotalUpVotes) AS Upvotes,
        SUM(TotalDownVotes) AS Downvotes,
        AVG(TotalLinks) AS AverageLinks
    FROM 
        PostStatistics
)

SELECT 
    TotalPosts,
    PostComments,
    Upvotes,
    Downvotes,
    AverageLinks
FROM 
    AggregatedStatistics;
