
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.CreationDate, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.CommentCount,
        RP.AnswerCount
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 10
)
SELECT 
    T.Title,
    T.OwnerDisplayName,
    T.CreationDate,
    T.Score,
    T.ViewCount,
    T.CommentCount,
    T.AnswerCount,
    (
        SELECT 
            STRING_AGG(CONCAT(U.DisplayName, ': ', V.CreationDate), ', ') 
        FROM 
            Votes V 
        JOIN 
            Users U ON V.UserId = U.Id 
        WHERE 
            V.PostId = T.PostId 
            AND V.VoteTypeId IN (2, 3)  
    ) AS VoterInfo
FROM 
    TopPosts T
ORDER BY 
    T.Score DESC, T.ViewCount DESC;
