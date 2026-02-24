WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
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
        UpvoteCount,
        DownvoteCount,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.Reputation, 
    U.PostCount, 
    U.QuestionCount, 
    U.AnswerCount, 
    U.UpvoteCount, 
    U.DownvoteCount, 
    U.AvgScore
FROM 
    TopUsers U
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Reputation DESC, 
    U.PostCount DESC;
