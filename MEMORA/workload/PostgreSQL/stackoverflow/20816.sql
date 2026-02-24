
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.Score IS NOT NULL
),
UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        STRING_AGG(CONCAT(ph.UserDisplayName, ' - ', ph.Comment), '; ') AS Comments
    FROM PostHistory ph
    WHERE ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY ph.PostId, ph.PostHistoryTypeId, ph.UserId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ua.TotalVotes,
    ua.Upvotes,
    ua.Downvotes,
    ua.BadgesCount,
    phd.Comments,
    CASE 
        WHEN ua.TotalVotes IS NULL OR ua.TotalVotes = 0 THEN 'No Activity'
        WHEN ua.Upvotes > ua.Downvotes THEN 'Positive Activity'
        WHEN ua.Upvotes < ua.Downvotes THEN 'Negative Activity'
        ELSE 'Neutral Activity'
    END AS UserActivityStatus
FROM RankedPosts rp
LEFT JOIN UserActivities ua ON EXISTS (
    SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.UserId = ua.UserId
)
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
