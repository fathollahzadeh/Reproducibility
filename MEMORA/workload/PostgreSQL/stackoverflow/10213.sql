WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(B.Class) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(C.Id) AS TotalComments,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.AnswerCount) AS AvgAnswersPerPost
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
)

SELECT 
    U.DisplayName AS User,
    U.Reputation AS Reputation,
    COALESCE(UR.TotalBadges, 0) AS TotalBadges,
    COALESCE(UR.TotalBounty, 0) AS TotalBounty,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalComments, 0) AS TotalComments,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PS.AvgAnswersPerPost, 0) AS AvgAnswersPerPost
FROM Users U
LEFT JOIN UserReputation UR ON U.Id = UR.UserId
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
ORDER BY U.Reputation DESC;