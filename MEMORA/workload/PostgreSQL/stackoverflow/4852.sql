
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        DENSE_RANK() OVER (PARTITION BY U.Id ORDER BY COALESCE(SUM(V.BountyAmount), 0) DESC) AS BountyRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        AnswerCount, 
        QuestionCount, 
        TotalBounty, 
        BountyRank
    FROM 
        UserActivity
    WHERE
        BountyRank <= 10
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.Score > 0 THEN 1 END) AS PositiveQuestions,
        COUNT(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 END) AS ClosedQuestions
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    UA.AnswerCount,
    UA.QuestionCount,
    UA.TotalBounty,
    PS.TotalQuestions,
    PS.PositiveQuestions,
    PS.ClosedQuestions
FROM 
    TopActiveUsers UA
JOIN 
    Users U ON UA.UserId = U.Id
LEFT JOIN 
    PostSummary PS ON U.Id = PS.OwnerUserId
WHERE 
    UA.TotalBounty > 0
ORDER BY 
    UA.TotalBounty DESC, 
    UA.AnswerCount DESC;
