
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalPositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS TotalNegativePosts,
        COUNT(CASE WHEN P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN P.Id END) AS RecentPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TagPostCounts AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
RecentBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days'
    GROUP BY 
        B.UserId
),
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalPositivePosts,
        UA.TotalNegativePosts,
        UA.RecentPosts,
        COALESCE(RB.BadgeCount, 0) AS RecentBadges,
        RANK() OVER (ORDER BY UA.TotalPosts DESC) AS PostRank
    FROM 
        UserActivity UA
    LEFT JOIN 
        RecentBadges RB ON UA.UserId = RB.UserId
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.TotalPosts,
    RU.TotalPositivePosts,
    RU.TotalNegativePosts,
    RU.RecentPosts,
    RU.RecentBadges,
    TPC.TagName,
    TPC.PostCount
FROM 
    RankedUsers RU
LEFT JOIN 
    TagPostCounts TPC ON TPC.PostCount > 0
WHERE 
    RU.TotalPosts > 10 AND 
    RU.RecentPosts > 0
ORDER BY 
    RU.PostRank, TPC.PostCount DESC
LIMIT 50;
