
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.VoteRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AnswerCount,
    tp.TotalBounty,
    pt.Name AS PostType,
    COUNT(DISTINCT ph.Id) AS HistoricalChangeCount
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId = pt.Id
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.CommentCount, tp.AnswerCount, tp.TotalBounty, pt.Name
ORDER BY 
    tp.TotalBounty DESC, tp.CommentCount DESC;
