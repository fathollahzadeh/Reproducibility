WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),  
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        NetVotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY NetVotes DESC) AS NetVotesRank
    FROM 
        UserScore
),
QuestionTags AS (
    SELECT 
        P.Id AS QuestionId,
        unnest(string_to_array(P.Tags, '><')) AS Tag
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        QuestionTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.NetVotes,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TP.Tag,
    TP.TagCount
FROM 
    TopUsers TU
JOIN 
    TagPopularity TP ON TU.QuestionCount > 0
ORDER BY 
    TU.ReputationRank, TU.NetVotesRank;
