
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
        (SELECT SUM(p.ViewCount) FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalViewCount
    FROM 
        Users u
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        ud.DisplayName,
        ud.Reputation,
        ud.BadgeCount,
        ud.TotalViewCount, 
        rp.UpVotes - rp.DownVotes AS NetVotes,
        rp.Rank
    FROM 
        RankedPosts rp
    JOIN 
        UserDetails ud ON rp.OwnerUserId = ud.UserId
    WHERE 
        rp.Rank = 1
),
FilteredPosts AS (
    SELECT 
        *,
        CASE 
            WHEN NetVotes >= 10 THEN 'High Engagement'
            WHEN NetVotes BETWEEN 0 AND 9 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        PostStatistics
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.AnswerCount,
    fp.DisplayName,
    fp.Reputation,
    fp.BadgeCount,
    fp.TotalViewCount,
    fp.EngagementLevel,
    CASE 
        WHEN fp.Reputation IS NULL THEN 'No Reputation'
        ELSE CAST(fp.Reputation AS VARCHAR)
    END AS ReputationStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
WHERE 
    EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11))
ORDER BY 
    fp.CreationDate DESC 
FETCH FIRST 10 ROWS ONLY;
