
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(U.Reputation) AS AverageReputation
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%') 
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 0
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS Contributions,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        U.DisplayName, U.Reputation
)
SELECT 
    PT.TagName,
    PT.PostCount,
    PT.QuestionCount,
    PT.AnswerCount,
    PT.AverageReputation,
    TU.DisplayName AS HighestContributor,
    TU.Reputation AS ContributorReputation,
    TU.Contributions AS ContributionCount
FROM 
    PopularTags PT
LEFT JOIN 
    TopUsers TU ON PT.TagRank = 1 AND TU.Contributions > 0
WHERE 
    PT.PostCount > 10 
ORDER BY 
    PT.TagRank;
