WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalUserPosts,
        STRING_AGG(t.TagName, ', ') AS AssociatedTags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.Score, p.OwnerUserId
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE NULL END), 0) AS TotalVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
PostInteraction AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        us.DisplayName,
        us.Reputation AS UserReputation,
        rp.AssociatedTags,
        CASE 
            WHEN rp.Score >= 10 THEN 'Hot'
            WHEN rp.Score BETWEEN 5 AND 9 THEN 'Trending'
            ELSE 'Normal'
        END AS PopularityLevel
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON us.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
    WHERE 
        rp.UserPostRank <= 3
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.UserReputation,
    pi.PopularityLevel,
    pi.AssociatedTags,
    pht.Name AS PostHistoryType,
    ph.CreationDate AS HistoryCreationDate,
    ph.UserDisplayName AS EditorDisplayName
FROM 
    PostInteraction pi
LEFT JOIN 
    PostHistory ph ON ph.PostId = pi.PostId
LEFT JOIN 
    PostHistoryTypes pht ON pht.Id = ph.PostHistoryTypeId
WHERE 
    ph.CreationDate >= pi.CreationDate
    AND pi.PopularityLevel = 'Hot'
    AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pi.PostId) > 5
ORDER BY 
    pi.Score DESC, 
    UserReputation DESC
LIMIT 100;