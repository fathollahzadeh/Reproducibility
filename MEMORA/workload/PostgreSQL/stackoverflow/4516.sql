WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.Score) FILTER (WHERE P.Score IS NOT NULL) AS AverageScore,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserStatistics AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PM.PostCount, 0) AS PostCount,
        COALESCE(PM.TotalViews, 0) AS TotalViews,
        COALESCE(PM.TotalScore, 0) AS TotalScore,
        COALESCE(PM.AverageScore, 0) AS AverageScore,
        COALESCE(PM.Questions, 0) AS Questions,
        COALESCE(PM.Answers, 0) AS Answers
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostMetrics PM ON U.Id = PM.OwnerUserId
),
RankedUsers AS (
    SELECT 
        US.*,
        RANK() OVER (ORDER BY US.Reputation DESC, US.BadgeCount DESC, US.TotalScore DESC) AS UserRank
    FROM UserStatistics US
)
SELECT 
    R.DisplayName,
    R.Reputation,
    R.BadgeCount,
    R.PostCount,
    R.TotalViews,
    R.TotalScore,
    R.AverageScore,
    R.Questions,
    R.Answers,
    CASE 
        WHEN R.UserRank <= 10 THEN 'Top User'
        WHEN R.UserRank <= 50 THEN 'Active User'
        ELSE 'New User'
    END AS UserCategory
FROM RankedUsers R
WHERE R.LastAccessDate <= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
ORDER BY R.UserRank;