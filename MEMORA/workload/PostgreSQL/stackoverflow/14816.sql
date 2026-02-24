WITH EnhancedPostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(Cm.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(COUNT(H.Id), 0) AS EditCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments Cm ON P.Id = Cm.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
)

SELECT 
    EPS.PostId,
    EPS.Title,
    EPS.CreationDate,
    EPS.Score,
    EPS.ViewCount,
    EPS.CommentCount,
    EPS.UpVoteCount,
    EPS.DownVoteCount,
    EPS.EditCount,
    PT.Name AS PostTypeName
FROM 
    EnhancedPostStatistics EPS
JOIN 
    PostTypes PT ON EPS.PostId IN (
        SELECT Id FROM Posts WHERE PostTypeId = PT.Id
    )
ORDER BY 
    EPS.Score DESC, EPS.ViewCount DESC
LIMIT 100;