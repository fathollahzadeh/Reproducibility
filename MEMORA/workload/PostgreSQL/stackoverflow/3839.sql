
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
MostActivePosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
UserBadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount,
        COUNT(DISTINCT PH.PostId) AS EditedPosts,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 24)
    GROUP BY PH.UserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(URS.ReputationRank, 0) AS ReputationRank,
    COALESCE(MAP.PostCount, 0) AS PostCount,
    COALESCE(MAP.TotalViews, 0) AS TotalViews,
    COALESCE(MAP.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(MAP.AverageScore, 0) AS AverageScore,
    COALESCE(UBS.BadgeCount, 0) AS BadgeCount,
    COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PHS.EditCount, 0) AS EditCount,
    COALESCE(PHS.EditedPosts, 0) AS EditedPosts,
    COALESCE(PHS.LastEditDate, NULL) AS LastEditDate
FROM Users U
LEFT JOIN UserReputation URS ON U.Id = URS.UserId
LEFT JOIN MostActivePosts MAP ON U.Id = MAP.OwnerUserId
LEFT JOIN UserBadgeSummary UBS ON U.Id = UBS.UserId
LEFT JOIN PostHistorySummary PHS ON U.Id = PHS.UserId
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, U.DisplayName ASC
LIMIT 100;
