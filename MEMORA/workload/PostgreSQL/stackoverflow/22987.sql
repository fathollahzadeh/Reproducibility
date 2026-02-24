
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(pv.VoteCount, 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        GREATEST(COALESCE(COUNT(DISTINCT c.Id), 0), NULLIF(SUM(CASE WHEN c.UserId IS NULL THEN 1 ELSE 0 END), 0)) AS CommentDetail
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) pv ON p.Id = pv.PostId
    WHERE
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, pv.VoteCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top Post'
            WHEN rp.Rank > 5 AND rp.Rank <= 10 THEN 'Mid-tier Post'
            ELSE 'Other Post'
        END AS PostCategory,
        CASE 
            WHEN rp.CommentDetail > 2 THEN 'Highly Interactive'
            WHEN rp.CommentDetail > 0 THEN 'Moderately Interactive'
            ELSE 'Rarely Commented'
        END AS InteractionLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.VoteCount > 0
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.PostCategory,
    fp.InteractionLevel,
    pht.Name AS PostHistoryType,
    COALESCE(ph.UserId, -1) AS LastUserToEdit
FROM 
    FilteredPosts fp
LEFT JOIN PostHistory ph ON fp.PostId = ph.PostId 
    AND ph.CreationDate = (
        SELECT MAX(Ph2.CreationDate)
        FROM PostHistory Ph2
        WHERE Ph2.PostId = fp.PostId
    ) 
LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    fp.CreationDate BETWEEN DATE '2021-01-01' AND TIMESTAMP '2024-10-01 12:34:56'
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;
