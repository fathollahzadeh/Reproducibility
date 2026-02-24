
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, U.DisplayName, P.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.AnswerCount,
        RANK() OVER (ORDER BY RP.ViewCount DESC) AS GlobalRank
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 3
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.ViewCount,
    FP.CreationDate,
    FP.OwnerDisplayName,
    FP.CommentCount,
    FP.AnswerCount,
    FP.GlobalRank
FROM 
    FilteredPosts FP
ORDER BY 
    FP.GlobalRank;
