
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '> %')
    GROUP BY 
        T.TagName
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PopularPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PopularPostCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    WHERE 
        P.ViewCount > 1000
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UBad.BadgeCount, 0) AS BadgeCount,
    COALESCE(UBad.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBad.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBad.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.PopularPostCount, 0) AS PopularPostCount,
    COALESCE(TS.PostCount, 0) AS TotalTags,
    COALESCE(TS.TotalViews, 0) AS TotalViews,
    COALESCE(TS.TotalScore, 0) AS TotalScore
FROM 
    Users U
LEFT JOIN 
    UserBadges UBad ON U.Id = UBad.UserId
LEFT JOIN 
    PopularPosts PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    TagStatistics TS ON TS.TagName IN (
        SELECT 
            unnest(string_to_array(P.Tags, '><')) 
        FROM 
            Posts P 
        WHERE 
            P.OwnerUserId = U.Id
    )
ORDER BY 
    U.Reputation DESC, U.DisplayName;
