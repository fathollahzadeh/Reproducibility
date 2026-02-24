
WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        MAX(ph.CreationDate) AS LastHistoryUpdate
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
VoteAnalytics AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes v
    INNER JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.OwnerDisplayName,
    pa.CommentCount,
    pa.BadgeCount,
    pa.LastHistoryUpdate,
    COALESCE(va.VoteCount, 0) AS TotalVotes,
    COALESCE(va.Upvotes, 0) AS Upvotes,
    COALESCE(va.Downvotes, 0) AS Downvotes
FROM PostAnalytics pa
LEFT JOIN VoteAnalytics va ON pa.PostId = va.PostId
ORDER BY pa.CreationDate DESC
LIMIT 100;
