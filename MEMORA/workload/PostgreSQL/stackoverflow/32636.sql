WITH RecursiveTagExcerpts AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        T.Count,
        T.ExcerptPostId,
        P.Title AS ExcerptTitle,
        P.OwnerUserId,
        P.CreationDate
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.ExcerptPostId = P.Id
    
    UNION ALL
    
    SELECT 
        T.Id,
        T.TagName,
        T.Count,
        T.ExcerptPostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate
    FROM 
        Tags T
    JOIN 
        Posts P ON T.WikiPostId = P.Id
)
, UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT B.Id) AS BadgeCount,
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
, UserPosts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    UP.TotalPosts,
    UP.TotalQuestions,
    UP.TotalAnswers,
    UP.LastPostDate,
    RTE.TagName,
    RTE.ExcerptTitle,
    RTE.Count AS TagCount
FROM 
    Users U
JOIN 
    UserBadges UB ON U.Id = UB.UserId
JOIN 
    UserPosts UP ON U.Id = UP.UserId
LEFT JOIN 
    RecursiveTagExcerpts RTE ON U.Id = RTE.OwnerUserId
WHERE 
    U.Reputation > 1000
    AND (RTE.TagName IS NOT NULL OR UP.TotalPosts > 5)
ORDER BY 
    U.Reputation DESC, 
    RTE.Count DESC;