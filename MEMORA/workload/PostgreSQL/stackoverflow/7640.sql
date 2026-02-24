WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.FavoriteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
TopPostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        COALESCE(uc.UserCount, 0) AS UserCount,
        COALESCE(v.ItemCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS TotalComments
    FROM 
        TopPosts tp
    LEFT JOIN (
        SELECT 
            PostId, COUNT(DISTINCT UserId) AS UserCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) uc ON tp.PostId = uc.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS ItemCount
        FROM 
            Votes
        WHERE 
            VoteTypeId IN (2, 3) 
        GROUP BY 
            PostId
    ) v ON tp.PostId = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON tp.PostId = c.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.FavoriteCount,
    pd.UserCount,
    pd.VoteCount,
    pd.TotalComments
FROM 
    TopPosts tp
JOIN 
    TopPostDetails pd ON tp.PostId = pd.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;