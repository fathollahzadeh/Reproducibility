
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        R.PostId,
        R.Title,
        R.CreationDate,
        R.Score,
        R.ViewCount,
        R.OwnerDisplayName,
        R.ScoreRank,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryDate
    FROM 
        RankedPosts R
    LEFT JOIN 
        PostHistory PH ON R.PostId = PH.PostId
    WHERE 
        R.ScoreRank <= 3
)
SELECT 
    T.PostId,
    T.Title,
    T.CreationDate,
    T.Score,
    T.ViewCount,
    T.OwnerDisplayName,
    STRING_AGG(DISTINCT PT.Name, ', ') AS PostTypes,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount
FROM 
    TopPosts T
LEFT JOIN 
    PostTypes PT ON T.PostId = PT.Id
LEFT JOIN 
    Badges B ON B.UserId = (SELECT U.Id FROM Users U WHERE U.DisplayName = T.OwnerDisplayName)
LEFT JOIN 
    Votes V ON V.PostId = T.PostId
GROUP BY 
    T.PostId, T.Title, T.CreationDate, T.Score, T.ViewCount, T.OwnerDisplayName
HAVING 
    COUNT(T.PostId) > 0
ORDER BY 
    T.Score DESC, T.ViewCount DESC;
