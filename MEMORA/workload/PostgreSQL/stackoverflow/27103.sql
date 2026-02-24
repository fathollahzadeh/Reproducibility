
WITH TagFrequency AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        TF.TagName,
        TF.PostCount,
        ROW_NUMBER() OVER (ORDER BY TF.PostCount DESC) AS TagRank
    FROM 
        TagFrequency TF
),
TopUsers AS (
    SELECT 
        MA.UserId,
        MA.DisplayName,
        MA.QuestionCount,
        MA.UpVoteCount,
        MA.DownVoteCount,
        MA.AcceptedAnswerCount,
        ROW_NUMBER() OVER (ORDER BY MA.QuestionCount DESC) AS UserRank
    FROM 
        MostActiveUsers MA
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.QuestionCount AS TotalQuestions,
    TU.UpVoteCount AS TotalUpVotes,
    TU.DownVoteCount AS TotalDownVotes,
    TU.AcceptedAnswerCount AS TotalAcceptedAnswers,
    TT.TagName AS TopTag,
    TT.PostCount AS TagPostCount
FROM 
    TopUsers TU
JOIN 
    TopTags TT ON TT.TagRank <= 5  
WHERE 
    TU.UserRank <= 10  
ORDER BY 
    TU.QuestionCount DESC, 
    TT.PostCount DESC;
