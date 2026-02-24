
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM UNNEST(string_to_array(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS TagPostCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.UpvotedPosts,
    U.AvgViewCount,
    UB.TotalBadges,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PT.TagName,
    PT.TagPostCount
FROM 
    UserPostStats U
LEFT JOIN 
    UserBadges UB ON U.UserId = UB.UserId
LEFT JOIN 
    PopularTags PT ON U.TotalPosts > 5  
ORDER BY 
    U.TotalPosts DESC,
    UB.TotalBadges DESC;
