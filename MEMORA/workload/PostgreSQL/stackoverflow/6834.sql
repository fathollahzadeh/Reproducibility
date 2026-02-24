
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 3
),
PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.Score,
        trp.ViewCount,
        trp.AnswerCount,
        trp.CommentCount,
        trp.OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(c.Id) AS TotalComments
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Votes v ON trp.PostId = v.PostId
    LEFT JOIN 
        Comments c ON trp.PostId = c.PostId
    GROUP BY 
        trp.PostId, trp.Title, trp.Score, trp.ViewCount, trp.AnswerCount, trp.CommentCount, trp.OwnerDisplayName
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pd.TotalUpVotes,
    pd.TotalDownVotes,
    pd.TotalComments
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 10;
