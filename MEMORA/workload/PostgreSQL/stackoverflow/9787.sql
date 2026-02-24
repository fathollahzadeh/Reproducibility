
WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
)
SELECT 
    R.OwnerDisplayName,
    R.Title,
    R.Score,
    R.ViewCount,
    R.CreationDate,
    T.QuestionCount,
    T.TotalScore,
    T.TotalViews
FROM 
    RankedPosts R
JOIN 
    TopUsers T ON R.OwnerDisplayName = T.DisplayName
WHERE 
    R.RankByScore <= 5
ORDER BY 
    R.Score DESC, R.ViewCount DESC
LIMIT 50;
