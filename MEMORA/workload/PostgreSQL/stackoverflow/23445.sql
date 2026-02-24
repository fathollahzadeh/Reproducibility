WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.Reputation
),
PostUpdates AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS TotalEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostsWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        ur.TotalBadges,
        pu.LastClosedDate,
        pu.TotalEdits
    FROM 
        RankedPosts rp
    JOIN 
        UserReputations ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostUpdates pu ON rp.PostId = pu.PostId
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.Score,
    pwb.ViewCount,
    pwb.Reputation,
    pwb.TotalBadges,
    pwb.LastClosedDate,
    pwb.TotalEdits,
    CASE 
        WHEN pwb.Score > 10 AND pwb.TotalBadges > 5 THEN 'Highly Active Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus,
    STRING_AGG(DISTINCT COALESCE(t.TagName, 'No Tags'), ', ') AS AssociatedTags
FROM 
    PostsWithBadges pwb
LEFT JOIN 
    (SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')) AS TagName
     FROM 
        Posts p
     WHERE 
        p.Tags IS NOT NULL
    ) AS t ON pwb.PostId = t.PostId
GROUP BY 
    pwb.PostId, pwb.Title, pwb.Score, pwb.ViewCount, pwb.Reputation, pwb.TotalBadges, pwb.LastClosedDate, pwb.TotalEdits
HAVING 
    SUM(CASE WHEN pwb.LastClosedDate IS NOT NULL THEN 1 ELSE 0 END) > 0 OR 
    COUNT(DISTINCT t.TagName) > 0
ORDER BY 
    pwb.Score DESC, pwb.ViewCount ASC
LIMIT 100;