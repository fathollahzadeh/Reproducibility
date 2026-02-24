
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
HighScoringPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.OwnerDisplayName,
    hsp.CommentCount,
    hsp.VoteCount,
    AVG(b.Class) AS AverageBadgeClass
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    Badges b ON hsp.PostId = b.UserId
GROUP BY 
    hsp.PostId, hsp.Title, hsp.CreationDate, hsp.Score, hsp.OwnerDisplayName, hsp.CommentCount, hsp.VoteCount
ORDER BY 
    hsp.Score DESC, hsp.CommentCount DESC;
