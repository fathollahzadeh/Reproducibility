
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
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
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerUserId,
        OwnerDisplayName,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
)
SELECT 
    tp.*, 
    pth.Comment AS LastEditComment, 
    pth.CreationDate AS LastEditDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory pth ON tp.PostId = pth.PostId AND pth.PostHistoryTypeId = 24
ORDER BY 
    tp.TotalUpvotes DESC, tp.CreationDate DESC;
