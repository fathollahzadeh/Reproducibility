
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        Upvotes,
        Downvotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.AnswerCount,
    TU.QuestionCount,
    TU.Upvotes,
    TU.Downvotes,
    CASE 
        WHEN TU.Reputation >= 10000 THEN 'Gold'
        WHEN TU.Reputation >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS Badge,
    PH.CreationDate AS LastEdited
FROM 
    TopUsers TU
LEFT JOIN 
    PostHistory PH ON PH.UserId = TU.UserId
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank, TU.QuestionCount DESC, TU.Upvotes DESC;
