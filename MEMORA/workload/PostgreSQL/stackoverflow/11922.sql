WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.LastActivityDate,
        p.LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CombinedStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ps.OwnerDisplayName,
        ps.LastActivityDate,
        ps.LastEditDate,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(vs.TotalVotes, 0) AS TotalVotes
    FROM 
        PostStats ps
    LEFT JOIN 
        VoteStats vs ON ps.PostId = vs.PostId
)
SELECT 
    *,
    (ViewCount / NULLIF(TotalVotes, 0)) AS ViewPerVoteRatio,
    (UpVotes / NULLIF(ViewCount, 0)) AS UpVoteRatio,
    (DownVotes / NULLIF(ViewCount, 0)) AS DownVoteRatio
FROM 
    CombinedStats
ORDER BY 
    Score DESC
LIMIT 10;