
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikiPosts,
        MAX(P.CreationDate) AS LastActivity,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserStatistics AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.Questions,
        UA.Answers,
        UA.TagWikiPosts,
        UA.LastActivity,
        UA.AvgViewCount,
        COALESCE(BC.BadgeCount, 0) AS BadgeCount,
        RANK() OVER (ORDER BY UA.TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY UA.AvgViewCount DESC) AS ViewRank
    FROM 
        UserActivity UA
    LEFT JOIN 
        BadgeCounts BC ON UA.UserId = BC.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TagWikiPosts,
    LastActivity,
    AvgViewCount,
    BadgeCount,
    PostRank,
    ViewRank
FROM 
    UserStatistics
WHERE 
    TotalPosts > 0
ORDER BY 
    TotalPosts DESC, AvgViewCount DESC
FETCH FIRST 10 ROWS ONLY;
