WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        pt.Name AS PostType,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS UpvoteCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3
        ), 0) AS DownvoteCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Posts a 
            WHERE a.ParentId = p.Id
        ), 0) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
AggregatedPostStats AS (
    SELECT 
        Tags,
        COUNT(PostId) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(UpvoteCount) AS TotalUpvotes,
        SUM(DownvoteCount) AS TotalDownvotes,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        PostDetails
    GROUP BY 
        Tags
),
RankedTags AS (
    SELECT 
        Tags,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        TotalAnswers,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        AggregatedPostStats
)
SELECT 
    rt.Tags,
    rt.TotalPosts,
    rt.TotalComments,
    rt.TotalUpvotes,
    rt.TotalDownvotes,
    rt.TotalAnswers,
    rt.Rank,
    CASE 
        WHEN rt.Rank <= 10 THEN 'Top 10 Tags'
        ELSE 'Other Tags'
    END AS TagCategory
FROM 
    RankedTags rt
ORDER BY 
    rt.Rank
LIMIT 20;