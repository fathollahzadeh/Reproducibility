
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
HighScoringPosts AS (
    SELECT * FROM RankedPosts
    WHERE Rank <= 100
),
PostHistoryInfo AS (
    SELECT
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        p.Id
)
SELECT 
    rsp.PostId,
    rsp.Title,
    rsp.CreationDate,
    rsp.ViewCount,
    rsp.Score,
    rsp.Author,
    rsp.Tags,
    rsp.CommentCount,
    phi.LastEdited,
    phi.EditCount,
    phi.EditTypes
FROM 
    HighScoringPosts rsp
LEFT JOIN 
    PostHistoryInfo phi ON rsp.PostId = phi.PostId
ORDER BY 
    rsp.Score DESC, rsp.ViewCount DESC;
