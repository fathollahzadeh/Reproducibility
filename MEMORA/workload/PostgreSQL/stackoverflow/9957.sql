
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount, p.AcceptedAnswerId
),
RankedPostHistory AS (
    SELECT 
        ph.PostId,
        pht.Name AS PostHistoryType,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, pht.Name
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AcceptedAnswerId,
        rp.Upvotes,
        rp.Downvotes,
        rp.CommentCount,
        COALESCE(rph.EditCount, 0) AS EditCount,
        rp.RowNum
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RankedPostHistory rph ON rp.PostId = rph.PostId
)
SELECT 
    *,
    (Upvotes - Downvotes) AS NetVoteScore,
    CASE 
        WHEN RowNum = 1 THEN 'Recent Question'
        WHEN RowNum = 2 THEN 'Second Latest'
        ELSE 'Older Post'
    END AS PostAgeCategory
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC, CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
