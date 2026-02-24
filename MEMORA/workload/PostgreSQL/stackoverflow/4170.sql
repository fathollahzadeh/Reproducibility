
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
ClosedPosts AS (
    SELECT 
        h.PostId, 
        h.CreationDate,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = h.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        PostHistory h
    WHERE 
        h.PostHistoryTypeId = 10
)
SELECT 
    us.UserId, 
    us.DisplayName, 
    us.Reputation, 
    us.UpVotes, 
    us.DownVotes, 
    pd.Title, 
    pd.Score, 
    pd.ViewCount, 
    pp.CloseCount
FROM 
    UserStats us
LEFT JOIN 
    PostDetails pd ON us.UserId = pd.OwnerUserId 
LEFT JOIN 
    ClosedPosts pp ON pd.PostId = pp.PostId
WHERE 
    us.Reputation > 1000 
    AND (us.UpVotes - us.DownVotes) > 100
    AND pd.rn <= 5
ORDER BY 
    us.Reputation DESC, pd.Score DESC;
