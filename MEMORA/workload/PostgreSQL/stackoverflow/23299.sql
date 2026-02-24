
WITH RecentUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.Score IS NOT NULL AND 
        P.ViewCount IS NOT NULL
),

UserBadgeCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.TotalViews,
    UA.UpVotesReceived,
    UA.DownVotesReceived,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UB.BadgeNames, 'No badges') AS Badges,
    TP.Title AS TopPostTitle,
    TP.ViewCount AS TopPostViews,
    TP.Score AS TopPostScore
FROM 
    RecentUserActivity UA
LEFT JOIN 
    UserBadgeCount UB ON UA.UserId = UB.UserId
LEFT JOIN 
    TopPosts TP ON UA.UserId = (SELECT P.OwnerUserId FROM Posts P WHERE P.Id = TP.PostId LIMIT 1)
WHERE 
    UA.Reputation > 1000
ORDER BY 
    UA.Reputation DESC, 
    UA.TotalViews DESC
LIMIT 10;
