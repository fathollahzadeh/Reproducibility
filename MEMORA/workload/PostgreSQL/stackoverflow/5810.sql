
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),

TopReputableUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        PostCount, 
        AnswerCount, 
        QuestionCount
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
    ORDER BY 
        Reputation DESC
    LIMIT 10
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate AS PostCreationDate,
        U.DisplayName AS OwnerName,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
)

SELECT 
    TRU.DisplayName AS TopUser,
    TRU.Reputation,
    PD.Title,
    PD.Score,
    PD.ViewCount,
    PD.PostCreationDate,
    PD.CommentCount,
    PD.UpVoteCount
FROM 
    TopReputableUsers TRU
JOIN 
    PostDetails PD ON TRU.DisplayName = PD.OwnerName
ORDER BY 
    TRU.Reputation DESC, PD.UpVoteCount DESC;
