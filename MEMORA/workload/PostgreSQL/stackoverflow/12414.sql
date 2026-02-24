
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
TopPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount, 
        P.CreationDate, 
        U.DisplayName AS OwnerDisplayName, 
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    ORDER BY 
        P.Score DESC 
    LIMIT 10
)
SELECT 
    UPC.UserId, 
    UPC.DisplayName, 
    UPC.PostCount, 
    TP.PostId, 
    TP.Title, 
    TP.Score, 
    TP.ViewCount, 
    TP.CreationDate, 
    TP.OwnerDisplayName
FROM 
    UserPostCounts UPC
LEFT JOIN 
    TopPosts TP ON UPC.UserId = TP.OwnerUserId;
