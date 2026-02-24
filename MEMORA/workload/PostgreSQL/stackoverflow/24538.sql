
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(v.upVotes, 0) AS UpVotes,
        COALESCE(v.downVotes, 0) AS DownVotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RowNum,
        pt.Name AS PostTypeName
    FROM Posts p
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS upVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS downVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes ctr ON ph.Comment::INTEGER = ctr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY p.Id
),
PostMeta AS (
    SELECT 
        r.PostId,
        r.Title,
        r.ViewCount,
        r.UpVotes,
        r.DownVotes,
        rc.LastClosedDate,
        rc.CloseReasons,
        CASE 
            WHEN (r.UpVotes - r.DownVotes) > 0 THEN 'Positive'
            WHEN (r.UpVotes - r.DownVotes) < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM RankedPosts r
    LEFT JOIN RecentClosedPosts rc ON r.PostId = rc.PostId
    WHERE r.RowNum = 1
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.LastClosedDate,
    pm.CloseReasons,
    pm.Sentiment,
    CASE 
        WHEN pm.UpVotes > 5 THEN 'Popular'
        ELSE 'Regular'
    END AS Popularity,
    CASE 
        WHEN pm.LastClosedDate IS NOT NULL AND pm.Sentiment = 'Negative' THEN 'Revise'
        WHEN pm.LastClosedDate IS NULL AND pm.Sentiment = 'Positive' THEN 'Promote'
        ELSE 'Evaluate'
    END AS ActionRecommended
FROM PostMeta pm
WHERE pm.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY pm.ViewCount DESC;
