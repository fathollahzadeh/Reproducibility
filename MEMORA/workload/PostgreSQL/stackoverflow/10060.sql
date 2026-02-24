WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        P.LastActivityDate,
        PT.Name AS PostType
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
),
VoteMetrics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
BadgeMetrics AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    PM.PostId,
    PM.Title,
    PM.CreationDate,
    PM.Score,
    PM.ViewCount,
    PM.AnswerCount,
    PM.CommentCount,
    PM.OwnerDisplayName,
    PM.LastActivityDate,
    PM.PostType,
    VM.Upvotes,
    VM.Downvotes,
    BM.BadgeCount
FROM 
    PostMetrics PM
LEFT JOIN 
    VoteMetrics VM ON PM.PostId = VM.PostId
LEFT JOIN 
    BadgeMetrics BM ON PM.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = BM.UserId)
ORDER BY 
    PM.LastActivityDate DESC
LIMIT 100;