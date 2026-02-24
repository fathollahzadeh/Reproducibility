
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.PostTypeId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.AnswerCount) AS AvgAnswerCount,
        AVG(P.CommentCount) AS AvgCommentCount
    FROM Posts P
    GROUP BY P.PostTypeId
)

SELECT 
    UE.UserId,
    UE.DisplayName,
    UE.TotalPosts,
    UE.TotalComments,
    UE.TotalVotes,
    UE.AcceptedAnswers,
    PS.PostTypeId,
    PS.PostCount,
    PS.TotalViews,
    PS.TotalScore,
    PS.AvgAnswerCount,
    PS.AvgCommentCount
FROM UserEngagement UE
JOIN PostStats PS ON UE.TotalPosts > 0
ORDER BY UE.TotalPosts DESC, PS.PostCount DESC;
