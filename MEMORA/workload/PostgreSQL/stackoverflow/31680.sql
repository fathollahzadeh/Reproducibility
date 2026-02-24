WITH RecursiveUserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM Users U
    JOIN Badges B ON U.Id = B.UserId
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.CreationDate,
        P.Title,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '366 days'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.UserId,
        P.Title,
        PH.PostHistoryTypeId,
        RANK() OVER (PARTITION BY PH.UserId ORDER BY PH.CreationDate DESC) AS ClosePostRank
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (10, 11)
),
TopTags AS (
    SELECT 
        T.TagName,
        T.Count,
        ROW_NUMBER() OVER (ORDER BY T.Count DESC) AS TagRank
    FROM Tags T
    WHERE T.Count > 0
)
SELECT 
    U.DisplayName,
    COALESCE(MIN(ST.BestPostTitle), 'No Recent Posts') AS BestRecentPost,
    COALESCE(SUM(CASE WHEN R.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(SUM(CASE WHEN R.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(SUM(CASE WHEN R.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
    COUNT(DISTINCT CP.PostId) AS TotalClosedPosts
FROM Users U
LEFT JOIN RecursiveUserBadges R ON U.Id = R.UserId AND R.BadgeRank <= 5
LEFT JOIN RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN (
    SELECT 
        OwnerUserId,
        MAX(Title) AS BestPostTitle
    FROM RecentPosts 
    WHERE PostTypeId = 1
    GROUP BY OwnerUserId
) ST ON U.Id = ST.OwnerUserId
LEFT JOIN ClosedPosts CP ON U.Id = CP.UserId
WHERE 
    U.Reputation > 500 
    AND U.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
GROUP BY U.DisplayName
HAVING COUNT(DISTINCT CP.PostId) > 0
ORDER BY U.DisplayName;