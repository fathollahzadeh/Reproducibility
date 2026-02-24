
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.ParentId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (ORDER BY p.Score DESC) AS RankByScore,
        p.OwnerUserId
    FROM Posts p
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24) THEN 1 END) AS EditSuggestionsCount
    FROM PostHistory ph
    WHERE ph.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months')
    GROUP BY ph.PostId
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ur.Reputation,
    ur.TotalBadges,
    phd.LastChangeDate,
    phd.ClosureCount,
    phd.EditSuggestionsCount,
    pvs.UpVotes,
    pvs.DownVotes,
    CASE 
        WHEN phd.ClosureCount > 0 THEN 'Closed'
        WHEN phd.EditSuggestionsCount > 0 THEN 'Under Edit Suggestion Review'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN rp.RankByViews = 1 THEN 'Most Viewed'
        WHEN rp.RankByScore = 1 THEN 'Top Scored'
        ELSE 'Regular Post'
    END AS PostCategory,
    STRING_AGG('Tag: ' || t.TagName, ', ') AS Tags
FROM RankedPosts rp
JOIN UserReputation ur ON ur.UserId = rp.OwnerUserId
LEFT JOIN PostHistoryDetail phd ON phd.PostId = rp.PostId
LEFT JOIN PostVoteStats pvs ON pvs.PostId = rp.PostId
LEFT JOIN LATERAL (
    SELECT 
        DISTINCT UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS TagName
    FROM Posts p 
    WHERE p.Id = rp.PostId
) AS t ON TRUE
WHERE 
    ur.Reputation >= 100 AND
    (pvs.UpVotes - pvs.DownVotes) > 5
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ViewCount, 
    ur.Reputation, ur.TotalBadges, 
    phd.LastChangeDate, phd.ClosureCount, phd.EditSuggestionsCount,
    pvs.UpVotes, pvs.DownVotes, rp.RankByViews, rp.RankByScore
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC
LIMIT 100;
