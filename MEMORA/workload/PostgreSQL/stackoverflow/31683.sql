
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND P.PostTypeId IN (1, 2) 
),
PostsWithComments AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        RP.AnswerCount,
        COUNT(C.Id) AS CommentCount,
        RP.RankScore
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.ViewCount, RP.Score, RP.AnswerCount, RP.RankScore
),
PostsBadges AS (
    SELECT 
        P.Id AS PostId,
        COUNT(B.Id) AS BadgesAwarded
    FROM 
        Posts P
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    WHERE 
        B.Date >= P.CreationDate
    GROUP BY 
        P.Id
)
SELECT 
    PWC.PostId,
    PWC.Title,
    PWC.ViewCount,
    PWC.Score,
    PWC.AnswerCount,
    PWC.CommentCount,
    COALESCE(PBA.BadgesAwarded, 0) AS BadgesAwarded
FROM 
    PostsWithComments PWC
LEFT JOIN 
    PostsBadges PBA ON PWC.PostId = PBA.PostId
WHERE 
    PWC.RankScore <= 5 
ORDER BY 
    PWC.Score DESC, PWC.ViewCount DESC
LIMIT 10;
