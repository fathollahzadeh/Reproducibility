WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM 
        Posts p
    LEFT JOIN (
        
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= '2023-01-01' 
)
SELECT 
    PostType,
    COUNT(*) AS TotalPosts,
    AVG(ViewCount) AS AvgViewCount,
    AVG(Score) AS AvgScore,
    AVG(AnswerCount) AS AvgAnswerCount,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(VoteCount) AS AvgVoteCount,
    AVG(BadgeCount) AS AvgBadgeCount
FROM 
    PostMetrics
GROUP BY 
    PostType
ORDER BY 
    TotalPosts DESC;