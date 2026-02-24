WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(U.Reputation) AS TotalReputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedPost,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(V.BountyAmount) AS AvgBounty
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    WHERE P.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
    GROUP BY P.Id, P.Title, P.PostTypeId, P.AcceptedAnswerId
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%,', T.TagName, ',%')
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.TotalReputation,
    U.TotalPosts,
    U.TotalComments,
    P.Title AS MostRecentPost,
    P.TotalComments AS CommentsOnPost,
    P.AvgBounty AS AverageBounty,
    T.TagName AS PopularTag
FROM UserReputation U
JOIN PostStatistics P ON U.UserId = P.AcceptedPost
CROSS JOIN PopularTags T
WHERE U.TotalReputation > 1000
ORDER BY U.TotalPosts DESC, P.AvgBounty DESC
LIMIT 5;