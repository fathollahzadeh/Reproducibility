
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount
    FROM 
        UserPostCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)
SELECT 
    U.DisplayName AS TopUserDisplayName,
    T.Title,
    T.CreationDate,
    T.ViewCount,
    T.Score,
    T.CommentCount
FROM 
    TopUsers U
JOIN 
    PostStats T ON U.UserId = T.OwnerUserId
ORDER BY 
    U.PostCount DESC, T.Score DESC;
