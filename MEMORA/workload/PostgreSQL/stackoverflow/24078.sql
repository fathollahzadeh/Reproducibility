
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(pt.UpVotes, 0) AS UpVotes,
    COALESCE(pt.DownVotes, 0) AS DownVotes,
    pt.TotalVotes,
    COALESCE(ptg.Tags, 'No Tags') AS Tags,
    ur.Reputation,
    ur.BadgeCount,
    CASE 
        WHEN cp.CloseCount IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS PostStatus,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pt ON rp.PostId = pt.PostId
LEFT JOIN 
    PostTags ptg ON rp.PostId = ptg.PostId
LEFT JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, ur.Reputation, ur.BadgeCount, 
    pt.UpVotes, pt.DownVotes, pt.TotalVotes, ptg.Tags, cp.CloseCount
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC
LIMIT 100;
