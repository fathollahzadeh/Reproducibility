
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    r.CommentCount,
    r.OwnerDisplayName,
    r.RankScore,
    r.UpVoteCount,
    r.DownVoteCount,
    COALESCE(ROUND((CAST(r.UpVoteCount AS DECIMAL) / NULLIF(r.UpVoteCount + r.DownVoteCount, 0)) * 100, 2), 0) AS UpVotePercentage
FROM 
    RankedPosts r
WHERE 
    r.RankScore <= 10
ORDER BY 
    r.Score DESC, r.CreationDate DESC;
