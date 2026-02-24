
WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount
    FROM 
        TagCounts
    WHERE 
        PostCount > (
            SELECT 
                AVG(PostCount) FROM TagCounts
        )
),
UserBadgeCounts AS (
    SELECT
        B.UserId,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    U.TotalScore,
    U.TotalPosts,
    COALESCE(UB.TotalBadges, 0) AS TotalBadges,
    STRING_AGG(PT.Tag, ', ') AS PopularTagsAssociated
FROM 
    UserReputation U
LEFT JOIN 
    UserBadgeCounts UB ON U.UserId = UB.UserId
LEFT JOIN 
    PopularTags PT ON EXISTS (
        SELECT 1 
        FROM Posts P
        WHERE P.Tags LIKE '%' || PT.Tag || '%'
        AND P.OwnerUserId = U.UserId
    )
WHERE 
    U.TotalPosts > 5
GROUP BY 
    U.DisplayName, U.TotalScore, U.TotalPosts, UB.TotalBadges
ORDER BY 
    U.TotalScore DESC
