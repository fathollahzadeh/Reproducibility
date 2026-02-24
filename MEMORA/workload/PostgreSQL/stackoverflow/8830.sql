
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.Views, 
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (2, 3) THEN 1 END), 0) AS TotalPosts,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        Views, 
        AnswerCount, 
        QuestionCount, 
        TotalPosts, 
        TotalUpVotes, 
        TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    T.UserId, 
    T.DisplayName, 
    T.Reputation, 
    T.Views, 
    T.AnswerCount, 
    T.QuestionCount, 
    T.TotalPosts, 
    T.TotalUpVotes, 
    T.TotalDownVotes
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Rank;
