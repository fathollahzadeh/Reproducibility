WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.Reputation DESC) AS UserRank
    FROM
        Users u
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY UserId
    ) v ON u.Id = v.UserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY UserId
    ) c ON u.Id = c.UserId
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM
        Posts p
    WHERE
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosed
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY
        ph.PostId
)
SELECT
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    pd.Title AS RecentPostTitle,
    pd.Score AS PostScore,
    pd.ViewCount AS PostViewCount,
    COUNT(DISTINCT cp.PostId) AS ClosedPostCount
FROM
    UserStats us 
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    PostDetails pd ON p.Id = pd.PostId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE
    us.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND pd.RecentPostRank <= 3
GROUP BY
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    pd.Title,
    pd.Score,
    pd.ViewCount
HAVING
    COUNT(DISTINCT cp.PostId) >= 1
ORDER BY
    us.Reputation DESC, us.BadgeCount DESC
LIMIT 10;