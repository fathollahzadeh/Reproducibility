
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostActivity AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(*) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(BA.PostCount, 0) AS PostCount,
        COALESCE(BG.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BR.BronzeBadges, 0) AS BronzeBadges,
        CASE 
            WHEN COALESCE(BA.PostCount, 0) = 0 THEN 0 
            ELSE (COALESCE(BG.GoldBadges, 0) + COALESCE(BS.SilverBadges, 0) + COALESCE(BR.BronzeBadges, 0)) / NULLIF(COALESCE(BA.PostCount, 1), 0)
        END AS BadgeRatio
    FROM 
        Users U
    LEFT JOIN 
        PostActivity BA ON U.Id = BA.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts BG ON U.Id = BG.UserId
    LEFT JOIN 
        UserBadgeCounts BS ON U.Id = BS.UserId
    LEFT JOIN 
        UserBadgeCounts BR ON U.Id = BR.UserId
    WHERE 
        U.Reputation >= 1000
),
FilteredTopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        BadgeRatio,
        RANK() OVER (ORDER BY BadgeRatio DESC) AS Rank
    FROM 
        TopUsers
)
SELECT 
    FTU.DisplayName,
    FTU.PostCount,
    FTU.GoldBadges,
    FTU.SilverBadges,
    FTU.BronzeBadges,
    FTU.BadgeRatio
FROM 
    FilteredTopUsers FTU
WHERE 
    FTU.Rank <= 10
    AND (FTU.BadgeRatio IS NOT NULL AND FTU.BadgeRatio > 0)
ORDER BY 
    FTU.BadgeRatio DESC;
