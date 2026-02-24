
WITH RecursiveTags AS (
    SELECT 
        Id,
        TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        Tags
    GROUP BY 
        Id, TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
InactiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        PopularPosts,
        AverageScore
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 0 AND (
            Questions = 0 OR AverageScore < 1
        )
),
TopTags AS (
    SELECT 
        R.TagName,
        R.TagUsageCount,
        ROW_NUMBER() OVER (ORDER BY R.TagUsageCount DESC) AS TagRank
    FROM 
        RecursiveTags R
    WHERE 
        R.TagUsageCount >= 10
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.PopularPosts,
    T.TagName,
    T.TagUsageCount
FROM 
    InactiveUsers U
JOIN 
    TopTags T ON U.UserId IN (
        SELECT 
            P.OwnerUserId 
        FROM 
            Posts P 
        WHERE 
            P.Tags LIKE '%' || T.TagName || '%'
    )
ORDER BY 
    U.TotalPosts DESC, T.TagUsageCount DESC;
