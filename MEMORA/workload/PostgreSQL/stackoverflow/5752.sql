WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
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
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.AnswerCount,
    TP.OwnerDisplayName,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    COALESCE(PB.BadgeCount, 0) AS OwnerBadgeCount
FROM 
    TopPosts TP
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
LEFT JOIN 
    Users U ON TP.OwnerDisplayName = U.DisplayName
LEFT JOIN 
    PostBadges PB ON U.Id = PB.UserId
ORDER BY 
    TP.Score DESC, TP.CreationDate DESC;