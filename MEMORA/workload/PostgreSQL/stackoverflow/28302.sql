WITH UserPostStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        SUM(B.Class) AS TotalBadges,
        STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS T(TagName) ON TRUE
    GROUP BY 
        U.Id, U.DisplayName
),

ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        AvgViewCount,
        TotalBadges,
        AssociatedTags
    FROM 
        UserPostStatistics
    WHERE 
        TotalPosts > 0
)

SELECT 
    AU.DisplayName,
    AU.TotalQuestions,
    AU.TotalAnswers,
    AU.TotalScore,
    AU.AvgViewCount,
    AU.TotalBadges,
    AU.AssociatedTags,
    P.CreationDate AS RecentPostDate,
    P.Title AS RecentPostTitle,
    P.ViewCount AS RecentPostViewCount
FROM 
    ActiveUsers AU
LEFT JOIN 
    Posts P ON AU.UserId = P.OwnerUserId
WHERE 
    P.CreationDate = (
        SELECT 
            MAX(CreationDate) 
        FROM 
            Posts 
        WHERE 
            OwnerUserId = AU.UserId
    )
ORDER BY 
    AU.TotalScore DESC, 
    AU.TotalPosts DESC
LIMIT 10;