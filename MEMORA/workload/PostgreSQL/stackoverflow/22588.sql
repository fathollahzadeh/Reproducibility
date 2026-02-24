
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        um.PostCount,
        um.GoldBadges,
        um.SilverBadges,
        um.BronzeBadges,
        um.UpVotesCount,
        um.DownVotesCount,
        RANK() OVER (ORDER BY um.Reputation DESC) AS ReputationRank
    FROM 
        UserMetrics um
)
SELECT 
    ru.PostId,
    ru.Title AS PostTitle,
    ru.PostTypeId,
    ru.CreationDate,
    ru.OwnerUserId,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(u.Reputation, 0) AS OwnerReputation,
    COALESCE(ru.Score, 0) AS PostScore,
    CASE 
        WHEN ru.Rank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostCategory,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ru.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ru.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ru.PostId AND v.VoteTypeId = 3) AS DownVotes,
    t.ReputationRank
FROM 
    RecentPosts ru
JOIN 
    Users u ON ru.OwnerUserId = u.Id
JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    ru.AcceptedAnswerId IS NULL
ORDER BY 
    ru.CreationDate DESC
LIMIT 100
OFFSET 0;
