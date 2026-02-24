WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PostRankings AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'High Engagement'
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.CommentCount,
    pr.UpVotes,
    pr.DownVotes,
    pr.EngagementLevel,
    COALESCE(b.Name, 'No Badge') AS UserBadge,
    u.Reputation AS UserReputation
FROM 
    PostRankings pr
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = pr.PostId)
LEFT JOIN 
    Badges b ON b.UserId = u.Id AND b.Class = 1
WHERE 
    EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = pr.PostId AND v.VoteTypeId IN (2, 3))
ORDER BY 
    pr.UpVotes DESC, pr.CommentCount DESC
LIMIT 10;