WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        Score
    FROM RankedPosts
    WHERE TagRank <= 5
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        p.Body,
        pht.Name AS HistoryType,
        ph.Text AS HistoryDetails
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Body,
    trp.Tags,
    trp.OwnerDisplayName,
    trp.CreationDate,
    trp.Score,
    COUNT(rph.PostId) AS RecentHistoryCount,
    STRING_AGG(rph.HistoryType || ': ' || rph.HistoryDetails, '; ') AS RecentHistoryDetails
FROM TopRankedPosts trp
LEFT JOIN RecentPostHistory rph ON trp.PostId = rph.PostId
GROUP BY 
    trp.PostId,
    trp.Title,
    trp.Body,
    trp.Tags,
    trp.OwnerDisplayName,
    trp.CreationDate,
    trp.Score
ORDER BY trp.Score DESC, trp.CreationDate DESC;