WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
CelebrityUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 10000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment 
            ELSE 'No reason provided' 
            END, ', ') AS CloseReasons
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
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    cu.DisplayName AS CelebrityUser,
    cu.BadgeCount,
    pvc.UpVotes,
    pvc.DownVotes,
    cp.LastClosedDate,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    CelebrityUsers cu ON cu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostVoteCounts pvc ON pvc.PostId = rp.PostId
LEFT JOIN 
    ClosedPostDetails cp ON cp.PostId = rp.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Rank, rp.Score DESC, rp.ViewCount DESC;