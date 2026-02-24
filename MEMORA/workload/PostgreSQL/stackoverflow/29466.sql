
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),

RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS Rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),

PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate AS CreatedAt,
        COALESCE(re.EditDate, NULL) AS MostRecentEditDate,
        COALESCE(re.UserDisplayName, NULL) AS LastEditor,
        COALESCE(re.Comment, 'No comments') AS LastEditComment,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentEdits re ON rp.PostId = re.PostId AND re.Rn = 1
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreatedAt,
    ps.LastEditor,
    ps.LastEditComment,
    ps.CommentCount,
    ps.VoteCount   
FROM 
    PostSummary ps
ORDER BY 
    ps.CommentCount DESC, 
    ps.VoteCount DESC
LIMIT 10;
