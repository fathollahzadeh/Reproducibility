WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation >= 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.UpVotes,
    T.DownVotes,
    CASE 
        WHEN T.Rank <= 10 THEN 'Top Contributor'
        WHEN T.Rank <= 50 THEN 'Contributor'
        ELSE 'New User'
    END AS UserStatus
FROM 
    TopUsers T
WHERE 
    T.PostCount > 0
ORDER BY 
    T.Rank;
