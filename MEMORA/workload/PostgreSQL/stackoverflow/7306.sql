
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2) 
),
PostVoteStats AS (
    SELECT 
        pv.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes pv
    JOIN 
        VoteTypes vt ON pv.VoteTypeId = vt.Id
    GROUP BY 
        pv.PostId
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    pvs.UpVotes,
    pvs.DownVotes,
    ubc.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
JOIN 
    UserBadgeCounts ubc ON ubc.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.PostId, rp.Score DESC;
