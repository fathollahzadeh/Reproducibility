WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(p.ClosedDate, '1900-01-01') AS ClosedDate,
        COALESCE(p.LastActivityDate, '1900-01-01') AS LastActivityDate,
        EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - p.CreationDate)) AS PostAgeInSeconds
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), VoteMetrics AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN v.VoteTypeId = 7 THEN 1 END) AS ReopenVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    pm.PostId,
    pm.PostTypeId,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.AnswerCount,
    pm.CommentCount,
    pm.FavoriteCount,
    pm.ClosedDate,
    pm.LastActivityDate,
    pm.PostAgeInSeconds,
    COALESCE(vm.UpVotes, 0) AS UpVotes,
    COALESCE(vm.DownVotes, 0) AS DownVotes,
    COALESCE(vm.CloseVotes, 0) AS CloseVotes,
    COALESCE(vm.ReopenVotes, 0) AS ReopenVotes
FROM 
    PostMetrics pm
LEFT JOIN 
    VoteMetrics vm ON pm.PostId = vm.PostId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;