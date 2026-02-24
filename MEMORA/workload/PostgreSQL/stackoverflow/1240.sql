
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRow,
        P.CreationDate
    FROM 
        Posts P 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstClosureDate,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalUpvotes,
    U.TotalDownvotes,
    U.TotalPosts,
    U.TotalComments,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    P.CommentCount,
    P.RecentPostRow,
    C.FirstClosureDate,
    C.CloseCount
FROM 
    UserStats U
LEFT JOIN 
    PostAnalytics P ON U.UserId = P.PostId 
LEFT JOIN 
    ClosedPosts C ON P.PostId = C.PostId
WHERE 
    (U.Reputation > 100 OR U.CreationDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')) 
    AND P.RecentPostRow <= 5
ORDER BY 
    U.Reputation DESC, 
    P.ViewCount DESC
LIMIT 50;
