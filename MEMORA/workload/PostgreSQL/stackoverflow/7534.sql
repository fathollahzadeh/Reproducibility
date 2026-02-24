
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.Id, T.TagName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        AnswerCount, 
        QuestionCount, 
        UpVotes, 
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
),
TopTags AS (
    SELECT 
        TagId, 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    U.Rank AS UserRank,
    U.DisplayName AS UserName,
    U.Reputation,
    U.PostCount AS TotalPosts,
    U.AnswerCount AS TotalAnswers,
    U.QuestionCount AS TotalQuestions,
    U.UpVotes AS TotalUpVotes,
    U.DownVotes AS TotalDownVotes,
    T.Rank AS TagRank,
    T.TagName AS TopTag,
    T.PostCount AS TagPostCount
FROM 
    TopUsers U
LEFT JOIN 
    TopTags T ON U.UserId IN (SELECT DISTINCT P.OwnerUserId FROM Posts P WHERE P.Tags LIKE CONCAT('%', T.TagName, '%'))
WHERE 
    U.Rank <= 10 AND (T.Rank IS NULL OR T.Rank <= 10)
ORDER BY 
    U.Rank, T.Rank;
