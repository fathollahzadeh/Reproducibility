WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
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
        QuestionCount,
        AnswerCount,
        TotalScore,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalScore,
    TU.BadgeCount,
    HF.UserDisplayName AS TopVoter,
    COUNT(DISTINCT P.Id) AS VotedPosts,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived
FROM 
    TopUsers TU
LEFT JOIN 
    Votes V ON TU.UserId = V.UserId
LEFT JOIN 
    Posts P ON V.PostId = P.Id
LEFT JOIN 
    (SELECT 
        U.Id,
        U.DisplayName AS UserDisplayName,
        COUNT(V2.Id) AS VotesGiven
     FROM 
        Votes V2
     JOIN 
        Users U ON V2.UserId = U.Id
     GROUP BY 
        U.Id, U.DisplayName
     ORDER BY 
        VotesGiven DESC
     LIMIT 1) HF ON 1=1
WHERE 
    TU.Rank <= 10
GROUP BY 
    TU.DisplayName, TU.Reputation, TU.QuestionCount, TU.AnswerCount, TU.TotalScore, TU.BadgeCount, HF.UserDisplayName
ORDER BY 
    TU.Reputation DESC;
