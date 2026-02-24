WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.PostTypeId,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        COALESCE(Answers.Count, 0) AS AnswerCount,
        COALESCE(Comments.Count, 0) AS CommentCount,
        COALESCE(Votes.Count, 0) AS VoteCount
    FROM 
        Posts
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS Count
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) AS Answers ON Posts.Id = Answers.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Count
        FROM 
            Comments
        GROUP BY 
            PostId
    ) AS Comments ON Posts.Id = Comments.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Count
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS Votes ON Posts.Id = Votes.PostId
)

SELECT 
    PostStats.Title,
    PostStats.CreationDate,
    PostStats.Score,
    PostStats.ViewCount,
    PostStats.AnswerCount,
    PostStats.CommentCount,
    PostStats.VoteCount,
    PostHistoryType.Name AS LastEditType
FROM 
    PostStats
LEFT JOIN 
    PostHistory ON PostStats.PostId = PostHistory.PostId
LEFT JOIN 
    PostHistoryTypes AS PostHistoryType ON PostHistory.PostHistoryTypeId = PostHistoryType.Id
WHERE 
    PostStats.PostTypeId = 1 
ORDER BY 
    PostStats.CreationDate DESC
LIMIT 100;