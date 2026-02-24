WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TopTags AS (
    SELECT 
        T.TagName,
        T.Count
    FROM 
        Tags T
    ORDER BY 
        T.Count DESC
    LIMIT 10
)
SELECT 
    PC.PostTypeId,
    PC.TotalPosts,
    PC.UniqueUsers,
    US.UserId,
    US.Reputation,
    US.TotalPosts AS UserTotalPosts,
    US.TotalAnswers,
    US.TotalQuestions,
    TT.TagName,
    TT.Count AS TagCount
FROM 
    PostCounts PC
JOIN 
    UserStats US ON US.TotalPosts > 0
JOIN 
    TopTags TT ON TT.Count > 0
ORDER BY 
    PC.TotalPosts DESC, US.Reputation DESC;