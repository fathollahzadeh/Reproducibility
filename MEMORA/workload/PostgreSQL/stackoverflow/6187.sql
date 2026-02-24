WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND P.PostTypeId = 1  
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(DISTINCT P.Id) >= 5
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    U.DisplayName AS TopUser,
    P.Title AS TopPost,
    P.Score,
    P.CreationDate,
    R.PostRank
FROM 
    TopUsers U
JOIN 
    RankedPosts R ON U.UserId = R.PostId
JOIN 
    Posts P ON R.PostId = P.Id
WHERE 
    R.PostRank = 1
ORDER BY 
    P.Score DESC, U.DisplayName;