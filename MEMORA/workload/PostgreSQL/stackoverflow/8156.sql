
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate ASC) AS RankByDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.CreationDate, P.Score, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Author, 
        CreationDate, 
        Score, 
        CommentCount, 
        EditCount,
        RankByScore,
        RankByDate
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10 OR RankByDate <= 5
)
SELECT 
    TP.Title,
    TP.Author,
    TP.CreationDate,
    TP.Score,
    TP.CommentCount,
    TP.EditCount,
    PT.Name AS PostType
FROM 
    TopPosts TP
JOIN 
    PostTypes PT ON TP.PostId = PT.Id
ORDER BY 
    TP.Score DESC, TP.CreationDate DESC;
