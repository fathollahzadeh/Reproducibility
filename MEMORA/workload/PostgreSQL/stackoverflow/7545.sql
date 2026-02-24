WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS UpvoteCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        CommentCount,
        UpvoteCount,
        PostRank
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpvoteCount,
    ph.UserDisplayName AS LastEditedBy,
    ph.CreationDate AS LastEditDate,
    ph.Comment AS EditComment
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 24)
WHERE 
    ph.CreationDate = (
        SELECT MAX(CreationDate)
        FROM PostHistory
        WHERE PostId = tp.PostId AND PostHistoryTypeId IN (4, 5, 24)
    )
ORDER BY 
    tp.ViewCount DESC;
