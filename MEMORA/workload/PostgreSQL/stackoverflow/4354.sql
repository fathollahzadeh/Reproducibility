WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyEarned,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
RecentPostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        (SELECT COUNT(C.Id) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    U.UserId,
    U.DisplayName AS UserName,
    U.Reputation,
    U.TotalPosts,
    U.TotalAnswers,
    U.TotalBountyEarned,
    U.ReputationRank,
    PT.TagName,
    RPD.PostId,
    RPD.Title,
    RPD.CreationDate,
    RPD.ViewCount,
    RPD.CommentCount
FROM UserStats U
LEFT JOIN PopularTags PT ON U.TotalPosts > 0
LEFT JOIN RecentPostDetails RPD ON RPD.OwnerName = U.DisplayName
WHERE U.ReputationRank <= 10
ORDER BY U.Reputation DESC, PT.PostCount DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;