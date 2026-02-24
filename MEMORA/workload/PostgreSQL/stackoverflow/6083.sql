
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 0
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
        TotalScore,
        TotalViews,
        RANK() OVER (ORDER BY TotalScore DESC, Reputation DESC) AS ScoreRank
    FROM 
        UserStats
    WHERE 
        PostCount > 0
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        COUNT(CI.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments CI ON P.Id = CI.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title, P.CreationDate
)
SELECT 
    TU.DisplayName,
    TU.ScoreRank,
    TU.TotalScore,
    TU.QuestionCount,
    TU.AnswerCount,
    RPA.Title,
    RPA.CreationDate AS RecentPostDate,
    RPA.CommentCount,
    RPA.UpVotes,
    RPA.DownVotes
FROM 
    TopUsers TU
JOIN 
    RecentPostActivity RPA ON TU.UserId = RPA.OwnerUserId
WHERE 
    TU.ScoreRank <= 10
ORDER BY 
    TU.ScoreRank, RPA.CreationDate DESC;
