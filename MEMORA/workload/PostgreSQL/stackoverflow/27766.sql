
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),

TopUserPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.LastActivityDate
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 5 
)

SELECT 
    U.DisplayName AS UserName,
    COUNT(TP.PostId) AS PostCount,
    STRING_AGG(DISTINCT TP.Title, '; ') AS TopPostTitles,
    MIN(TP.CreationDate) AS FirstPostDate,
    MAX(TP.LastActivityDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    TopUserPosts TP ON U.DisplayName = TP.OwnerDisplayName
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(TP.PostId) > 0 
ORDER BY 
    PostCount DESC, U.DisplayName;
