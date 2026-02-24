WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
CombinedStats AS (
    SELECT 
        ps.PostId,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ps.FavoriteCount,
        ps.OwnerDisplayName,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(vs.AcceptedVotes, 0) AS AcceptedVotes
    FROM 
        PostStats ps
    LEFT JOIN 
        VoteStats vs ON ps.PostId = vs.PostId
)
SELECT 
    *,
    (ViewCount * 1.0 / NULLIF(AnswerCount, 0)) AS ViewsPerAnswer,
    (UpVotes * 1.0 / NULLIF(CommentCount, 0)) AS UpVotesPerComment
FROM 
    CombinedStats
ORDER BY 
    Score DESC
LIMIT 100;