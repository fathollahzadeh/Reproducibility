
WITH TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        MIN(P.CreationDate) AS FirstPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
TopPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        RANK() OVER (ORDER BY P.Score DESC) AS PostRank,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE 
        P.Score > 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(PS.PostCount, 0) AS PostCount,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    PP.Title,
    PP.ViewCount,
    PP.Score,
    PP.CreationDate,
    CASE 
        WHEN PP.Id IS NOT NULL THEN 'Top Post'
        ELSE 'No Top Post'
    END AS PostStatus
FROM 
    TopUsers U
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    TopPosts PP ON U.Id = PP.OwnerUserId AND PP.PostRank <= 5
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Reputation DESC, PS.TotalViews DESC;
