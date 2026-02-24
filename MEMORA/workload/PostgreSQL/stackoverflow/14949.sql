WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(NULLIF(u.DisplayName, ''), 'Community User') AS OwnerDisplayName,
        p.LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        p.Id AS PostId
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
), 
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerDisplayName,
    ps.LastEditDate,
    COALESCE(ts.TagName, 'No Tags') AS TagName,
    COALESCE(vs.VoteCount, 0) AS TotalVotes,
    COALESCE(vs.UpVotes, 0) AS UpVoteCount,
    COALESCE(vs.DownVotes, 0) AS DownVoteCount
FROM 
    PostStats ps
LEFT JOIN 
    TagStats ts ON ps.PostId = ts.PostId
LEFT JOIN 
    VoteStats vs ON ps.PostId = vs.PostId
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
LIMIT 100;