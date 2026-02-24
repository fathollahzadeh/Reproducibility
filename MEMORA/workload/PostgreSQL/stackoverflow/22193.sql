
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseReasonsCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(cp.CloseReasonsCount, 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes, 
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, cp.CloseReasonsCount, p.ViewCount
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        us.UsersWithBadges,
        ps.CloseCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.ViewCount,
        CASE 
            WHEN ps.UpVotes - ps.DownVotes > 0 THEN 'Positive' 
            WHEN ps.UpVotes - ps.DownVotes < 0 THEN 'Negative' 
            ELSE 'Neutral' 
        END AS Sentiment
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            u.Id,
            COUNT(DISTINCT b.Id) AS UsersWithBadges
        FROM 
            Users u
        INNER JOIN 
            Badges b ON u.Id = b.UserId
        GROUP BY 
            u.Id
    ) us ON rp.PostId = us.Id
    LEFT JOIN 
        PostStatistics ps ON rp.PostId = ps.PostId
    WHERE 
        rp.Rank = 1 
)
SELECT 
    fo.PostId,
    fo.Title,
    COALESCE(fo.CreationDate, CAST('2024-10-01 12:34:56' AS TIMESTAMP)) AS PostCreationDate,
    fo.CloseCount,
    fo.UpVotes,
    fo.DownVotes,
    fo.ViewCount,
    fo.Sentiment
FROM 
    FinalOutput fo
WHERE 
    fo.CloseCount IS NULL OR fo.CloseCount < 5
ORDER BY 
    fo.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
