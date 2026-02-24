WITH ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Title,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(CommentCount) AS AvgCommentCount,
        SUM(OwnerReputation) AS TotalOwnerReputation
    FROM 
        ActivePosts
)
SELECT 
    ps.TotalPosts,
    ps.AvgScore,
    ps.AvgViewCount,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    ps.TotalOwnerReputation
FROM 
    PostStatistics ps