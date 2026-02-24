
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    COALESCE(AVG(b.Class), 0) AS AverageBadgeClass,
    COALESCE(STRING_AGG(DISTINCT REPLACE(t.TagName, '<', '&lt;'), ', '), '') AS AssociatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    Posts p ON p.Id = tp.PostId
LEFT JOIN 
    (SELECT 
        pt.Id AS PostId, 
        t.TagName
     FROM 
        Posts pt
     JOIN 
        Tags t ON t.ExcerptPostId = pt.Id) AS t ON t.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.Score, tp.UpVotes, tp.DownVotes, tp.CommentCount
ORDER BY 
    tp.Score DESC;
