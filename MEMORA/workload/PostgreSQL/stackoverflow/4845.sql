WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldCount,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverCount,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CloseReasonCount AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
)
SELECT 
    U.DisplayName,
    COALESCE(UBC.GoldCount, 0) AS GoldBadges,
    COALESCE(UBC.SilverCount, 0) AS SilverBadges,
    COALESCE(UBC.BronzeCount, 0) AS BronzeBadges,
    COALESCE(PS.PostCount, 0) AS NumberOfPosts,
    COALESCE(PS.TotalScore, 0) AS TotalPostScore,
    COALESCE(PS.AvgViewCount, 0) AS AvgPostViewCount,
    COALESCE(CRC.CloseReasonCount, 0) AS CloseReasonTotal
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    CloseReasonCount CRC ON U.Id = CRC.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC
LIMIT 50;
