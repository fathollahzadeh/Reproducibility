
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT c.Id) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE WHEN rp.PostRank <= 5 THEN 'Top' ELSE 'Other' END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AnswerCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.PostCategory,
    (tp.UpVoteCount * 1.0 / NULLIF(tp.CommentCount + tp.AnswerCount, 0)) AS EngagementRatio
FROM 
    TopPosts tp
WHERE 
    tp.PostCategory = 'Top'
ORDER BY 
    tp.UpVoteCount DESC;
