WITH RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Score,
        rp.Title,
        ru.DisplayName
    FROM 
        RecentPosts rp
    JOIN 
        RankedUsers ru ON rp.OwnerUserId = ru.Id
    WHERE 
        rp.Score > 10
)
SELECT 
    hsp.PostId,
    hsp.Title AS PostTitle,
    hsp.Score AS PostScore,
    hsp.CreationDate,
    hsp.DisplayName AS AuthorName,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.PostId = hsp.PostId AND v.VoteTypeId = 2
        ) THEN 'Highly Voted'
        ELSE 'Less Popular'
    END AS PopularityStatus,
    COALESCE(
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = hsp.PostId),
        0
    ) AS CommentCount
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    PostHistory ph ON hsp.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(CreationDate) 
        FROM PostHistory 
        WHERE PostId = hsp.PostId 
            AND PostHistoryTypeId IN (10, 11)
    )
WHERE 
    ph.PostHistoryTypeId IS NULL
ORDER BY 
    hsp.Score DESC, 
    hsp.CreationDate DESC
LIMIT 10;