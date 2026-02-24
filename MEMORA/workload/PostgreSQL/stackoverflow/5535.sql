
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END), 0) AS QuestionsAnswered,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostsCount,
        QuestionsAnswered,
        AnswersCount,
        RANK() OVER (ORDER BY Reputation DESC, UpVotes DESC) AS Rank
    FROM 
        UserScores
)
SELECT 
    R.DisplayName,
    R.Reputation,
    R.UpVotes,
    R.DownVotes,
    R.PostsCount,
    R.QuestionsAnswered,
    R.AnswersCount,
    R.Rank,
    (SELECT COUNT(*) FROM Users) AS TotalUsers
FROM 
    RankedUsers R
WHERE 
    R.Rank <= 10
ORDER BY 
    R.Rank;
