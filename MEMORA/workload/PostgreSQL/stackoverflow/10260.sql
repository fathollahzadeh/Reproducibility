WITH UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    TotalViews,
    TotalScore,
    CommentCount,
    BadgeCount,
    (TotalViews / NULLIF(PostCount, 0)) AS AverageViewsPerPost,
    (TotalScore / NULLIF(PostCount, 0)) AS AverageScorePerPost,
    (CommentCount / NULLIF(PostCount, 0)) AS AverageCommentsPerPost
FROM 
    UserEngagement
ORDER BY 
    Reputation DESC, 
    PostCount DESC;