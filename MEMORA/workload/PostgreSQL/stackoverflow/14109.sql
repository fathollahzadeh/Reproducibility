WITH UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        P.Id AS PostId,
        P.Title AS PostTitle,
        P.CreationDate AS PostCreationDate,
        P.Score AS PostScore,
        P.ViewCount AS PostViewCount,
        P.AnswerCount AS PostAnswerCount,
        P.CommentCount AS PostCommentCount,
        COALESCE(C.VoteCount, 0) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
)

SELECT 
    UP.UserId,
    UP.UserDisplayName,
    COUNT(UP.PostId) AS TotalPosts,
    SUM(UP.PostScore) AS TotalPostScore,
    SUM(UP.PostViewCount) AS TotalPostViews,
    SUM(UP.VoteCount) AS TotalVotes,
    MAX(UP.PostCreationDate) AS LastPostDate
FROM 
    UserPosts UP
GROUP BY 
    UP.UserId, UP.UserDisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 10;