WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS TotalDownvotedPosts,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount,
        AVG(COALESCE(U.Reputation, 0)) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeStatistics AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditsCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenActions
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalWikis,
    UA.TotalUpvotedPosts,
    UA.TotalDownvotedPosts,
    UA.AvgViewCount,
    UA.AvgReputation,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PHS.EditsCount, 0) AS EditsCount,
    COALESCE(PHS.TitleEdits, 0) AS TitleEdits,
    COALESCE(PHS.CloseReopenActions, 0) AS CloseReopenActions
FROM 
    UserActivity UA
LEFT JOIN 
    BadgeStatistics BS ON UA.UserId = BS.UserId
LEFT JOIN 
    PostHistoryStats PHS ON UA.UserId = PHS.UserId
ORDER BY 
    UA.TotalPosts DESC, UA.AvgReputation DESC
LIMIT 100;
