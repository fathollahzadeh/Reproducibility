
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsMade,
        MAX(U.Reputation) AS Reputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        AnswersGiven,
        QuestionsAsked,
        CommentsMade,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY PostsCreated DESC) AS ActivityRank
    FROM 
        UserActivity
    WHERE 
        PostsCreated > 0
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        T.TagName
    FROM 
        ActiveUsers U
    JOIN 
        TopTags T ON U.QuestionsAsked = (SELECT MAX(QuestionsAsked) FROM ActiveUsers)
)
SELECT
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    T.TagName AS MostPopularTag,
    COUNT(DISTINCT P.Id) AS QuestionsAsked,
    SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
FROM 
    TopUsers U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId AND P.PostTypeId = 1  
JOIN 
    Tags T ON T.TagName = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))
GROUP BY 
    U.DisplayName, U.Reputation, T.TagName
ORDER BY 
    U.Reputation DESC, QuestionsAsked DESC;
