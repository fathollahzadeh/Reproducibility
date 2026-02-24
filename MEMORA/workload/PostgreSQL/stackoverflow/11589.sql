
WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2022-01-01'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation, u.DisplayName
),
AverageMetrics AS (
    SELECT 
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount,
        AVG(CommentCount) AS AvgCommentsPerPost,
        AVG(VoteCount) AS AvgVotesPerPost,
        COUNT(PostId) AS TotalPosts
    FROM 
        PostAnalytics
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.VoteCount,
    pa.OwnerReputation,
    pa.OwnerDisplayName,
    am.AvgScore,
    am.AvgViewCount,
    am.AvgCommentsPerPost,
    am.AvgVotesPerPost,
    am.TotalPosts
FROM 
    PostAnalytics pa,
    AverageMetrics am
ORDER BY 
    pa.Score DESC  
LIMIT 100;
