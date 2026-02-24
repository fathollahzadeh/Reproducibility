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
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
), 

BadgeSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ' ORDER BY b.Name) AS BadgeNames
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
), 

PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    bs.BadgeNames,
    pvs.VoteCount,
    pvs.UpVotes,
    pvs.DownVotes,
    CASE 
        WHEN pvs.VoteCount IS NULL THEN 'No Votes'
        WHEN pvs.UpVotes > pvs.DownVotes THEN 'Positive Feedback'
        WHEN pvs.UpVotes < pvs.DownVotes THEN 'Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS FeedbackStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgeSummary bs ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = bs.UserId LIMIT 1)
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;