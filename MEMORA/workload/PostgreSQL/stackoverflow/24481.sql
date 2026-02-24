WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        COUNT(DISTINCT B.Id) AS BadgeCount, 
        MAX(B.Date) AS LastBadgeDate
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
), 
PostStatistics AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPostHistory AS (
    SELECT 
        PH.UserId, 
        COUNT(PH.Id) AS ClosedPostCount,
        SUM(CASE WHEN PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentClosedPosts,
        STRING_AGG(DISTINCT P.Title, ', ') AS ClosedPostTitles
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.UserId
),
AggregatedData AS (
    SELECT 
        U.UserId,
        U.Reputation,
        COALESCE(U.BadgeCount, 0) AS BadgeCount,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(P.TotalViews, 0) AS TotalViews,
        COALESCE(P.TotalScore, 0) AS TotalScore,
        COALESCE(C.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(C.RecentClosedPosts, 0) AS RecentClosedPosts,
        COALESCE(C.ClosedPostTitles, 'None') AS ClosedPostTitles
    FROM UserReputation U
    LEFT JOIN PostStatistics P ON U.UserId = P.OwnerUserId
    LEFT JOIN ClosedPostHistory C ON U.UserId = C.UserId
),
RankedUsers AS (
    SELECT 
        A.*,
        RANK() OVER (ORDER BY A.Reputation DESC, A.PostCount DESC) AS OverallRank
    FROM AggregatedData A
)
SELECT 
    RU.UserId,
    RU.Reputation,
    RU.BadgeCount,
    RU.PostCount,
    RU.TotalViews,
    RU.TotalScore,
    RU.ClosedPostCount,
    RU.RecentClosedPosts,
    RU.ClosedPostTitles,
    RU.OverallRank,
    CASE 
        WHEN RU.Reputation IS NULL THEN 'No reputation'
        WHEN RU.Reputation > 1000 THEN 'Expert'
        ELSE 'Novice' 
    END AS UserLevel
FROM RankedUsers RU
WHERE RU.OverallRank <= 10
ORDER BY RU.OverallRank;