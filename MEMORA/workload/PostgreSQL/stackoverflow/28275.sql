WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON POSITION(CONCAT('<', t.TagName, '>') IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate
),

PopularPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate, 
        CommentCount, 
        VoteCount, 
        Tags
    FROM 
        RankedPosts
    WHERE 
        rn = 1 AND VoteCount > 5 

),

DetailedPostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName AS EditorDisplayName,
        ph.Comment,
        ph.Text AS NewValue
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.Id IN (SELECT PostId FROM PopularPosts) 
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.CreationDate,
    pp.CommentCount,
    pp.VoteCount,
    pp.Tags,
    dph.PostHistoryTypeId,
    dph.HistoryDate,
    dph.EditorDisplayName,
    dph.Comment,
    dph.NewValue
FROM 
    PopularPosts pp
LEFT JOIN 
    DetailedPostHistory dph ON pp.PostId = dph.PostId
ORDER BY 
    pp.VoteCount DESC, pp.CreationDate DESC;