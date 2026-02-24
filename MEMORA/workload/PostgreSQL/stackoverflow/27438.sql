
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
RecentPostHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        H.CreationDate,
        P.OwnerDisplayName,
        P.Score,
        H.Comment
    FROM PostHistory H
    JOIN Posts P ON H.PostId = P.Id
    WHERE H.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    AND H.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalUpvotes,
    US.TotalDownvotes,
    PT.TagName,
    PT.PostCount,
    PT.TotalViews,
    RPH.PostId,
    RPH.Title,
    RPH.CreationDate AS RecentActivityDate,
    RPH.OwnerDisplayName AS PostOwner,
    RPH.Score AS PostScore,
    RPH.Comment AS ActionComment
FROM UserStats US
JOIN PopularTags PT ON US.TotalPosts > 3
LEFT JOIN RecentPostHistory RPH ON US.DisplayName = RPH.OwnerDisplayName
ORDER BY US.Reputation DESC, PT.PostCount DESC, RPH.CreationDate DESC
LIMIT 50;
