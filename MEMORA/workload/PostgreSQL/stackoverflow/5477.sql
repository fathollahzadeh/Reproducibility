WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpvotedPosts,
        DownvotedPosts,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
    WHERE PostCount > 0
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.UpvotedPosts,
    TU.DownvotedPosts,
    TU.TotalBounty
FROM TopUsers TU
WHERE TU.Rank <= 10
ORDER BY TU.Rank;