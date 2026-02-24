
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
TopUsers AS (
    SELECT 
        ru.UserId,
        ru.DisplayName
    FROM 
        RankedUsers ru
    WHERE 
        ru.ReputationRank <= 10
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    ps.PostCount,
    ps.TotalViews,
    ps.AcceptedAnswers,
    ps.AnswerCount,
    CASE 
        WHEN ps.PostCount = 0 THEN 0
        ELSE (CAST(ps.AcceptedAnswers AS FLOAT) / ps.PostCount) * 100 
    END AS AcceptanceRate
FROM 
    TopUsers tu
LEFT JOIN 
    PostStats ps ON tu.UserId = ps.OwnerUserId
ORDER BY 
    tu.DisplayName;
