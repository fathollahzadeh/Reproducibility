WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PopularPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.Score,
        RP.ViewCount,
        COUNT(C.Id) AS CommentCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    WHERE 
        RP.PostRank <= 5
    GROUP BY 
        RP.PostId, RP.Title, RP.OwnerDisplayName, RP.Score, RP.ViewCount
)
SELECT 
    PP.Title,
    PP.OwnerDisplayName,
    PP.Score,
    PP.ViewCount,
    PP.CommentCount,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    PopularPosts PP
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) B ON PP.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = B.UserId)
ORDER BY 
    PP.Score DESC, PP.ViewCount DESC;