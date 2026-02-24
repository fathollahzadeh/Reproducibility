WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(P.Id) AS PostCount, 
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        PostCount, 
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM 
        UserPostCounts
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.UserId,
    T.PostCount,
    T.TotalScore,
    T.ScoreRank,
    T.PostCountRank,
    COALESCE(B.Name, 'No Badge') AS TopBadge,
    CASE 
        WHEN T.ScoreRank <= 10 OR T.PostCountRank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS UserType
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
LEFT JOIN 
    Badges B ON U.Id = B.UserId AND B.Class = 1  
WHERE 
    U.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
ORDER BY 
    T.TotalScore DESC, T.PostCount DESC
LIMIT 100;