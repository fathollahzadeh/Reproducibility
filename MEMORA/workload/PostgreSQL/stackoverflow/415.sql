WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS TotalPosts, 
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews,
        COUNT(DISTINCT P.Tags) AS UniqueTags
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
        PS.TotalPosts,
        PS.TotalScore,
        PS.AvgViews,
        PS.UniqueTags
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    WHERE 
        U.Reputation > 1000
),
RankedUsers AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS ScoreRank
    FROM 
        TopUsers
),
FinalOutput AS (
    SELECT 
        UserId, 
        DisplayName, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges, 
        TotalPosts, 
        TotalScore, 
        AvgViews, 
        UniqueTags,
        ScoreRank
    FROM 
        RankedUsers
    WHERE 
        ScoreRank <= 10
)
SELECT 
    CONCAT(DisplayName, ' (Gold: ', GoldBadges, ', Silver: ', SilverBadges, ', Bronze: ', BronzeBadges, ')') AS UserInfo,
    TotalPosts,
    TotalScore,
    AvgViews,
    UniqueTags
FROM 
    FinalOutput
ORDER BY 
    ScoreRank;
