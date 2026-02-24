WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
),
PostComments AS (
    SELECT 
        PC.PostId,
        COUNT(PC.Id) AS CommentCount,
        AVG(PC.Score) AS AvgCommentScore
    FROM 
        Comments PC
    GROUP BY 
        PC.PostId
),
FinalOutput AS (
    SELECT 
        T.PostId,
        T.Title,
        T.Score,
        T.ViewCount,
        T.CreationDate,
        T.OwnerDisplayName,
        COALESCE(PC.CommentCount, 0) AS CommentCount,
        COALESCE(PC.AvgCommentScore, 0) AS AvgCommentScore
    FROM 
        TopPosts T
    LEFT JOIN 
        PostComments PC ON T.PostId = PC.PostId
)

SELECT 
    FO.PostId,
    FO.Title,
    FO.Score,
    FO.ViewCount,
    FO.CreationDate,
    FO.OwnerDisplayName,
    FO.CommentCount,
    FO.AvgCommentScore
FROM 
    FinalOutput FO
ORDER BY 
    FO.Score DESC, FO.ViewCount DESC;