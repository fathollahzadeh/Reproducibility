
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Anonymous') AS Owner,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.AnswerCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        Owner,
        Tags,
        CommentCount,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        PostDetails
    WHERE 
        AnswerCount > 0
),
FailedVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.Title,
    tp.Score,
    tp.Owner,
    tp.Tags,
    tp.CommentCount,
    COALESCE(fv.DownVotes, 0) AS DownVotes,
    COALESCE(fv.UpVotes, 0) AS UpVotes,
    CASE 
        WHEN COALESCE(fv.DownVotes, 0) > COALESCE(fv.UpVotes, 0) THEN 'Needs Improvement'
        WHEN COALESCE(fv.DownVotes, 0) = COALESCE(fv.UpVotes, 0) THEN 'Balanced'
        ELSE 'Well Received'
    END AS PostReception
FROM 
    TopPosts tp
LEFT JOIN 
    FailedVotes fv ON tp.PostId = fv.PostId
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Score DESC;
