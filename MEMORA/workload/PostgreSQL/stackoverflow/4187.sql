
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(P.ViewCount), 0) AS TotalPostViews,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.TotalPostViews,
    U.BadgeCount,
    U.CommentCount,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.UpVotes,
    RP.DownVotes
FROM 
    UserStats U
LEFT JOIN 
    RankedPosts RP ON U.UserId = RP.PostId
WHERE 
    U.Reputation > 1000
    AND (U.Views IS NULL OR U.Views > 500)
    AND (RP.rn IS NULL OR RP.rn <= 5)
ORDER BY 
    U.TotalPostViews DESC, U.Reputation DESC
LIMIT 10 OFFSET 0;
