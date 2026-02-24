WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
    GROUP BY 
        p.Id, u.Id 
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, '>')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
AggregatedUserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.UserDisplayName,
    rp.CommentCount,
    tp.TagName,
    cp.CloseReasons,
    aus.DisplayName AS TopUser,
    aus.GoldBadges,
    aus.SilverBadges,
    aus.BronzeBadges,
    aus.AvgBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    AggregatedUserStats aus ON aus.Id = (SELECT UserId FROM Users WHERE Reputation = (SELECT MAX(Reputation) FROM Users))
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CommentCount DESC NULLS LAST, 
    rp.Title ASC
LIMIT 100;