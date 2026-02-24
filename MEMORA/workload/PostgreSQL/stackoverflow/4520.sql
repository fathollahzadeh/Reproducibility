WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), UserPostVotes AS (
    SELECT 
        v.PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
), PostWithHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
), RichPostData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(upv.UpVotes, 0) AS UpVotes,
        COALESCE(upv.DownVotes, 0) AS DownVotes,
        ph.HistoryTypes,
        ph.HistoryCount,
        COALESCE(rp.Rank, 0) AS Rank
    FROM RankedPosts rp
    LEFT JOIN UserPostVotes upv ON rp.PostId = upv.PostId
    LEFT JOIN PostWithHistory ph ON rp.PostId = ph.PostId
)
SELECT 
    rpd.*,
    CASE 
        WHEN rpd.Score > 100 THEN 'Highly Rated'
        WHEN rpd.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rpd.PostId) AS CommentCount
FROM RichPostData rpd
WHERE rpd.Rank <= 10 OR rpd.HistoryCount > 5
ORDER BY rpd.Score DESC, rpd.CreationDate DESC;