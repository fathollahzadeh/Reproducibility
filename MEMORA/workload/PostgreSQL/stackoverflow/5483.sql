
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000 AND 
        U.CreationDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR')
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views, U.UpVotes, U.DownVotes
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        UpVotesCount, 
        DownVotesCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.UpVotesCount,
    T.DownVotesCount,
    CASE 
        WHEN T.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorStatus
FROM 
    TopUsers T
WHERE 
    T.Rank <= 50
ORDER BY 
    T.Rank;
