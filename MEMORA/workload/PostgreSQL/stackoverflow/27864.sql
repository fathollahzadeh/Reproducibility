WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Owner,
        p.AnswerCount,
        p.Score,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),

DetailedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        p.Title AS PostTitle,
        p.Body AS PostBody,
        pt.Name AS PostHistoryType 
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'  
),

CommentDetails AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentsSummary
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.Owner,
    rp.AnswerCount,
    rp.Score,
    rp.TagRank,
    dph.UserDisplayName AS LastEditedBy,
    dph.EditDate,
    dph.Comment AS EditComment,
    dph.PostTitle,
    dph.PostBody,
    cd.CommentCount,
    cd.CommentsSummary
FROM 
    RankedPosts rp
LEFT JOIN 
    DetailedPostHistory dph ON rp.PostId = dph.PostId
LEFT JOIN 
    CommentDetails cd ON rp.PostId = cd.PostId
WHERE 
    rp.TagRank = 1  
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 50;