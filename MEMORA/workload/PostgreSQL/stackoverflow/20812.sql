WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswersCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserEngagement AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        UBad.GoldBadges,
        UBad.SilverBadges,
        UBad.BronzeBadges,
        PM.QuestionsCount,
        PM.AnswersCount,
        PM.TotalScore,
        PM.TotalViews,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN UserBadges UBad ON U.Id = UBad.UserId
    LEFT JOIN PostMetrics PM ON U.Id = PM.OwnerUserId
)
SELECT 
    CTE.*,
    CASE 
        WHEN CTE.QuestionsCount = 0 AND CTE.TotalViews > 1000 THEN 'Highly Viewed Non-Contributor'
        WHEN CTE.QuestionsCount > 0 THEN 'Active Contributor'
        ELSE 'Inactive User'
    END AS UserStatus,
    CASE 
        WHEN CTE.GoldBadges = 0 THEN NULL
        ELSE CONCAT(CTE.GoldBadges, ' Gold Badges')
    END AS GoldBadgeInfo,
    ARRAY_AGG(DISTINCT PT.Name) FILTER (WHERE PT.Id IS NOT NULL) AS PostTypesContributed
FROM UserEngagement CTE
LEFT JOIN Posts P ON CTE.Id = P.OwnerUserId
LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY CTE.Id, CTE.DisplayName, CTE.Reputation, CTE.GoldBadges, CTE.SilverBadges, CTE.BronzeBadges, 
         CTE.QuestionsCount, CTE.AnswersCount, CTE.TotalScore, CTE.TotalViews, CTE.Rank
ORDER BY CTE.Rank
LIMIT 100;
