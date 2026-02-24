
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStatistics AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, '><')) AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
RankedUsers AS (
    SELECT 
        US.UserId, 
        US.DisplayName, 
        US.TotalPosts, 
        US.TotalAnswers, 
        US.TotalQuestions, 
        US.TotalScore,
        RANK() OVER (ORDER BY US.TotalScore DESC) AS UserRank
    FROM 
        UserStatistics US
)
SELECT 
    RU.DisplayName AS User,
    RU.TotalPosts,
    RU.TotalAnswers,
    RU.TotalQuestions,
    RU.TotalScore,
    T.TagName,
    T.TagUsage,
    CASE 
        WHEN RU.TotalAnswers > 10 THEN 'Active Contributor'
        WHEN RU.TotalPosts > 20 THEN 'Frequent User'
        ELSE 'New Member'
    END AS ParticipationLevel
FROM 
    RankedUsers RU
LEFT JOIN 
    TagStatistics T ON T.TagUsage > 5
WHERE 
    RU.TotalScore > 100
ORDER BY 
    RU.TotalScore DESC,
    T.TagUsage DESC;
