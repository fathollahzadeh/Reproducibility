WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Tags) AS TagPostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
    ORDER BY 
        TagPostCount DESC
    LIMIT 5
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.TotalQuestions,
        US.TotalAnswers,
        US.TotalUpvotedPosts
    FROM 
        UserStatistics US
    JOIN 
        Users U ON US.UserId = U.Id
    WHERE 
        US.Reputation > 1000
    ORDER BY 
        US.Reputation DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalUpvotedPosts,
    PT.TagName AS PopularTag,
    PT.TagPostCount
FROM 
    TopUsers TU
CROSS JOIN 
    PopularTags PT
ORDER BY 
    TU.Reputation DESC, PT.TagPostCount DESC;
