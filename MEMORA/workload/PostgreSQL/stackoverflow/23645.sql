WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Post_Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS Upvote_Count,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS Downvote_Count
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS Badge_Count,
        STRING_AGG(b.Name, ', ') AS Badge_Names
    FROM Badges b
    GROUP BY b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (1, 4) THEN ph.CreationDate END) AS Last_Title_Edit,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS Last_Closed_Date,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS Last_Reopened_Date
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    rp.Title,
    rp.Body,
    rp.Score,
    rp.CreationDate,
    ub.Badge_Count,
    ub.Badge_Names,
    pd.Last_Title_Edit,
    pd.Last_Closed_Date,
    pd.Last_Reopened_Date,
    COALESCE(NULLIF(rp.Upvote_Count, 0), null) AS Upvotes_Or_Null,
    CASE 
        WHEN rp.Post_Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS Post_Type_Description
FROM RankedPosts rp
LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN PostHistoryDetails pd ON rp.PostId = pd.PostId
WHERE (pd.Last_Title_Edit IS NULL OR pd.Last_Title_Edit < cast('2024-10-01' as date) - INTERVAL '30 days')
  AND (pd.Last_CLOSED_Date IS NULL OR pd.Last_CLOSED_Date < cast('2024-10-01' as date) - INTERVAL '60 days')
ORDER BY rp.Score DESC, rp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;