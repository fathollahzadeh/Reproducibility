WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COALESCE(AVG(LENGTH(CASE WHEN P.Body IS NOT NULL THEN P.Body END)), 0) AS AvgPostLength
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName
),
TopUserStats AS (
    SELECT 
        UserId,
        DisplayName,
        TotalQuestions,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        AvgPostLength,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS AnswerRank,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank
    FROM 
        UserStatistics
)
SELECT 
    T.DisplayName,
    T.TotalQuestions,
    T.TotalAnswers,
    T.TotalUpVotes,
    T.TotalDownVotes,
    T.AvgPostLength,
    T.AnswerRank,
    T.UpVoteRank,
    CASE 
        WHEN T.AnswerRank <= 10 THEN 'Top Contributor'
        WHEN T.UpVoteRank <= 10 THEN 'Popular User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    TopUserStats T
WHERE 
    T.TotalAnswers > 0 OR T.TotalUpVotes > 0
ORDER BY 
    T.UpVoteRank, T.AnswerRank;