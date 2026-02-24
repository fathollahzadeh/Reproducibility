WITH UserPostStatistics AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty 
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY U.Id, U.DisplayName
),
TopPerformingUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        PositivePosts,
        NegativePosts,
        AcceptedAnswers,
        CommentCount,
        TotalBounty,
        RANK() OVER (ORDER BY PostCount DESC, TotalBounty DESC) AS UserRank
    FROM UserPostStatistics
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.PostCount,
    T.PositivePosts,
    T.NegativePosts,
    T.AcceptedAnswers,
    T.CommentCount,
    T.TotalBounty
FROM TopPerformingUsers T
WHERE T.UserRank <= 10
ORDER BY T.UserRank;