
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(VB.BountyAmount) FILTER (WHERE VB.VoteTypeId = 9), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN P.Id END) AS TotalAcceptedAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Votes VB ON U.Id = VB.UserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBounty,
        TotalUpvotes,
        TotalDownvotes,
        TotalPosts,
        TotalAcceptedAnswers,
        TotalComments,
        RANK() OVER (ORDER BY TotalBounty DESC, TotalUpvotes DESC) AS UserRank
    FROM UserStats
)
SELECT 
    RU.DisplayName,
    RU.TotalBounty,
    RU.TotalUpvotes,
    RU.TotalDownvotes,
    RU.TotalPosts,
    RU.TotalAcceptedAnswers,
    RU.TotalComments,
    CASE 
        WHEN RU.TotalPosts > 0 THEN ROUND((CAST(RU.TotalUpvotes AS DECIMAL) / NULLIF(RU.TotalPosts, 0)) * 100, 2)
        ELSE 0
    END AS UpvotePercentage,
    CASE 
        WHEN RU.TotalPosts > 0 THEN ROUND((CAST(RU.TotalAcceptedAnswers AS DECIMAL) / NULLIF(RU.TotalPosts, 0)) * 100, 2)
        ELSE 0
    END AS AcceptanceRate
FROM RankedUsers RU
WHERE RU.UserRank <= 10
ORDER BY RU.TotalBounty DESC, RU.TotalUpvotes DESC;
