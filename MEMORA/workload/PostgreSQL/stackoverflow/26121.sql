WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Owner,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),

RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        ph.PostHistoryTypeId,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
)

SELECT 
    rp.Title,
    rp.Owner,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    array_agg(DISTINCT r.Title) AS RelatedPosts,
    CASE 
        WHEN re.PostId IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    COUNT(DISTINCT re.UserId) AS UniqueEditors
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1
LEFT JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
LEFT JOIN 
    Posts r ON pl.RelatedPostId = r.Id
WHERE 
    rp.Rank <= 5  
GROUP BY 
    rp.PostId, rp.Title, rp.Owner, rp.ViewCount, rp.AnswerCount, rp.CommentCount, re.PostId
ORDER BY 
    rp.ViewCount DESC;