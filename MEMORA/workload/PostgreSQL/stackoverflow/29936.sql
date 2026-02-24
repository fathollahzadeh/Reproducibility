
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags AS T
    JOIN 
        Posts AS P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS BestBadgeClass
    FROM 
        Users AS U
    LEFT JOIN 
        Badges AS B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    R.DisplayName,
    R.Reputation,
    R.TotalPosts,
    R.TotalQuestions,
    R.TotalAnswers,
    R.TotalViews,
    UT.UserId AS BadgeUserId,
    UT.BadgeCount,
    UT.BestBadgeClass,
    PT.TagName AS PopularTag,
    PT.PostCount AS TagPostCount,
    PT.TotalViews AS TagTotalViews
FROM 
    RankedUsers AS R
JOIN 
    UserBadges AS UT ON R.UserId = UT.UserId
CROSS JOIN 
    PopularTags AS PT
WHERE 
    R.TotalPosts > 0
ORDER BY 
    R.Reputation DESC, UT.BadgeCount DESC, PT.TotalViews DESC;
