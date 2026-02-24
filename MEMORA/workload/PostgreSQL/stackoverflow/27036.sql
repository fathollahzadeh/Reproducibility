WITH UserTagCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        T.TagName,
        COUNT(*) AS TagCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        LATERAL (SELECT UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS TagName) T
        ON TRUE
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName, T.TagName
),
RankedTags AS (
    SELECT 
        UserId,
        DisplayName,
        TagName,
        TagCount,
        RANK() OVER (PARTITION BY UserId ORDER BY TagCount DESC) AS TagRank
    FROM 
        UserTagCounts
),
TopUserTags AS (
    SELECT 
        UserId,
        DisplayName,
        TagName
    FROM 
        RankedTags
    WHERE 
        TagRank = 1
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        B.Name AS BadgeName,
        B.Class,
        B.Date
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        B.Class = 1 
)
SELECT 
    TUT.DisplayName AS TopUser,
    TUT.TagName AS FavoriteTag,
    COUNT(UB.BadgeName) AS GoldBadges,
    SUM(CASE WHEN Post.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentPosts
FROM 
    TopUserTags TUT
LEFT JOIN 
    Posts Post ON TUT.UserId = Post.OwnerUserId
LEFT JOIN 
    UserBadges UB ON TUT.UserId = UB.UserId
GROUP BY 
    TUT.DisplayName, TUT.TagName
ORDER BY 
    GoldBadges DESC, RecentPosts DESC
LIMIT 10;