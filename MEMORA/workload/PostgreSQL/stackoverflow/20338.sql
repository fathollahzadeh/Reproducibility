
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
)

SELECT 
    u.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.UpVotes IS NULL AND rp.DownVotes IS NULL THEN 'No votes yet'
        ELSE CONCAT_WS(' ', 
            COALESCE(CONCAT('Upvotes:', rp.UpVotes), 'No upvotes'), 
            COALESCE(CONCAT('Downvotes:', rp.DownVotes), 'No downvotes'))
    END AS VoteSummary,
    COALESCE(b.Name, 'No badge') AS BadgeName,
    CASE 
        WHEN (rp.UpVotes - rp.DownVotes) > 0 THEN 'Positive Engagement'
        WHEN (rp.UpVotes - rp.DownVotes) < 0 THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus,
    CASE 
        WHEN rl.PostId IS NOT NULL THEN 'Has Related Post' 
        ELSE 'No Related Post' 
    END AS RelatedPostStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1 
LEFT JOIN 
    PostLinks rl ON rp.PostId = rl.PostId AND rl.LinkTypeId = 1 
WHERE 
    rp.RN = 1
ORDER BY 
    rp.ViewCount DESC 
LIMIT 10;
