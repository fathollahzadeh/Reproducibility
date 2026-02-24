WITH PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN v.VoteTypeId = 7 THEN 1 END) AS ReopenVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        COALESCE(pvc.CloseVotes, 0) AS CloseVotes,
        COALESCE(pvc.ReopenVotes, 0) AS ReopenVotes,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCounts pvc ON p.Id = pvc.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.CloseVotes,
    pm.ReopenVotes,
    pm.AnswerCount,
    pm.CommentCount,
    pm.FavoriteCount
FROM 
    PostMetrics pm
ORDER BY 
    pm.ViewCount DESC, pm.UpVotes DESC;