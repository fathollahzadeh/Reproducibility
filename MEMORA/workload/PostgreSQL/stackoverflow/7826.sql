WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS ScoreRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.OwnerDisplayName,
    TP.Score,
    TP.ViewCount,
    PC.CommentCount,
    PB.BadgeCount
FROM 
    TopPosts TP
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
LEFT JOIN 
    PostBadges PB ON (TP.OwnerDisplayName = (SELECT U.DisplayName FROM Users U WHERE U.Id = PB.UserId LIMIT 1))
ORDER BY 
    TP.Score DESC, 
    TP.ViewCount DESC;