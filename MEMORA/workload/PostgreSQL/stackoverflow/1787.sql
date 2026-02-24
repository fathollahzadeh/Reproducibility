
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS Owner,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, P.ViewCount, U.DisplayName, P.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        Owner,
        RankScore,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
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
FinalResult AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Score,
        TP.CreationDate,
        TP.Owner,
        TP.UpVoteCount,
        TP.DownVoteCount,
        COALESCE(PC.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN TP.Score >= 10 THEN 'High Score'
            WHEN TP.Score BETWEEN 5 AND 9 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostComments PC ON TP.PostId = PC.PostId
)
SELECT 
    FR.*,
    UP.AverageViewCount
FROM 
    FinalResult FR
CROSS JOIN (
    SELECT 
        AVG(ViewCount) AS AverageViewCount
    FROM 
        Posts
) UP
WHERE 
    FR.CommentCount > 0
ORDER BY 
    FR.Score DESC, FR.CreationDate ASC
LIMIT 100;
