
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
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
        TotalBounties,
        VoteCount
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalBounties,
    TU.VoteCount,
    P.Title AS LastPostTitle,
    P.CreationDate AS LastPostDate,
    P.ViewCount AS LastPostViewCount
FROM 
    TopUsers TU
LEFT JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
WHERE 
    P.LastActivityDate = (
        SELECT MAX(P2.LastActivityDate) 
        FROM Posts P2 
        WHERE P2.OwnerUserId = TU.UserId
    )
ORDER BY 
    TU.Reputation DESC;
