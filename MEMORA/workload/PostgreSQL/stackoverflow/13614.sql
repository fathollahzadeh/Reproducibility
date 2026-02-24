WITH PostInteractionCounts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PostSummary AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(ic.CommentCount, 0) AS CommentCount,
        COALESCE(ic.VoteCount, 0) AS VoteCount,
        COALESCE(ic.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(ic.DownVoteCount, 0) AS DownVoteCount,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        PostInteractionCounts ic ON p.Id = ic.PostId
)
SELECT
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.Score,
    ps.ViewCount
FROM 
    PostSummary ps
ORDER BY 
    ps.CreationDate DESC;