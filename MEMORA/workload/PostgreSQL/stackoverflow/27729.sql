
WITH TagFrequency AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TagDetails AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        TF.PostCount
    FROM 
        Tags T
    JOIN 
        TagFrequency TF ON T.TagName = TF.Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
MostPopularTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS PopularityRank
    FROM 
        TagDetails
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AcceptedAnswerCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
)
SELECT 
    MT.TagName AS MostPopularTag,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.QuestionCount AS UserQuestionCount,
    U.AcceptedAnswerCount AS UserAcceptedAnswers,
    MT.PostCount AS TagPostCount
FROM 
    MostPopularTags MT
JOIN 
    TopUsers U ON MT.PopularityRank <= 10 AND U.ReputationRank <= 10
ORDER BY 
    MT.PostCount DESC, U.Reputation DESC;
