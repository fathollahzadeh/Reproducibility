WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.OwnerPostRank = 1 THEN 'Top Post'
            WHEN rp.OwnerPostRank <= 5 THEN 'High Performer'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    tp.*,
    CASE
        WHEN tp.ViewCount > 1000 THEN 'Highly Viewed'
        WHEN tp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
        ELSE 'Low Visibility'
    END AS VisibilityCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC, 
    tp.Score DESC
LIMIT 50;