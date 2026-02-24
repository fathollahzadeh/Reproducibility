WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName
), PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Score,
        COALESCE(MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END), NULL) AS CloseDate,
        COALESCE(MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate END), NULL) AS ReopenDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.AnswerCount, P.CommentCount, P.Score
), UserPostDetails AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        PM.PostId,
        PM.Title,
        PM.ViewCount,
        PM.AnswerCount,
        PM.CommentCount,
        PM.Score,
        PM.CloseDate,
        PM.ReopenDate
    FROM 
        UserActivity UA
    JOIN 
        Posts P ON UA.UserId = P.OwnerUserId
    JOIN 
        PostMetrics PM ON P.Id = PM.PostId
)
SELECT 
    UPD.UserId,
    UPD.DisplayName,
    COUNT(DISTINCT UPD.PostId) AS PostsCreated,
    SUM(UPD.ViewCount) AS TotalViews,
    SUM(UPD.AnswerCount) AS TotalAnswers,
    SUM(UPD.CommentCount) AS TotalComments,
    SUM(UPD.Score) AS TotalScore,
    COUNT(DISTINCT CASE WHEN UPD.CloseDate IS NOT NULL THEN UPD.PostId END) AS ClosedPosts,
    COUNT(DISTINCT CASE WHEN UPD.ReopenDate IS NOT NULL THEN UPD.PostId END) AS ReopenedPosts
FROM 
    UserPostDetails UPD
GROUP BY 
    UPD.UserId, UPD.DisplayName
ORDER BY 
    TotalViews DESC
LIMIT 10;
