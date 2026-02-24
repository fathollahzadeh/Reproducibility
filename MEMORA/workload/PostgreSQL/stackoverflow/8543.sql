
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS TotalAnswerScore,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS TotalDownVotes,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalAnswerScore,
        TotalQuestions,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        RANK() OVER (ORDER BY TotalAnswerScore DESC, (TotalUpVotes - TotalDownVotes) DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.TotalAnswerScore,
    T.TotalQuestions,
    T.TotalAnswers,
    T.TotalUpVotes,
    T.TotalDownVotes,
    T.TotalBadges,
    T.Rank
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10;
