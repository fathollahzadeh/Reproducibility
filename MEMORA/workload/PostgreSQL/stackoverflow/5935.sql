WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserRankings AS (
    SELECT 
        UBC.UserId,
        UBC.DisplayName,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgViewCount, 0) AS AvgViewCount,
        UBC.BadgeCount,
        UBC.GoldBadges,
        UBC.SilverBadges,
        UBC.BronzeBadges,
        RANK() OVER (ORDER BY COALESCE(PS.TotalScore, 0) DESC, UBC.BadgeCount DESC) AS Rank
    FROM 
        UserBadgeCounts UBC
    LEFT JOIN 
        PostStats PS ON UBC.UserId = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    AvgViewCount,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Rank
FROM 
    UserRankings
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
