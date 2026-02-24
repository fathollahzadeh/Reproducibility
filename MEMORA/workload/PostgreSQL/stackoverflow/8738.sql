
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        Reputation > 0
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViewCount,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS TagRank
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
TopUserTags AS (
    SELECT 
        U.DisplayName AS TopUser,
        T.TagName,
        COUNT(P.Id) AS TagUsageCount
    FROM 
        TopUsers U
    JOIN 
        Posts P ON U.UserId = P.OwnerUserId
    JOIN 
        Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        U.DisplayName, T.TagName
)
SELECT 
    U.DisplayName AS UserName, 
    U.Reputation, 
    T.TagName, 
    T.TagUsageCount, 
    (SELECT TagRank FROM PopularTags PT WHERE PT.TagName = T.TagName) AS TagRank
FROM 
    TopUserTags T
JOIN 
    TopUsers U ON T.TopUser = U.DisplayName
WHERE 
    U.ReputationRank <= 10 AND (SELECT TagRank FROM PopularTags PT WHERE PT.TagName = T.TagName) <= 5
ORDER BY 
    U.ReputationRank, TagRank;
