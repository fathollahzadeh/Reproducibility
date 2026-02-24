
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Tags
),
RecentAcceptedAnswers AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerDisplayName,
        p.AcceptedAnswerId,
        pa.Title AS AcceptedAnswerTitle
    FROM 
        Posts p
        LEFT JOIN Posts pa ON p.AcceptedAnswerId = pa.Id
    WHERE 
        p.PostTypeId = 1
        AND pa.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostHistoryAgg AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph 
        JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.UpvoteCount,
    rp.DownvoteCount,
    rp.CommentCount,
    ra.OwnerDisplayName,
    ra.AcceptedAnswerTitle,
    pha.HistoryTypes,
    pha.HistoryCount
FROM 
    RankedPosts rp
    LEFT JOIN RecentAcceptedAnswers ra ON rp.PostId = ra.Id
    LEFT JOIN PostHistoryAgg pha ON rp.PostId = pha.PostId
WHERE 
    rp.PostRank = 1 
    AND (rp.CommentCount IS NULL OR rp.CommentCount > 0)
    AND (rp.UpvoteCount - rp.DownvoteCount) > 0
ORDER BY 
    rp.UpvoteCount DESC, rp.DownvoteCount ASC
LIMIT 50;
