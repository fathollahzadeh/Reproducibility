
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
),
HighEngagementUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        E.TotalPosts,
        E.TotalComments,
        E.TotalUpvotes,
        E.TotalDownvotes,
        E.LastPostDate,
        (SELECT COUNT(*) FROM RecentPostHistory RPH WHERE RPH.UserId = U.Id) AS RecentActivityCount
    FROM Users U
    JOIN UserEngagement E ON U.Id = E.UserId
    WHERE E.TotalPosts > 5 AND E.TotalComments > 10
)
SELECT 
    H.UserId,
    H.DisplayName,
    H.Reputation,
    H.CreationDate,
    H.TotalPosts,
    H.TotalComments,
    H.TotalUpvotes,
    H.TotalDownvotes,
    H.LastPostDate,
    H.RecentActivityCount
FROM HighEngagementUsers H
ORDER BY H.Reputation DESC, H.TotalPosts DESC
LIMIT 10;
