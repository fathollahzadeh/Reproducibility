WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        B.Name,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
), 

PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore,
        AVG(P.ViewCount) AS AvgViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), 

PopularTags AS (
    SELECT 
        T.TagName,
        T.Count,
        ROW_NUMBER() OVER (ORDER BY T.Count DESC) AS TagRank
    FROM 
        Tags T
    WHERE 
        T.Count > 100
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    PS.TotalPosts,
    PS.Questions,
    PS.Answers,
    PS.AvgScore,
    PS.AvgViews,
    PTag.TagName AS MostPopularTag,
    PTag.Count AS PopularityCount
FROM 
    Users U
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM UserBadges 
     WHERE BadgeRank = 1 
     GROUP BY UserId) B ON U.Id = B.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    (SELECT TagName, Count 
     FROM PopularTags 
     WHERE TagRank = 1) PTag ON TRUE
WHERE 
    U.Reputation > 100 AND 
    U.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    U.Reputation DESC,
    TotalPosts DESC;