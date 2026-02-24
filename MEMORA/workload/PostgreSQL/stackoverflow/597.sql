
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        PH.PostId AS EditPostId,
        PH.UserDisplayName,
        PH.CreationDate AS EditDate,
        PH.Comment AS EditComment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    JOIN 
        PostHistory PH ON p.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (4, 5) 
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName,
        rp.CommentCount,
        pa.EditDate,
        pa.EditComment,
        COALESCE(pa.UserDisplayName, 'No Edits') AS LastEditedBy,
        CASE 
            WHEN rp.Score >= 100 THEN 'Popular'
            WHEN rp.Score BETWEEN 50 AND 99 THEN 'Liked'
            ELSE 'New'
        END AS Popularity
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostActivity pa ON rp.PostId = pa.PostId AND pa.EditRank = 1
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.OwnerName,
    ps.CommentCount,
    ps.EditDate,
    ps.EditComment,
    ps.LastEditedBy,
    ps.Popularity
FROM 
    PostSummary ps
WHERE 
    ps.CommentCount > 0
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
LIMIT 10;
