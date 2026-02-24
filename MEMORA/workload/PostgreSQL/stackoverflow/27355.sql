
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS Tag
    FROM 
        Posts P
    WHERE 
        P.Tags IS NOT NULL
),
TagStats AS (
    SELECT 
        PT.Tag,
        COUNT(DISTINCT PT.PostId) AS PostCount,
        COUNT(DISTINCT U.Id) AS UserCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        PostTags PT
    JOIN 
        Posts P ON PT.PostId = P.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        PT.Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        UserCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.Views,
    US.BadgeCount,
    TT.Tag,
    TT.PostCount AS TagPostCount,
    TT.UserCount AS TagUserCount,
    TT.QuestionCount AS TagQuestionCount,
    TT.AnswerCount AS TagAnswerCount
FROM 
    UserStats US
JOIN 
    TopTags TT ON TT.UserCount > 0
WHERE 
    US.Reputation > 1000
ORDER BY 
    TT.TagRank, US.Reputation DESC, US.Views DESC
LIMIT 10;
