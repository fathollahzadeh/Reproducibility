
WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS ActivityRank
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentUserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    WHERE 
        B.Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        B.UserId
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        RANK() OVER (ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    WHERE 
        P.ViewCount > 100
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.LastAccessDate,
    COALESCE(RU.BadgeCount, 0) AS BadgeCount,
    COALESCE(RU.BadgeNames, 'No badges') AS BadgeNames,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViewCount,
    TP.CreationDate AS TopPostCreationDate
FROM 
    RecursiveUserActivity U
LEFT JOIN 
    RecentUserBadges RU ON U.UserId = RU.UserId
JOIN 
    TopPosts TP ON U.UserId = TP.OwnerUserId
WHERE 
    U.ActivityRank = 1 
    AND TP.RankByScore <= 10 
ORDER BY 
    U.Reputation DESC, U.LastAccessDate DESC;
