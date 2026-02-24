
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalUpvotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),

TopUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        UM.TotalQuestions,
        UM.TotalAnswers
    FROM 
        UserMetrics UM
    JOIN 
        Users U ON UM.UserId = U.Id
    ORDER BY 
        UM.Reputation DESC
    LIMIT 5
)

SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation AS UserReputation,
    TU.CreationDate AS UserCreationDate,
    PT.TagName AS PopularTag,
    PT.PostCount AS TagPostCount
FROM 
    TopUsers TU
CROSS JOIN 
    PopularTags PT
ORDER BY 
    TU.Reputation DESC, PT.PostCount DESC;
