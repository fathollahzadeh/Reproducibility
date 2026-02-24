WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId IN (1, 2) AND 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Author, Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(c.Score) AS TotalScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Author,
    TP.Score,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    COALESCE(PC.TotalScore, 0) AS CommentTotalScore
FROM 
    TopPosts TP
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
ORDER BY 
    TP.Score DESC, TP.CreationDate ASC;