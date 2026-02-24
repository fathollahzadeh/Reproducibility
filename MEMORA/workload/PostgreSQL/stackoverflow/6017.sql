
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(b.Id) FILTER (WHERE b.UserId IS NOT NULL) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),

TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, OwnerDisplayName, ViewCount, Score, CommentCount, UpVoteCount, BadgeCount, Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    tp.*,
    pt.Name AS PostType,
    CASE 
        WHEN tp.Score > 100 THEN 'High Performer'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON EXISTS (SELECT 1 FROM Posts p WHERE p.Id = tp.PostId AND p.PostTypeId = pt.Id);
