WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PV.UserId) AS VoteCount,
        AVG(CASE WHEN PV.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        AVG(CASE WHEN PV.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes PV ON P.Id = PV.PostId
    WHERE 
        P.CreationDate >= '2020-01-01'  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AcceptedAnswerId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AcceptedAnswerId,
    CommentCount,
    VoteCount,
    UpVotes,
    DownVotes
FROM 
    PostStats
ORDER BY 
    Score DESC, ViewCount DESC;