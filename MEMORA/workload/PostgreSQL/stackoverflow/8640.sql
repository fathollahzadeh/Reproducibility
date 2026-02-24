WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount,
        COUNT(DISTINCT PH.PostId) AS EditedPostCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalViews,
    UA.TotalScore,
    UA.AvgScore,
    UA.LastPostDate,
    COALESCE(BC.BadgeCount, 0) AS BadgeCount,
    COALESCE(BC.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(BC.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(BC.BronzeBadgeCount, 0) AS BronzeBadgeCount,
    COALESCE(PHS.EditCount, 0) AS EditCount,
    COALESCE(PHS.EditedPostCount, 0) AS EditedPostCount
FROM 
    UserActivity UA
LEFT JOIN 
    BadgeCounts BC ON UA.UserId = BC.UserId
LEFT JOIN 
    PostHistorySummary PHS ON UA.UserId = PHS.UserId
ORDER BY 
    UA.TotalScore DESC,
    UA.PostCount DESC
LIMIT 100;
