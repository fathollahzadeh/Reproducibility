WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerName,
        DENSE_RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2023-01-01' 
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 
),

PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerName,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CommentCount,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerName, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CommentCount
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerName,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.TotalComments,
    pd.UpVotes,
    pd.DownVotes,
    CASE WHEN pd.UpVotes + pd.DownVotes > 0 THEN 
        ROUND((pd.UpVotes * 1.0 / (pd.UpVotes + pd.DownVotes)) * 100, 2)
    ELSE 0 END AS ApprovalRatio
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;