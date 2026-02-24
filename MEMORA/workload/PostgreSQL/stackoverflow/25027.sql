WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        Id AS PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TopTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS Count
    FROM 
        TagCounts
    GROUP BY 
        Tag
    ORDER BY 
        Count DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
UserSummary AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalAnswers,
        UA.AcceptedAnswers,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserActivity UA
    LEFT JOIN 
        UserBadges UB ON UA.UserId = UB.UserId
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalAnswers,
    U.AcceptedAnswers,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    T.Tag,
    T.Count AS TagCount
FROM 
    UserSummary U
JOIN 
    TopTags T ON U.TotalAnswers > 0
ORDER BY 
    U.TotalPosts DESC, 
    U.AcceptedAnswers DESC, 
    T.Count DESC;
