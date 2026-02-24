
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        MAX(B.Class) AS HighestBadgeClass,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        CARDINALITY(STRING_TO_ARRAY(P.Tags, '<>')) AS TagCount
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Posts P
    JOIN Tags T ON POSITION(T.TagName IN P.Tags) > 0
    GROUP BY P.Id, T.TagName
),
UserPostStatistics AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COUNT(RP.PostId) AS RecentPostCount,
        COALESCE(SUM(CASE WHEN RP.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePostCount,
        COALESCE(AVG(RP.ViewCount), 0) AS AvgViewCount,
        COALESCE(SUM(PT.PostCount), 0) AS TotalTaggedCount
    FROM UserBadges UB
    LEFT JOIN RecentPosts RP ON UB.UserId = RP.OwnerUserId
    LEFT JOIN PostTags PT ON PT.PostId = RP.PostId
    GROUP BY UB.UserId, UB.DisplayName
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalBadges,
        U.HighestBadgeClass,
        UPS.RecentPostCount,
        UPS.PositivePostCount,
        UPS.AvgViewCount,
        UPS.TotalTaggedCount
    FROM UserBadges U
    JOIN UserPostStatistics UPS ON U.UserId = UPS.UserId
)
SELECT 
    CS.DisplayName,
    CS.TotalBadges,
    CASE 
        WHEN CS.HighestBadgeClass = 1 THEN 'Gold'
        WHEN CS.HighestBadgeClass = 2 THEN 'Silver'
        WHEN CS.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None'
    END AS BadgeType,
    CS.RecentPostCount,
    CS.PositivePostCount,
    ROUND(CS.AvgViewCount, 2) AS AverageViews,
    CS.TotalTaggedCount,
    CASE 
        WHEN CS.RecentPostCount = 0 THEN NULL
        ELSE ROUND((CAST(CS.PositivePostCount AS decimal) / CS.RecentPostCount) * 100, 2) 
    END AS PositivePostPercentage
FROM CombinedStats CS
WHERE (CS.RecentPostCount > 0 OR CS.TotalBadges > 0)
ORDER BY CS.TotalBadges DESC, CS.AvgViewCount DESC NULLS LAST;
