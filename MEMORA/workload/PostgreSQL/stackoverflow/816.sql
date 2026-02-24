WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 
    WHERE 
        U.Reputation > 1000
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
        TotalViews,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalViews DESC) AS Ranking
    FROM 
        UserActivity
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.AnswerCount,
    T.QuestionCount,
    T.TotalViews,
    COALESCE(T.TotalBounty, 0) AS TotalBounty,
    LPAD(COALESCE(T.Ranking::text, '999'), 3, '0') AS Ranking
FROM 
    TopUsers T
WHERE 
    T.Ranking <= 10
ORDER BY 
    T.Ranking ASC;